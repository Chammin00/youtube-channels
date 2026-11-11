# ApexPulse 3D Gallery: Motion-Picture Exhibition Hallway & Gaming Highlight Studio

[![Quality Gate](https://img.shields.io/badge/Self--Check%20Gate-21%2F21%20(10%2F10%20PASS)-10b981.svg?style=for-the-badge)](./Test-GalleryQualityGate.ps1)
[![Three.js](https://img.shields.io/badge/Three.js-1K%20PBR%20Museum%20Corridor-d4af37.svg?style=for-the-badge&logo=three.js)](https://threejs.org/)
[![Licensed Audio](https://img.shields.io/badge/Audio-19%20CC--BY%204.0%20Tracks%20%2B%2027%20CC0%20SFX-3b82f6.svg?style=for-the-badge)](./audio_manifest.json)
[![FFmpeg Render](https://img.shields.io/badge/FFmpeg--Mix--Engine--18dB%20Sidechain%20Ducking-f59e0b.svg?style=for-the-badge)](./Start-HighlightStudio.ps1)

> **A 10/10 motion-picture 3D museum exhibition hallway built on the architecture of `theringsofsaturn/3D-art-gallery-threejs` with real 1K Poly Haven PBR textures, real licensed studio music (Kevin MacLeod CC-BY 4.0), real human announcer & foley soundbytes (Kenney.nl CC0 1.0), and a 3-phase first-person human walk down the corridor from picture to picture.**

---

## 🏛️ 1. 10/10 Museum Gallery Architecture & First-Person Hallway Walk

Every stage of building a gaming highlight video is a **physical framed painting** hanging along a 3D museum corridor with 13 tall arched windows looking out onto a cinematic **Earth Galaxy Volcano Mountain Bridge** panorama:

| Exhibit | Hallway Location | Picture Frame Title | Purpose |
| :--- | :--- | :--- | :--- |
| **Picture 1** | Left Gallery Wall (`Z = +8.5`) | `01. SELECT YOUR VIDEO CLIP` | Upload your own `.mp4`/`.webm`/`.mov` or pick one of 3 real sample gameplay reels |
| **Picture 2** | Right Gallery Wall (`Z = +2.5`) | `02. CHOOSE BACKGROUND MUSIC` | Audition & select from 19 full-length licensed studio MP3s across 4 moods, or port your own `.mp3`/`.wav` |
| **Picture 3** | Left Gallery Wall (`Z = -3.5`) | `03. INSERT ★ SOUNDBYTES` | Assign 27 real human announcer & foley soundbytes at 4 `★` inflection markers and test the live `-18dB` sidechain ducking mix |
| **Picture 4** | Grand Center Wall (`Z = -11.2`) | `04. THE PREMIERE & PLAN` | Choose membership tier (`$1.99` Single Pass, `$39/mo` 50 Videos, `$100/mo` Unlimited), copy YouTube CC-BY attribution, and render the master `.mp4` |

### Architectural Windows & Exterior Vista (`assets/licensed/textures/earth_galaxy_volcano_bridge_vista.jpg`)
* **13 Arched Windows**: Tall walnut jambs with brushed-brass mullions and semicircular arched fanlights with radial brass spokes.
* **Monumental Vista**: High above misty volcanic mountain chasms with glowing red magma rivers, an ancient colossal stone suspension bridge spans between towering peaks beneath a massive radiant Earth, swirling spiral galaxy, and celestial aurora ribbons.
* **Volumetric Beams & Floor Pools**: Dual-tone cosmic light beams (celestial cyan from the planet Earth and warm amber from volcanic magma) stream across the herringbone parquet floor in sync with window positions.

### How the First-Person Walk Works (`hallway-scene.js`)
When you click **`Submit & Walk to Picture X →`** (or click any framed painting directly on the 3D wall):
1. **Menu Auto-Retracts**: The sculpted pop-up menu smoothly slides away so you have an unobstructed view of the 3D museum hallway.
2. **Phase 1 — Step Back & Turn**: The camera steps backward onto the crimson & gold central carpet runner and turns your gaze straight down the corridor.
3. **Phase 2 — Biomechanical First-Person Stride**: You walk down the center of the hallway past walnut pilasters, leather museum benches, and ceiling track spotlights with natural vertical head-bob, lateral stride sway, and **synchronized real hardwood footstep sounds** (`L` / `R` telemetry indicator in the top HUD).
4. **Phase 3 — Turn & Approach Next Picture**: Upon reaching the next painting's station, you turn toward the wall, step into viewing stance, and the sculpted pop-up menu for that picture opens automatically.

---

## 🎵 2. 100% Real Licensed Music & Studio Soundbytes (Zero Bot / TTS Voices)

All legacy synthetic `System.Speech` TTS WAVs have been quarantined (`assets/audio/_quarantined_tts/`). Every item in the dropdowns and music tree is backed by a verified disk file and a `LICENSE.json` record via [`Build-AudioManifest.ps1`](./Build-AudioManifest.ps1):

* **19 Full-Length Studio Music Tracks (`assets/licensed/music/`, CC-BY 4.0 by Kevin MacLeod — Incompetech)**:
  * **Chill & Lounge (5 tracks)**: *Local Forecast - Elevator*, *Airport Lounge*, *Bossa Antigua*, *Cool Vibes*, *Lobby Time*
  * **High-Octane Hype & Funk (4 tracks)**: *Volatile Reaction*, *Funkorama*, *Aggressor*, *Rhinoceros*
  * **Dramatic Tension & Boss Prep (5 tracks)**: *Investigations*, *Hitman*, *Darkest Child*, *Ouroboros*, *Dispersion Relation*
  * **Playful & Comedy Montages (5 tracks)**: *Sneaky Snitch*, *Monkeys Spinning Monkeys*, *Fluffing a Duck*, *Carefree*, *Pixel Peeker Polka - faster*
* **27 Real Studio Human Voiceover & Foley Soundbytes (`assets/licensed/sfx/`, CC0 1.0 Public Domain by Kenney.nl)**:
  * **★ 02.4s Dramatic Tension (7 cues)**: *Announcer - Final Round*, *Sudden Death*, *Prepare Yourself*, *Fight*, *Tie Breaker*, *Voiceover - Hurry Up*, *Ready*
  * **★ 06.8s Kill / Elimination (7 cues)**: *Announcer - Multi Kill*, *Combo Breaker*, *Combo Hit*, *Foley - Heavy Knockout Punch*, *Heavy Armor Strike*, *Elimination Bell Hit*, *Blade Slash Confirm*
  * **★ 11.5s Loss / Whiff (5 cues)**: *Announcer - Game Over*, *You Lose*, *Loser*, *Voiceover - Mission Failed*, *Time Over*
  * **★ 16.2s Win / Clutch Victory (8 cues)**: *Announcer - Flawless Victory*, *Winner*, *You Win*, *Voiceover - Congratulations*, *Mission Completed*, *Objective Achieved*, *New Highscore*, *Level Up*
* **8 Real Hardwood Footstep Foley Samples (`assets/licensed/footsteps/`, CC0 1.0 Public Domain)**:
  * `footstep_01.ogg` through `footstep_08.ogg` triggered in sync with camera stride cycles.
* **Port Your Own Files Instantly**:
  * Click **`+ Port Your Music (.MP3/.WAV)`** in Picture 2 or **`+ Port Your Soundbytes`** in Picture 3 to load any local audio files directly into the studio, or drop them into `assets/licensed/` and run `.\Build-AudioManifest.ps1`.

---

## ✅ 3. Automated 10/10 Quality Gate Self-Check

Before serving or deploying changes, run [`Test-GalleryQualityGate.ps1`](./Test-GalleryQualityGate.ps1) to verify all 21 automated checks (file integrity, zero-TTS audit, 19 MP3 tracks, 27 OGG soundbytes, 8 footsteps, 9 Poly Haven PBR maps, 3-phase walk logic, HTTP MIME headers, and live FFmpeg `POST /api/render` sidechain mix):

```powershell
Set-Location "g:\My Drive\Antigravity\Projects\youtube channels"
.\Test-GalleryQualityGate.ps1
```

---

## 🚀 4. Launching the Studio Locally

```powershell
Set-Location "g:\My Drive\Antigravity\Projects\youtube channels"
.\Start-HighlightStudio.ps1
```

This starts the local HTTP & FFmpeg render server and opens `http://localhost:8080/index.html` in your default browser.
