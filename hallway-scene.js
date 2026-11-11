/**
 * ApexPulse 3D: Museum Gallery Hallway & First-Person Walking Engine
 * Built on the architecture of theringsofsaturn/3D-art-gallery-threejs:
 * - Real 1K PBR Poly Haven textures (herringbone_parquet, painted_plaster_wall, beige_wall_001)
 *   with Diffuse + OpenGL Normal + Roughness maps.
 * - Multi-layer museum walnut & brushed-gold picture frames with overhead picture lights
 *   and brass museum placards.
 * - Architectural ceiling coffers, track lighting rails, wainscoting, and gallery benches
 *   for rich parallax depth as you walk down the corridor.
 * - 3-Phase Choreographed First-Person Walk between paintings with biomechanical head-bob,
 *   lateral stride sway, and synchronized real CC0 hardwood footstep triggers.
 */

class GalleryHallway {
  constructor(canvasContainerId, callbacks = {}) {
    this.container = document.getElementById(canvasContainerId);
    this.onWalkStart = callbacks.onWalkStart || (() => {});
    this.onWalkProgress = callbacks.onWalkProgress || (() => {});
    this.onFootstep = callbacks.onFootstep || (() => {});
    this.onArrive = callbacks.onArrive || (() => {});
    if (!this.container) return;

    this.scene = null;
    this.camera = null;
    this.renderer = null;
    this.clock = new THREE.Clock();
    this.textureLoader = new THREE.TextureLoader();

    // 4 Framed Exhibits down the hallway (angled slightly along the corridor so arched windows & sunbeams are visible beside every painting)
    this.pictures = [
      {
        id: 1,
        roman: 'I',
        stepLabel: 'STEP 01 OF 04',
        title: 'SELECT YOUR VIDEO CLIP',
        subtitle: 'Upload Gameplay or Pick a Sample Reel',
        wall: 'left',
        position: { x: -3.38, y: 1.85, z: 7.5 },
        standPos: { x: -0.45, y: 1.72, z: 8.45 },
        lookPos: { x: -2.85, y: 1.82, z: 6.35 },
        accentHex: 0x60a5fa,
        accentCss: '#60a5fa',
        palette: ['#0c192c', '#172a46', '#1e3a5f'],
        completed: false,
        summaryText: 'Awaiting Selection'
      },
      {
        id: 2,
        roman: 'II',
        stepLabel: 'STEP 02 OF 04',
        title: 'CHOOSE BACKGROUND MUSIC',
        subtitle: '19 Real Licensed Studio Tracks (CC BY 4.0)',
        wall: 'right',
        position: { x: 3.38, y: 1.85, z: 0.5 },
        standPos: { x: 0.45, y: 1.72, z: 1.45 },
        lookPos: { x: 2.85, y: 1.82, z: -0.65 },
        accentHex: 0xf59e0b,
        accentCss: '#f59e0b',
        palette: ['#23180c', '#3b2610', '#543414'],
        completed: false,
        summaryText: 'Local Forecast - Elevator'
      },
      {
        id: 3,
        roman: 'III',
        stepLabel: 'STEP 03 OF 04',
        title: 'INSERT SOUNDBYTES AT ★ MARKS',
        subtitle: '27 Real Human Voiceovers & Foley Impacts (CC0)',
        wall: 'left',
        position: { x: -3.38, y: 1.85, z: -6.5 },
        standPos: { x: -0.45, y: 1.72, z: -5.55 },
        lookPos: { x: -2.85, y: 1.82, z: -7.65 },
        accentHex: 0xf43f5e,
        accentCss: '#f43f5e',
        palette: ['#280d15', '#3f1422', '#591c2f'],
        completed: false,
        summaryText: '4 Star Marks Configured'
      },
      {
        id: 4,
        roman: 'IV',
        stepLabel: 'STEP 04 OF 04',
        title: 'THE PREMIERE & EXPORT',
        subtitle: 'Preview Master Mix, Choose Plan & Download MP4',
        wall: 'end',
        position: { x: 0.0, y: 1.95, z: -15.2 },
        standPos: { x: 0.0, y: 1.72, z: -10.8 },
        lookPos: { x: 0.0, y: 1.92, z: -15.2 },
        accentHex: 0x10b981,
        accentCss: '#10b981',
        palette: ['#092218', '#113828', '#164e37'],
        completed: false,
        summaryText: 'Ready for Premiere'
      }
    ];

    this.activePictureId = 1;
    this.interactiveMeshes = [];
    this.paintingCanvases = new Map();
    this.kineticSculptures = [];
    this.sunbeamMeshes = [];

    // Camera state
    this.camPos = new THREE.Vector3();
    this.camLook = new THREE.Vector3();
    this.camRoll = 0;

    // Choreographed Walk State Machine
    this.walkState = null;
    this.mouseX = 0;
    this.mouseY = 0;

    this.init();
  }

  init() {
    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color(0x0c0b0e);
    this.scene.fog = new THREE.FogExp2(0x0c0b0e, 0.022);

    const aspect = this.container.clientWidth / this.container.clientHeight;
    this.camera = new THREE.PerspectiveCamera(50, aspect, 0.1, 80);

    const p1 = this.pictures[0];
    this.camPos.set(p1.standPos.x, p1.standPos.y, p1.standPos.z);
    this.camLook.set(p1.lookPos.x, p1.lookPos.y, p1.lookPos.z);
    this.camera.position.copy(this.camPos);
    this.camera.lookAt(this.camLook);

    this.renderer = new THREE.WebGLRenderer({
      antialias: true,
      alpha: false,
      powerPreference: 'high-performance'
    });
    this.renderer.setSize(this.container.clientWidth, this.container.clientHeight);
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    this.renderer.outputEncoding = THREE.sRGBEncoding;
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = 1.18;
    this.renderer.shadowMap.enabled = true;
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    this.container.appendChild(this.renderer.domElement);

    this.buildGalleryArchitecture();
    this.setupMuseumLighting();
    this.buildFramedPaintings();
    this.buildGalleryWindows();
    this.buildHallwayDecorations();
    this.buildCorridorFurniture();
    this.buildDustParticles();

    window.addEventListener('resize', () => this.onResize());
    window.addEventListener('mousemove', (e) => this.onMouseMove(e));
    this.container.addEventListener('click', (e) => this.onCanvasClick(e));

    this.animate();
  }

  loadTiledPBR(basePath, repeatX, repeatY, isColor = false) {
    const tex = this.textureLoader.load(basePath);
    tex.wrapS = THREE.RepeatWrapping;
    tex.wrapT = THREE.RepeatWrapping;
    tex.repeat.set(repeatX, repeatY);
    if (isColor) tex.encoding = THREE.sRGBEncoding;
    return tex;
  }

  buildGalleryArchitecture() {
    const hallWidth = 7.0;
    const hallLength = 34.0;
    const hallHeight = 4.3;
    const centerZ = -2.5;

    // 1. Floor: Real CC0 Poly Haven Herringbone Parquet 1K PBR
    const floorDiff = this.loadTiledPBR('assets/licensed/textures/herringbone_parquet_diff_1k.jpg', 4, 18, true);
    const floorNor = this.loadTiledPBR('assets/licensed/textures/herringbone_parquet_nor_1k.jpg', 4, 18, false);
    const floorRough = this.loadTiledPBR('assets/licensed/textures/herringbone_parquet_rough_1k.jpg', 4, 18, false);

    const floorMat = new THREE.MeshStandardMaterial({
      map: floorDiff,
      normalMap: floorNor,
      roughnessMap: floorRough,
      roughness: 0.55,
      metalness: 0.08
    });
    const floorMesh = new THREE.Mesh(new THREE.PlaneGeometry(hallWidth, hallLength), floorMat);
    floorMesh.rotation.x = -Math.PI / 2;
    floorMesh.position.set(0, 0, centerZ);
    floorMesh.receiveShadow = true;
    this.scene.add(floorMesh);

    // Center Carpet Runner down the walking aisle for visual path guidance
    const runnerMat = new THREE.MeshStandardMaterial({
      color: 0x1a1517,
      roughness: 0.9,
      metalness: 0.02
    });
    const runner = new THREE.Mesh(new THREE.PlaneGeometry(1.45, hallLength - 4), runnerMat);
    runner.rotation.x = -Math.PI / 2;
    runner.position.set(0, 0.004, centerZ);
    runner.receiveShadow = true;
    this.scene.add(runner);

    // Brushed Brass Runner Trim Edges
    const brassTrimMat = new THREE.MeshStandardMaterial({
      color: 0xc9a24d,
      metalness: 0.78,
      roughness: 0.28
    });
    [-0.74, 0.74].forEach((rx) => {
      const trim = new THREE.Mesh(new THREE.PlaneGeometry(0.03, hallLength - 4), brassTrimMat);
      trim.rotation.x = -Math.PI / 2;
      trim.position.set(rx, 0.005, centerZ);
      this.scene.add(trim);
    });

    // 2. Walls: Real CC0 Poly Haven Painted Plaster Wall 1K PBR
    const wallDiff = this.loadTiledPBR('assets/licensed/textures/painted_plaster_wall_diff_1k.jpg', 8, 2, true);
    const wallNor = this.loadTiledPBR('assets/licensed/textures/painted_plaster_wall_nor_1k.jpg', 8, 2, false);
    const wallRough = this.loadTiledPBR('assets/licensed/textures/painted_plaster_wall_rough_1k.jpg', 8, 2, false);

    const wallMat = new THREE.MeshStandardMaterial({
      color: 0x2a282d,
      map: wallDiff,
      normalMap: wallNor,
      roughnessMap: wallRough,
      roughness: 0.82,
      metalness: 0.04
    });

    const leftWall = new THREE.Mesh(new THREE.PlaneGeometry(hallLength, hallHeight), wallMat);
    leftWall.rotation.y = Math.PI / 2;
    leftWall.position.set(-hallWidth / 2, hallHeight / 2, centerZ);
    leftWall.receiveShadow = true;
    this.scene.add(leftWall);

    const rightWall = new THREE.Mesh(new THREE.PlaneGeometry(hallLength, hallHeight), wallMat);
    rightWall.rotation.y = -Math.PI / 2;
    rightWall.position.set(hallWidth / 2, hallHeight / 2, centerZ);
    rightWall.receiveShadow = true;
    this.scene.add(rightWall);

    const endWall = new THREE.Mesh(new THREE.PlaneGeometry(hallWidth, hallHeight), wallMat);
    endWall.position.set(0, hallHeight / 2, -15.5);
    endWall.receiveShadow = true;
    this.scene.add(endWall);

    const backWall = new THREE.Mesh(new THREE.PlaneGeometry(hallWidth, hallHeight), wallMat);
    backWall.rotation.y = Math.PI;
    backWall.position.set(0, hallHeight / 2, 13.5);
    this.scene.add(backWall);

    // 3. Ceiling: Textured Plaster with Architectural Coffered Beams
    const ceilDiff = this.loadTiledPBR('assets/licensed/textures/beige_wall_001_diff_1k.jpg', 6, 14, true);
    const ceilRough = this.loadTiledPBR('assets/licensed/textures/beige_wall_001_rough_1k.jpg', 6, 14, false);
    const ceilMat = new THREE.MeshStandardMaterial({
      color: 0x18171b,
      map: ceilDiff,
      roughnessMap: ceilRough,
      roughness: 0.88
    });
    const ceiling = new THREE.Mesh(new THREE.PlaneGeometry(hallWidth, hallLength), ceilMat);
    ceiling.rotation.x = Math.PI / 2;
    ceiling.position.set(0, hallHeight, centerZ);
    this.scene.add(ceiling);

    // Architectural Wall Pilasters & Ceiling Cross-Beams every 3.5m (aligned at bay boundaries: 9.25, 5.75, 2.25, -1.25, -4.75, -8.25, -11.75, -15.25)
    const walnutMat = new THREE.MeshStandardMaterial({
      color: 0x1b1410,
      roughness: 0.38,
      metalness: 0.1
    });

    for (let z = 9.25; z >= -15.3; z -= 3.5) {
      // Left & Right Wall Pilasters with Brass Capital & Base Trim
      [-hallWidth / 2 + 0.06, hallWidth / 2 - 0.06].forEach((px) => {
        const pilaster = new THREE.Mesh(new THREE.BoxGeometry(0.14, hallHeight, 0.24), walnutMat);
        pilaster.position.set(px, hallHeight / 2, z);
        pilaster.castShadow = true;
        pilaster.receiveShadow = true;
        this.scene.add(pilaster);

        // Brushed Brass Capital Crown & Plinth Ring
        const capital = new THREE.Mesh(new THREE.BoxGeometry(0.16, 0.08, 0.28), brassTrimMat);
        capital.position.set(px, hallHeight - 0.26, z);
        this.scene.add(capital);
      });

      // Ceiling Coffer Beam with Gold Center Inlay
      const beam = new THREE.Mesh(new THREE.BoxGeometry(hallWidth, 0.18, 0.26), walnutMat);
      beam.position.set(0, hallHeight - 0.09, z);
      this.scene.add(beam);

      const beamInlay = new THREE.Mesh(new THREE.BoxGeometry(hallWidth - 0.4, 0.02, 0.06), brassTrimMat);
      beamInlay.position.set(0, hallHeight - 0.185, z);
      this.scene.add(beamInlay);
    }

    // Dark Walnut Wainscoting Baseboard & Chair Rail along both walls
    [-hallWidth / 2 + 0.03, hallWidth / 2 - 0.03].forEach((wx) => {
      const base = new THREE.Mesh(new THREE.BoxGeometry(0.06, 0.26, hallLength), walnutMat);
      base.position.set(wx, 0.13, centerZ);
      this.scene.add(base);

      const rail = new THREE.Mesh(new THREE.BoxGeometry(0.05, 0.05, hallLength), brassTrimMat);
      rail.position.set(wx, 0.72, centerZ);
      this.scene.add(rail);
    });

    // Ceiling Track-Lighting Rails
    const railMat = new THREE.MeshStandardMaterial({ color: 0x0e0e11, metalness: 0.85, roughness: 0.22 });
    [-2.05, 2.05].forEach((tx) => {
      const track = new THREE.Mesh(new THREE.BoxGeometry(0.07, 0.05, hallLength - 4), railMat);
      track.position.set(tx, hallHeight - 0.18, centerZ);
      this.scene.add(track);
    });
  }

  buildGalleryWindows() {
    // Monumental Earth Galaxy Volcano Mountain Bridge Panorama outside the museum windows
    const vistaTex = this.textureLoader.load('assets/licensed/textures/earth_galaxy_volcano_bridge_vista.jpg');
    vistaTex.encoding = THREE.sRGBEncoding;
    vistaTex.wrapS = THREE.RepeatWrapping;
    vistaTex.wrapT = THREE.ClampToEdgeWrapping;

    const walnutCasingMat = new THREE.MeshStandardMaterial({
      color: 0x1a120d,
      roughness: 0.3,
      metalness: 0.15
    });
    const brassMullionMat = new THREE.MeshStandardMaterial({
      color: 0xd4af37,
      roughness: 0.25,
      metalness: 0.85
    });
    const marbleSillMat = new THREE.MeshStandardMaterial({
      color: 0xe5dfd5,
      roughness: 0.22,
      metalness: 0.06
    });
    const glassMat = new THREE.MeshPhysicalMaterial({
      color: 0xdbeafe,
      transparent: true,
      opacity: 0.16,
      roughness: 0.06,
      metalness: 0.12,
      reflectivity: 0.95
    });

    // Volumetric celestial Earth-light & aurora beam material
    const celestialBeamMat = new THREE.MeshBasicMaterial({
      color: 0x7dd3fc,
      transparent: true,
      opacity: 0.085,
      side: THREE.DoubleSide,
      depthWrite: false,
      blending: THREE.AdditiveBlending
    });

    // Volumetric volcanic magma ember beam material
    const volcanicBeamMat = new THREE.MeshBasicMaterial({
      color: 0xf97316,
      transparent: true,
      opacity: 0.075,
      side: THREE.DoubleSide,
      depthWrite: false,
      blending: THREE.AdditiveBlending
    });

    // Luminous floor patch materials (celestial Earth glow & volcanic hearth glow)
    const celestialFloorGlowMat = new THREE.MeshBasicMaterial({
      color: 0x38bdf8,
      transparent: true,
      opacity: 0.12,
      depthWrite: false,
      blending: THREE.AdditiveBlending
    });
    const volcanicFloorGlowMat = new THREE.MeshBasicMaterial({
      color: 0xf97316,
      transparent: true,
      opacity: 0.11,
      depthWrite: false,
      blending: THREE.AdditiveBlending
    });

    // 13 Arched Museum Windows with panoramic offsets revealing Galaxy -> Volcanic Bridge -> Earth
    const windowBays = [
      { wall: 'left',  z: 10.6, vistaOffset: 0.02, theme: 'galaxy' },
      { wall: 'right', z: 10.6, vistaOffset: 0.18, theme: 'galaxy' },
      { wall: 'right', z: 7.5,  vistaOffset: 0.28, theme: 'bridge' }, // Opposite Picture 1 (Spanning Bridge)
      { wall: 'left',  z: 4.0,  vistaOffset: 0.38, theme: 'volcano' }, // Next to Picture 1 (Lava Veins & Gorge)
      { wall: 'right', z: 4.0,  vistaOffset: 0.48, theme: 'bridge' },
      { wall: 'left',  z: 0.5,  vistaOffset: 0.58, theme: 'earth' }, // Opposite Picture 2 (Earth Horizon)
      { wall: 'left',  z: -3.0, vistaOffset: 0.68, theme: 'earth' }, // Next to Picture 2 & 3
      { wall: 'right', z: -3.0, vistaOffset: 0.32, theme: 'bridge' },
      { wall: 'right', z: -6.5, vistaOffset: 0.72, theme: 'earth' }, // Opposite Picture 3 (Radiant Planet Earth)
      { wall: 'left',  z: -10.0, vistaOffset: 0.82, theme: 'aurora' }, // Flanking Premiere Walk
      { wall: 'right', z: -10.0, vistaOffset: 0.42, theme: 'bridge' },
      { wall: 'left',  z: -13.2, vistaOffset: 0.62, theme: 'earth' }, // Twin Sanctuary Windows flanking Picture 4
      { wall: 'right', z: -13.2, vistaOffset: 0.22, theme: 'galaxy' }
    ];

    const winW = 2.15;
    const rectH = 1.95;
    const archR = winW / 2;

    windowBays.forEach((wb, idx) => {
      const isLeft = wb.wall === 'left';
      const isVolcanic = wb.theme === 'volcano' || wb.theme === 'bridge';
      const beamMat = isVolcanic ? volcanicBeamMat : celestialBeamMat;
      const floorMat = isVolcanic ? volcanicFloorGlowMat : celestialFloorGlowMat;
      const lightColor = isVolcanic ? 0xfba04b : 0x7dd3fc;
      const group = new THREE.Group();

      // Panoramic UV mapping framing the cosmic sky, Earth, mountains, bridge, and lava
      const winTex = vistaTex.clone();
      winTex.needsUpdate = true;
      winTex.repeat.set(0.34, 0.96);
      winTex.offset.set(wb.vistaOffset % 1.0, 0.02);

      const vistaMat = new THREE.MeshBasicMaterial({
        map: winTex
      });

      // 1. Rectangular Window Vista Pane
      const vistaRect = new THREE.Mesh(new THREE.PlaneGeometry(winW - 0.16, rectH), vistaMat);
      vistaRect.position.set(0, 0, 0.02);
      group.add(vistaRect);

      // 2. Semicircular Arched Fanlight Top Vista
      const archGeo = new THREE.CircleGeometry(archR - 0.08, 32, 0, Math.PI);
      const vistaArch = new THREE.Mesh(archGeo, vistaMat);
      vistaArch.position.set(0, rectH / 2, 0.02);
      group.add(vistaArch);

      // 3. Specular Glass Layer
      const glassRect = new THREE.Mesh(new THREE.PlaneGeometry(winW - 0.14, rectH), glassMat);
      glassRect.position.set(0, 0, 0.055);
      group.add(glassRect);

      // 4. Outer Walnut Jambs & Arched Crown Molding
      [-winW / 2, winW / 2].forEach((jx) => {
        const jamb = new THREE.Mesh(new THREE.BoxGeometry(0.14, rectH + 0.1, 0.16), walnutCasingMat);
        jamb.position.set(jx, 0, 0.06);
        jamb.castShadow = true;
        group.add(jamb);

        const brassInlay = new THREE.Mesh(new THREE.BoxGeometry(0.035, rectH, 0.175), brassMullionMat);
        brassInlay.position.set(jx + (jx < 0 ? 0.05 : -0.05), 0, 0.06);
        group.add(brassInlay);
      });

      // Arched Walnut & Gold Torus Molding at top of window
      const archFrame = new THREE.Mesh(
        new THREE.TorusGeometry(archR, 0.075, 12, 36, Math.PI),
        walnutCasingMat
      );
      archFrame.position.set(0, rectH / 2, 0.06);
      group.add(archFrame);

      const archGoldRim = new THREE.Mesh(
        new THREE.TorusGeometry(archR - 0.055, 0.022, 10, 36, Math.PI),
        brassMullionMat
      );
      archGoldRim.position.set(0, rectH / 2, 0.08);
      group.add(archGoldRim);

      // 5. Projecting Marble Windowsill & Walnut Apron
      const sill = new THREE.Mesh(new THREE.BoxGeometry(winW + 0.32, 0.09, 0.28), marbleSillMat);
      sill.position.set(0, -rectH / 2 - 0.04, 0.11);
      sill.castShadow = true;
      sill.receiveShadow = true;
      group.add(sill);

      const apron = new THREE.Mesh(new THREE.BoxGeometry(winW + 0.16, 0.11, 0.14), walnutCasingMat);
      apron.position.set(0, -rectH / 2 - 0.13, 0.05);
      group.add(apron);

      // 6. Architectural Mullion Grid (2 Vertical + 2 Horizontal + Transom Bar + Radial Fanlight Bars)
      const transomBar = new THREE.Mesh(new THREE.BoxGeometry(winW - 0.08, 0.065, 0.12), walnutCasingMat);
      transomBar.position.set(0, rectH / 2, 0.065);
      group.add(transomBar);

      const transomGold = new THREE.Mesh(new THREE.BoxGeometry(winW - 0.12, 0.02, 0.135), brassMullionMat);
      transomGold.position.set(0, rectH / 2, 0.065);
      group.add(transomGold);

      [-winW / 6, winW / 6].forEach((mx) => {
        const vMullion = new THREE.Mesh(new THREE.BoxGeometry(0.038, rectH, 0.09), brassMullionMat);
        vMullion.position.set(mx, 0, 0.06);
        group.add(vMullion);
      });

      [-rectH / 6, rectH / 6].forEach((my) => {
        const hMullion = new THREE.Mesh(new THREE.BoxGeometry(winW - 0.14, 0.035, 0.09), brassMullionMat);
        hMullion.position.set(0, my, 0.06);
        group.add(hMullion);
      });

      // Radial fanlight spokes inside the arch
      [Math.PI * 0.25, Math.PI * 0.5, Math.PI * 0.75].forEach((ang) => {
        const spokeLen = archR - 0.08;
        const spoke = new THREE.Mesh(new THREE.BoxGeometry(0.028, spokeLen, 0.08), brassMullionMat);
        spoke.position.set(
          Math.cos(ang) * (spokeLen / 2),
          rectH / 2 + Math.sin(ang) * (spokeLen / 2),
          0.06
        );
        spoke.rotation.z = ang - Math.PI / 2;
        group.add(spoke);
      });

      // Position Window Group on Left or Right Wall
      const wallX = isLeft ? -3.46 : 3.46;
      const winCenterY = 1.92;
      group.position.set(wallX, winCenterY, wb.z);
      group.rotation.y = isLeft ? Math.PI / 2 : -Math.PI / 2;
      this.scene.add(group);

      // 7. Volumetric Celestial & Volcanic Light Beams angling into the gallery
      const inwardSign = isLeft ? 1 : -1;
      const shaftPlane = new THREE.Mesh(new THREE.PlaneGeometry(1.85, 3.65), beamMat);
      shaftPlane.position.set(wallX + inwardSign * 1.15, 1.58, wb.z);
      shaftPlane.rotation.y = isLeft ? Math.PI / 2 : -Math.PI / 2;
      shaftPlane.rotation.x = isLeft ? -0.52 : 0.52;
      this.scene.add(shaftPlane);
      this.sunbeamMeshes.push({ mesh: shaftPlane, phase: idx * 0.7 });

      // Cross-plane for 3D volumetric light beam visibility when looking straight down the corridor
      const crossShaft = new THREE.Mesh(new THREE.PlaneGeometry(2.3, 3.2), beamMat);
      crossShaft.position.set(wallX + inwardSign * 1.18, 1.55, wb.z);
      crossShaft.rotation.z = isLeft ? 0.52 : -0.52;
      this.scene.add(crossShaft);
      this.sunbeamMeshes.push({ mesh: crossShaft, phase: idx * 0.7 + 1.2 });

      // 8. Luminous Celestial Earth & Volcanic Lava Floor Glow on the Herringbone Parquet
      const floorPatch = new THREE.Mesh(new THREE.PlaneGeometry(1.75, 1.95), floorMat);
      floorPatch.rotation.x = -Math.PI / 2;
      floorPatch.position.set(wallX + inwardSign * 1.65, 0.007, wb.z);
      this.scene.add(floorPatch);

      // Ethereal Earth cyan & volcanic hearth ambient fill on alternating bays
      if (idx % 2 === 0) {
        const bayFill = new THREE.PointLight(lightColor, 0.58, 8.0, 1.8);
        bayFill.position.set(wallX + inwardSign * 0.85, 2.35, wb.z);
        this.scene.add(bayFill);
      }
    });
  }

  buildHallwayDecorations() {
    const brassMat = new THREE.MeshStandardMaterial({
      color: 0xd4af37,
      metalness: 0.86,
      roughness: 0.22
    });
    const darkMarbleMat = new THREE.MeshStandardMaterial({
      color: 0x16181d,
      roughness: 0.24,
      metalness: 0.12
    });
    const velvetRopeMat = new THREE.MeshStandardMaterial({
      color: 0x7f1d1d,
      roughness: 0.65,
      metalness: 0.05
    });
    const sconceGlowMat = new THREE.MeshBasicMaterial({
      color: 0xffe4b5
    });
    const foliageMat = new THREE.MeshStandardMaterial({
      color: 0x1e3f29,
      roughness: 0.55,
      metalness: 0.04
    });

    // 1. Warm Brushed-Brass & Alabaster Wall Sconces on every Walnut Pilaster
    for (let z = 9.25; z >= -15.3; z -= 3.5) {
      [-3.36, 3.36].forEach((sx) => {
        const sconceGroup = new THREE.Group();

        const backplate = new THREE.Mesh(new THREE.BoxGeometry(0.04, 0.34, 0.12), brassMat);
        sconceGroup.add(backplate);

        const arm = new THREE.Mesh(new THREE.BoxGeometry(0.12, 0.035, 0.04), brassMat);
        arm.position.set(sx < 0 ? 0.06 : -0.06, -0.04, 0);
        sconceGroup.add(arm);

        const shade = new THREE.Mesh(new THREE.CylinderGeometry(0.055, 0.04, 0.24, 14), sconceGlowMat);
        shade.position.set(sx < 0 ? 0.11 : -0.11, 0.06, 0);
        sconceGroup.add(shade);

        const ringTop = new THREE.Mesh(new THREE.TorusGeometry(0.056, 0.008, 8, 16), brassMat);
        ringTop.rotation.x = Math.PI / 2;
        ringTop.position.set(sx < 0 ? 0.11 : -0.11, 0.17, 0);
        sconceGroup.add(ringTop);

        sconceGroup.position.set(sx, 2.38, z);
        this.scene.add(sconceGroup);
      });
    }

    // 2. Crimson Velvet Rope Stanchions guarding each of the 4 Framed Paintings
    this.pictures.forEach((pic) => {
      const isLeft = pic.wall === 'left';
      const isEnd = pic.wall === 'end';
      const stanchionGroup = new THREE.Group();

      const span = isEnd ? 2.8 : 2.3;
      [-span / 2, span / 2].forEach((offset) => {
        const base = new THREE.Mesh(new THREE.CylinderGeometry(0.14, 0.16, 0.04, 18), brassMat);
        base.position.set(isEnd ? offset : 0, 0.02, isEnd ? 0 : offset);
        stanchionGroup.add(base);

        const post = new THREE.Mesh(new THREE.CylinderGeometry(0.024, 0.024, 0.78, 14), brassMat);
        post.position.set(isEnd ? offset : 0, 0.41, isEnd ? 0 : offset);
        stanchionGroup.add(post);

        const finial = new THREE.Mesh(new THREE.SphereGeometry(0.045, 14, 14), brassMat);
        finial.position.set(isEnd ? offset : 0, 0.82, isEnd ? 0 : offset);
        stanchionGroup.add(finial);
      });

      // Draped Velvet Rope Segment
      const rope = new THREE.Mesh(new THREE.CylinderGeometry(0.018, 0.018, span, 12), velvetRopeMat);
      rope.position.set(0, 0.68, 0);
      if (isEnd) {
        rope.rotation.z = Math.PI / 2;
      } else {
        rope.rotation.x = Math.PI / 2;
      }
      stanchionGroup.add(rope);

      const stX = isEnd ? 0 : (isLeft ? -2.68 : 2.68);
      const stZ = isEnd ? -14.1 : pic.position.z;
      stanchionGroup.position.set(stX, 0, stZ);
      this.scene.add(stanchionGroup);
    });

    // 3. Sculpted Marble Pedestals with Rotating Golden Armillary Sculptures & Botanical Planters beneath Windows
    const alcovePlacements = [
      { x: 2.78,  z: 7.5,  type: 'sculpture' },
      { x: -2.78, z: 4.0,  type: 'planter'   },
      { x: 2.78,  z: 4.0,  type: 'sculpture' },
      { x: -2.78, z: 0.5,  type: 'sculpture' },
      { x: -2.78, z: -3.0, type: 'planter'   },
      { x: 2.78,  z: -3.0, type: 'sculpture' },
      { x: 2.78,  z: -6.5, type: 'planter'   },
      { x: -2.78, z: -10.0, type: 'sculpture' },
      { x: 2.78,  z: -10.0, type: 'planter'  }
    ];

    alcovePlacements.forEach((item, idx) => {
      const group = new THREE.Group();

      if (item.type === 'sculpture') {
        // Fluted Dark Marble Plinth with Gold Trim
        const plinth = new THREE.Mesh(new THREE.BoxGeometry(0.46, 0.96, 0.46), darkMarbleMat);
        plinth.position.set(0, 0.48, 0);
        plinth.castShadow = true;
        plinth.receiveShadow = true;
        group.add(plinth);

        const cap = new THREE.Mesh(new THREE.BoxGeometry(0.52, 0.05, 0.52), brassMat);
        cap.position.set(0, 0.98, 0);
        group.add(cap);

        // Kinetic Gold Armillary Sculpture on Top
        const sculp = new THREE.Group();
        const ring1 = new THREE.Mesh(new THREE.TorusGeometry(0.21, 0.018, 12, 28), brassMat);
        const ring2 = new THREE.Mesh(new THREE.TorusGeometry(0.16, 0.015, 12, 28), brassMat);
        ring2.rotation.y = Math.PI / 3;
        ring2.rotation.x = Math.PI / 4;
        const core = new THREE.Mesh(new THREE.OctahedronGeometry(0.075, 0), brassMat);
        sculp.add(ring1, ring2, core);
        sculp.position.set(0, 1.28, 0);
        group.add(sculp);
        this.kineticSculptures.push({ mesh: sculp, speed: 0.45 + (idx % 3) * 0.15 });
      } else {
        // Brushed-Brass & Marble Architectural Gallery Planter
        const pot = new THREE.Mesh(new THREE.CylinderGeometry(0.26, 0.20, 0.48, 18), darkMarbleMat);
        pot.position.set(0, 0.24, 0);
        pot.castShadow = true;
        group.add(pot);

        const rim = new THREE.Mesh(new THREE.TorusGeometry(0.26, 0.02, 10, 20), brassMat);
        rim.rotation.x = Math.PI / 2;
        rim.position.set(0, 0.48, 0);
        group.add(rim);

        // Sculpted Topiary / Museum Foliage Cluster
        const bush1 = new THREE.Mesh(new THREE.DodecahedronGeometry(0.24, 1), foliageMat);
        bush1.position.set(0, 0.66, 0);
        const bush2 = new THREE.Mesh(new THREE.DodecahedronGeometry(0.17, 1), foliageMat);
        bush2.position.set(0.08, 0.88, -0.04);
        const bush3 = new THREE.Mesh(new THREE.DodecahedronGeometry(0.14, 1), foliageMat);
        bush3.position.set(-0.07, 1.05, 0.05);
        group.add(bush1, bush2, bush3);
      }

      group.position.set(item.x, 0, item.z);
      this.scene.add(group);
    });

    // 4. Ornate Ceiling Chandelier Pendants along the Center Corridor
    [7.5, 4.0, 0.5, -3.0, -6.5, -10.0, -13.2].forEach((cz) => {
      const chandelier = new THREE.Group();
      const rod = new THREE.Mesh(new THREE.CylinderGeometry(0.015, 0.015, 0.55, 10), brassMat);
      rod.position.set(0, 4.02, 0);
      chandelier.add(rod);

      const haloRing = new THREE.Mesh(new THREE.TorusGeometry(0.32, 0.02, 10, 24), brassMat);
      haloRing.rotation.x = Math.PI / 2;
      haloRing.position.set(0, 3.74, 0);
      chandelier.add(haloRing);

      const globe = new THREE.Mesh(new THREE.SphereGeometry(0.11, 16, 16), sconceGlowMat);
      globe.position.set(0, 3.74, 0);
      chandelier.add(globe);

      chandelier.position.set(0, 0, cz);
      this.scene.add(chandelier);
    });
  }

  buildCorridorFurniture() {
    // Low museum benches & warm floor bollards between exhibits to amplify the sensation of walking past physical objects
    const leatherMat = new THREE.MeshStandardMaterial({ color: 0x231a16, roughness: 0.45, metalness: 0.08 });
    const legMat = new THREE.MeshStandardMaterial({ color: 0xc9a24d, roughness: 0.28, metalness: 0.82 });

    const benchZPositions = [4.0, -3.0, -9.5];
    benchZPositions.forEach((bz) => {
      const group = new THREE.Group();
      // Cushion
      const cushion = new THREE.Mesh(new THREE.BoxGeometry(0.75, 0.12, 1.65), leatherMat);
      cushion.position.set(0, 0.44, 0);
      cushion.castShadow = true;
      cushion.receiveShadow = true;
      group.add(cushion);

      // Brass Frame Legs
      [-0.65, 0.65].forEach((lz) => {
        const leg = new THREE.Mesh(new THREE.BoxGeometry(0.68, 0.38, 0.05), legMat);
        leg.position.set(0, 0.19, lz);
        group.add(leg);
      });

      group.position.set(0, 0, bz);
      this.scene.add(group);
    });
  }

  setupMuseumLighting() {
    // Soft warm museum ambient fill
    const ambient = new THREE.AmbientLight(0xfff4e6, 0.48);
    this.scene.add(ambient);

    // Warm overhead corridor chandelier / recessed downlights down the walkway
    [8.0, 2.0, -4.0, -10.0].forEach((z) => {
      const downlight = new THREE.PointLight(0xffe4c4, 0.65, 11, 1.8);
      downlight.position.set(0, 3.95, z);
      this.scene.add(downlight);
    });

    // Focused Museum Spotlights on each of the 4 Framed Paintings
    this.pictures.forEach((pic) => {
      const isLeft = pic.wall === 'left';
      const isEnd = pic.wall === 'end';
      const spotX = isEnd ? 0 : (isLeft ? -2.05 : 2.05);
      const spotZ = isEnd ? -12.6 : pic.position.z;

      const spot = new THREE.SpotLight(0xfff6e5, 2.4, 14, Math.PI / 4.2, 0.48, 1.2);
      spot.position.set(spotX, 4.05, spotZ);
      spot.castShadow = true;
      spot.shadow.mapSize.width = 1024;
      spot.shadow.mapSize.height = 1024;

      const targetObj = new THREE.Object3D();
      targetObj.position.set(pic.position.x, pic.position.y, pic.position.z);
      this.scene.add(targetObj);
      spot.target = targetObj;
      this.scene.add(spot);

      // Brass Spotlight Canister on Ceiling Rail
      const canister = new THREE.Mesh(
        new THREE.CylinderGeometry(0.06, 0.085, 0.24, 16),
        new THREE.MeshStandardMaterial({ color: 0xc9a24d, metalness: 0.85, roughness: 0.22 })
      );
      canister.position.set(spotX, 4.06, spotZ);
      canister.lookAt(targetObj.position);
      canister.rotateX(Math.PI / 2);
      this.scene.add(canister);
    });
  }

  buildFramedPaintings() {
    const walnutFrameMat = new THREE.MeshStandardMaterial({
      color: 0x19120d,
      roughness: 0.28,
      metalness: 0.14
    });
    const goldFiletMat = new THREE.MeshStandardMaterial({
      color: 0xd4af37,
      roughness: 0.24,
      metalness: 0.86
    });
    const linenMatBoard = new THREE.MeshStandardMaterial({
      color: 0xf5f2eb,
      roughness: 0.88,
      metalness: 0.02
    });

    this.pictures.forEach((pic) => {
      const isLeft = pic.wall === 'left';
      const isEnd = pic.wall === 'end';

      const frameW = isEnd ? 4.3 : 3.3;
      const frameH = isEnd ? 2.55 : 2.05;

      const group = new THREE.Group();

      // 1. Outer Beveled Walnut Molding
      const outerBox = new THREE.Mesh(new THREE.BoxGeometry(frameW, frameH, 0.11), walnutFrameMat);
      outerBox.castShadow = true;
      outerBox.receiveShadow = true;
      group.add(outerBox);

      // 2. Inner Brushed Gold Filet Lip
      const goldLip = new THREE.Mesh(
        new THREE.BoxGeometry(frameW - 0.16, frameH - 0.16, 0.116),
        goldFiletMat
      );
      group.add(goldLip);

      // 3. Museum Linen Matting Board
      const matBoard = new THREE.Mesh(
        new THREE.BoxGeometry(frameW - 0.24, frameH - 0.24, 0.12),
        linenMatBoard
      );
      group.add(matBoard);

      // 4. High-Resolution Painting Canvas
      const canvasW = frameW - 0.52;
      const canvasH = frameH - 0.52;
      const texObj = this.createPaintingCanvasTexture(pic);
      this.paintingCanvases.set(pic.id, texObj);

      const paintingPlane = new THREE.Mesh(
        new THREE.PlaneGeometry(canvasW, canvasH),
        new THREE.MeshStandardMaterial({
          map: texObj.texture,
          roughness: 0.35,
          metalness: 0.04
        })
      );
      paintingPlane.position.z = 0.062;
      group.add(paintingPlane);

      // 5. Overhead Brass Picture Light Bar attached to top of frame
      const lightArm = new THREE.Mesh(new THREE.BoxGeometry(0.95, 0.04, 0.22), goldFiletMat);
      lightArm.position.set(0, frameH / 2 + 0.08, 0.11);
      group.add(lightArm);

      // 6. Brass Museum Placard below the frame
      const placardMesh = this.createPlacardMesh(pic);
      placardMesh.position.set(0, -frameH / 2 - 0.23, 0.02);
      group.add(placardMesh);

      // Position on gallery wall
      group.position.set(pic.position.x, pic.position.y, pic.position.z);
      if (isLeft) {
        group.rotation.y = Math.PI / 2;
      } else if (!isEnd) {
        group.rotation.y = -Math.PI / 2;
      }

      paintingPlane.userData = { pictureId: pic.id };
      outerBox.userData = { pictureId: pic.id };
      this.interactiveMeshes.push(paintingPlane, outerBox);

      this.scene.add(group);
    });
  }

  createPaintingCanvasTexture(pic) {
    const canvas = document.createElement('canvas');
    canvas.width = 1024;
    canvas.height = 640;
    const texture = new THREE.CanvasTexture(canvas);
    texture.encoding = THREE.sRGBEncoding;
    const obj = { canvas, texture, pic };
    this.drawPaintingCanvas(obj);
    return obj;
  }

  drawPaintingCanvas(obj) {
    const { canvas, texture, pic } = obj;
    const ctx = canvas.getContext('2d');
    const W = canvas.width;
    const H = canvas.height;

    // Rich gallery artwork background
    const grad = ctx.createLinearGradient(0, 0, W, H);
    grad.addColorStop(0, pic.palette[0]);
    grad.addColorStop(0.55, pic.palette[1]);
    grad.addColorStop(1, pic.palette[2]);
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, W, H);

    // Subtle geometric architectural engraving lines (museum print motif)
    ctx.strokeStyle = 'rgba(255, 255, 255, 0.06)';
    ctx.lineWidth = 1.5;
    for (let r = 90; r <= 340; r += 65) {
      ctx.beginPath();
      ctx.arc(W * 0.78, H * 0.5, r, 0, Math.PI * 2);
      ctx.stroke();
    }

    // Double Gold Exhibition Inner Frame Border
    ctx.strokeStyle = pic.accentCss;
    ctx.lineWidth = 6;
    ctx.strokeRect(28, 28, W - 56, H - 56);
    ctx.strokeStyle = 'rgba(212, 175, 55, 0.45)';
    ctx.lineWidth = 2;
    ctx.strokeRect(42, 42, W - 84, H - 84);

    // Roman Numeral Medallion
    ctx.fillStyle = pic.accentCss;
    ctx.font = '700 22px "Segoe UI", sans-serif';
    ctx.textAlign = 'left';
    ctx.fillText(`EXHIBIT ${pic.roman}  •  ${pic.stepLabel}`, 76, 108);

    // Completed Status Badge on Painting
    ctx.textAlign = 'right';
    if (pic.completed) {
      ctx.fillStyle = '#10b981';
      ctx.font = '700 22px "Segoe UI", sans-serif';
      ctx.fillText('✓ COMPLETED', W - 76, 108);
    } else {
      ctx.fillStyle = '#e2e8f0';
      ctx.font = '600 20px "Segoe UI", sans-serif';
      ctx.fillText('ACTIVE EXHIBIT', W - 76, 108);
    }

    // Main Exhibit Title
    ctx.textAlign = 'left';
    ctx.fillStyle = '#ffffff';
    ctx.font = '800 50px "Segoe UI", sans-serif';
    ctx.fillText(pic.title, 76, 230);

    // Subtitle
    ctx.fillStyle = '#cbd5e1';
    ctx.font = '500 27px "Segoe UI", sans-serif';
    ctx.fillText(pic.subtitle, 76, 285);

    // Divider line
    ctx.strokeStyle = 'rgba(255,255,255,0.18)';
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(76, 330);
    ctx.lineTo(W - 76, 330);
    ctx.stroke();

    // Current Selection Summary Box painted directly onto the canvas
    ctx.fillStyle = 'rgba(10, 12, 18, 0.55)';
    ctx.fillRect(76, 365, W - 152, 110);
    ctx.strokeStyle = pic.accentCss;
    ctx.lineWidth = 2;
    ctx.strokeRect(76, 365, W - 152, 110);

    ctx.fillStyle = '#94a3b8';
    ctx.font = '600 18px monospace';
    ctx.fillText('CURRENT CURATION:', 102, 405);

    ctx.fillStyle = '#f8fafc';
    ctx.font = '700 26px "Segoe UI", sans-serif';
    ctx.fillText(pic.summaryText || 'Ready', 102, 448);

    // Bottom Call-to-Action Footer
    ctx.fillStyle = pic.accentCss;
    ctx.font = '700 21px monospace';
    ctx.fillText('CLICK PAINTING TO OPEN EXHIBIT MENU  →', 76, 548);

    texture.needsUpdate = true;
  }

  updatePaintingStatus(pictureId, summaryText, completed = true) {
    const obj = this.paintingCanvases.get(pictureId);
    if (!obj) return;
    obj.pic.summaryText = summaryText;
    obj.pic.completed = completed;
    this.drawPaintingCanvas(obj);
  }

  createPlacardMesh(pic) {
    const canvas = document.createElement('canvas');
    canvas.width = 512;
    canvas.height = 128;
    const ctx = canvas.getContext('2d');

    const grad = ctx.createLinearGradient(0, 0, 512, 128);
    grad.addColorStop(0, '#c9a24d');
    grad.addColorStop(0.5, '#e2c16b');
    grad.addColorStop(1, '#a88232');
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, 512, 128);

    ctx.strokeStyle = '#291f0c';
    ctx.lineWidth = 6;
    ctx.strokeRect(6, 6, 500, 116);

    ctx.fillStyle = '#141109';
    ctx.textAlign = 'center';
    ctx.font = '800 25px "Segoe UI", sans-serif';
    ctx.fillText(`EXHIBIT ${pic.roman}: ${pic.title}`, 256, 54);
    ctx.font = '600 18px "Segoe UI", sans-serif';
    ctx.fillText(pic.subtitle, 256, 92);

    const tex = new THREE.CanvasTexture(canvas);
    tex.encoding = THREE.sRGBEncoding;
    return new THREE.Mesh(
      new THREE.PlaneGeometry(1.35, 0.32),
      new THREE.MeshStandardMaterial({ map: tex, metalness: 0.72, roughness: 0.28 })
    );
  }

  // -------------------------------------------------------------------------
  // 3-PHASE CHOREOGRAPHED FIRST-PERSON WALK DOWN THE HALLWAY
  // -------------------------------------------------------------------------
  walkToPicture(targetPictureId, immediate = false) {
    const toPic = this.pictures.find((p) => p.id === targetPictureId);
    if (!toPic) return;

    const fromPic = this.pictures.find((p) => p.id === this.activePictureId) || toPic;
    this.activePictureId = targetPictureId;

    if (immediate || (fromPic.id === toPic.id && !this.walkState)) {
      this.walkState = null;
      this.camPos.set(toPic.standPos.x, toPic.standPos.y, toPic.standPos.z);
      this.camLook.set(toPic.lookPos.x, toPic.lookPos.y, toPic.lookPos.z);
      this.camRoll = 0;
      this.onArrive(toPic);
      return;
    }

    const startPos = this.camPos.clone();
    const startLook = this.camLook.clone();

    // Hallway centerline waypoints for natural human walking trajectory
    const aisleStartPos = new THREE.Vector3(0, 1.72, startPos.z);
    const aisleEndPos = new THREE.Vector3(0, 1.72, toPic.standPos.z);
    const finalPos = new THREE.Vector3(toPic.standPos.x, toPic.standPos.y, toPic.standPos.z);
    const finalLook = new THREE.Vector3(toPic.lookPos.x, toPic.lookPos.y, toPic.lookPos.z);

    // Look down the hallway direction while walking
    const zDir = toPic.standPos.z < startPos.z ? -1 : 1;
    const hallwayAheadLook = new THREE.Vector3(0, 1.70, toPic.standPos.z + zDir * 4.5);

    const corridorDistance = Math.abs(toPic.standPos.z - startPos.z);
    const phase1Dur = 0.52; // Step back to center aisle & turn down corridor
    const phase2Dur = Math.max(1.55, Math.min(2.65, corridorDistance * 0.25)); // Walk down corridor with footsteps
    const phase3Dur = 0.62; // Turn to painting & step into viewing stance
    const totalDur = phase1Dur + phase2Dur + phase3Dur;

    // Total footsteps based on distance (~1 step every 0.42s during walk)
    const totalSteps = Math.max(4, Math.round(phase2Dur / 0.38));

    this.walkState = {
      fromPic,
      toPic,
      startPos,
      startLook,
      aisleStartPos,
      aisleEndPos,
      hallwayAheadLook,
      finalPos,
      finalLook,
      phase1Dur,
      phase2Dur,
      phase3Dur,
      totalDur,
      totalSteps,
      lastStepIndex: -1,
      elapsed: 0
    };

    this.onWalkStart(fromPic, toPic, totalDur);
  }

  skipActiveWalk() {
    if (!this.walkState) return;
    const toPic = this.walkState.toPic;
    this.walkState = null;
    this.camPos.copy(new THREE.Vector3(toPic.standPos.x, toPic.standPos.y, toPic.standPos.z));
    this.camLook.copy(new THREE.Vector3(toPic.lookPos.x, toPic.lookPos.y, toPic.lookPos.z));
    this.camRoll = 0;
    this.onArrive(toPic);
  }

  smoothstep(t) {
    const x = Math.max(0, Math.min(1, t));
    return x * x * (3 - 2 * x);
  }

  updateWalkAnimation(delta) {
    if (!this.walkState) return;
    const ws = this.walkState;
    ws.elapsed += delta;

    const pct = Math.min(1, ws.elapsed / ws.totalDur);
    this.onWalkProgress(pct, ws.fromPic, ws.toPic);

    if (ws.elapsed <= ws.phase1Dur) {
      // Phase 1: Step back onto center carpet runner & turn head down the hallway
      const u = this.smoothstep(ws.elapsed / ws.phase1Dur);
      this.camPos.lerpVectors(ws.startPos, ws.aisleStartPos, u);
      this.camLook.lerpVectors(ws.startLook, ws.hallwayAheadLook, u);
      this.camPos.y = 1.72 + Math.sin(u * Math.PI) * 0.025;
      this.camRoll = 0;
      if (ws.lastStepIndex < 0 && u > 0.55) {
        ws.lastStepIndex = 0;
        this.onFootstep(0);
      }
    } else if (ws.elapsed <= ws.phase1Dur + ws.phase2Dur) {
      // Phase 2: Human Stride Down the Center Hallway
      const walkTime = ws.elapsed - ws.phase1Dur;
      const u = this.smoothstep(walkTime / ws.phase2Dur);

      this.camPos.lerpVectors(ws.aisleStartPos, ws.aisleEndPos, u);

      // Biomechanical walking cadence: vertical bounce + lateral sway + subtle roll
      const strideCycles = u * ws.totalSteps * Math.PI;
      const verticalBob = Math.abs(Math.sin(strideCycles)) * 0.068;
      const lateralSway = Math.sin(strideCycles) * 0.042;
      this.camPos.y = 1.72 + verticalBob;
      this.camPos.x += lateralSway;
      this.camRoll = Math.sin(strideCycles) * 0.011;

      // Keep gaze forward down the corridor, beginning to glance toward the painting near the end
      const glanceBlend = this.smoothstep((u - 0.68) / 0.32);
      this.camLook.lerpVectors(ws.hallwayAheadLook, ws.finalLook, glanceBlend * 0.55);
      this.camLook.y = 1.72 + verticalBob * 0.6;

      // Trigger synchronized real footstep audio on each stride cycle
      const currentStepIdx = Math.floor(u * ws.totalSteps) + 1;
      if (currentStepIdx > ws.lastStepIndex && currentStepIdx <= ws.totalSteps) {
        ws.lastStepIndex = currentStepIdx;
        this.onFootstep(currentStepIdx);
      }
    } else if (ws.elapsed < ws.totalDur) {
      // Phase 3: Turn to face the painting on the wall & step into viewing stance
      const turnTime = ws.elapsed - ws.phase1Dur - ws.phase2Dur;
      const u = this.smoothstep(turnTime / ws.phase3Dur);

      this.camPos.lerpVectors(ws.aisleEndPos, ws.finalPos, u);
      const midLook = new THREE.Vector3().lerpVectors(ws.hallwayAheadLook, ws.finalLook, 0.55);
      this.camLook.lerpVectors(midLook, ws.finalLook, u);
      this.camPos.y = 1.72 + Math.sin(u * Math.PI) * 0.022;
      this.camRoll = (1 - u) * this.camRoll;

      if (ws.lastStepIndex <= ws.totalSteps && u > 0.45) {
        ws.lastStepIndex = ws.totalSteps + 1;
        this.onFootstep(ws.lastStepIndex);
      }
    } else {
      // Arrived squarely in front of the target painting
      const arrivedPic = ws.toPic;
      this.walkState = null;
      this.camPos.copy(ws.finalPos);
      this.camLook.copy(ws.finalLook);
      this.camRoll = 0;
      this.onArrive(arrivedPic);
    }
  }

  onCanvasClick(e) {
    if (this.walkState) return;
    const rect = this.container.getBoundingClientRect();
    const mouse = new THREE.Vector2(
      ((e.clientX - rect.left) / rect.width) * 2 - 1,
      -((e.clientY - rect.top) / rect.height) * 2 + 1
    );
    const raycaster = new THREE.Raycaster();
    raycaster.setFromCamera(mouse, this.camera);
    const hits = raycaster.intersectObjects(this.interactiveMeshes);
    if (hits.length > 0 && hits[0].object.userData.pictureId) {
      this.walkToPicture(hits[0].object.userData.pictureId);
    }
  }

  onMouseMove(e) {
    this.mouseX = (e.clientX / window.innerWidth) * 2 - 1;
    this.mouseY = -(e.clientY / window.innerHeight) * 2 + 1;
  }

  onResize() {
    if (!this.container || !this.camera || !this.renderer) return;
    const w = this.container.clientWidth;
    const h = this.container.clientHeight;
    this.camera.aspect = w / h;
    this.camera.updateProjectionMatrix();
    this.renderer.setSize(w, h);
  }

  buildDustParticles() {
    const particleCount = 220;
    const geometry = new THREE.BufferGeometry();
    const positions = new Float32Array(particleCount * 3);
    for (let i = 0; i < particleCount; i++) {
      positions[i * 3] = (Math.random() - 0.5) * 5.6;
      positions[i * 3 + 1] = 0.5 + Math.random() * 3.4;
      positions[i * 3 + 2] = -14.5 + Math.random() * 26.0;
    }
    geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
    const material = new THREE.PointsMaterial({
      color: 0xf5dc84,
      size: 0.042,
      transparent: true,
      opacity: 0.65,
      blending: THREE.AdditiveBlending
    });
    this.dustParticles = new THREE.Points(geometry, material);
    this.scene.add(this.dustParticles);
  }

  animate() {
    requestAnimationFrame(() => this.animate());
    const delta = Math.min(0.05, this.clock.getDelta());

    // Atmospheric volumetric dust motes drifting in sunbeams (Bruno Simon inspiration)
    if (this.dustParticles) {
      const positions = this.dustParticles.geometry.attributes.position.array;
      for (let i = 0; i < positions.length; i += 3) {
        positions[i + 1] += Math.sin(Date.now() * 0.0012 + i) * 0.002;
        positions[i] += Math.cos(Date.now() * 0.0008 + i) * 0.001;
      }
      this.dustParticles.geometry.attributes.position.needsUpdate = true;
    }

    // Gentle kinetic rotation for the museum alcove armillary sculptures
    if (this.kineticSculptures && this.kineticSculptures.length > 0) {
      for (let i = 0; i < this.kineticSculptures.length; i++) {
        const ks = this.kineticSculptures[i];
        ks.mesh.rotation.y += delta * ks.speed;
        ks.mesh.rotation.x += delta * (ks.speed * 0.35);
      }
    }

    if (this.walkState) {
      this.updateWalkAnimation(delta);
      this.camera.position.copy(this.camPos);
      this.camera.lookAt(this.camLook);
      this.camera.rotation.z += this.camRoll;
    } else {
      // Subtle breathing parallax while standing in front of a painting
      const px = this.camPos.x + this.mouseX * 0.06;
      const py = this.camPos.y + this.mouseY * 0.04;
      this.camera.position.x += (px - this.camera.position.x) * (delta * 4.0);
      this.camera.position.y += (py - this.camera.position.y) * (delta * 4.0);
      this.camera.position.z += (this.camPos.z - this.camera.position.z) * (delta * 4.0);
      this.camera.lookAt(this.camLook);
    }

    this.renderer.render(this.scene, this.camera);
  }
}

window.GalleryHallway = GalleryHallway;
