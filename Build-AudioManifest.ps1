#Requires -Version 5.1
<#
.SYNOPSIS
    Builds audio_manifest.json and audio_manifest.js from real, verified character soundbytes and background music on disk.

.DESCRIPTION
    The 3D Highlight Studio webpage ONLY lists audio that this script verifies on disk.
    1. Quarantines legacy System.Speech TTS .wav files in assets/audio/_quarantined_tts
       so synthetic bot/narrator voices are never listed or played.
    2. Syncs the user-approved Tekken 8 / Marshall Law real character soundbytes
       (Pokemon Stadium, Mario SM64, Eustace Laughs, Rush Hour, Kurama, Hiei, Captain Insano,
       Peppy Barrel Roll, CJ Here We Go Again, Rolf Hat of Discipline) into assets/licensed/sfx/{tension,kill,loss,win}.
    3. Syncs the curated Gaming & Anime Background Music library (Sonic Adventure 1 & 2, Yu Yu Hakusho,
       Streets of Rage 2, River City Ransom/Girls, Mega Man 2, Perfect Dark, Pokemon XD, Zelda, DKC)
       alongside the Kevin MacLeod CC-BY 4.0 studio categories into assets/licensed/music.
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

$ytMusicSource     = 'G:\My Drive\Antigravity\Projects\automate my day\modules\youtube\music'
$ytSoundbiteSource = 'G:\My Drive\Antigravity\Projects\automate my day\modules\youtube\soundbites'

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
# 2. Configure Music Categories & LICENSE.json Metadata
# ---------------------------------------------------------------------------
$musicCategories = [ordered]@{
    'sonic_yyh'    = @{
        label               = 'Sonic Adventure & Yu Yu Hakusho OST'
        mood                = 'High-octane Dreamcast rock, Chao vibes & 90s anime battle grooves'
        artist              = 'SEGA Sound Team / Studio Pierrot'
        source              = 'Curated Gaming & Anime Vault'
        license             = 'Creator Vault OST'
        licenseUrl          = 'https://youtube.com/@chaseham00'
        attribution         = '"{title}" - Curated Gaming & Anime Soundtrack (@chaseham00)'
        attributionTemplate = '"{title}" - Curated Gaming & Anime Soundtrack (@chaseham00)'
    }
    'arcade_retro' = @{
        label               = 'Arcade Fighting & Retro Classics'
        mood                = 'Streets of Rage 2, Guile Theme, River City Ransom, Mega Man 2 & Pokemon XD'
        artist              = 'Yuzo Koshiro / Capcom / Technos / Nintendo'
        source              = 'Retro Arcade Vault'
        license             = 'Creator Vault OST'
        licenseUrl          = 'https://youtube.com/@chaseham00'
        attribution         = '"{title}" - Retro Arcade & Fighting Soundtrack (@chaseham00)'
        attributionTemplate = '"{title}" - Retro Arcade & Fighting Soundtrack (@chaseham00)'
    }
    'perfect_dark' = @{
        label               = 'Perfect Dark Tactical & Synth Score'
        mood                = 'Grant Kirkhope & Graeme Norgate sci-fi espionage & combat themes'
        artist              = 'Rareware Sound Team'
        source              = 'Perfect Dark OST Vault'
        license             = 'Creator Vault OST'
        licenseUrl          = 'https://youtube.com/@chaseham00'
        attribution         = '"{title}" - Perfect Dark Tactical Soundtrack (@chaseham00)'
        attributionTemplate = '"{title}" - Perfect Dark Tactical Soundtrack (@chaseham00)'
    }
    'flow_music'   = @{
        label               = 'Google Flow Music Originals (Monetization-Safe)'
        mood                = 'Original Lyria studio grooves, anime jazz-rock, neo-soul, and sleep beds'
        artist              = 'Chase (@chaseham00) / Google Flow Music'
        source              = 'Google Flow Music Vault'
        license             = 'Original Creator Track (Flow Music)'
        licenseUrl          = 'https://youtube.com/@chaseham00'
        attribution         = '"{title}" - Original Track produced with Google Flow Music (@chaseham00)'
        attributionTemplate = '"{title}" - Google Flow Music Original (@chaseham00)'
    }
    'chill'        = @{
        label               = 'Chill & Lounge Grooves'
        mood                = 'Warm jazz, bossa nova, Rhodes lounge & late-night vibe'
        artist              = 'Kevin MacLeod'
        source              = 'incompetech.com'
        license             = 'CC BY 4.0'
        licenseUrl          = 'https://creativecommons.org/licenses/by/4.0/'
        attribution         = '"{title}" Kevin MacLeod (incompetech.com) - Licensed under Creative Commons: By Attribution 4.0'
        attributionTemplate = '"{title}" by Kevin MacLeod (incompetech.com) - CC BY 4.0'
    }
    'hype'         = @{
        label               = 'High-Energy & Action Funk'
        mood                = 'Driving slap bass, funk grooves & competitive montage pace'
        artist              = 'Kevin MacLeod'
        source              = 'incompetech.com'
        license             = 'CC BY 4.0'
        licenseUrl          = 'https://creativecommons.org/licenses/by/4.0/'
        attribution         = '"{title}" Kevin MacLeod (incompetech.com) - Licensed under Creative Commons: By Attribution 4.0'
        attributionTemplate = '"{title}" by Kevin MacLeod (incompetech.com) - CC BY 4.0'
    }
    'tension'      = @{
        label               = 'Dramatic Tension & Stealth'
        mood                = 'Dark orchestral pulse, suspense & boss-fight buildup'
        artist              = 'Kevin MacLeod'
        source              = 'incompetech.com'
        license             = 'CC BY 4.0'
        licenseUrl          = 'https://creativecommons.org/licenses/by/4.0/'
        attribution         = '"{title}" Kevin MacLeod (incompetech.com) - Licensed under Creative Commons: By Attribution 4.0'
        attributionTemplate = '"{title}" by Kevin MacLeod (incompetech.com) - CC BY 4.0'
    }
    'playful'      = @{
        label               = 'Upbeat & Playful Classics'
        mood                = 'Lighthearted acoustic, sneaky plucks & celebration hooks'
        artist              = 'Kevin MacLeod'
        source              = 'incompetech.com'
        license             = 'CC BY 4.0'
        licenseUrl          = 'https://creativecommons.org/licenses/by/4.0/'
        attribution         = '"{title}" Kevin MacLeod (incompetech.com) - Licensed under Creative Commons: By Attribution 4.0'
        attributionTemplate = '"{title}" by Kevin MacLeod (incompetech.com) - CC BY 4.0'
    }
}

foreach ($catKey in $musicCategories.Keys) {
    $catPath = Join-Path $musicDir $catKey
    if (-not (Test-Path $catPath)) { $null = New-Item -ItemType Directory -Path $catPath -Force }
    $metaInfo = $musicCategories[$catKey]
    $licObj = [PSCustomObject]@{
        label               = $metaInfo.label
        mood                = $metaInfo.mood
        artist              = $metaInfo.artist
        source              = $metaInfo.source
        license             = $metaInfo.license
        licenseUrl          = $metaInfo.licenseUrl
        attribution         = $metaInfo.attribution
        attributionTemplate = $metaInfo.attributionTemplate
    }
    $licObj | ConvertTo-Json | Set-Content -Path (Join-Path $catPath 'LICENSE.json') -Encoding UTF8
}

$sfxLicense = [PSCustomObject]@{
    artist      = 'Verified Character Voicelines & Studio Foley'
    source      = 'Tekken 8 / Marshall Law Approved Soundboard + Kenney.nl'
    license     = 'Approved Character Baseline'
    licenseUrl  = 'https://youtube.com/@chaseham00'
    attribution = 'Authentic Character Soundbytes & Studio Foley (@chaseham00)'
}

Write-Output $sfxLicense | ConvertTo-Json | Set-Content -Path (Join-Path $stepsDir 'LICENSE.json') -Encoding UTF8
foreach ($evt in @('kill', 'win', 'loss', 'tension')) {
    $sfxLicense | ConvertTo-Json | Set-Content -Path (Join-Path (Join-Path $sfxDir $evt) 'LICENSE.json') -Encoding UTF8
}

function Copy-AudioAssetIfChanged {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)][string]$SourcePath,
        [Parameter(Mandatory = $true)][string]$DestinationPath
    )

    if (-not (Test-Path -Path $SourcePath)) {
        return $false
    }

    $shouldCopy = -not (Test-Path -Path $DestinationPath)
    if (-not $shouldCopy) {
        $srcItem = Get-Item -Path $SourcePath
        $destItem = Get-Item -Path $DestinationPath
        if (($srcItem.Length -ne $destItem.Length) -or ($srcItem.LastWriteTimeUtc -gt $destItem.LastWriteTimeUtc)) {
            $shouldCopy = $true
        }
    }

    if ($shouldCopy -and $PSCmdlet.ShouldProcess($DestinationPath, "Copy from $SourcePath")) {
        Copy-Item -Path $SourcePath -Destination $DestinationPath -Force
        return $true
    }
    return $false
}

# ---------------------------------------------------------------------------
# 2B. Sync Curated Background Music from YouTube Automation Vault
# ---------------------------------------------------------------------------
if (Test-Path $ytMusicSource) {
    $musicSyncMap = @(
        # Sonic Adventure 1 & 2 + Yu Yu Hakusho
        @{ Src = 'sonic_adventure_city_escape.mp3';              Cat = 'sonic_yyh';    DestName = 'Sonic Adventure 2 - City Escape.mp3' },
        @{ Src = 'sonic_live_and_learn_rock.mp3';                Cat = 'sonic_yyh';    DestName = 'Sonic Adventure 2 - Live and Learn.mp3' },
        @{ Src = 'sonic_adventure_it_doesnt_matter.mp3';         Cat = 'sonic_yyh';    DestName = 'Sonic Adventure - It Doesnt Matter.mp3' },
        @{ Src = 'sonic_adventure_theme_of_e102_gamma.mp3';      Cat = 'sonic_yyh';    DestName = 'Sonic Adventure - Theme of E-102 Gamma.mp3' },
        @{ Src = 'sonic_adventure_e101_beta_crazy_robo.mp3';     Cat = 'sonic_yyh';    DestName = 'Sonic Adventure - E-101 Beta Crazy Robo.mp3' },
        @{ Src = 'sonic_adventure_green_forest.mp3';             Cat = 'sonic_yyh';    DestName = 'Sonic Adventure 2 - Green Forest.mp3' },
        @{ Src = 'sonic_adventure_final_rush.mp3';               Cat = 'sonic_yyh';    DestName = 'Sonic Adventure 2 - Final Rush.mp3' },
        @{ Src = 'sonic_adventure_wild_canyon.mp3';              Cat = 'sonic_yyh';    DestName = 'Sonic Adventure 2 - Wild Canyon.mp3' },
        @{ Src = 'sonic_adventure_pumpkin_hill.mp3';             Cat = 'sonic_yyh';    DestName = 'Sonic Adventure 2 - Pumpkin Hill.mp3' },
        @{ Src = 'sonic_adventure_for_true_story.mp3';           Cat = 'sonic_yyh';    DestName = 'Sonic Adventure 2 - For True Story.mp3' },
        @{ Src = 'sonic_adventure_unknown_from_me.mp3';          Cat = 'sonic_yyh';    DestName = 'Sonic Adventure - Unknown From Me.mp3' },
        @{ Src = 'yu_yu_hakusho_opening_smile_bomb.mp3';         Cat = 'sonic_yyh';    DestName = 'Yu Yu Hakusho - Smile Bomb Opening.mp3' },
        @{ Src = 'yu_yu_hakusho_ed1_homework_doesnt_end.mp3';    Cat = 'sonic_yyh';    DestName = 'Yu Yu Hakusho - Homework Doesnt End ED1.mp3' },
        @{ Src = 'yu_yu_hakusho_ed3.mp3';                        Cat = 'sonic_yyh';    DestName = 'Yu Yu Hakusho - Ending 3 Unbalanced Kiss.mp3' },
        @{ Src = 'yu_yu_hakusho_ed5.mp3';                        Cat = 'sonic_yyh';    DestName = 'Yu Yu Hakusho - Ending 5 Daydream Generation.mp3' },
        @{ Src = 'yu_yu_hakusho_chill.mp3';                      Cat = 'sonic_yyh';    DestName = 'Yu Yu Hakusho - Struggle of Sadness.mp3' },

        # Arcade Fighting & Retro Classics
        @{ Src = 'Streets Of Rage 2 Soundtrack - Stage 1-1 (Go Straight).mp3'; Cat = 'arcade_retro'; DestName = 'Streets of Rage 2 - Stage 1-1 Go Straight.mp3' },
        @{ Src = 'guile_theme_arcade.mp3';                       Cat = 'arcade_retro'; DestName = 'Street Fighter II - Guiles Theme Arcade.mp3' },
        @{ Src = 'pokemon_xd_miror_b_battle.mp3';                Cat = 'arcade_retro'; DestName = 'Pokemon XD - Miror B Battle Groove.mp3' },
        @{ Src = 'river_city_ransom_boss_battle_01.mp3';         Cat = 'arcade_retro'; DestName = 'River City Ransom - Boss Battle 01.mp3' },
        @{ Src = 'river_city_ransom_boss_battle_02.mp3';         Cat = 'arcade_retro'; DestName = 'River City Ransom - Boss Battle 02.mp3' },
        @{ Src = 'river_city_ransom_final_battle.mp3';           Cat = 'arcade_retro'; DestName = 'River City Ransom - Final Battle.mp3' },
        @{ Src = 'river_city_ransom_twin_dragons.mp3';           Cat = 'arcade_retro'; DestName = 'River City Ransom - Twin Dragons.mp3' },
        @{ Src = 'river_city_ransom_river_city_high.mp3';        Cat = 'arcade_retro'; DestName = 'River City Ransom - River City High.mp3' },
        @{ Src = 'river_city_ransom_menu_shop.mp3';              Cat = 'arcade_retro'; DestName = 'River City Ransom - Menu Shop.mp3' },
        @{ Src = 'river_city_ransom_prologue_credit_roll.mp3';   Cat = 'arcade_retro'; DestName = 'River City Ransom - Prologue Credit Roll.mp3' },
        @{ Src = 'rcg_knock_out.mp3';                            Cat = 'arcade_retro'; DestName = 'River City Girls - Knock Out.mp3' },
        @{ Src = 'rcg_dont_give_a.mp3';                          Cat = 'arcade_retro'; DestName = 'River City Girls - Dont Give A.mp3' },
        @{ Src = 'rcg_the_burbs.mp3';                            Cat = 'arcade_retro'; DestName = 'River City Girls - The Burbs.mp3' },
        @{ Src = 'rcg_manga_1.mp3';                              Cat = 'arcade_retro'; DestName = 'River City Girls - Manga Cutscene.mp3' },
        @{ Src = 'rcg_shop_1.mp3';                               Cat = 'arcade_retro'; DestName = 'River City Girls - Shop Theme 1.mp3' },
        @{ Src = 'rcg_shop_2.mp3';                               Cat = 'arcade_retro'; DestName = 'River City Girls - Shop Theme 2.mp3' },
        @{ Src = 'rcg_shop_3.mp3';                               Cat = 'arcade_retro'; DestName = 'River City Girls - Shop Theme 3.mp3' },
        @{ Src = 'rcg_shop_4.mp3';                               Cat = 'arcade_retro'; DestName = 'River City Girls - Shop Theme 4.mp3' },
        @{ Src = 'rcg_shop_5.mp3';                               Cat = 'arcade_retro'; DestName = 'River City Girls - Shop Theme 5.mp3' },
        @{ Src = 'nes_megaman2_dr_wily_stage_1.mp3';             Cat = 'arcade_retro'; DestName = 'Mega Man 2 - Dr Wily Stage 1.mp3' },
        @{ Src = 'nes_megaman2_quickman.mp3';                    Cat = 'arcade_retro'; DestName = 'Mega Man 2 - Quick Man Stage.mp3' },
        @{ Src = 'nes_megaman2_bubbleman.mp3';                   Cat = 'arcade_retro'; DestName = 'Mega Man 2 - Bubble Man Stage.mp3' },
        @{ Src = 'nes_megaman2_title_theme.mp3';                 Cat = 'arcade_retro'; DestName = 'Mega Man 2 - Opening Title Theme.mp3' },
        @{ Src = 'ninja_gaiden_cutscene_act_1.mp3';              Cat = 'arcade_retro'; DestName = 'Ninja Gaiden - Act 1 Cutscene.mp3' },
        @{ Src = 'ninja_gaiden_cutscene_act_2.mp3';              Cat = 'arcade_retro'; DestName = 'Ninja Gaiden - Act 2 Cutscene.mp3' },
        @{ Src = 'ninja_gaiden_cutscene_act_4.mp3';              Cat = 'arcade_retro'; DestName = 'Ninja Gaiden - Act 4 Cutscene.mp3' },
        @{ Src = 'ninja_gaiden_cutscene_act_5.mp3';              Cat = 'arcade_retro'; DestName = 'Ninja Gaiden - Act 5 Cutscene.mp3' },
        @{ Src = 'zelda_fairy_fountain_chill.mp3';               Cat = 'arcade_retro'; DestName = 'Zelda - Great Fairy Fountain.mp3' },
        @{ Src = 'dkc_aquatic_ambiance.mp3';                     Cat = 'arcade_retro'; DestName = 'Donkey Kong Country - Aquatic Ambiance.mp3' },
        @{ Src = 'wii_shop_channel_chill_trap.mp3';              Cat = 'arcade_retro'; DestName = 'Wii Shop Channel - Original Theme.mp3' },

        # Perfect Dark Tactical Score
        @{ Src = 'perfect_dark_datadyne_central_defection.mp3';      Cat = 'perfect_dark'; DestName = 'Perfect Dark - DataDyne Central Defection.mp3' },
        @{ Src = 'perfect_dark_datadyne_central_defection_x.mp3';    Cat = 'perfect_dark'; DestName = 'Perfect Dark - DataDyne Defection Action X.mp3' },
        @{ Src = 'perfect_dark_datadyne_central_investigation_x.mp3';Cat = 'perfect_dark'; DestName = 'Perfect Dark - DataDyne Investigation X.mp3' },
        @{ Src = 'perfect_dark_datadyne_central_extraction_x.mp3';   Cat = 'perfect_dark'; DestName = 'Perfect Dark - DataDyne Extraction X.mp3' },
        @{ Src = 'perfect_dark_carrington_institute.mp3';            Cat = 'perfect_dark'; DestName = 'Perfect Dark - Carrington Institute HQ.mp3' },
        @{ Src = 'perfect_dark_institute_menu.mp3';                  Cat = 'perfect_dark'; DestName = 'Perfect Dark - Institute Main Menu.mp3' },
        @{ Src = 'perfect_dark_carrington_institute_defense.mp3';    Cat = 'perfect_dark'; DestName = 'Perfect Dark - Carrington Institute Defense.mp3' },
        @{ Src = 'perfect_dark_carrington_institute_defense_x.mp3';  Cat = 'perfect_dark'; DestName = 'Perfect Dark - Carrington Defense Action X.mp3' },
        @{ Src = 'perfect_dark_carrington_villa_hostage_one_x.mp3';  Cat = 'perfect_dark'; DestName = 'Perfect Dark - Carrington Villa Hostage X.mp3' },
        @{ Src = 'perfect_dark_chicago_stealth.mp3';                 Cat = 'perfect_dark'; DestName = 'Perfect Dark - Chicago Stealth Ambience.mp3' },
        @{ Src = 'perfect_dark_chicago_stealth_x.mp3';               Cat = 'perfect_dark'; DestName = 'Perfect Dark - Chicago Punk Action X.mp3' },
        @{ Src = 'perfect_dark_g5_building_reconnaissance_x.mp3';    Cat = 'perfect_dark'; DestName = 'Perfect Dark - G5 Building Recon X.mp3' },
        @{ Src = 'perfect_dark_area_51_rescue_x.mp3';                Cat = 'perfect_dark'; DestName = 'Perfect Dark - Area 51 Rescue X.mp3' },
        @{ Src = 'perfect_dark_area_51_escape_x.mp3';                Cat = 'perfect_dark'; DestName = 'Perfect Dark - Area 51 Escape X.mp3' },
        @{ Src = 'perfect_dark_air_base_espionage_x.mp3';            Cat = 'perfect_dark'; DestName = 'Perfect Dark - Air Base Espionage X.mp3' },
        @{ Src = 'perfect_dark_skedar_ruins_battle_shrine_x.mp3';    Cat = 'perfect_dark'; DestName = 'Perfect Dark - Skedar Ruins Battle Shrine X.mp3' },
        @{ Src = 'perfect_dark_skedar_leader.mp3';                   Cat = 'perfect_dark'; DestName = 'Perfect Dark - Skedar Leader Boss Finale.mp3' },
        @{ Src = 'perfect_dark_credits.mp3';                         Cat = 'perfect_dark'; DestName = 'Perfect Dark - End Credits Theme.mp3' }
    )

    $syncedMusicCount = 0
    foreach ($mItem in $musicSyncMap) {
        $srcFile = Join-Path $ytMusicSource $mItem.Src
        $destFolder = Join-Path $musicDir $mItem.Cat
        $destPath = Join-Path $destFolder $mItem.DestName
        if (Copy-AudioAssetIfChanged -SourcePath $srcFile -DestinationPath $destPath) {
            $syncedMusicCount++
        }
    }
    if ($syncedMusicCount -gt 0) {
        Write-Host "Synced $syncedMusicCount curated Gaming & Anime BGM tracks into assets/licensed/music." -ForegroundColor Cyan
    }
}

# ---------------------------------------------------------------------------
# 2D. Sync Google Flow Music Originals (if staged in exports/youtube_channels)
# ---------------------------------------------------------------------------
$flowMusicExportSource = 'G:\My Drive\Antigravity\Projects\Google Flow-music\exports\youtube_channels'
if (Test-Path $flowMusicExportSource) {
    $flowMusicFiles = @(Get-ChildItem -Path $flowMusicExportSource -File -ErrorAction SilentlyContinue |
        Where-Object { $audioExt -contains $_.Extension.ToLowerInvariant() })
    $syncedFlowCount = 0
    $flowDestFolder = Join-Path $musicDir 'flow_music'
    foreach ($fmFile in $flowMusicFiles) {
        $destPath = Join-Path $flowDestFolder $fmFile.Name
        if (Copy-AudioAssetIfChanged -SourcePath $fmFile.FullName -DestinationPath $destPath) {
            $syncedFlowCount++
        }
    }
    if ($syncedFlowCount -gt 0) {
        Write-Host "Synced $syncedFlowCount Google Flow Music originals into assets/licensed/music/flow_music." -ForegroundColor Cyan
    }
}

# ---------------------------------------------------------------------------
# 2C. Sync Approved Tekken 8 / Marshall Law Real Character Soundbytes
# ---------------------------------------------------------------------------
if (Test-Path $ytSoundbiteSource) {
    $approvedSfxMap = @(
        # TENSION (★ Mark 1: Standoff / Opponent Heat Engager / Flip Kick Lead-in / Clutch Comeback)
        @{ Src = 'pokemon_whats_the_matter_trainer.mp3'; Evt = 'tension'; DestName = '01_Pokemon Stadium - Theyre Staring Each Other Down (Standoff).mp3' },
        @{ Src = 'cj_here_we_go_again.wav';              Evt = 'tension'; DestName = '02_CJ (GTA SA) - Aw Shit Here We Go Again (Opponent Heat Engager).wav' },
        @{ Src = 'do_a_barrel_roll_peppy.wav';           Evt = 'tension'; DestName = '03_Peppy (Star Fox 64) - Do a Barrel Roll (Law Flip Attack).wav' },
        @{ Src = 'waterboy_you_can_do_it.mp3';           Evt = 'tension'; DestName = '05_Waterboy (Rob Schneider) - You Can Do It (Clutch Comeback).mp3' },
        @{ Src = 'rush_hour_put_the_gun_down.mp3';       Evt = 'tension'; DestName = '06_Rush Hour - Put Your Gun Down Fight Like a Man (Enemy Lancer Cross).mp3' },
        @{ Src = 'pd_elvis_dont_mess_maian.mp3';         Evt = 'tension'; DestName = '07_Perfect Dark (Elvis Maian) - Dont Mess With the Maian Im Bad (Locust Duel).mp3' },

        # KILL (★ Mark 2: Law Successful Throw / Good Kick Lee / Counter-Hit / Rolf Discipline / Captain Insano / Eustace Laughs / Elvis & PD Guard)
        @{ Src = 'mario_so_long_bowser.mp3';             Evt = 'kill';    DestName = '01_Mario (SM64) - So Long Eh Bowser (Law Successful Throw).mp3' },
        @{ Src = 'damn_good_kick_lee.wav';               Evt = 'kill';    DestName = '02_Rush Hour - Damn Good Kick Lee (Heavy Kick).wav' },
        @{ Src = 'good_kick_lee_clean_vocal.wav';        Evt = 'kill';    DestName = '03_Rush Hour - Good Kick Lee (Short Kick Cut).wav' },
        @{ Src = 'pokemon_counterattack.mp3';            Evt = 'kill';    DestName = '04_Pokemon Stadium - A Counterattack (Counter-Hit).mp3' },
        @{ Src = 'rolf_hat_of_discipline.mp3';           Evt = 'kill';    DestName = '06_Rolf (Ed Edd n Eddy) - The Hat of Discipline.mp3' },
        @{ Src = 'waterboy_captain_insano_no_mercy.mp3'; Evt = 'kill';    DestName = '07_Captain Insano (Waterboy) - Shows No Mercy (Toe-Stomp & Heat).mp3' },
        @{ Src = 'eustace_laugh.mp3';                    Evt = 'kill';    DestName = '08_Eustace Bagge - Evil Smug Laugh (Slide & Hit).mp3' },
        @{ Src = 'eustace_happy_laugh.mp3';              Evt = 'kill';    DestName = '09_Eustace Bagge - Happy Cackle Laugh (Hit & Slide).mp3' },
        @{ Src = 'pd_elvis_eat_hot_death.mp3';           Evt = 'kill';    DestName = '10_Perfect Dark (Elvis Maian) - Eat Hot Death Weirdos (Locust Kill).mp3' },
        @{ Src = 'pd_elvis_alien_butt_kick_ass.mp3';     Evt = 'kill';    DestName = '11_Perfect Dark (Elvis Maian) - Kiss My Alien Butt Ill Kick Your Ass (Locust).mp3' },
        @{ Src = 'pd_body_bag_morgue.mp3';               Evt = 'kill';    DestName = '12_Perfect Dark (Guard) - Grab a Body Bag One for the Morgue (Gnasher Gib).mp3' },
        @{ Src = 'pd_target_eliminated.mp3';             Evt = 'kill';    DestName = '13_Perfect Dark (Guard) - Target Eliminated (Headshot).mp3' },

        # LOSS (★ Mark 3: Whiff / Dodge / Sidestep / Throw Break Escape / Shes a Tricky One)
        @{ Src = 'pokemon_thats_a_miss.mp3';             Evt = 'loss';    DestName = '01_Pokemon Stadium - Oh Thats a Miss Whoops (Whiff).mp3' },
        @{ Src = 'pokemon_way_to_dodge.mp3';             Evt = 'loss';    DestName = '02_Pokemon Stadium - Yes Way to Dodge (Sidestep).mp3' },
        @{ Src = 'pokemon_skillfully_avoided.mp3';       Evt = 'loss';    DestName = '03_Pokemon Stadium - It Skillfully Avoided That Blow (Duck).mp3' },
        @{ Src = 'rush_hour_get_your_hands_off_me.mp3';  Evt = 'loss';    DestName = '04_Rush Hour - Get Your Hands Off of Me (Throw Break).mp3' },
        @{ Src = 'pd_shes_a_tricky_one.mp3';             Evt = 'loss';    DestName = '05_Perfect Dark (Guard) - Shes a Tricky One (Wallbounce Evasion).mp3' },
        @{ Src = 'pd_why_me.mp3';                        Evt = 'loss';    DestName = '06_Perfect Dark (Guard) - Why Me Nooo (Meatshield Execution).mp3' },
        @{ Src = 'pd_elvis_watch_the_suit.mp3';          Evt = 'loss';    DestName = '07_Perfect Dark (Elvis Maian) - Oh Its All Going Wrong Watch the Suit (Locust).mp3' },

        # WIN (★ Mark 4: Round End / K.O. / After Defeating Enemy / Non-Human & Locust Opponent)
        @{ Src = 'pokemon_knockout.mp3';                 Evt = 'win';     DestName = '01_Pokemon Stadium - Knockout There It Is (Round KO).mp3' },
        @{ Src = 'rush_hour_wipe_yourself_off.mp3';      Evt = 'win';     DestName = '02_Rush Hour - Wipe Yourself Off Man You Dead (KO Finish).mp3' },
        @{ Src = 'rush_hour_not_in_rush_hour_3.mp3';     Evt = 'win';     DestName = '03_Rush Hour - Damn He Aint Gonna Be in Rush Hour 3 (Brutal KO).mp3' },
        @{ Src = 'rush_hour_aint_nobody_understand.mp3'; Evt = 'win';     DestName = '04_Rush Hour - Dont Nobody Understand (Non-Human Opponent KO).mp3' },
        @{ Src = 'waterboy_captain_insano_no_mercy.mp3'; Evt = 'win';     DestName = '05_Captain Insano (Waterboy) - Shows No Mercy (Round End).mp3' },
        @{ Src = 'rolf_hat_of_discipline.mp3';           Evt = 'win';     DestName = '06_Rolf (Ed Edd n Eddy) - The Hat of Discipline (Finisher).mp3' },
        @{ Src = 'damn_good_kick_lee.wav';               Evt = 'win';     DestName = '07_Rush Hour - Damn Good Kick Lee (Kick KO).wav' },
        @{ Src = 'eustace_happy_laugh.mp3';              Evt = 'win';     DestName = '08_Eustace Bagge - Happy Cackle Laugh (Victory).mp3' },
        @{ Src = 'leon_bingo.mp3';                       Evt = 'win';     DestName = '09_Resident Evil 4 (Leon) - Wheres Everyone Going Bingo (Squad Wipe).mp3' },
        @{ Src = 'pd_elvis_eat_hot_death.mp3';           Evt = 'win';     DestName = '10_Perfect Dark (Elvis Maian) - Eat Hot Death Weirdos (Locust Finisher).mp3' },
        @{ Src = 'pd_body_bag_morgue.mp3';               Evt = 'win';     DestName = '11_Perfect Dark (Guard) - Grab a Body Bag One for the Morgue (Finisher).mp3' }
    )

    $syncedSfxCount = 0
    foreach ($sItem in $approvedSfxMap) {
        $srcFile = Join-Path $ytSoundbiteSource $sItem.Src
        $destFolder = Join-Path $sfxDir $sItem.Evt
        $destPath = Join-Path $destFolder $sItem.DestName
        if (Copy-AudioAssetIfChanged -SourcePath $srcFile -DestinationPath $destPath) {
            $syncedSfxCount++
        }
    }
    if ($syncedSfxCount -gt 0) {
        Write-Host "Synced $syncedSfxCount approved Tekken 8 / Marshall Law real character soundbytes into assets/licensed/sfx." -ForegroundColor Green
    }
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
        # Strip numeric sorting prefix (e.g., '01_') from display title while keeping clean sorting
        $title = ($f.BaseName -replace '^\d+_', '')
        $credit = $license.attribution
        if ($license.attributionTemplate) { $credit = $license.attributionTemplate.Replace('{title}', $title) }
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
    MusicCategories = $music.Count
    MusicTracks     = $trackCount
    TensionSFX      = $sfx['tension'].Count
    KillSFX         = $sfx['kill'].Count
    LossSFX         = $sfx['loss'].Count
    WinSFX          = $sfx['win'].Count
    Footsteps       = $footsteps.Count
    SkippedFiles    = $skipped.Count
}
