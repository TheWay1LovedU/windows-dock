<#
  Build Dock (Windows x64, MSVC, Ninja).

  Usage:
    powershell -ExecutionPolicy Bypass -File scripts\build.ps1

  Optional:
    -VcVars  full path to vcvars64.bat
#>
param([string]$VcVars = "")

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

function Find-VcVars {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    if (Test-Path $vswhere) {
        $install = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
        if ($install) {
            $candidate = Join-Path $install 'VC\Auxiliary\Build\vcvars64.bat'
            if (Test-Path $candidate) { return $candidate }
        }
    }
    foreach ($candidate in @(
        'D:\VS2022BuildTools\VC\Auxiliary\Build\vcvars64.bat',
        'C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat',
        'C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat',
        'C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvars64.bat',
        'C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars64.bat'
    )) {
        if (Test-Path $candidate) { return $candidate }
    }
    return $null
}

if (-not $VcVars) { $VcVars = Find-VcVars }
if (-not $VcVars -or -not (Test-Path $VcVars)) {
    throw "vcvars64.bat not found. Install Visual Studio 2022 Build Tools with 'Desktop development with C++', or pass -VcVars <path>."
}
$vsRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $VcVars)))
$vsCmake = Join-Path $vsRoot 'Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe'
$vsNinja = Join-Path $vsRoot 'Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\ninja.exe'
$cmake = if (Get-Command cmake -ErrorAction SilentlyContinue) { 'cmake' } elseif (Test-Path $vsCmake) { $vsCmake } else { $null }
if (-not $cmake) { throw "cmake not found. Install CMake (the Visual Studio C++ workload includes it)." }
$ninjaDir = if (Test-Path $vsNinja) { Split-Path -Parent $vsNinja } else { '' }

Write-Host "Using MSVC environment: $VcVars"
Write-Host "Using CMake: $cmake"
$pathPrefix = if ($ninjaDir) { "set PATH=$ninjaDir;%PATH% && " } else { '' }
cmd /c "`"$VcVars`" >nul && $pathPrefix`"$cmake`" -S `"$root`" -B `"$root\build`" -G Ninja -DCMAKE_BUILD_TYPE=Release && `"$cmake`" --build `"$root\build`""
if ($LASTEXITCODE -ne 0) { throw "Build failed (exit $LASTEXITCODE)" }

$exe = Join-Path $root 'build\Dock.exe'
if (-not (Test-Path $exe)) { throw "Missing $exe" }
Write-Host ("Build OK: {0}  ({1:N0} bytes)" -f $exe, (Get-Item $exe).Length)
