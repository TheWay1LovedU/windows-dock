<#
  Package the portable build into dist\Dock-v<major>.<minor>.zip

  Usage:
    powershell -ExecutionPolicy Bypass -File scripts\package.ps1
#>
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$exe  = Join-Path $root 'build\Dock.exe'
if (-not (Test-Path $exe)) { throw "Missing $exe - run scripts\build.ps1 first." }

$ver  = (Get-Item $exe).VersionInfo.FileVersion
$name = "Dock-v$($ver.Split('.')[0]).$($ver.Split('.')[1])"
$dist = Join-Path $root 'dist'
$out  = Join-Path $dist $name
if (Test-Path $out) { Remove-Item -LiteralPath $out -Recurse -Force }
New-Item -ItemType Directory -Path $out -Force | Out-Null

Copy-Item $exe $out
Copy-Item (Join-Path $root 'README.md') $out
Copy-Item (Join-Path $root 'LICENSE')   $out
Copy-Item (Join-Path $root 'app.ico')   $out

# The Chinese-named manual is located by pattern to keep this script ASCII-only.
$manual = Get-ChildItem -LiteralPath $root -File -Filter '*.txt' |
    Where-Object { $_.Name -notin @('CMakeLists.txt') } |
    Sort-Object Length -Descending |
    Select-Object -First 1
if ($manual) { Copy-Item $manual.FullName $out }

$zip = Join-Path $dist "$name.zip"
if (Test-Path $zip) { Remove-Item -LiteralPath $zip -Force }
Compress-Archive -Path (Join-Path $out '*') -DestinationPath $zip -CompressionLevel Optimal

Write-Host "Packaged: $zip"
Get-ChildItem $out | ForEach-Object { "  {0}  {1:N0} bytes" -f $_.Name, $_.Length }
