<#
  打包便携版：dist\Dock-v<major>.<minor>\*.{exe,txt,md,ico}
  用法：powershell -ExecutionPolicy Bypass -File scripts\package.ps1
#>
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$exe  = Join-Path $root 'build\Dock.exe'
if (-not (Test-Path $exe)) { throw "未找到 $exe，请先运行 scripts\build.ps1" }

$ver  = (Get-Item $exe).VersionInfo.FileVersion
$name = "Dock-v$($ver.Split('.')[0]).$($ver.Split('.')[1])"
$dist = Join-Path $root 'dist'
$out  = Join-Path $dist $name
if (Test-Path $out) { Remove-Item -LiteralPath $out -Recurse -Force }
New-Item -ItemType Directory -Path $out -Force | Out-Null

Copy-Item $exe $out
Copy-Item (Join-Path $root '使用说明.txt') $out
Copy-Item (Join-Path $root 'README.md')    $out
Copy-Item (Join-Path $root 'app.ico')      $out

$zip = Join-Path $dist "$name.zip"
if (Test-Path $zip) { Remove-Item -LiteralPath $zip -Force }
Compress-Archive -Path (Join-Path $out '*') -DestinationPath $zip -CompressionLevel Optimal

Write-Host "打包完成：$zip"
Get-ChildItem $out | ForEach-Object { "  {0}  {1:N0} bytes" -f $_.Name, $_.Length }
