# Ver README renderizado en el navegador (usa marked.js de CDN)
$md  = Get-Content 'C:\RUNEFORGE_V2_CORE\README.md' -Raw
$md  = $md -replace '\\','\\' -replace '`','\`' -replace '\$','\$'
$html = @"
<!DOCTYPE html><html><head><meta charset="UTF-8">
<title>RUNEFORGE README</title>
<style>body{font-family:-apple-system,Segoe UI,sans-serif;max-width:900px;margin:40px auto;padding:20px;background:#0d1117;color:#c9d1d9}
pre{background:#161b22;padding:14px;border-radius:8px;overflow-x:auto}
code{background:#161b22;padding:2px 6px;border-radius:4px;font-family:monospace}
table{border-collapse:collapse;width:100%;margin:14px 0}
th,td{border:1px solid #30363d;padding:8px 12px;text-align:left}
th{background:#161b22}
h1,h2{border-bottom:1px solid #30363d;padding-bottom:6px}
a{color:#58a6ff}</style></head>
<body><div id="c"></div>
<script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
<script>
  const md = `$md`;
  document.getElementById('c').innerHTML = marked.parse(md);
</script></body></html>
"@
$tmp = "$env:TEMP\runeforge_readme.html"
$html | Set-Content $tmp -Encoding UTF8
Start-Process $tmp