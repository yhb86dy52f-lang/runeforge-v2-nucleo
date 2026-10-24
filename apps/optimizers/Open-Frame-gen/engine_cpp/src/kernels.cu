#include <cuda_runtime.h>
#include <device_launch_parameters.h>
#include <cuda_fp16.h>

// BGRA -> Planar FP16 RGB with HIGH-QUALITY bilinear downscale (matching PyTorch's interpolate)
__global__ void ConvertBGRAToPlanarFP16Scaled(const unsigned char* bgra, __half* output, int sw, int sh, int dw, int dh, int pitch) {
    int dx = blockIdx.x * blockDim.x + threadIdx.x;
    int dy = blockIdx.y * blockDim.y + threadIdx.y;
    if (dx < dw && dy < dh) {
        // Match PyTorch F.interpolate behavior with align_corners=False
        // This uses pixel centers: src_coord = (dst_coord + 0.5) * scale - 0.5
        float scaleX = (float)sw / dw;
        float scaleY = (float)sh / dh;
        float sx_f = ((float)dx + 0.5f) * scaleX - 0.5f;
        float sy_f = ((float)dy + 0.5f) * scaleY - 0.5f;
        
        // Clamp to valid range
        sx_f = fmaxf(0.0f, fminf(sx_f, (float)(sw - 1)));
        sy_f = fmaxf(0.0f, fminf(sy_f, (float)(sh - 1)));
        
        int sx0 = (int)sx_f;
        int sy0 = (int)sy_f;
        int sx1 = min(sx0 + 1, sw - 1);
        int sy1 = min(sy0 + 1, sh - 1);
        float fx = sx_f - sx0;
        float fy = sy_f - sy0;
        
        // Bilinear fetch for each channel
        #define GET_BGRA(x, y, c) ((float)bgra[(y) * pitch + (x) * 4 + (c)] / 255.0f)
        
        float r = GET_BGRA(sx0,sy0,2)*(1-fx)*(1-fy) + GET_BGRA(sx1,sy0,2)*fx*(1-fy) 
                + GET_BGRA(sx0,sy1,2)*(1-fx)*fy     + GET_BGRA(sx1,sy1,2)*fx*fy;
        float g = GET_BGRA(sx0,sy0,1)*(1-fx)*(1-fy) + GET_BGRA(sx1,sy0,1)*fx*(1-fy) 
                + GET_BGRA(sx0,sy1,1)*(1-fx)*fy     + GET_BGRA(sx1,sy1,1)*fx*fy;
        float b = GET_BGRA(sx0,sy0,0)*(1-fx)*(1-fy) + GET_BGRA(sx1,sy0,0)*fx*(1-fy) 
                + GET_BGRA(sx0,sy1,0)*(1-fx)*fy     + GET_BGRA(sx1,sy1,0)*fx*fy;
        #undef GET_BGRA
        
        int planeSize = dw * dh;
        output[0 * planeSize + dy * dw + dx] = __float2half(r);
        output[1 * planeSize + dy * dw + dx] = __float2half(g);
        output[2 * planeSize + dy * dw + dx] = __float2half(b);
    }
}

// Planar FP16 RGB -> BGRA with HIGH-QUALITY bilinear upscale (matching OpenGL GL_LINEAR)
// Includes sharpening + saturation/contrast boost to match real frames
__global__ void ConvertAndSharpenScaled(const __half* input, unsigned char* bgra, int sw, int sh, int dw, int dh, int pitch, float sharpness) {
    int dx = blockIdx.x * blockDim.x + threadIdx.x;
    int dy = blockIdx.y * blockDim.y + threadIdx.y;
    if (dx < dw && dy < dh) {
        // Match PyTorch/OpenGL behavior: pixel-center aligned bilinear
        float scaleX = (float)sw / dw;
        float scaleY = (float)sh / dh;
        float sx_f = ((float)dx + 0.5f) * scaleX - 0.5f;
        float sy_f = ((float)dy + 0.5f) * scaleY - 0.5f;
        
        // Clamp
        sx_f = fmaxf(0.0f, fminf(sx_f, (float)(sw - 1)));
        sy_f = fmaxf(0.0f, fminf(sy_f, (float)(sh - 1)));
        
        int sx0 = (int)sx_f;
        int sy0 = (int)sy_f;
        int sx1 = min(sx0 + 1, sw - 1);
        int sy1 = min(sy0 + 1, sh - 1);
        float fx = sx_f - sx0;
        float fy = sy_f - sy0;

        int planeSize = sw * sh;
        
        // Lambda for bilinear fetch of a single channel
        auto bilinear = [&](int c) {
            float v00 = __half2float(input[c * planeSize + sy0 * sw + sx0]);
            float v10 = __half2float(input[c * planeSize + sy0 * sw + sx1]);
            float v01 = __half2float(input[c * planeSize + sy1 * sw + sx0]);
            float v11 = __half2float(input[c * planeSize + sy1 * sw + sx1]);
            return v00*(1-fx)*(1-fy) + v10*fx*(1-fy) + v01*(1-fx)*fy + v11*fx*fy;
        };
        
        float r = bilinear(0);
        float g = bilinear(1);
        float b = bilinear(2);

        // Optional CAS (Contrast Adaptive Sharpening) style enhancement
        if (sharpness > 0.0f && sx0 > 0 && sy0 > 0 && sx1 < sw-1 && sy1 < sh-1) {
            auto get = [&](int x, int y, int c) {
                return __half2float(input[c * planeSize + y * sw + x]);
            };
            
            int cx = (sx0 + sx1) / 2;
            int cy = (sy0 + sy1) / 2;
            cx = max(1, min(sw-2, cx));
            cy = max(1, min(sh-2, cy));
            
            for (int c = 0; c < 3; c++) {
                float center = get(cx, cy, c);
                float n = get(cx, cy-1, c);
                float s = get(cx, cy+1, c);
                float e = get(cx+1, cy, c);
                float w = get(cx-1, cy, c);
                
                float mn = fminf(fminf(fminf(n, s), fminf(e, w)), center);
                float mx = fmaxf(fmaxf(fmaxf(n, s), fmaxf(e, w)), center);
                
                float* channel = (c == 0) ? &r : (c == 1) ? &g : &b;
                float avg = (n + s + e + w) * 0.25f;
                float detail = center - avg;
                float sharpened = *channel + detail * sharpness;
                *channel = fmaxf(mn, fminf(mx, sharpened));
            }
        }

        // === COLOR MATCHING: Slight contrast & saturation boost ===
        
        // 1. Subtle contrast boost (expand toward 0/1, centered at 0.5)
        const float contrastBoost = 1.01f;  // 8% more contrast
        r = (r - 0.5f) * contrastBoost + 0.5f;
        g = (g - 0.5f) * contrastBoost + 0.5f;
        b = (b - 0.5f) * contrastBoost + 0.5f;
        
        // 2. Subtle saturation boost (push colors away from gray)
        const float satBoost = 1.08f;  // 8% more saturation
        float luma = 0.299f * r + 0.587f * g + 0.114f * b;
        r = luma + (r - luma) * satBoost;
        g = luma + (g - luma) * satBoost;
        b = luma + (b - luma) * satBoost;
        
        // Clamp to valid range
        r = fmaxf(0.0f, fminf(1.0f, r));
        g = fmaxf(0.0f, fminf(1.0f, g));
        b = fmaxf(0.0f, fminf(1.0f, b));

        // Write output with proper rounding
        int idx = dy * pitch + dx * 4;
        bgra[idx + 0] = (unsigned char)(b * 255.0f + 0.5f);
        bgra[idx + 1] = (unsigned char)(g * 255.0f + 0.5f);
        bgra[idx + 2] = (unsigned char)(r * 255.0f + 0.5f);
        bgra[idx + 3] = 255;
    }
}

extern "C" void LaunchBGRAToPlanarFP16(const unsigned char* bgra, void* output, int sw, int sh, int dw, int dh, int pitch, cudaStream_t stream) {
    dim3 block(16, 16); 
    dim3 grid((unsigned int)(dw + block.x - 1) / block.x, (unsigned int)(dh + block.y - 1) / block.y);
    ConvertBGRAToPlanarFP16Scaled<<<grid, block, 0, stream>>>(bgra, (__half*)output, sw, sh, dw, dh, pitch);
}

extern "C" void LaunchPlanarFP16ToBGRA(const void* input, unsigned char* bgra, int sw, int sh, int dw, int dh, int pitch, float sharpness, cudaStream_t stream) {
    dim3 block(16, 16); 
    dim3 grid((unsigned int)(dw + block.x - 1) / block.x, (unsigned int)(dh + block.y - 1) / block.y);
    ConvertAndSharpenScaled<<<grid, block, 0, stream>>>((const __half*)input, bgra, sw, sh, dw, dh, pitch, sharpness);
}
