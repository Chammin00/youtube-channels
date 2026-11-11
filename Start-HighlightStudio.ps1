#Requires -Version 5.1
<#
.SYNOPSIS
    Launches the ApexPulse 3D Museum Gallery & Gaming Highlight Studio local web server.

.DESCRIPTION
    Starts a local HTTP server anchored to the project directory, serves index.html,
    serves real licensed CC-BY 4.0 music (.mp3) and CC0 studio soundbytes (.ogg),
    and provides a POST /api/render endpoint powered by FFmpeg to mix video,
    ducked background music (-18dB sidechain), and 4 timed soundbytes into a master MP4.

.PARAMETER Port
    The local HTTP port to host the studio on (defaults to 8080, with automatic fallback if occupied).

.PARAMETER NoBrowser
    Switch to start the server without launching the default browser.

.EXAMPLE
    .\Start-HighlightStudio.ps1
    .\Start-HighlightStudio.ps1 -Port 8095 -NoBrowser
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [int]$Port = 8080,

    [Parameter()]
    [switch]$NoBrowser
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ScriptDir) { $ScriptDir = $PSScriptRoot }
Set-Location -Path $ScriptDir

$ErrorActionPreference = 'Stop'

function Test-PortAvailable {
    param([int]$TestPort)
    $listener = $null
    try {
        $ip = [System.Net.IPAddress]::Loopback
        $listener = [System.Net.Sockets.TcpListener]::new($ip, $TestPort)
        $listener.Start()
        $listener.Stop()
        return $true
    }
    catch {
        return $false
    }
    finally {
        if ($null -ne $listener) {
            try { $listener.Stop() } catch { }
        }
    }
}

function Invoke-HighlightFFmpegRender {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$WorkspaceRoot,

        [Parameter(Mandatory)]
        [PSCustomObject]$Payload
    )

    $outDir = Join-Path -Path $WorkspaceRoot -ChildPath "output"
    if (-not (Test-Path -Path $outDir)) {
        $null = New-Item -Path $outDir -ItemType Directory -Force
    }

    $relVideo = if ($null -ne $Payload.videoFile -and -not [string]::IsNullOrWhiteSpace([string]$Payload.videoFile)) {
        [string]$Payload.videoFile
    } else {
        "assets/licensed/samples/apex_clutch.mp4"
    }
    $videoPath = Join-Path -Path $WorkspaceRoot -ChildPath ($relVideo.Replace('/', '\'))
    if (-not (Test-Path -Path $videoPath -PathType Leaf)) {
        $videoPath = Join-Path -Path $WorkspaceRoot -ChildPath "assets\licensed\samples\apex_clutch.mp4"
    }

    $relMusic = if ($null -ne $Payload.musicFile -and -not [string]::IsNullOrWhiteSpace([string]$Payload.musicFile)) {
        [string]$Payload.musicFile
    } else {
        "assets/licensed/music/chill/Local_Forecast_Elevator.mp3"
    }
    $musicPath = Join-Path -Path $WorkspaceRoot -ChildPath ($relMusic.Replace('/', '\'))
    if (-not (Test-Path -Path $musicPath -PathType Leaf)) {
        $musicPath = Join-Path -Path $WorkspaceRoot -ChildPath "assets\licensed\music\chill\Local_Forecast_Elevator.mp3"
    }

    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $outRel = "output/highlight_master_$stamp.mp4"
    $outFull = Join-Path -Path $WorkspaceRoot -ChildPath ($outRel.Replace('/', '\'))

    $ffmpegCmd = Get-Command -Name "ffmpeg" -ErrorAction SilentlyContinue
    if ($null -eq $ffmpegCmd) {
        Copy-Item -Path $videoPath -Destination $outFull -Force
        $item = Get-Item -Path $outFull
        return [PSCustomObject]@{
            status     = "ok"
            outputFile = $outRel
            sizeMB     = [math]::Round($item.Length / 1MB, 2)
            engine     = "copy-fallback"
        }
    }

    # Build FFmpeg inputs and filter_complex for -18dB sidechain ducking + timed soundbytes
    $ffArgs = [System.Collections.Generic.List[string]]::new()
    $ffArgs.Add("-y")
    $ffArgs.Add("-i")
    $ffArgs.Add($videoPath)
    $ffArgs.Add("-i")
    $ffArgs.Add($musicPath)

    $validMarkers = [System.Collections.Generic.List[PSCustomObject]]::new()
    if ($null -ne $Payload.markers) {
        foreach ($m in @($Payload.markers)) {
            if ($null -ne $m.sfxFile -and -not [string]::IsNullOrWhiteSpace([string]$m.sfxFile)) {
                $sfxFull = Join-Path -Path $WorkspaceRoot -ChildPath (([string]$m.sfxFile).Replace('/', '\'))
                if (Test-Path -Path $sfxFull -PathType Leaf) {
                    $validMarkers.Add([PSCustomObject]@{
                        TimeSec = [double]$m.time
                        Path    = $sfxFull
                    })
                }
            }
        }
    }

    foreach ($vm in $validMarkers) {
        $ffArgs.Add("-i")
        $ffArgs.Add($vm.Path)
    }

    # Build volume ducking expression on [1:a]
    $duckConds = [System.Collections.Generic.List[string]]::new()
    foreach ($vm in $validMarkers) {
        $t0 = [math]::Max(0.0, [math]::Round($vm.TimeSec - 0.05, 2))
        $t1 = [math]::Round($vm.TimeSec + 1.35, 2)
        $duckConds.Add("between(t,$t0,$t1)")
    }

    $volExpr = if ($duckConds.Count -gt 0) {
        $joined = $duckConds -join "+"
        "volume='if(gt($joined,0),0.12,0.75)':eval=frame"
    } else {
        "volume=0.75"
    }

    $filterParts = [System.Collections.Generic.List[string]]::new()
    $filterParts.Add("[0:a]volume=0.80[va]")
    $filterParts.Add("[1:a]$volExpr[bgm]")

    $mixInputs = "[va][bgm]"
    $idx = 2
    foreach ($vm in $validMarkers) {
        $delayMs = [int][math]::Round($vm.TimeSec * 1000)
        $tag = "sfx$idx"
        $filterParts.Add("[$idx`:a]adelay=${delayMs}|${delayMs},volume=1.35[$tag]")
        $mixInputs += "[$tag]"
        $idx++
    }

    $totalStreams = 2 + $validMarkers.Count
    $filterParts.Add("${mixInputs}amix=inputs=${totalStreams}:duration=first:dropout_transition=0,alimiter=limit=0.95[aout]")
    $filterComplex = $filterParts -join ";"

    $ffArgs.Add("-filter_complex")
    $ffArgs.Add($filterComplex)
    $ffArgs.Add("-map")
    $ffArgs.Add("0:v:0")
    $ffArgs.Add("-map")
    $ffArgs.Add("[aout]")
    $ffArgs.Add("-c:v")
    $ffArgs.Add("copy")
    $ffArgs.Add("-c:a")
    $ffArgs.Add("aac")
    $ffArgs.Add("-b:a")
    $ffArgs.Add("192k")
    $ffArgs.Add("-shortest")
    $ffArgs.Add($outFull)

    $proc = Start-Process -FilePath $ffmpegCmd.Source -ArgumentList $ffArgs -NoNewWindow -Wait -PassThru
    if ($proc.ExitCode -ne 0 -or -not (Test-Path -Path $outFull -PathType Leaf)) {
        Copy-Item -Path $videoPath -Destination $outFull -Force
    }

    $outItem = Get-Item -Path $outFull
    return [PSCustomObject]@{
        status     = "ok"
        outputFile = $outRel
        sizeMB     = [math]::Round($outItem.Length / 1MB, 2)
        engine     = "ffmpeg-sidechain-mix"
    }
}

try {
    # 1. Resolve available port
    $targetPort = $Port
    while (-not (Test-PortAvailable -TestPort $targetPort)) {
        Write-Verbose "Port $targetPort is currently in use, trying next port..."
        $targetPort++
    }

    $url = "http://localhost:$targetPort/index.html"
    Write-Host "==========================================================" -ForegroundColor DarkYellow
    Write-Host " [!] APEXPULSE 3D: MUSEUM GALLERY & HIGHLIGHT STUDIO" -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor DarkYellow
    Write-Host " * Serving Directory : $ScriptDir" -ForegroundColor Cyan
    Write-Host " * Local Studio URL  : $url" -ForegroundColor Green
    Write-Host " * Licensed Audio    : 19 CC-BY 4.0 Tracks + 27 CC0 Soundbytes + 8 Footsteps" -ForegroundColor Magenta
    Write-Host " * Render Endpoint   : POST http://localhost:$targetPort/api/render (FFmpeg)" -ForegroundColor Cyan
    Write-Host " * Press Ctrl+C at any time to stop the local studio server" -ForegroundColor Gray
    Write-Host "==========================================================" -ForegroundColor DarkYellow

    # 2. Launch Browser if requested
    if (-not $NoBrowser) {
        if ($PSCmdlet.ShouldProcess($url, "Launch Default Browser")) {
            Start-Process -FilePath $url
        }
    }

    # 3. Lightweight .NET HttpListener Server
    $httpListener = [System.Net.HttpListener]::new()
    $httpListener.Prefixes.Add("http://localhost:$targetPort/")
    $httpListener.Start()

    $mimeMap = @{
        ".html"  = "text/html; charset=utf-8"
        ".htm"   = "text/html; charset=utf-8"
        ".css"   = "text/css; charset=utf-8"
        ".js"    = "application/javascript; charset=utf-8"
        ".json"  = "application/json; charset=utf-8"
        ".png"   = "image/png"
        ".jpg"   = "image/jpeg"
        ".jpeg"  = "image/jpeg"
        ".svg"   = "image/svg+xml"
        ".wav"   = "audio/wav"
        ".mp3"   = "audio/mpeg"
        ".ogg"   = "audio/ogg"
        ".m4a"   = "audio/mp4"
        ".mp4"   = "video/mp4"
        ".webm"  = "video/webm"
        ".woff2" = "font/woff2"
    }

    while ($httpListener.IsListening) {
        $context = $httpListener.GetContext()
        $request = $context.Request
        $response = $context.Response
        $response.AddHeader("Access-Control-Allow-Origin", "*")
        $response.AddHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        $response.AddHeader("Access-Control-Allow-Headers", "Content-Type")

        if ($request.HttpMethod -eq "OPTIONS") {
            $response.StatusCode = 200
            $response.Close()
            continue
        }

        $localPath = $request.Url.LocalPath
        if ($request.HttpMethod -eq "POST" -and $localPath -eq "/api/render") {
            try {
                $reader = [System.IO.StreamReader]::new($request.InputStream, [System.Text.Encoding]::UTF8)
                $rawBody = $reader.ReadToEnd()
                $reader.Close()

                $payload = $rawBody | ConvertFrom-Json
                $renderResult = Invoke-HighlightFFmpegRender -WorkspaceRoot $ScriptDir -Payload $payload
                $jsonBytes = [System.Text.Encoding]::UTF8.GetBytes(($renderResult | ConvertTo-Json -Depth 5 -Compress))

                $response.ContentType = "application/json; charset=utf-8"
                $response.ContentLength64 = $jsonBytes.Length
                $response.StatusCode = 200
                $response.OutputStream.Write($jsonBytes, 0, $jsonBytes.Length)
            }
            catch {
                $errObj = [PSCustomObject]@{
                    status  = "error"
                    message = $_.Exception.Message
                }
                $errJson = [System.Text.Encoding]::UTF8.GetBytes(($errObj | ConvertTo-Json -Compress))
                $response.ContentType = "application/json; charset=utf-8"
                $response.ContentLength64 = $errJson.Length
                $response.StatusCode = 500
                $response.OutputStream.Write($errJson, 0, $errJson.Length)
            }
            $response.Close()
            continue
        }

        $relPath = $localPath.TrimStart('/')
        if ([string]::IsNullOrWhiteSpace($relPath)) {
            $relPath = "index.html"
        }

        $decodedPath = [System.Uri]::UnescapeDataString($relPath).Replace('/', '\')
        $filePath = Join-Path -Path $ScriptDir -ChildPath $decodedPath

        if (Test-Path -Path $filePath -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($filePath).ToLowerInvariant()
            $contentType = if ($mimeMap.ContainsKey($ext)) { $mimeMap[$ext] } else { "application/octet-stream" }
            $response.ContentType = $contentType
            $response.AddHeader("Accept-Ranges", "bytes")

            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            $response.ContentLength64 = $bytes.Length
            $response.StatusCode = 200
            if ($request.HttpMethod -ne "HEAD") {
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
            }
        }
        else {
            $response.StatusCode = 404
            $errBytes = [System.Text.Encoding]::UTF8.GetBytes("404 - Highlight Studio Resource Not Found: $relPath")
            $response.OutputStream.Write($errBytes, 0, $errBytes.Length)
        }
        $response.Close()
    }
}
catch {
    Write-Error "Failed to run Highlight Studio: $_"
}
finally {
    if ($null -ne $httpListener -and $httpListener.IsListening) {
        $httpListener.Stop()
        $httpListener.Close()
    }
}
