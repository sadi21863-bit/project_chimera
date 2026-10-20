<#
.SYNOPSIS
    Build the Windows release and stage the Local-AI runtime beside the executable.

.DESCRIPTION
    The NobodyWho GDExtension is deliberately NOT inside the PCK: an engine-startup load of it
    costs ~43 s of init on this hardware (a runtime load costs ~2.4 s), so it is shipped as a
    loose file next to ProjectChimera.exe and loaded on demand by LocalAI (godot/autoload/
    local_ai.gd). This script exports the game and stages that DLL in the layout the game looks
    for: <exe dir>/addons/nobodywho/libnobodywho-godot-x86_64-pc-windows-msvc-release.dll

    The DLL is not tracked in git (repo policy: large native binaries stay out of the repo), so a
    fresh clone cannot produce a LOCAL-AI-enabled build until the DLL is restored. Its expected
    size and SHA-256 are pinned in docs/model-download-flow-design.md section 11.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File tools/build-windows.ps1
#>
[CmdletBinding()]
param(
    [string]$Godot = "C:\Users\aditya\Desktop\Godot472\Godot_v4.7.2-stable_win64_console.exe",
    [string]$Preset = "Windows Desktop"
)

$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot
$godotDir = Join-Path $repo "godot"
$buildDir = Join-Path $repo "build\windows"
$exe = Join-Path $buildDir "ProjectChimera.exe"
$dllName = "libnobodywho-godot-x86_64-pc-windows-msvc-release.dll"
$dllSrc = Join-Path $godotDir "addons\nobodywho\$dllName"
$dllDstDir = Join-Path $buildDir "addons\nobodywho"

if (-not (Test-Path -LiteralPath $Godot)) { throw "Godot not found: $Godot" }

Write-Host "Exporting preset '$Preset' ..."
& $Godot --headless --path $godotDir --export-release $Preset $exe
if ($LASTEXITCODE -ne 0) { throw "Export failed with exit code $LASTEXITCODE" }

if ([System.IO.File]::Exists($dllSrc)) {
    [System.IO.Directory]::CreateDirectory($dllDstDir) | Out-Null
    [System.IO.File]::Copy($dllSrc, (Join-Path $dllDstDir $dllName), $true)
    $len = (New-Object System.IO.FileInfo($dllSrc)).Length
    Write-Host "Staged Local-AI runtime: addons/nobodywho/$dllName ($len bytes)"
} else {
    Write-Warning "NobodyWho DLL not found at $dllSrc - build has no LOCAL AI runtime."
}

Get-ChildItem -LiteralPath $buildDir -Recurse -File |
    Select-Object @{n = "file"; e = { $_.FullName.Substring($buildDir.Length + 1) } }, Length |
    Format-Table -AutoSize
