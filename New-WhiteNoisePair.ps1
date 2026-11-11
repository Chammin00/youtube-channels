#Requires -Version 5.1
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ScriptDir) { $ScriptDir = $PSScriptRoot }
Set-Location -Path $ScriptDir

function New-WhiteNoisePair {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$SoundbytePath,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$Id = "cartoon-episode",

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$Character = "Eustace Bagge",

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$AccentHex = "0xd97706",

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateSet("white", "pink", "brown")]
        [string]$NoiseColor = "brown",

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [int]$ShortDurationSeconds = 14,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [int]$LongDurationSeconds = 3600,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [int]$IntervalSeconds = 600,

        [Parameter()]
        [string]$OutputDirectory = (Join-Path -Path $ScriptDir -ChildPath "output")
    )

    begin {
        $ErrorActionPreference = 'Stop'
        $ffmpegCmd = Get-Command -Name "ffmpeg" -ErrorAction SilentlyContinue
        if ($null -eq $ffmpegCmd) {
            throw [System.InvalidOperationException]::New("FFmpeg is required on PATH to render the Short and Long-form video pairs.")
        }

        if (-not (Test-Path -Path $OutputDirectory)) {
            $null = New-Item -Path $OutputDirectory -ItemType Directory -Force
        }
    }

    process {
        $tempSegment = $null
        try {
            if (-not (Test-Path -Path $SoundbytePath)) {
                throw [System.IO.FileNotFoundException]::New("Soundbyte audio file not found: $SoundbytePath")
            }

            $resolvedSoundbyte = (Resolve-Path -Path $SoundbytePath).Path
            $shortOut = Join-Path -Path $OutputDirectory -ChildPath ("{0}_SHORT_9x16.mp4" -f $Id)
            $longOut  = Join-Path -Path $OutputDirectory -ChildPath ("{0}_LONG_16x9.mp4" -f $Id)

            # 1. Render 9:16 Short (Soundbyte hits at 4.5s over soothing noise + live waveform)
            if ($PSCmdlet.ShouldProcess($shortOut, "Render 9:16 YouTube Short ($ShortDurationSeconds s) for $Character")) {
                $shortFilter = "[0:a]volume=0.22,lowpass=f=1800[bg];[1:a]adelay=4500|4500,volume=1.45[sb];[bg][sb]amix=inputs=2:duration=first:dropout_transition=0[aout];[aout]asplit=2[a_final][a_viz];[a_viz]showwaves=s=1080x360:mode=cline:colors=${AccentHex}:rate=30[waves];color=c=0x0d0b14:s=1080x1920:r=30:d=$ShortDurationSeconds[base];[base][waves]overlay=x=0:y=(H-h)/2[vout]"

                $shortArgs = @(
                    "-hide_banner", "-loglevel", "error", "-y",
                    "-f", "lavfi", "-i", "anoisesrc=d=${ShortDurationSeconds}:c=${NoiseColor}:r=48000:a=0.5",
                    "-i", $resolvedSoundbyte,
                    "-filter_complex", $shortFilter,
                    "-map", "[vout]",
                    "-map", "[a_final]",
                    "-c:v", "libx264", "-preset", "veryfast", "-crf", "21", "-pix_fmt", "yuv420p",
                    "-c:a", "aac", "-b:a", "192k",
                    "-shortest",
                    $shortOut
                )
                & ffmpeg @shortArgs
                if ($LASTEXITCODE -ne 0) {
                    throw [System.InvalidOperationException]::New("FFmpeg failed while rendering Short video.")
                }
            }

            # 2. Render 16:9 Long-Form Video using a single Interval cycle + stream_loop for instant multi-hour assembly
            if ($PSCmdlet.ShouldProcess($longOut, "Render 16:9 Long-Form Video ($LongDurationSeconds s) for $Character")) {
                $cycleSec = [Math]::Min($IntervalSeconds, $LongDurationSeconds)
                $loopsNeeded = [Math]::Max(0, [int][Math]::Ceiling(($LongDurationSeconds / [double]$cycleSec)) - 1)
                $tempSegment = Join-Path -Path $OutputDirectory -ChildPath ("{0}_temp_cycle.mp4" -f $Id)

                $longFilter = "[0:a]volume=0.18,lowpass=f=1400[bg];[1:a]adelay=3000|3000,volume=1.25[sb];[bg][sb]amix=inputs=2:duration=first:dropout_transition=0[aout];[aout]asplit=2[a_final][a_viz];[a_viz]showwaves=s=1920x240:mode=cline:colors=${AccentHex}:rate=24[waves];color=c=0x09070e:s=1920x1080:r=24:d=$cycleSec[base];[base][waves]overlay=x=0:y=H-300[vout]"

                $segArgs = @(
                    "-hide_banner", "-loglevel", "error", "-y",
                    "-f", "lavfi", "-i", "anoisesrc=d=${cycleSec}:c=${NoiseColor}:r=48000:a=0.5",
                    "-i", $resolvedSoundbyte,
                    "-filter_complex", $longFilter,
                    "-map", "[vout]",
                    "-map", "[a_final]",
                    "-c:v", "libx264", "-preset", "ultrafast", "-crf", "23", "-pix_fmt", "yuv420p",
                    "-c:a", "aac", "-b:a", "192k",
                    "-shortest",
                    $tempSegment
                )
                & ffmpeg @segArgs
                if ($LASTEXITCODE -ne 0) {
                    throw [System.InvalidOperationException]::New("FFmpeg failed while rendering Long-Form cycle segment.")
                }

                if ($loopsNeeded -gt 0) {
                    $loopArgs = @(
                        "-hide_banner", "-loglevel", "error", "-y",
                        "-stream_loop", "$loopsNeeded",
                        "-i", $tempSegment,
                        "-t", "$LongDurationSeconds",
                        "-c", "copy",
                        $longOut
                    )
                    & ffmpeg @loopArgs
                    if ($LASTEXITCODE -ne 0) {
                        throw [System.InvalidOperationException]::New("FFmpeg failed while looping Long-Form video.")
                    }
                }
                else {
                    Move-Item -Path $tempSegment -Destination $longOut -Force
                }
            }

            [PSCustomObject]@{
                EpisodeId        = $Id
                Character        = $Character
                AccentHex        = $AccentHex
                NoiseColor       = $NoiseColor
                SoundbyteSource  = $resolvedSoundbyte
                ShortVideoPath   = $shortOut
                LongVideoPath    = $longOut
                ShortDurationSec = $ShortDurationSeconds
                LongDurationSec  = $LongDurationSeconds
                IntervalSec      = $IntervalSeconds
                Status           = "ReadyForUpload"
            }
        }
        catch [System.IO.FileNotFoundException] {
            Write-Error -Message $_.Exception.Message -ErrorAction Stop
        }
        catch {
            Write-Error -Message ("Failed to generate white noise pair for '{0}': {1}" -f $Id, $_.Exception.Message) -ErrorAction Stop
        }
        finally {
            if ($null -ne $tempSegment -and (Test-Path -Path $tempSegment)) {
                Remove-Item -Path $tempSegment -Force -ErrorAction SilentlyContinue
            }
        }
    }

    end {
        Write-Verbose -Message "Completed white noise pair generation pipeline."
    }
}
