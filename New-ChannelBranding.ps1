#Requires -Version 5.1
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ScriptDir) { $ScriptDir = $PSScriptRoot }
Set-Location -Path $ScriptDir

function New-ChannelBranding {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [string]$OutputDirectory = (Join-Path -Path $ScriptDir -ChildPath "assets\branding")
    )

    begin {
        $ErrorActionPreference = 'Stop'
        Add-Type -AssemblyName System.Drawing
        if (-not (Test-Path -Path $OutputDirectory)) {
            $null = New-Item -Path $OutputDirectory -ItemType Directory -Force
        }
    }

    process {
        try {
            $avatarPath = Join-Path -Path $OutputDirectory -ChildPath "channel_avatar_800x800.png"
            $bannerPath = Join-Path -Path $OutputDirectory -ChildPath "channel_banner_2560x1440.png"
            $thumbPath  = Join-Path -Path $OutputDirectory -ChildPath "ep01_thumbnail_1280x720.png"

            # 1. Channel Avatar (800x800) - Dark Nowhere Static + Iconic Gold Glasses & Hat Silhouette
            if ($PSCmdlet.ShouldProcess($avatarPath, "Generate 800x800 Channel Avatar")) {
                $bmp = New-Object System.Drawing.Bitmap(800, 800)
                $g = [System.Drawing.Graphics]::FromImage($bmp)
                $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

                $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
                    (New-Object System.Drawing.Point(0, 0)),
                    (New-Object System.Drawing.Point(800, 800)),
                    [System.Drawing.Color]::FromArgb(255, 13, 11, 22),
                    [System.Drawing.Color]::FromArgb(255, 32, 18, 48)
                )
                $g.FillRectangle($bgBrush, 0, 0, 800, 800)

                # Soundwave bars across center
                $amberPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(220, 217, 119, 6), 8)
                $heights = @(40, 90, 180, 70, 260, 340, 150, 290, 110, 60, 210, 120, 50)
                for ($i = 0; $i -lt $heights.Count; $i++) {
                    $x = 140 + ($i * 44)
                    $h = $heights[$i]
                    $g.DrawLine($amberPen, $x, (400 - $h / 2), $x, (400 + $h / 2))
                }

                # Iconic round glasses silhouette
                $glassPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 250, 204, 21), 16)
                $fillGlass = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(190, 254, 240, 138))
                $g.FillEllipse($fillGlass, 220, 290, 140, 140)
                $g.FillEllipse($fillGlass, 440, 290, 140, 140)
                $g.DrawEllipse($glassPen, 220, 290, 140, 140)
                $g.DrawEllipse($glassPen, 440, 290, 140, 140)
                $g.DrawLine($glassPen, 360, 360, 440, 360)

                $fontMain = New-Object System.Drawing.Font("Impact", 62, [System.Drawing.FontStyle]::Regular)
                $whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
                $amberBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 251, 191, 36))
                $sf = New-Object System.Drawing.StringFormat
                $sf.Alignment = [System.Drawing.StringAlignment]::Center
                $g.DrawString("CARTOON WHITE NOISE", $fontMain, $whiteBrush, (New-Object System.Drawing.RectangleF(0, 595, 800, 85)), $sf)

                $bmp.Save($avatarPath, [System.Drawing.Imaging.ImageFormat]::Png)
                $g.Dispose()
                $bmp.Dispose()
            }

            # 2. Channel Banner (2560x1440, Safe Area centered at 1546x423)
            if ($PSCmdlet.ShouldProcess($bannerPath, "Generate 2560x1440 Channel Banner")) {
                $bmp = New-Object System.Drawing.Bitmap(2560, 1440)
                $g = [System.Drawing.Graphics]::FromImage($bmp)
                $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

                $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
                    (New-Object System.Drawing.Point(0, 0)),
                    (New-Object System.Drawing.Point(2560, 1440)),
                    [System.Drawing.Color]::FromArgb(255, 9, 7, 15),
                    [System.Drawing.Color]::FromArgb(255, 28, 15, 43)
                )
                $g.FillRectangle($bgBrush, 0, 0, 2560, 1440)

                $titleFont = New-Object System.Drawing.Font("Impact", 86, [System.Drawing.FontStyle]::Regular)
                $subFont   = New-Object System.Drawing.Font("Segoe UI", 32, [System.Drawing.FontStyle]::Bold)
                $amberBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 245, 158, 11))
                $whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
                $sf = New-Object System.Drawing.StringFormat
                $sf.Alignment = [System.Drawing.StringAlignment]::Center

                $g.DrawString("CARTOON WHITE NOISE", $titleFont, $whiteBrush, (New-Object System.Drawing.RectangleF(0, 580, 2560, 140)), $sf)
                $g.DrawString("SOOTHING NOISE + 1 ICONIC CARTOON & GAMING SOUNDBYTE PER UPLOAD", $subFont, $amberBrush, (New-Object System.Drawing.RectangleF(0, 725, 2560, 80)), $sf)

                $bmp.Save($bannerPath, [System.Drawing.Imaging.ImageFormat]::Png)
                $g.Dispose()
                $bmp.Dispose()
            }

            # 3. Episode 1 High-CTR Thumbnail (1280x720) - "SLEEP TIGHT."
            if ($PSCmdlet.ShouldProcess($thumbPath, "Generate 1280x720 Episode 1 Thumbnail")) {
                $bmp = New-Object System.Drawing.Bitmap(1280, 720)
                $g = [System.Drawing.Graphics]::FromImage($bmp)
                $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

                $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
                    (New-Object System.Drawing.Point(0, 0)),
                    (New-Object System.Drawing.Point(1280, 720)),
                    [System.Drawing.Color]::FromArgb(255, 10, 8, 18),
                    [System.Drawing.Color]::FromArgb(255, 45, 16, 58)
                )
                $g.FillRectangle($bgBrush, 0, 0, 1280, 720)

                # Calm audio wave on left turns into massive orange spike on right
                $calmPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(220, 147, 51, 234), 6)
                for ($x = 60; $x -lt 700; $x += 18) {
                    $h = 20 + (($x * 7) % 36)
                    $g.DrawLine($calmPen, $x, (420 - $h), $x, (420 + $h))
                }
                $spikePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 245, 158, 11), 12)
                $spikeHeights = @(90, 220, 310, 260, 340, 190, 280, 140)
                for ($i = 0; $i -lt $spikeHeights.Count; $i++) {
                    $x = 730 + ($i * 28)
                    $h = $spikeHeights[$i] / 2
                    $g.DrawLine($spikePen, $x, (420 - $h), $x, (420 + $h))
                }

                # Glowing Eustace Glasses Silhouette in top right
                $glowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(230, 250, 204, 21))
                $g.FillEllipse($glowBrush, 920, 150, 110, 110)
                $g.FillEllipse($glowBrush, 1070, 150, 110, 110)
                $bridgePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 250, 204, 21), 14)
                $g.DrawLine($bridgePen, 1030, 205, 1070, 205)

                # 2-Word Complementary Thumbnail Overlay: "SLEEP TIGHT."
                $heroFont = New-Object System.Drawing.Font("Impact", 118, [System.Drawing.FontStyle]::Regular)
                $tagFont  = New-Object System.Drawing.Font("Segoe UI", 32, [System.Drawing.FontStyle]::Bold)
                $whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
                $amberBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 251, 191, 36))

                $g.DrawString("SLEEP TIGHT.", $heroFont, $whiteBrush, 55, 80)
                $g.DrawString("1 HOUR BROWN NOISE + 1 EUSTACE LINE", $tagFont, $amberBrush, 65, 595)

                $bmp.Save($thumbPath, [System.Drawing.Imaging.ImageFormat]::Png)
                $g.Dispose()
                $bmp.Dispose()
            }

            [PSCustomObject]@{
                AvatarPath    = $avatarPath
                BannerPath    = $bannerPath
                ThumbnailPath = $thumbPath
                Status        = "Generated"
            }
        }
        finally {
            # Resources disposed inline
        }
    }
}

New-ChannelBranding
