# Project Chimera — bootstrap script (run manually if clones missing)
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

New-Item -ItemType Directory -Force -Path "godot","ai-server","docs" | Out-Null

if (-not (Test-Path "godot\project.godot")) {
    Write-Host "Cloning ProtoCRPG..."
    git clone --branch prototype --depth 1 https://github.com/MatteoCalvanico/ProtoCRPG.git godot-temp
    Get-ChildItem godot-temp | Move-Item -Destination godot -Force
    Remove-Item godot-temp -Recurse -Force
}

$addons = @{
    "beehave" = "https://github.com/bitbrain/beehave.git"
    "event_bus" = "https://github.com/iAM-Linus/event-bus-plugin.git"
    "dialog_system" = "https://github.com/Pandita-Studio/dialog-system-godot-addon.git"
    "locker" = "https://github.com/GameDrivenDesign/Locker.git"
}

New-Item -ItemType Directory -Force -Path "godot\addons" | Out-Null
foreach ($name in $addons.Keys) {
    $dest = "godot\addons\$name"
    if (-not (Test-Path $dest)) {
        Write-Host "Cloning $name..."
        git clone --depth 1 $addons[$name] $dest
    }
}

if (-not (Test-Path ".git")) { git init }

Write-Host "Setup complete."
