#Requires -Version 5.1
<#
.SYNOPSIS
    Builds audio_manifest.json and audio_manifest.js from real, licensed audio files on disk.

.DESCRIPTION
    The studio webpage ONLY lists audio that this script verifies on disk.
    Nothing is hard-coded in the UI, so a track title can never appear without
    a real, playable audio file behind it.

    1. Quarantines legacy System.Speech TTS .wav files in assets/audio/_quarantined_tts
       so synthetic bot voices are never listed or played.
    2. Ensures LICENSE.json metadata exists for all CC-BY 4.0 Kevin MacLeod music folders
       and CC0 1.0 Kenney.nl voiceover/foley folders.
    3. Curates real human voiceover and foley recordings from assets/licensed/_downloads
       into assets/licensed/sfx/{kill,win,loss,tension} and assets/licensed/footsteps.
    4. Writes audio_manifest.json and audio_manifest.js.

.EXAMPLE
    .\Build-AudioManifest.ps1
#>
[CmdletBinding(SupportsShouldProcess)]
param()

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ScriptDir) { $ScriptDir = $PSScriptRoot }
Set-Location -Path $ScriptDir
$ErrorActionPreference = 'Stop'

$root       = Join-Path $ScriptDir 'assets\licensed'
$musicDir   = Join-Path $root 'music'
$sfxDir     = Join-Path $root 'sfx'
$stepsDir   = Join-Path $root 'footsteps'
$dlDir      = Join-Path $root '_downloads'
$outJson    = Join-Path $ScriptDir 'audio_manifest.json'
$outJs      = Join-Path $ScriptDir 'audio_manifest.js'
$audioExt   = @('.mp3', '.ogg', '.wav', '.m4a')

foreach ($d in @($musicDir, $sfxDir, $stepsDir, $dlDir)) {
    if (-not (Test-Path $d)) { $null = New-Item -ItemType Directory -Path $d -Force }
}
foreach ($evt in @('kill', 'win', 'loss', 'tension')) {
    $p = Join-Path $sfxDir $evt
    if (-not (Test-Path $p)) { $null = New-Item -ItemType Directory -Path $p -Force }
}

# ---------------------------------------------------------------------------
# 1. Quarantine legacy System.Speech TTS files in assets/audio
# ---------------------------------------------------------------------------
$legacyAudioDir = Join-Path $ScriptDir 'assets\audio'
if (Test-Path $legacyAudioDir) {
    $quarantineDir = Join-Path $legacyAudioDir '_quarantined_tts'
    $legacyWavs = @(Get-ChildItem -Path $legacyAudioDir -Filter 'ep*.wav' -File -ErrorAction SilentlyContinue)
    if ($legacyWavs.Count -gt 0) {
        if (-not (Test-Path $quarantineDir)) { $null = New-Item -ItemType Directory -Path $quarantineDir -Force }
        foreach ($w in $legacyWavs) {
            Move-Item -Path $w.FullName -Destination (Join-Path $quarantineDir $w.Name) -Force
        }
        Write-Host "Quarantined $($legacyWavs.Count) legacy System.Speech TTS files into assets/audio/_quarantined_tts" -ForegroundColor Yellow
    }
}

# ---------------------------------------------------------------------------
# 2. Write LICENSE.json for Kevin MacLeod CC-BY 4.0 music categories
# ---------------------------------------------------------------------------
$musicCategories = [ordered]@{
    'chill'   = @{ label = 'Chill & Lounge Grooves';    mood = 'Warm jazz, bossa nova, Rhodes lounge & late-night vibe' }
    'hype'    = @{ label = 'High-Energy & Action Funk'; mood = 'Driving slap bass, funk grooves & competitive montage pace' }
    'tension' = @{ label = 'Dramatic Tension & Stealth'; mood = 'Dark orchestral pulse, suspense & boss-fight buildup' }
    'playful' = @{ label = 'Upbeat & Playful Classics'; mood = 'Lighthearted acoustic, sneaky plucks & celebration hooks' }
}

foreach ($catKey in $musicCategories.Keys) {
    $catPath = Join-Path $musicDir $catKey
    if (-not (Test-Path $catPath)) { $null = New-Item -ItemType Directory -Path $catPath -Force }
    $licObj = [PSCustomObject]@{
        label               = $musicCategories[$catKey].label
        mood                = $musicCategories[$catKey].mood
        artist              = 'Kevin MacLeod'
        source              = 'incompetech.com'
        license             = 'CC BY 4.0'
        licenseUrl          = 'https://creativecommons.org/licenses/by/4.0/'
        attribution         = '"{title}" Kevin MacLeod (incompetech.com) - Licensed under Creative Commons: By Attribution 4.0'
        attributionTemplate = '"{title}" by Kevin MacLeod (incompetech.com) - CC BY 4.0'
    }
    $licObj | ConvertTo-Json | Set-Content -Path (Join-Path $catPath 'LICENSE.json') -Encoding UTF8
}

$kenneyLicense = [PSCustomObject]@{
    artist      = 'Kenney Studio Recording'
    source      = 'Kenney.nl Audio Pack'
    license     = 'CC0 1.0 Public Domain'
    licenseUrl  = 'https://creativecommons.org/publicdomain/zero/1.0/'
    attribution = 'Kenney.nl (CC0 1.0 Public Domain - Real Studio Voiceover & Foley)'
}

Write-Output $kenneyLicense | ConvertTo-Json | Set-Content -Path (Join-Path $stepsDir 'LICENSE.json') -Encoding UTF8
foreach ($evt in @('kill', 'win', 'loss', 'tension')) {
    $kenneyLicense | ConvertTo-Json | Set-Content -Path (Join-Path (Join-Path $sfxDir $evt) 'LICENSE.json') -Encoding UTF8
}

# ---------------------------------------------------------------------------
# 3. Curate real studio voiceover & foley files from _downloads
# ---------------------------------------------------------------------------
$curatedMap = @(
    # Footsteps (real recorded floor footsteps)
    @{ Pack = 'kenney rpg audio';              File = 'footstep_0.ogg';             Dest = $stepsDir;                  Name = 'footstep_01.ogg' },
    @{ Pack = 'kenney rpg audio';              File = 'footstep_1.ogg';             Dest = $stepsDir;                  Name = 'footstep_02.ogg' },
    @{ Pack = 'kenney rpg audio';              File = 'footstep_2.ogg';             Dest = $stepsDir;                  Name = 'footstep_03.ogg' },
    @{ Pack = 'kenney rpg audio';              File = 'footstep_3.ogg';             Dest = $stepsDir;                  Name = 'footstep_04.ogg' },
    @{ Pack = 'kenney rpg audio';              File = 'footstep_4.ogg';             Dest = $stepsDir;                  Name = 'footstep_05.ogg' },
    @{ Pack = 'kenney rpg audio';              File = 'footstep_5.ogg';             Dest = $stepsDir;                  Name = 'footstep_06.ogg' },
    @{ Pack = 'kenney rpg audio';              File = 'footstep_6.ogg';             Dest = $stepsDir;                  Name = 'footstep_07.ogg' },
    @{ Pack = 'kenney rpg audio';              File = 'footstep_7.ogg';             Dest = $stepsDir;                  Name = 'footstep_08.ogg' },

    # Kill / Elimination (real human announcer + real foley impacts)
    @{ Pack = 'kenney voiceover pack fighter'; File = 'multi_kill.ogg';             Dest = (Join-Path $sfxDir 'kill'); Name = 'Announcer - Multi Kill.ogg' },
    @{ Pack = 'kenney voiceover pack fighter'; File = 'combo_breaker.ogg';          Dest = (Join-Path $sfxDir 'kill'); Name = 'Announcer - Combo Breaker.ogg' },
    @{ Pack = 'kenney voiceover pack fighter'; File = 'combo.ogg';                  Dest = (Join-Path $sfxDir 'kill'); Name = 'Announcer - Combo Hit.ogg' },
    @{ Pack = 'kenney impact sounds';          File = 'impact_punch_heavy_000.ogg'; Dest = (Join-Path $sfxDir 'kill'); Name = 'Foley - Heavy Knockout Punch.ogg' },
    @{ Pack = 'kenney impact sounds';          File = 'impact_metal_heavy_000.ogg'; Dest = (Join-Path $sfxDir 'kill'); Name = 'Foley - Heavy Armor Strike.ogg' },
    @{ Pack = 'kenney impact sounds';          File = 'impact_bell_heavy_000.ogg';  Dest = (Join-Path $sfxDir 'kill'); Name = 'Foley - Elimination Bell Hit.ogg' },
    @{ Pack = 'kenney rpg audio';              File = 'knife_slice.ogg';            Dest = (Join-Path $sfxDir 'kill'); Name = 'Foley - Blade Slash Confirm.ogg' },

    # Win / Victory (real human voiceover announcer)
    @{ Pack = 'kenney voiceover pack fighter'; File = 'flawless_victory.ogg';       Dest = (Join-Path $sfxDir 'win');  Name = 'Announcer - Flawless Victory.ogg' },
    @{ Pack = 'kenney voiceover pack fighter'; File = 'winner.ogg';                 Dest = (Join-Path $sfxDir 'win');  Name = 'Announcer - Winner.ogg' },
    @{ Pack = 'kenney voiceover pack fighter'; File = 'you_win.ogg';                Dest = (Join-Path $sfxDir 'win');  Name = 'Announcer - You Win.ogg' },
    @{ Pack = 'voice type 1';                  File = 'congratulations.ogg';        Dest = (Join-Path $sfxDir 'win');  Name = 'Voiceover - Congratulations.ogg' },
    @{ Pack = 'voice type 1';                  File = 'mission_completed.ogg';      Dest = (Join-Path $sfxDir 'win');  Name = 'Voiceover - Mission Completed.ogg' },
    @{ Pack = 'voice type 1';                  File = 'objective_achieved.ogg';     Dest = (Join-Path $sfxDir 'win');  Name = 'Voiceover - Objective Achieved.ogg' },
    @{ Pack = 'voice type 1';                  File = 'new_highscore.ogg';          Dest = (Join-Path $sfxDir 'win');  Name = 'Voiceover - New Highscore.ogg' },
    @{ Pack = 'voice type 1';                  File = 'level_up.ogg';               Dest = (Join-Path $sfxDir 'win');  Name = 'Voiceover - Level Up.ogg' },

    # Loss / Defeat (real human voiceover announcer)
    @{ Pack = 'kenney voiceover pack fighter'; File = 'game_over.ogg';              Dest = (Join-Path $sfxDir 'loss'); Name = 'Announcer - Game Over.ogg' },
    @{ Pack = 'kenney voiceover pack fighter'; File = 'you_lose.ogg';               Dest = (Join-Path $sfxDir 'loss'); Name = 'Announcer - You Lose.ogg' },
    @{ Pack = 'kenney voiceover pack fighter'; File = 'loser.ogg';                  Dest = (Join-Path $sfxDir 'loss'); Name = 'Announcer - Loser.ogg' },
    @{ Pack = 'voice type 1';                  File = 'mission_failed.ogg';         Dest = (Join-Path $sfxDir 'loss'); Name = 'Voiceover - Mission Failed.ogg' },
    @{ Pack = 'voice type 1';                  File = 'time_over.ogg';              Dest = (Join-Path $sfxDir 'loss'); Name = 'Voiceover - Time Over.ogg' },

    # Tension / Buildup (real human voiceover announcer)
    @{ Pack = 'kenney voiceover pack fighter'; File = 'final_round.ogg';            Dest = (Join-Path $sfxDir 'tension'); Name = 'Announcer - Final Round.ogg' },
    @{ Pack = 'kenney voiceover pack fighter'; File = 'sudden_death.ogg';           Dest = (Join-Path $sfxDir 'tension'); Name = 'Announcer - Sudden Death.ogg' },
    @{ Pack = 'kenney voiceover pack fighter'; File = 'prepare_yourself.ogg';       Dest = (Join-Path $sfxDir 'tension'); Name = 'Announcer - Prepare Yourself.ogg' },
    @{ Pack = 'kenney voiceover pack fighter'; File = 'fight.ogg';                  Dest = (Join-Path $sfxDir 'tension'); Name = 'Announcer - Fight.ogg' },
    @{ Pack = 'kenney voiceover pack fighter'; File = 'tie_breaker.ogg';            Dest = (Join-Path $sfxDir 'tension'); Name = 'Announcer - Tie Breaker.ogg' },
    @{ Pack = 'voice type 1';                  File = 'hurry_up.ogg';               Dest = (Join-Path $sfxDir 'tension'); Name = 'Voiceover - Hurry Up.ogg' },
    @{ Pack = 'voice type 1';                  File = 'ready.ogg';                  Dest = (Join-Path $sfxDir 'tension'); Name = 'Voiceover - Ready.ogg' }
)

$allDlFiles = @(Get-ChildItem -Path $dlDir -Recurse -File -ErrorAction SilentlyContinue)
$copiedCount = 0
foreach ($item in $curatedMap) {
    $match = $allDlFiles | Where-Object { $_.Directory.Name -eq $item.Pack -and $_.Name -eq $item.File } | Select-Object -First 1
    if ($null -ne $match) {
        $destFile = Join-Path $item.Dest $item.Name
        if (-not (Test-Path $destFile)) {
            Copy-Item -Path $match.FullName -Destination $destFile -Force
            $copiedCount++
        }
    }
}
if ($copiedCount -gt 0) {
    Write-Host "Curated $copiedCount real studio voiceover & foley files into assets/licensed." -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# 4. Scan disk and build manifest
# ---------------------------------------------------------------------------
function Get-RelativeWebPath {
    param([string]$FullPath)
    return $FullPath.Substring($ScriptDir.Length + 1).Replace('\', '/')
}

function Get-FolderLicense {
    param([string]$Folder)
    $lic = Join-Path $Folder 'LICENSE.json'
    if (Test-Path $lic) { return (Get-Content $lic -Raw | ConvertFrom-Json) }
    return $null
}

$skipped = New-Object System.Collections.Generic.List[string]

function Get-AudioEntries {
    param([string]$Folder, [string]$IdPrefix)
    $license = Get-FolderLicense -Folder $Folder
    $files = @(Get-ChildItem -Path $Folder -File -ErrorAction SilentlyContinue |
        Where-Object { $audioExt -contains $_.Extension.ToLowerInvariant() -and $_.Length -gt 1024 } |
        Sort-Object Name)
    $entries = @()
    foreach ($f in $files) {
        if ($null -eq $license) { $skipped.Add((Get-RelativeWebPath $f.FullName)); continue }
        $title = $f.BaseName
        $credit = $license.attribution
        if ($license.attributionTemplate) { $credit = $license.attributionTemplate.Replace('{title}', $f.BaseName) }
        $entries += [PSCustomObject]@{
            id         = ('{0}-{1}' -f $IdPrefix, ($f.BaseName.ToLowerInvariant() -replace '[^a-z0-9]+', '-')).Trim('-')
            title      = $title
            file       = Get-RelativeWebPath $f.FullName
            bytes      = $f.Length
            sizeMB     = [math]::Round($f.Length / 1MB, 2)
            sizeKB     = [math]::Round($f.Length / 1KB, 1)
            artist     = $license.artist
            source     = $license.source
            license    = $license.license
            licenseUrl = $license.licenseUrl
            credit     = $credit
        }
    }
    return ,$entries
}

$music = @()
foreach ($catKey in $musicCategories.Keys) {
    $catFolder = Join-Path $musicDir $catKey
    if (Test-Path $catFolder) {
        $tracks = Get-AudioEntries -Folder $catFolder -IdPrefix ('m-' + $catKey)
        if ($tracks.Count -gt 0) {
            $meta = Get-FolderLicense -Folder $catFolder
            $music += [PSCustomObject]@{
                id     = $catKey
                label  = $meta.label
                mood   = $meta.mood
                tracks = $tracks
            }
        }
    }
}

$sfx = [ordered]@{}
foreach ($evt in @('tension', 'kill', 'loss', 'win')) {
    $sfx[$evt] = Get-AudioEntries -Folder (Join-Path $sfxDir $evt) -IdPrefix ('s-' + $evt)
}

$footsteps = Get-AudioEntries -Folder $stepsDir -IdPrefix 'step'

$manifest = [PSCustomObject]@{
    generated = (Get-Date).ToString('s')
    music     = $music
    sfx       = $sfx
    footsteps = $footsteps
}

$jsonText = $manifest | ConvertTo-Json -Depth 8
Set-Content -Path $outJson -Value $jsonText -Encoding UTF8
Set-Content -Path $outJs -Value ("window.AUDIO_MANIFEST = " + $jsonText + ";") -Encoding UTF8

$trackCount = ($music | ForEach-Object { $_.tracks.Count } | Measure-Object -Sum).Sum
[PSCustomObject]@{
    MusicTracks = [int]$trackCount
    TensionSFX  = @($sfx['tension']).Count
    KillSFX     = @($sfx['kill']).Count
    LossSFX     = @($sfx['loss']).Count
    WinSFX      = @($sfx['win']).Count
    Footsteps   = @($footsteps).Count
    Skipped     = $skipped.Count
}
