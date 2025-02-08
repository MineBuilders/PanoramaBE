<#
Copyright (C) 2025 Cdm2883

This file is part of PanoramaBE.

This software is licensed under the GNU General Public License v2.
#>

param (
    [string]$Inputs = $PWD.Path,
    [string]$Name = "PanoramaBE",
    [string]$Description = "A panorama background pack generated by PanoramaBE."
)

function Resolve-Path {
    param([string]$Path)
    
    if (-not [System.IO.Path]::IsPathRooted($Path)) {
        $Path = Join-Path $PWD.Path $Path
    }
    return [System.IO.Path]::GetFullPath($Path)
}

$Inputs = Resolve-Path -Path $Inputs

function Resolve-Panorama {
    param([int]$Order)

    $Path = Join-Path $Inputs "panorama_$Order.png"
    if (-not (Test-Path $Path)) {
        Write-Warning "$Path does not exist!"
        exit
    }
    return $Path
}

$Panorama0 = Resolve-Panorama -Order 0
$Panorama1 = Resolve-Panorama -Order 1
$Panorama2 = Resolve-Panorama -Order 2
$Panorama3 = Resolve-Panorama -Order 3
$Panorama4 = Resolve-Panorama -Order 4
$Panorama5 = Resolve-Panorama -Order 5

$Temp = Join-Path $Inputs ".temp"
New-Item -Path $Temp -ItemType Directory -Force | Out-Null

Set-Content -Path (Join-Path $Temp "manifest.json") -Value @"
{
    "format_version": 2,
    "header": {
        "description": "$Description",
        "name": "$Name",
        "uuid": "$([guid]::NewGuid())",
        "version": [0, 0, 1],
        "min_engine_version": [1, 13, 0]
    },
    "modules": [
        {
            "description": "$Description",
            "type": "resources",
            "uuid": "$([guid]::NewGuid())",
            "version": [0, 0, 1]
        }
    ]
}
"@

Copy-Item -Path $Panorama0 -Destination (Join-Path $Temp "pack_icon.png")

$UI = Join-Path $Temp "textures\ui"
New-Item -Path $UI -ItemType Directory -Force | Out-Null
Copy-Item -Path $Panorama0 -Destination (Join-Path $UI "panorama_0.png")
Copy-Item -Path $Panorama1 -Destination (Join-Path $UI "panorama_1.png")
Copy-Item -Path $Panorama2 -Destination (Join-Path $UI "panorama_2.png")
Copy-Item -Path $Panorama3 -Destination (Join-Path $UI "panorama_3.png")
Copy-Item -Path $Panorama4 -Destination (Join-Path $UI "panorama_4.png")
Copy-Item -Path $Panorama5 -Destination (Join-Path $UI "panorama_5.png")

$Output = Join-Path $Inputs "$Name.zip"
Get-ChildItem -Path $Temp | Compress-Archive -DestinationPath $Output

$McPack = Join-Path $Inputs "$Name.mcpack"
if (Test-Path $McPack) {
    $Answer = Read-Host "$Name.mcpack already exist, delete it? (Y/n)"
    if ($Answer -eq "n") { exit }
    Remove-Item -Path $McPack
}

Rename-Item -Path $Output -NewName "$Name.mcpack"

Remove-Item -Path $Temp -Recurse -Force
