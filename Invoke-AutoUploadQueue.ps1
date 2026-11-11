#Requires -Version 5.1
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ScriptDir) { $ScriptDir = $PSScriptRoot }
Set-Location -Path $ScriptDir

. (Join-Path -Path $ScriptDir -ChildPath "New-WhiteNoisePair.ps1")

function Invoke-AutoUploadQueue {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [int]$MaxEpisodesToProcess = 1,

        [Parameter()]
        [switch]$RenderOnlyIfUnapproved
    )

    begin {
        $ErrorActionPreference = 'Stop'
        Add-Type -AssemblyName System.Speech
        Add-Type -AssemblyName System.Drawing
        $catalogFile = Join-Path -Path $ScriptDir -ChildPath "character_rotation_catalog.json"
        $audioDir    = Join-Path -Path $ScriptDir -ChildPath "assets\audio"
        $brandDir    = Join-Path -Path $ScriptDir -ChildPath "assets\branding"
        $outputDir   = Join-Path -Path $ScriptDir -ChildPath "output"
        $secretFile  = Join-Path -Path $ScriptDir -ChildPath "client_secret.json"

        foreach ($d in @($audioDir, $brandDir, $outputDir)) {
            if (-not (Test-Path -Path $d)) {
                $null = New-Item -Path $d -ItemType Directory -Force
            }
        }
    }

    process {
        try {
            $catalog = Get-Content -Path $catalogFile -Raw | ConvertFrom-Json
            $processedCount = 0

            foreach ($ep in $catalog) {
                if ($ep.status -eq "uploaded") {
                    continue
                }
                if ($processedCount -ge $MaxEpisodesToProcess) {
                    break
                }

                $shortOut = Join-Path -Path $outputDir -ChildPath ("{0}_SHORT_9x16.mp4" -f $ep.id)
                $longOut  = Join-Path -Path $outputDir -ChildPath ("{0}_LONG_16x9.mp4" -f $ep.id)
                $wavPath  = Join-Path -Path $audioDir -ChildPath ("{0}.wav" -f $ep.id)
                $thumbOut = Join-Path -Path $brandDir -ChildPath ("{0}_thumbnail_1280x720.png" -f $ep.id)

                # 1. Ensure character soundbyte exists
                if (-not (Test-Path -Path $wavPath)) {
                    if ($PSCmdlet.ShouldProcess($wavPath, "Synthesize character soundbyte for $($ep.character)")) {
                        $rawWav = Join-Path -Path $audioDir -ChildPath ("raw_{0}.wav" -f $ep.id)
                        $synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
                        $synth.Rate = -1
                        $synth.Volume = 100
                        $synth.SetOutputToWaveFile($rawWav)
                        $synth.Speak($ep.quote)
                        $synth.Dispose()

                        $profile = if ($null -ne $ep.sound_profile) { $ep.sound_profile } else { "speech" }
                        if ($profile -like "chao_*") {
                            # Dreamy high-pitched Chao coo + harmonic Dreamcast chime + soft reverb tail
                            & ffmpeg -hide_banner -loglevel error -y `
                                -i $rawWav `
                                -f lavfi -i "sine=f=880:d=1.8" `
                                -filter_complex "[0:a]asetrate=22050*1.55,aresample=48000,atempo=0.85,lowpass=f=4200,aecho=0.8:0.9:50|90:0.35|0.25,volume=1.5[vox];[1:a]afade=t=in:st=0:d=0.1,afade=t=out:st=0.5:d=1.2,aecho=0.8:0.88:60:0.4,volume=0.25[chime];[vox][chime]amix=inputs=2:duration=first[out]" `
                                -map "[out]" $wavPath
                        }
                        else {
                            & ffmpeg -hide_banner -loglevel error -y -i $rawWav -af "highpass=f=160,lowpass=f=3800,aecho=0.8:0.88:35:0.2,volume=1.7" $wavPath
                        }
                        Remove-Item -Path $rawWav -Force -ErrorAction SilentlyContinue
                    }
                }

                # 2. Ensure episode Thumbnail exists
                if (-not (Test-Path -Path $thumbOut)) {
                    if ($PSCmdlet.ShouldProcess($thumbOut, "Render 1280x720 Thumbnail for $($ep.id)")) {
                        $bmp = New-Object System.Drawing.Bitmap(1280, 720)
                        $g = [System.Drawing.Graphics]::FromImage($bmp)
                        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
                        $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
                            (New-Object System.Drawing.Point(0, 0)),
                            (New-Object System.Drawing.Point(1280, 720)),
                            [System.Drawing.Color]::FromArgb(255, 10, 8, 18),
                            [System.Drawing.Color]::FromArgb(255, 38, 16, 52)
                        )
                        $g.FillRectangle($bgBrush, 0, 0, 1280, 720)

                        $heroFont = New-Object System.Drawing.Font("Impact", 110, [System.Drawing.FontStyle]::Regular)
                        $subFont  = New-Object System.Drawing.Font("Segoe UI", 34, [System.Drawing.FontStyle]::Bold)
                        $whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
                        $amberBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 251, 191, 36))

                        $g.DrawString($ep.thumbnail_text, $heroFont, $whiteBrush, 55, 90)
                        $g.DrawString(("{0} ({1}) + {2} NOISE" -f $ep.character.ToUpper(), $ep.show.ToUpper(), $ep.noise_color.ToUpper()), $subFont, $amberBrush, 60, 580)
                        $bmp.Save($thumbOut, [System.Drawing.Imaging.ImageFormat]::Png)
                        $g.Dispose()
                        $bmp.Dispose()
                    }
                }

                # 3. Ensure Short & Long-Form Videos are rendered
                if ((-not (Test-Path -Path $shortOut)) -or (-not (Test-Path -Path $longOut))) {
                    $null = New-WhiteNoisePair `
                        -SoundbytePath $wavPath `
                        -Id $ep.id `
                        -Character $ep.character `
                        -AccentHex $ep.accent_hex `
                        -NoiseColor $ep.noise_color `
                        -ShortDurationSeconds 14 `
                        -LongDurationSeconds 3600 `
                        -IntervalSeconds 60
                    $ep.status = "rendered"
                }

                # 4. Attempt YouTube Upload if OAuth client_secret.json is present
                $canUpload = Test-Path -Path $secretFile
                if ($canUpload -and (-not $RenderOnlyIfUnapproved)) {
                    if ($PSCmdlet.ShouldProcess($ep.id, "Upload Short + Long-Form video pair to YouTube")) {
                        & python (Join-Path -Path $ScriptDir -ChildPath "youtube_api_upload.py") --episode-id $ep.id
                        if ($LASTEXITCODE -eq 0) {
                            $ep.status = "uploaded"
                        }
                    }
                }

                $processedCount++
                [PSCustomObject]@{
                    EpisodeId      = $ep.id
                    Character      = $ep.character
                    Quote          = $ep.quote
                    QueueStatus    = $ep.status
                    ShortVideoPath = $shortOut
                    LongVideoPath  = $longOut
                    ThumbnailPath  = $thumbOut
                    OAuthReady     = $canUpload
                }
            }

            $catalog | ConvertTo-Json -Depth 6 | Set-Content -Path $catalogFile -Encoding UTF8
        }
        finally {
            # Clean completion
        }
    }
}
