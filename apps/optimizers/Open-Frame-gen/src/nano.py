import os
import platform
import torch
import torch.nn as nn
import torch.nn.functional as F

if platform.system() == "Windows":
    os.environ["TORCHDYNAMO_DISABLE"] = "1"

def _dw_conv(in_ch, out_ch, stride=1):
    return nn.Sequential(
        nn.Conv2d(in_ch, in_ch, 3, stride=stride, padding=1, groups=in_ch, bias=False),
        nn.BatchNorm2d(in_ch),
        nn.LeakyReLU(0.1, inplace=True),
        nn.Conv2d(in_ch, out_ch, 1, bias=True),
        nn.BatchNorm2d(out_ch),
        nn.LeakyReLU(0.1, inplace=True),
    )

class SEBlock(nn.Module):
    def __init__(self, ch, r=8):
        super().__init__()
        mid = max(ch // r, 4)
        self.fc = nn.Sequential(
            nn.Linear(ch, mid),
            nn.ReLU(inplace=True),
            nn.Linear(mid, ch),
            nn.Sigmoid(),
        )

    def forward(self, x):
        # Global Avg Pool via mean
        w = torch.mean(x, dim=(2, 3))
        w = self.fc(w)
        return x * w.unsqueeze(-1).unsqueeze(-1)

class NanoModel(nn.Module):
    def __init__(self):
        super().__init__()
        self.e1 = _dw_conv(6, 48, stride=2)
        self.e2 = _dw_conv(48, 96, stride=2)
        self.e3 = _dw_conv(96, 128, stride=2)
        self.btn = _dw_conv(128, 96)
        self.se = SEBlock(96, r=8)
        self.d1 = _dw_conv(96 + 128, 96)
        self.d2 = _dw_conv(96 + 96, 64)
        self.d3 = _dw_conv(64 + 48, 32)
        self.head = nn.Sequential(
            nn.Conv2d(32, 32, 3, 1, 1),
            nn.LeakyReLU(0.1, inplace=True),
            nn.Conv2d(32, 3, 3, 1, 1),
        )
        self.register_buffer('_t', torch.tensor([0.5], dtype=torch.float32))

    def warp(self, img, flow):
        b, _, h, w = flow.shape
        
        # Grid generation without meshgrid named indexing
        # This is more robust for older ONNX tracers
        grid_y = torch.linspace(-1, 1, h, device=flow.device, dtype=flow.dtype)
        grid_x = torch.linspace(-1, 1, w, device=flow.device, dtype=flow.dtype)
        
        gy, gx = torch.meshgrid(grid_y, grid_x, indexing='ij')
        base_grid = torch.stack([gx, gy], dim=-1).unsqueeze(0)
        
        # Scale flow to [-1, 1]
        flow_norm = torch.stack([
            flow[:, 0] * (2.0 / (w - 1.0)),
            flow[:, 1] * (2.0 / (h - 1.0))
        ], dim=-1)
        
        grid = base_grid + flow_norm
        return F.grid_sample(img, grid, mode='bilinear', padding_mode='border', align_corners=True)

    def set_timestamp(self, t):
        """Set interpolation timestamp (0.0 to 1.0)"""
        self._t.fill_(t)
    
    def forward(self, x, return_flow=False):
        # Using fixed shape variables for interpolation to ensure constants
        b, c, h, w = x.shape
        
        img0, img1 = x[:, :3], x[:, 3:]
        
        # 1. Feature Extraction
        # Use constant size for pooling
        xs = F.avg_pool2d(x, 2) 
        
        s1 = self.e1(xs) # H/4
        s2 = self.e2(s1) # H/8
        s3 = self.e3(s2) # H/16
        
        # 2. Bottleneck
        b_feat = self.se(self.btn(s3))
        
        # 3. Decoding
        u1 = self.d1(torch.cat([b_feat, s3], dim=1))
        
        # Upsample via size tuple
        u2_size = (h // 8, w // 8)
        u2 = F.interpolate(u1, size=u2_size, mode='bilinear', align_corners=False)
        u2 = self.d2(torch.cat([u2, s2], dim=1))
        
        u3_size = (h // 4, w // 4)
        u3 = F.interpolate(u2, size=u3_size, mode='bilinear', align_corners=False)
        u3 = self.d3(torch.cat([u3, s1], dim=1))
        
        # 4. Head
        out = self.head(u3)
        flow = out[:, :2]
        mask = torch.sigmoid(out[:, 2:3])
        
        # 5. Upscale
        flow_full = F.interpolate(flow, size=(h, w), mode='bilinear', align_corners=False) * 4.0
        mask_full = F.interpolate(mask, size=(h, w), mode='bilinear', align_corners=False)
        
        # 6. Warp & Blend
        t = self._t[0]
        
        warped0 = self.warp(img0, flow_full * t)
        warped1 = self.warp(img1, flow_full * (t - 1.0))
        
        res = warped0 * mask_full + warped1 * (1.0 - mask_full)
        res = torch.clamp(res, 0.0, 1.0)
        
        if return_flow:
            return res, flow_full
        return res

class NanoEngine:
    def __init__(self, model_path, input_shape=(1080, 1920), low_vram=False):
        self.device = torch.device("cuda")
        self.model = NanoModel().to(self.device).half().eval()
        if os.path.exists(model_path):
            self.model.load_state_dict(torch.load(model_path, map_location=self.device))
        
        self.input_shape = input_shape
        self.static_input = torch.randn(1, 6, *input_shape, device=self.device, dtype=torch.float16)
        
        # Warmup & Capture CUDA Graph
        for _ in range(3): 
            with torch.inference_mode():
                self.model(self.static_input)
        
        self.graph = torch.cuda.CUDAGraph()
        with torch.cuda.graph(self.graph):
            self.static_output = self.model(self.static_input)

    def infer_tensor(self, x, t=0.5):
        # x is [1, 6, H, W]
        self.static_input.copy_(x)
        self.graph.replay()
        # Return [3, H, W] uint8 RGB
        return (self.static_output[0] * 255).byte()
