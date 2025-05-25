<#
Copyright (C) 2025 Cdm2883

This file is part of PanoramaBE.

This software is licensed under the GNU General Public License v2.
#>

param (
    [string]$Path = $PWD.Path
)

$ErrorActionPreference = "Stop"

if (-not [System.IO.Path]::IsPathRooted($Path)) {
    $Path = Join-Path $PWD.Path $Path
}
$Path = [System.IO.Path]::GetFullPath($Path)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PanoramaShot = Join-Path $ScriptDir "panorama_shot.ps1"
$PanoramaMerge = Join-Path $ScriptDir "panorama_merge.py"
$PanoramaHugin = Join-Path $ScriptDir "panorama_hugin.ps1"
$PanoramaPack = Join-Path $ScriptDir "panorama_pack.ps1"
if (-not (Test-Path $PanoramaShot) `
    -or -not (Test-Path $PanoramaMerge) `
    -or -not (Test-Path $PanoramaHugin) `
    -or -not (Test-Path $PanoramaPack)) {
    Write-Warning "Oops! Some scripts are missing!"
    Write-Host "You could redownload them from https://github.com/MineBuilders/PanoramaBE,"
    Write-Host -NoNewline "and then you must put them "
    Write-Host -NoNewline -ForegroundColor Red "TOGETHER"
    Write-Host "!"
    Write-Host

    $AutoDownload = Read-Host "Would you like to download automatically from github? (Y/n)"
    if ($AutoDownload -eq "n") { exit }
    $Files = @{
        "panorama_shot.ps1"  = $PanoramaShot
        "panorama_merge.py"  = $PanoramaMerge
        "panorama_hugin.ps1" = $PanoramaHugin
        "panorama_pack.ps1"  = $PanoramaPack
    }
    foreach ($Name in $Files.Keys) {
        $Path = $Files[$Name]
        $Url = "https://raw.githubusercontent.com/MineBuilders/PanoramaBE/main/scripts/$Name"
        if (-not (Test-Path $Path)) {
            Write-Host "Downloading $Name..."
            Invoke-WebRequest -Uri $Url -OutFile $Path -UseBasicParsing
        }
    }
    Clear-Host
}


$ESC = [char]27
Write-Host
Write-Host -ForegroundColor Yellow "$ESC[1m     ____                                               ____  ______"
Write-Host -ForegroundColor Yellow "$ESC[1m    / __ \____ _____  ____  _________ _____ ___  ____ _/ __ )/ ____/ "
Write-Host -ForegroundColor Yellow "$ESC[1m   / /_/ / __ ``/ __ \/ __ \/ ___/ __ ``/ __ ``__ \/ __ ``/ __  / __/    "
Write-Host -ForegroundColor Yellow "$ESC[1m  / ____/ /_/ / / / / /_/ / /  / /_/ / / / / / / /_/ / /_/ / /___    "
Write-Host -ForegroundColor Yellow "$ESC[1m /_/    \__,_/_/ /_/\____/_/   \__,_/_/ /_/ /_/\__,_/_____/_____/    "
Write-Host -ForegroundColor Yellow "$ESC[1m             Cdm2883 - https://github.com/MineBuilders/PanoramaBE"
Write-Host
Write-Host " A collection of tools to help you take panoramic photos \"
Write-Host "                                      \ in Minecraft Bedrock Edition."
Write-Host

Write-Host -ForegroundColor Cyan " 1. Just shot & make directly (recommend)."
Write-Host -ForegroundColor Cyan " 2. Shot and process with Hugin."
$Action = Read-Host " Press the Number to start you journey (default: 1)"

Clear-Host

if ($Action -ne "2") {

    Write-Host -NoNewline "First of all, please set fov in your game settings to "
    Write-Host -NoNewline -ForegroundColor Green "$ESC[1m82"
    Write-Host "!"
    Write-Host -ForegroundColor DarkGray "$ESC[3m(Settings > Video > Field of View)"
    Write-Host
    Read-Host "Then press Enter, shooting will start in 5 seconds..."
    Clear-Host

    & $PanoramaShot -Outputs $Path
    Clear-Host

    $Answer = Read-Host "Would you like to merge a equirectangular image? (y/N)"
    $HasNoPython = -not (Get-Command python -ErrorAction SilentlyContinue) `
                 -or -not (Get-Command pip -ErrorAction SilentlyContinue)
    if ($Answer -eq "y" -and $HasNoPython) {
        Write-Warning "Sorry, you have to install Python first!"
        Write-Warning "And you have to add Python to PATH!"
        Write-Host
    } elseif ($Answer -eq "y") {
        function Get-PIP {
            param([string]$Name)
            $IsInstalled = pip show $Name
            if ($IsInstalled) { return }
            Write-Warning "You haven't install $Name yet, try to install..."
            pip install $Name
        }
        Get-PIP -Name "opencv-python"
        Get-PIP -Name "py360convert"
        python $PanoramaMerge --inputs $Path
        Clear-Host
    }

} else {

    $Hugin = "C:\Program Files\Hugin\bin"
    if (-not (Test-Path $Hugin)) {
        $Hugin = "D:\Program Files\Hugin\bin"
        if (-not (Test-Path $Hugin)) {
            Write-Host "Have you installed Hugin?"
            $Hugin = Read-Host "If so, input the absolute bin path (like D:\Program Files\Hugin\bin)"
            if (-not (Test-Path $Hugin)) {
                Clear-Host
                Write-Warning "You haven't install Hugin yet!"
                exit
            }
        }
    }

    Write-Host -ForegroundColor Green "Goto Settings > Video > Field of View,"
    $FOV = Read-Host "And tell me the value"
    $FOV = [decimal]$FOV

    Write-Host
    Write-Host "Would you like more random shot?"
    $Random = Read-Host "How many would you like? (default: 3)"
    if (-not $Random) { $Random = 3 }
    $Random = [int]$Random

    Write-Host
    Write-Host -ForegroundColor Yellow "Are you ready?"
    Read-Host "Then press Enter, shooting will start in 5 seconds..."
    Clear-Host

    & $PanoramaShot -Outputs $Path -NoCrop -Random $Random
    Clear-Host

    Read-Host "Then press Enter, start run hugin..."

    & $PanoramaHugin -Hugin $Hugin -FOV $FOV -Inputs $Path -CubeMap
    Clear-Host

    $Path = Join-Path $Path "hugin"
}

$Answer = Read-Host "Would you like a resource pack? (Y/n)"
if (-not $Answer -eq "n") {
    $Name = Read-Host "What name would you like (default: PanoramaBE)"
    if (-not $Name) { $Name = "PanoramaBE" }
    $Description = Read-Host "What description would you like"
    if (-not $Description) { $Description = "A panorama background pack generated by PanoramaBE." }
    & $PanoramaPack -Inputs $Path -Name $Name -Description $Description
}

Clear-Host
Write-Host "Everything done, Bye!"
Write-Host -NoNewline "Check your files at >> "
Write-Host -NoNewline -ForegroundColor Green $Path
Write-Host " <<"
