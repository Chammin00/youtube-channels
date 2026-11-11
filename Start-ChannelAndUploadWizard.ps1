#Requires -Version 5.1
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ScriptDir) { $ScriptDir = $PSScriptRoot }
Set-Location -Path $ScriptDir

function Start-ChannelAndUploadWizard {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [switch]$OpenBrowserAndFolders
    )

    begin {
        $ErrorActionPreference = 'Stop'
        $outputDir   = Join-Path -Path $ScriptDir -ChildPath "output"
        $brandingDir = Join-Path -Path $ScriptDir -ChildPath "assets\branding"
        $secretFile  = Join-Path -Path $ScriptDir -ChildPath "client_secret.json"
    }

    process {
        if (Test-Path -Path $secretFile) {
            if ($PSCmdlet.ShouldProcess("YouTube Data API v3", "Upload Episode 1 Long-Form and Short via OAuth2")) {
                & python (Join-Path -Path $ScriptDir -ChildPath "youtube_api_upload.py") --episode-id "ep01-eustace-stupid-dog"
            }
        }
        elseif ($OpenBrowserAndFolders) {
            if ($PSCmdlet.ShouldProcess("Browser & File Explorer", "Open YouTube Channel Creation, YouTube Studio, and Rendered Assets")) {
                Start-Process "https://www.youtube.com/account"
                Start-Process "https://studio.youtube.com"
                Start-Process "explorer.exe" -ArgumentList "`"$outputDir`""
                Start-Process "explorer.exe" -ArgumentList "`"$brandingDir`""
            }
        }

        [PSCustomObject]@{
            ChannelName       = "Cartoon White Noise"
            ChannelHandle     = "@CartoonWhiteNoise"
            AvatarFile        = (Join-Path -Path $brandingDir -ChildPath "channel_avatar_800x800.png")
            BannerFile        = (Join-Path -Path $brandingDir -ChildPath "channel_banner_2560x1440.png")
            ThumbnailFile     = (Join-Path -Path $brandingDir -ChildPath "ep01_thumbnail_1280x720.png")
            ShortVideoFile    = (Join-Path -Path $outputDir -ChildPath "ep01-eustace-stupid-dog_SHORT_9x16.mp4")
            LongVideoFile     = (Join-Path -Path $outputDir -ChildPath "ep01-eustace-stupid-dog_LONG_16x9.mp4")
            OAuthConfigured   = (Test-Path -Path $secretFile)
        }
    }
}

Start-ChannelAndUploadWizard -OpenBrowserAndFolders
