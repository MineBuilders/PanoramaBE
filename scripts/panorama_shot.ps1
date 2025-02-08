param (
    [string]$Outputs = $PWD.Path,
    [switch]$NoCrop,
    [int]$Random = 0
)

function Resolve-Path {
    param([string]$Path)
    
    if (-not [System.IO.Path]::IsPathRooted($Path)) {
        $Path = Join-Path $PWD.Path $Path
    }
    return [System.IO.Path]::GetFullPath($Path)
}

$Outputs = Resolve-Path -Path $Outputs

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class DPIUtils {
    [DllImport("user32.dll")]
    public static extern bool SetProcessDPIAware();
}
"@
[DPIUtils]::SetProcessDPIAware() | Out-Null

Add-Type -AssemblyName System.Windows.Forms

function Invoke-Command {
    param([string]$Command)
    
    $Command = $Command -replace "@", "+2" -replace "~", "+``"
    [System.Windows.Forms.SendKeys]::SendWait("/")
    Start-Sleep -Milliseconds 300
    [System.Windows.Forms.SendKeys]::SendWait("$Command{ENTER}")
}

function Switch-Fullscreen {
    [System.Windows.Forms.SendKeys]::SendWait("{F11}{F1}")
}

function Start-Screenshot {
    param([string]$SaveName)

    $Screen = [System.Windows.Forms.Screen]::PrimaryScreen
    $ScreenWidth  = $Screen.Bounds.Width
    $ScreenHeight = $Screen.Bounds.Height

    if ($NoCrop) {
        $ImageWidth = $ScreenWidth
        $ImageHeight = $ScreenHeight
        $Offset = $Screen.Bounds.Location
    } else {
        $ScreenMin = [Math]::Min($ScreenWidth, $ScreenHeight)
        $ImageWidth = $ScreenMin
        $ImageHeight = $ScreenMin
        $OffsetX = $Screen.Bounds.X + [Math]::Round(($ScreenWidth - $ScreenMin) / 2)
        $OffsetY = $Screen.Bounds.Y + [Math]::Round(($ScreenHeight - $ScreenMin) / 2)
        $Offset = New-Object System.Drawing.Point($OffsetX, $OffsetY)
    }

    $Image = New-Object System.Drawing.Bitmap($ImageWidth, $ImageHeight)
    $Graphic = [System.Drawing.Graphics]::FromImage($Image)
    $Graphic.CopyFromScreen($Offset, [System.Drawing.Point]::Empty, $Image.Size)

    $FormatPNG = [System.Drawing.Imaging.ImageFormat]::Png
    $Image.Save($Outputs + "\" + $SaveName + ".png", $FormatPNG)

    $Graphic.Dispose()
    $Image.Dispose()
}

Write-Host "Panorama shooting will start in 5 seconds..."

Start-Sleep -Seconds 5

Switch-Fullscreen

Invoke-Command -Command "tp @s ~~~ 0 0"
Start-Sleep -Seconds 1
Start-Screenshot -SaveName "panorama_0"

Invoke-Command -Command "tp @s ~~~ 90 0"
Start-Sleep -Seconds 1
Start-Screenshot -SaveName "panorama_1"

Invoke-Command -Command "tp @s ~~~ 180 0"
Start-Sleep -Seconds 1
Start-Screenshot -SaveName "panorama_2"

Invoke-Command -Command "tp @s ~~~ 270 0"
Start-Sleep -Seconds 1
Start-Screenshot -SaveName "panorama_3"

Invoke-Command -Command "tp @s ~~~ 0 -90"
Start-Sleep -Seconds 1
Start-Screenshot -SaveName "panorama_4"

Invoke-Command -Command "tp @s ~~~ 0 90"
Start-Sleep -Seconds 1
Start-Screenshot -SaveName "panorama_5"

for ($i = 0; $i -lt $Random; $i++) {
    $RandomInteger1 = Get-Random -Minimum 0 -Maximum 361
    $RandomDecimal1 = (Get-Random -Minimum 0 -Maximum 1) / 10
    $RandomNumber1 = [math]::Round($RandomInteger1 + $RandomDecimal1, 1)

    $RandomInteger2 = Get-Random -Minimum -90 -Maximum 91
    $RandomDecimal2 = (Get-Random -Minimum 0 -Maximum 1) / 10
    $RandomNumber2 = [math]::Round($RandomInteger2 + $RandomDecimal2, 1)

    Invoke-Command -Command "tp @s ~~~ $RandomNumber1 $RandomNumber2"
    Start-Sleep -Seconds 1
    Start-Screenshot -SaveName "panorama_$($i + 6)"
}

Switch-Fullscreen

Write-Host

Write-Host "Everything done, Bye!"
