/**
 * ApexPulse Studio Engine (v4.0)
 * - 100% Real Licensed Audio (19 Kevin MacLeod CC-BY 4.0 Studio Tracks + 27 Kenney CC0 Voiceovers/Foley + 8 CC0 Hardwood Footsteps)
 * - Zero TTS / Zero Synthetic Math-Wave Buzzers
 * - Live Web Audio API AnalyserNode Spectrum Meter + Smooth -18dB Sidechain Ducking
 * - Direct User Audio & Video File Porting (Drag-and-Drop / File Picker + Persistent Local Upload)
 */

class StudioEngine {
  constructor() {
    this.manifest = null;

    // Sample gameplay reels (real MP4 files on disk)
    this.sampleVideos = [
      {
        id: 'apex_clutch',
        title: 'Apex Legends — 1v3 Final Ring Clutch',
        subtitle: 'High-tempo squad elimination & champion finish',
        file: 'assets/licensed/samples/apex_clutch.mp4',
        duration: 20.0,
        genre: 'Battle Royale FPS'
      },
      {
        id: 'valorant_ace',
        title: 'Valorant — Operator 5K Round Ace',
        subtitle: 'Precision sniper holds & final defuse',
        file: 'assets/licensed/samples/valorant_ace.mp4',
        duration: 20.0,
        genre: 'Tactical Shooter'
      },
      {
        id: 'elden_boss',
        title: 'Elden Ring — Malenia No-Hit Finale',
        subtitle: 'Tense dodge sequence & boss poise break',
        file: 'assets/licensed/samples/elden_boss.mp4',
        duration: 20.0,
        genre: 'Action RPG'
      }
    ];

    this.selectedVideo = { ...this.sampleVideos[0], isCustom: false };
    this.selectedMusic = null;

    // 4 Star Mark Inflection Points along the clip timeline
    this.markers = [
      {
        id: 'mark_tension',
        time: 3.2,
        event: 'tension',
        eventTitle: 'Dramatic Tension / Buildup',
        badgeColor: '#f59e0b',
        description: 'Enemy spotted / final round standoff begins',
        sfx: null
      },
      {
        id: 'mark_kill',
        time: 7.6,
        event: 'kill',
        eventTitle: 'Kill / Elimination Impact',
        badgeColor: '#ef4444',
        description: 'Decisive headshot or multi-kill impact',
        sfx: null
      },
      {
        id: 'mark_loss',
        time: 13.4,
        event: 'loss',
        eventTitle: 'Near-Loss / Opponent Whiff',
        badgeColor: '#a855f7',
        description: 'Close call or opponent defeat callout',
        sfx: null
      },
      {
        id: 'mark_win',
        time: 18.0,
        event: 'win',
        eventTitle: 'Win / Victory Celebration',
        badgeColor: '#10b981',
        description: 'Round won & match victory announcement',
        sfx: null
      }
    ];

    this.pricingPlans = [
      {
        id: 'single_clip',
        name: 'Pay-As-You-Go Pass',
        price: '$1.99',
        period: 'per highlight video',
        badge: 'SINGLE CLIP',
        popular: false,
        features: [
          'Export this highlight in 1080p 60fps MP4',
          'Full access to all 19 studio music tracks',
          'All 27 real human voiceover & foley soundbytes',
          'Automatic -18dB sidechain music ducking',
          'Full CC-BY / CC0 YouTube monetization clearance'
        ]
      },
      {
        id: 'creator_50',
        name: 'Creator 50 Plan',
        price: '$39',
        period: 'per month (50 videos)',
        badge: 'MOST POPULAR • $0.78 / CLIP',
        popular: true,
        features: [
          'Up to 50 rendered highlight videos per month',
          'Port unlimited custom MP3/WAV music & soundbytes',
          'Monthly curated studio music & SFX vault drops',
          'Automated YouTube Chapters & CC-BY credit block',
          'Priority FFmpeg 1080p/4K local & cloud muxing'
        ]
      },
      {
        id: 'unlimited_studio',
        name: 'Unlimited Studio Pass',
        price: '$100',
        period: 'per month (unlimited)',
        badge: 'UNLIMITED VIP STUDIO',
        popular: false,
        features: [
          'Unlimited highlight videos every single month',
          'Direct automated YouTube Data API v3 upload queue',
          'Custom team soundboard & shared folder syncing',
          '4K 60fps master export + 9:16 Shorts auto-crop',
          'Dedicated commercial multi-channel license'
        ]
      }
    ];
    this.selectedPlanId = 'creator_50';

    // Web Audio API Graph
    this.audioCtx = null;
    this.analyser = null;
    this.bgmGain = null;
    this.sfxGain = null;
    this.freqData = null;

    // HTML5 Audio Elements
    this.previewAudio = new Audio();
    this.previewAudio.crossOrigin = 'anonymous';
    this.bgmAudio = new Audio();
    this.bgmAudio.crossOrigin = 'anonymous';
    this.bgmAudio.loop = true;
    this.sfxAudio = new Audio();
    this.sfxAudio.crossOrigin = 'anonymous';

    this.footstepPool = [];
    this.footstepCursor = 0;

    this.isAuditioning = false;
    this.isDucking = false;
    this.firedMarkerIds = new Set();
    this.auditionRaf = null;

    // Advanced Audio & Video Mastering Additions (Ableton/CapCut Inspirations)
    this.aspectRatio = '16:9';
    this.eqPreset = 'gaming';
    this.eqFilter = null;
    this.soundboardPads = [
      { id: 1, key: '1', title: 'Tension', file: 'assets/licensed/sfx/tension/Kenney_Impact_Metal_001.ogg', color: '#f59e0b' },
      { id: 2, key: '2', title: 'Elim Impact', file: 'assets/licensed/sfx/kill/Kenney_Impact_Wood_Heavy_000.ogg', color: '#ef4444' },
      { id: 3, key: '3', title: 'Double Kill', file: 'assets/licensed/sfx/kill/Kenney_Voice_Double_Kill.ogg', color: '#f43f5e' },
      { id: 4, key: '4', title: 'Opponent Defeat', file: 'assets/licensed/sfx/loss/Kenney_Voice_You_Lose.ogg', color: '#a855f7' },
      { id: 5, key: '5', title: 'Victory Horn', file: 'assets/licensed/sfx/win/Kenney_Voice_Victory.ogg', color: '#10b981' },
      { id: 6, key: '6', title: 'Winner Shout', file: 'assets/licensed/sfx/win/Kenney_Voice_Winner.ogg', color: '#34d399' },
      { id: 7, key: '7', title: 'Heavy Punch', file: 'assets/licensed/sfx/kill/Kenney_Impact_Punch_000.ogg', color: '#ec4899' },
      { id: 8, key: '8', title: 'Dramatic Stinger', file: 'assets/licensed/sfx/tension/Kenney_Impact_Glass_Heavy_000.ogg', color: '#6366f1' }
    ];
  }

  async init() {
    if (window.AUDIO_MANIFEST) {
      this.manifest = window.AUDIO_MANIFEST;
    } else {
      const resp = await fetch('audio_manifest.json');
      this.manifest = await resp.json();
    }

    // Default Music Selection (first track in first category)
    if (this.manifest.music && this.manifest.music.length > 0 && this.manifest.music[0].tracks.length > 0) {
      this.selectedMusic = this.manifest.music[0].tracks[0];
    }

    // Default Soundbyte Selections for each of the 4 Star Marks
    this.markers.forEach((m) => {
      const list = (this.manifest.sfx && this.manifest.sfx[m.event]) || [];
      if (list.length > 0) {
        m.sfx = list[0];
      }
    });

    // Preload real CC0 hardwood footsteps
    if (this.manifest.footsteps && this.manifest.footsteps.length > 0) {
      this.footstepPool = this.manifest.footsteps.map((f) => {
        const a = new Audio(f.file);
        a.preload = 'auto';
        a.volume = 0.48;
        return a;
      });
    }
  }

  ensureAudioGraph() {
    if (!this.audioCtx) {
      const Ctx = window.AudioContext || window.webkitAudioContext;
      this.audioCtx = new Ctx();
      this.analyser = this.audioCtx.createAnalyser();
      this.analyser.fftSize = 64;
      this.analyser.smoothingTimeConstant = 0.78;
      this.freqData = new Uint8Array(this.analyser.frequencyBinCount);

      this.bgmGain = this.audioCtx.createGain();
      this.bgmGain.gain.value = 0.75;

      this.sfxGain = this.audioCtx.createGain();
      this.sfxGain.gain.value = 1.0;

      const previewSrc = this.audioCtx.createMediaElementSource(this.previewAudio);
      const bgmSrc = this.audioCtx.createMediaElementSource(this.bgmAudio);
      const sfxSrc = this.audioCtx.createMediaElementSource(this.sfxAudio);

      // Parametric Master EQ Node (Ableton Live Inspiration)
      this.eqFilter = this.audioCtx.createBiquadFilter();
      this.applyEQPreset(this.eqPreset || 'gaming');

      previewSrc.connect(this.eqFilter);
      bgmSrc.connect(this.bgmGain);
      this.bgmGain.connect(this.eqFilter);
      sfxSrc.connect(this.sfxGain);
      this.sfxGain.connect(this.eqFilter);

      this.eqFilter.connect(this.analyser);
      this.analyser.connect(this.audioCtx.destination);
    }
    if (this.audioCtx.state === 'suspended') {
      this.audioCtx.resume();
    }
  }

  applyEQPreset(preset) {
    this.eqPreset = preset;
    if (!this.eqFilter || !this.audioCtx) return;
    const now = this.audioCtx.currentTime;
    if (preset === 'gaming') {
      this.eqFilter.type = 'peaking';
      this.eqFilter.frequency.setValueAtTime(2500, now);
      this.eqFilter.Q.setValueAtTime(1.1, now);
      this.eqFilter.gain.setValueAtTime(5.0, now);
    } else if (preset === 'bass') {
      this.eqFilter.type = 'lowshelf';
      this.eqFilter.frequency.setValueAtTime(140, now);
      this.eqFilter.gain.setValueAtTime(6.5, now);
    } else if (preset === 'clarity') {
      this.eqFilter.type = 'highshelf';
      this.eqFilter.frequency.setValueAtTime(7500, now);
      this.eqFilter.gain.setValueAtTime(4.0, now);
    } else {
      // Flat / Reference
      this.eqFilter.type = 'peaking';
      this.eqFilter.frequency.setValueAtTime(1000, now);
      this.eqFilter.gain.setValueAtTime(0, now);
    }
  }

  setAspectRatio(ratio) {
    this.aspectRatio = ratio === '9:16' ? '9:16' : '16:9';
    return this.aspectRatio;
  }

  triggerSoundboardPad(index) {
    this.ensureAudioGraph();
    const pad = this.soundboardPads[index];
    if (!pad) return null;
    const sfx = new Audio(pad.file);
    sfx.crossOrigin = 'anonymous';
    sfx.volume = 0.95;
    sfx.play().catch(() => {});
    return pad;
  }

  getSpectrumLevels(barCount = 20) {
    if (!this.analyser || !this.freqData) {
      return new Array(barCount).fill(4);
    }
    this.analyser.getByteFrequencyData(this.freqData);
    const out = [];
    for (let i = 0; i < barCount; i++) {
      const val = this.freqData[i % this.freqData.length] || 0;
      out.push(Math.max(4, Math.round((val / 255) * 100)));
    }
    return out;
  }

  playFootstep(stepIndex = 0) {
    if (!this.footstepPool || this.footstepPool.length === 0) return;
    const idx = (stepIndex >= 0 ? stepIndex : this.footstepCursor++) % this.footstepPool.length;
    const base = this.footstepPool[idx];
    if (!base) return;
    try {
      const clone = base.cloneNode();
      clone.volume = 0.42 + (stepIndex % 2) * 0.08;
      clone.playbackRate = 0.96 + (stepIndex % 3) * 0.04;
      clone.play().catch(() => {});
    } catch (_) {}
  }

  // -------------------------------------------------------------------------
  // Audition Individual Music Track or Soundbyte
  // -------------------------------------------------------------------------
  auditionFile(fileUrl, onEndedCallback) {
    this.ensureAudioGraph();
    this.stopAuditionMix();
    this.previewAudio.pause();
    this.previewAudio.src = fileUrl;
    this.previewAudio.currentTime = 0;
    this.previewAudio.volume = 0.9;
    this.previewAudio.onended = () => {
      if (onEndedCallback) onEndedCallback();
    };
    this.previewAudio.play().catch((err) => console.warn('Audio play error:', err));
  }

  stopPreview() {
    this.previewAudio.pause();
    try {
      this.previewAudio.currentTime = 0;
    } catch (_) {}
  }

  isPreviewPlaying(fileUrl) {
    return !this.previewAudio.paused && this.previewAudio.src.endsWith(encodeURI(fileUrl).replace(/%20/g, ' ')) ||
      (!this.previewAudio.paused && decodeURIComponent(this.previewAudio.src).endsWith(fileUrl));
  }

  // -------------------------------------------------------------------------
  // Select Video, Music, Soundbytes, and Port Custom User Files
  // -------------------------------------------------------------------------
  selectSampleVideoById(id) {
    const found = this.sampleVideos.find((s) => s.id === id);
    if (found) {
      this.selectedVideo = { ...found, isCustom: false };
    }
    return this.selectedVideo;
  }

  setCustomVideoFile(file) {
    const url = URL.createObjectURL(file);
    this.selectedVideo = {
      id: 'custom_' + Date.now(),
      title: file.name.replace(/\.[^.]+$/, ''),
      subtitle: `Uploaded File • ${(file.size / (1024 * 1024)).toFixed(1)} MB`,
      file: url,
      rawFile: file,
      duration: 20.0,
      genre: 'Custom Upload',
      isCustom: true
    };
    return this.selectedVideo;
  }

  findMusicById(trackId) {
    if (!this.manifest || !this.manifest.music) return null;
    for (const cat of this.manifest.music) {
      const hit = cat.tracks.find((t) => t.id === trackId);
      if (hit) return hit;
    }
    return null;
  }

  selectMusicById(trackId) {
    const hit = this.findMusicById(trackId);
    if (hit) {
      this.selectedMusic = hit;
    }
    return this.selectedMusic;
  }

  portCustomMusicFiles(fileList) {
    if (!fileList || fileList.length === 0) return null;
    let customCat = this.manifest.music.find((c) => c.id === 'custom_ported');
    if (!customCat) {
      customCat = {
        id: 'custom_ported',
        label: 'Your Ported Music Files',
        mood: 'Custom studio tracks imported from your device',
        tracks: []
      };
      this.manifest.music.unshift(customCat);
    }

    let firstAdded = null;
    Array.from(fileList).forEach((file) => {
      const url = URL.createObjectURL(file);
      const cleanTitle = file.name.replace(/\.[^.]+$/, '');
      const entry = {
        id: 'm-custom-' + Date.now() + '-' + Math.random().toString(36).slice(2, 6),
        title: cleanTitle,
        file: url,
        rawFile: file,
        bytes: file.size,
        sizeMB: +(file.size / (1024 * 1024)).toFixed(2),
        artist: 'User Ported Track',
        source: 'Local Device Import',
        license: 'User Owned / Custom',
        credit: `${cleanTitle} (User Imported Track)`
      };
      customCat.tracks.unshift(entry);
      if (!firstAdded) firstAdded = entry;
    });

    if (firstAdded) {
      this.selectedMusic = firstAdded;
    }
    return firstAdded;
  }

  assignSoundbyteToMarker(markerId, sfxId) {
    const marker = this.markers.find((m) => m.id === markerId);
    if (!marker) return null;
    const pool = (this.manifest.sfx && this.manifest.sfx[marker.event]) || [];
    const hit = pool.find((s) => s.id === sfxId);
    if (hit) {
      marker.sfx = hit;
    }
    return marker;
  }

  portCustomSfxFiles(eventKey, fileList) {
    if (!fileList || fileList.length === 0) return null;
    if (!this.manifest.sfx[eventKey]) {
      this.manifest.sfx[eventKey] = [];
    }
    let firstAdded = null;
    Array.from(fileList).forEach((file) => {
      const url = URL.createObjectURL(file);
      const cleanTitle = file.name.replace(/\.[^.]+$/, '');
      const entry = {
        id: `s-${eventKey}-custom-${Date.now()}-${Math.random().toString(36).slice(2, 5)}`,
        title: `Custom - ${cleanTitle}`,
        file: url,
        rawFile: file,
        bytes: file.size,
        sizeKB: +(file.size / 1024).toFixed(1),
        artist: 'User Ported Soundbyte',
        source: 'Local Device Import',
        license: 'User Owned / Custom',
        credit: `${cleanTitle} (User Imported Soundbyte)`
      };
      this.manifest.sfx[eventKey].unshift(entry);
      if (!firstAdded) firstAdded = entry;
    });

    if (firstAdded) {
      const marker = this.markers.find((m) => m.event === eventKey);
      if (marker) marker.sfx = firstAdded;
    }
    return firstAdded;
  }

  // -------------------------------------------------------------------------
  // Synchronized Master Mix Playback (Video + BGM + -18dB Sidechain Ducking)
  // -------------------------------------------------------------------------
  startAuditionMix(videoEl, callbacks = {}) {
    this.ensureAudioGraph();
    this.stopPreview();
    this.stopAuditionMix();

    this.isAuditioning = true;
    this.firedMarkerIds.clear();

    if (videoEl) {
      videoEl.currentTime = 0;
      videoEl.muted = true;
      videoEl.play().catch(() => {});
    }

    if (this.selectedMusic) {
      this.bgmAudio.src = this.selectedMusic.file;
      this.bgmAudio.currentTime = 0;
      if (this.bgmGain && this.audioCtx) {
        this.bgmGain.gain.cancelScheduledValues(this.audioCtx.currentTime);
        this.bgmGain.gain.setValueAtTime(0.75, this.audioCtx.currentTime);
      }
      this.bgmAudio.play().catch((err) => console.warn('BGM play error:', err));
    }

    const startWall = performance.now();
    const tick = () => {
      if (!this.isAuditioning) return;

      const t = videoEl && !videoEl.paused && videoEl.duration
        ? videoEl.currentTime
        : (performance.now() - startWall) / 1000;

      const dur = (videoEl && videoEl.duration && isFinite(videoEl.duration))
        ? videoEl.duration
        : (this.selectedVideo.duration || 20.0);

      // Check each star mark cue
      this.markers.forEach((m) => {
        if (!m.sfx) return;
        const delta = t - m.time;
        if (delta >= 0 && delta < 0.22 && !this.firedMarkerIds.has(m.id)) {
          this.firedMarkerIds.add(m.id);
          this.fireDuckedSoundbyte(m, callbacks.onCueFired);
        }
      });

      if (callbacks.onTick) {
        callbacks.onTick(t, dur, this.isDucking);
      }

      if (t >= dur - 0.08) {
        this.stopAuditionMix(videoEl);
        if (callbacks.onComplete) callbacks.onComplete();
        return;
      }

      this.auditionRaf = requestAnimationFrame(tick);
    };

    this.auditionRaf = requestAnimationFrame(tick);
  }

  fireDuckedSoundbyte(marker, onCueFired) {
    if (!marker || !marker.sfx) return;
    this.ensureAudioGraph();

    const now = this.audioCtx.currentTime;
    this.isDucking = true;

    // Smooth -18dB sidechain duck on BGM (0.75 -> 0.095 in 45ms)
    if (this.bgmGain) {
      this.bgmGain.gain.cancelScheduledValues(now);
      this.bgmGain.gain.setValueAtTime(this.bgmGain.gain.value, now);
      this.bgmGain.gain.linearRampToValueAtTime(0.095, now + 0.045);
    }

    this.sfxAudio.pause();
    this.sfxAudio.src = marker.sfx.file;
    this.sfxAudio.currentTime = 0;

    const restoreBgm = () => {
      if (!this.audioCtx || !this.bgmGain) return;
      const tEnd = this.audioCtx.currentTime;
      this.bgmGain.gain.cancelScheduledValues(tEnd);
      this.bgmGain.gain.setValueAtTime(this.bgmGain.gain.value, tEnd);
      this.bgmGain.gain.linearRampToValueAtTime(0.75, tEnd + 0.38);
      setTimeout(() => {
        this.isDucking = false;
      }, 380);
    };

    this.sfxAudio.onended = restoreBgm;
    this.sfxAudio.play().catch(() => {
      restoreBgm();
    });

    if (onCueFired) {
      onCueFired(marker);
    }
  }

  stopAuditionMix(videoEl) {
    this.isAuditioning = false;
    this.isDucking = false;
    if (this.auditionRaf) {
      cancelAnimationFrame(this.auditionRaf);
      this.auditionRaf = null;
    }
    this.bgmAudio.pause();
    this.sfxAudio.pause();
    if (videoEl) {
      try {
        videoEl.pause();
      } catch (_) {}
    }
  }

  buildYouTubeAttributionBlock() {
    const lines = [
      `Highlight mixed with ApexPulse 3D Gallery Studio (-18dB sidechain audio ducking)`,
      ``,
      `TIMESTAMPS & SOUNDBYTE CUES:`,
      `0:00 - Highlight Opening`
    ];
    this.markers.forEach((m) => {
      const mm = Math.floor(m.time / 60);
      const ss = String(Math.floor(m.time % 60)).padStart(2, '0');
      lines.push(`${mm}:${ss} - ★ ${m.eventTitle}: ${m.sfx ? m.sfx.title : 'None'}`);
    });
    lines.push(``);
    lines.push(`MUSIC & AUDIO LICENSE CREDITS:`);
    if (this.selectedMusic) {
      lines.push(`• Background Music: ${this.selectedMusic.credit}`);
      if (this.selectedMusic.licenseUrl) {
        lines.push(`  License: ${this.selectedMusic.license} (${this.selectedMusic.licenseUrl})`);
      }
    }
    lines.push(`• Soundbytes & Foley: Kenney.nl Audio Packs — CC0 1.0 Public Domain`);
    return lines.join('\n');
  }
}

window.StudioEngine = StudioEngine;
