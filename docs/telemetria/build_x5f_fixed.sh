#!/data/data/com.termux/files/usr/bin/bash
set -e
cd ~/public/DECODE || { echo "❌ No DECODE"; exit 1; }
echo "🧹 Limpiando"
rm -rf apk_build
mkdir -p apk_build/assets apk_build/res/drawable apk_build/java/com/sepcol/gps

echo "📝 tsconfig.json Cero Bloat fix"
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "es2017",
    "module": "esnext",
    "lib": ["es2015","es2016","dom"],
    "strict": false,
    "esModuleInterop": true,
    "skipLibCheck": true
  },
  "include": ["*.ts"]
}
EOF

echo "☕ Compilando TS con lib es2015"
npx tsc --lib es2015,dom --target es2017 ct.ts kw.ts r0.ts || echo "⚠️ usando JS existentes"

echo "📝 Corrigiendo index.html .ts->.js + viewport"
sed -i 's/\.ts"/.js"/g' index.html
if ! grep -q "viewport" index.html; then
  sed -i 's/<head>/<head>\n    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">/' index.html
fi

echo "📂 Copiando assets"
cp index.html app.css icon.png *.js apk_build/assets/
cp icon.png apk_build/res/drawable/icon.png
cd apk_build

if [ ! -f android.jar ]; then
  curl -sL -o android.jar https://github.com/Sable/android-platforms/raw/master/android-30/android.jar
fi

cat > AndroidManifest.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="com.sepcol.gps">
    <uses-permission android:name="android.permission.INTERNET" />
    <application android:label="SEPCOLGPS NEXUS v20" android:icon="@drawable/icon" android:theme="@android:style/Theme.NoTitleBar">
        <activity android:name=".MainActivity" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF

cat > java/com/sepcol/gps/MainActivity.java << 'EOF'
package com.sepcol.gps;
import android.app.Activity;
import android.os.Bundle;
import android.webkit.WebView;
import android.webkit.WebSettings;
public class MainActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        WebView webView = new WebView(this);
        WebSettings s = webView.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setUseWideViewPort(true);
        s.setLoadWithOverviewMode(true);
        s.setLayoutAlgorithm(WebSettings.LayoutAlgorithm.NORMAL);
        s.setSupportZoom(false);
        s.setBuiltInZoomControls(false);
        s.setDisplayZoomControls(false);
        s.setAllowFileAccess(true);
        s.setAllowFileAccessFromFileURLs(true);
        webView.loadUrl("file:///android_asset/index.html");
        setContentView(webView);
    }
}
EOF

echo "🔨 Compilando Java"
javac -source 8 -target 8 -bootclasspath android.jar -d java java/com/sepcol/gps/MainActivity.java
d8 --lib android.jar --output . java/com/sepcol/gps/MainActivity.class

echo "📦 Empaquetando"
aapt2 compile --dir res -o compiled.zip
aapt2 link -o app_unsigned.apk -I android.jar --manifest AndroidManifest.xml -R compiled.zip --auto-add-overlay

echo "🔗 Inyectando"
zip -q -u app_unsigned.apk classes.dex
zip -q -r app_unsigned.apk assets

echo "🔏 Firmando"
keytool -genkeypair -v -keystore my-release-key.keystore -alias app -keyalg RSA -keysize 2048 -validity 10000 -storepass 123456 -keypass 123456 -dname "CN=Android" > /dev/null 2>&1 || true
apksigner sign --ks my-release-key.keystore --ks-pass pass:123456 --min-sdk-version 21 --out SEPCOLGPS.apk app_unsigned.apk

echo "✅ Copiando a Descargas"
cp SEPCOLGPS.apk /sdcard/Download/
ls -lh SEPCOLGPS.apk
echo "🚀 Instalando"
termux-open --content-type application/vnd.android.package-archive /sdcard/Download/SEPCOLGPS.apk
