#!/data/data/com.termux/files/usr/bin/bash
# CT Thermo Lab Pro - Termux v3
echo "=== CT Thermo Lab Pro - Termux v3 ==="
if ! command -v termux-sms-list >/dev/null; then echo "pkg install termux-api + app Termux:API F-Droid"; exit 1; fi
termux-sms-list -l 30 > /tmp/sms.json
HEX=$(grep -oE "[0-9A-Fa-f]{120,}" /tmp/sms.json | tail -1)
if [ -z "$HEX" ]; then echo "No HEX largo"; grep -o "#ADC.*" /tmp/sms.json | tail -10; exit 0; fi
echo "HEX: ${HEX:0:80}..."
python ~/calamp_decoder_v3.py "$HEX"
