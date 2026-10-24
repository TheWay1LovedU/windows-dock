<#
  一键构建（Windows x64 / MSVC / Ninja）
  用法：
    powershell -ExecutionPolicy Bypass -File scripts\build.ps1
  可选参数：
    -VcVars   vcvars64.bat 的完整路径（默认自动查找 VS / Build Tools）
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
    throw "未找到 vcvars64.bat。请安装 Visual Studio 2022 Build Tools（C++ 桌面开发），或用 -VcVars 指定路径。"
}
if (-not (Get-Command cmake -ErrorAction SilentlyContinue)) {
    throw "未找到 cmake。请安装 CMake 并加入 PATH（VS 安装器可选「C++ CMake tools」）。"
}

Write-Host "使用 MSVC 环境：$VcVars"
cmd /c "`"$VcVars`" >nul && cmake -S `"$root`" -B `"$root\build`" -G Ninja -DCMAKE_BUILD_TYPE=Release && cmake --build `"$root\build`""
if ($LASTEXITCODE -ne 0) { throw "构建失败（exit $LASTEXITCODE）" }

$exe = Join-Path $root 'build\Dock.exe'
if (-not (Test-Path $exe)) { throw "未生成 $exe" }
Write-Host ("构建完成：{0}  ({1:N0} bytes)" -f $exe, (Get-Item $exe).Length)
