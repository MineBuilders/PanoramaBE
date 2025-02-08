<#
Copyright (C) 2025 Cdm2883

This file is part of PanoramaBE.

This software is licensed under the GNU General Public License v2.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Hugin,
    [decimal]$FOV,
    [string]$Inputs = $PWD.Path,
    [switch]$CubeMap
)

if (-not $FOV) {
    $FOV = Read-Host "Please enter your game FOV (horizontal field of view, default: 60)"
    $FOV = If (-not $FOV) { 60 } else { [decimal]$FOV }
}

Add-Type -AssemblyName System.Drawing

function Resolve-Path {
    param([string]$Path)
    
    if (-not [System.IO.Path]::IsPathRooted($Path)) {
        $Path = Join-Path $PWD.Path $Path
    }
    return [System.IO.Path]::GetFullPath($Path)
}

function Resolve-Hugin {
    param([string]$Path)

    $Path = Join-Path $Hugin $Path
    if (-not (Test-Path $Path)) {
        Write-Warning "$Path does not exist! Please check if Hugin is properly installed! ($Hugin)"
        Exit
    }
    return $Path
}

function Convert-PNG {
    param(
        [string]$Path,
        [string]$Output
    )
    $Image = [System.Drawing.Image]::FromFile($Path)
    $Image.Save($Output, [System.Drawing.Imaging.ImageFormat]::Png)
    $Image.Dispose()
    Remove-Item -Path $Path
}

# Prepare inputs
$Inputs = Resolve-Path -Path $Inputs
$Outputs = Join-Path $Inputs "hugin"
New-Item -Path $Outputs -ItemType Directory -Force | Out-Null

$InputImages = Get-ChildItem -Path $Inputs -Filter "panorama_*.png"
if ($InputImages.Count -eq 0) {
    Write-Host "No images found matching 'panorama_*.png' in the working directory. ($Inputs)"
    exit
}

# Execute Hugin
$PtoGen = Resolve-Hugin -Path "pto_gen.exe"
$HuginExecutor = Resolve-Hugin -Path "hugin_executor.exe"

$PtoFile = Join-Path $Outputs "panorama.pto"

& $PtoGen -f $FOV -o $PtoFile $InputImages.FullName
& $HuginExecutor --assistant $PtoFile
& $HuginExecutor --stitching --prefix=$PtoFile $PtoFile

$PanoramaTIF = Join-Path $Outputs "panorama.tif"
$PanoramaPNG = Join-Path $Outputs "panorama.png"
Convert-PNG -Path $PanoramaTIF -Output $PanoramaPNG

# Cube maps

if (-not $CubeMap) { exit }

$Perl = Resolve-Hugin -Path "exiftool_files\perl.exe"
$Nona = Resolve-Hugin -Path "nona.exe"

function Install-Panotools {
    $PanotoolsScript = "https://github.com/gitpan/Panotools-Script/archive/refs/heads/master.zip"
    $MathTrig = "https://perldoc.perl.org/Math::Trig.txt"
    $ImageSize = "https://raw.githubusercontent.com/rjray/image-size/refs/heads/master/lib/Image/Size.pm"
    $IPCOpen2 = "https://raw.githubusercontent.com/Perl/perl5/refs/heads/blead/ext/IPC-Open3/lib/IPC/Open2.pm"
    $IPCOpen3 = "https://raw.githubusercontent.com/Perl/perl5/refs/heads/blead/ext/IPC-Open3/lib/IPC/Open3.pm"

    $Temp = Join-Path $Outputs ".temp"
    New-Item -Path $Temp -ItemType Directory -Force | Out-Null

    $PanotoolsScriptZip = Join-Path $Temp "PanotoolsScript.zip"
    $PanotoolsScriptPath = Join-Path $Temp "PanotoolsScript"
    Invoke-WebRequest -Uri $PanotoolsScript -OutFile $PanotoolsScriptZip
    Expand-Archive -Path $PanotoolsScriptZip -DestinationPath $PanotoolsScriptPath -Force
    Copy-Item -Path (Join-Path $PanotoolsScriptPath "Panotools-Script-master\lib\Panotools") `
              -Destination (Join-Path $Hugin "exiftool_files\lib\Panotools") `
              -Recurse
    Copy-Item -Path (Join-Path $PanotoolsScriptPath "Panotools-Script-master\bin") `
              -Destination (Join-Path $Hugin "exiftool_files\bin") `
              -Recurse
    
    Invoke-WebRequest -Uri $MathTrig -OutFile (Join-Path $Hugin "exiftool_files\lib\Math\Trig.pm")
    Invoke-WebRequest -Uri $ImageSize -OutFile (Join-Path $Hugin "exiftool_files\lib\Image\Size.pm")

    New-Item -Path (Join-Path $Hugin "exiftool_files\lib\IPC") -ItemType Directory -Force | Out-Null
    Invoke-WebRequest -Uri $IPCOpen2 -OutFile (Join-Path $Hugin "exiftool_files\lib\IPC\Open2.pm")
    Invoke-WebRequest -Uri $IPCOpen3 -OutFile (Join-Path $Hugin "exiftool_files\lib\IPC\Open3.pm")

    Remove-Item -Path $Temp -Recurse -Force
}

$CheckPanotoolsPath = Join-Path $Hugin "exiftool_files\lib\Panotools"
if (-not (Test-Path $CheckPanotoolsPath)) {
    $answer = Read-Host "You haven't install Panotools::Script yet, fix it? (y/N)"
    if ($answer -ne "y") { exit }
    Install-Panotools
    Write-Host "Panotools::Script installed successfully!"
}

$Erect2cubic = Resolve-Hugin -Path "exiftool_files\bin\erect2cubic"
$CubePto = Join-Path $Outputs "panorama_cube.pto"

& $Perl $Erect2cubic --erect=$PanoramaPNG --ptofile=$CubePto
& $Nona -o (Join-Path $Outputs "panorama_") $CubePto

$NonaTIFs = Get-ChildItem -Path $Outputs -Filter "panorama_000*.tif"
foreach ($File in $NonaTIFs) {
    $FileName = $File.Name
    $Order = $FileName.Substring($FileName.Length - 5, 1)
    $Output = Join-Path $Outputs "panorama_$Order.png"
    Convert-PNG -Path $File.FullName -Output $Output
}
