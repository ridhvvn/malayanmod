/**
 * TMS7 Three.js Viewer — Flutter Web Interop Version
 *
 * Exposes two global functions callable from Dart via js_interop:
 *   - window.initTms7Scene(containerId) → creates the scene inside a DOM element
 *   - window.updateLiveryTexture(dataUrl) → swaps the baked texture with user image
 */

(function () {
  "use strict";

  let scene, camera, renderer, controls, bakedMaterial, clock;
  let animationFrameId = null;

  /**
   * Initialize the entire Three.js scene inside the given container element.
   * @param {string} containerId - The ID of the DOM element to mount the canvas into.
   */
  window.initTms7Scene = function (containerId) {
    const container = document.getElementById(containerId);
    if (!container) {
      console.error("[TMS7] Container not found:", containerId);
      return;
    }

    // Prevent double-init
    if (renderer) {
      console.warn("[TMS7] Scene already initialized.");
      return;
    }

    const debugObject = {
      clearColor: "#888888",
    };

    // ─── Scene ──────────────────────────────────────────────────────
    scene = new THREE.Scene();

    // ─── Loaders ────────────────────────────────────────────────────
    const textureLoader = new THREE.TextureLoader();
    const gltfLoader = new THREE.GLTFLoader();

    const bakedTexture = textureLoader.load("three/texture.jpg");
    const aoTexture = textureLoader.load("three/ao.jpg");

    bakedTexture.encoding = THREE.sRGBEncoding;
    bakedTexture.flipY = false;

    // ─── Materials ──────────────────────────────────────────────────
    bakedMaterial = new THREE.MeshBasicMaterial({ map: bakedTexture });
    const aoMaterial = new THREE.MeshBasicMaterial({ map: aoTexture });

    // ─── Model ──────────────────────────────────────────────────────
    gltfLoader.load("three/tms7.glb", function (gltf) {
      const bakedMesh = gltf.scene.children.find(
        (child) => child.name === "baked"
      );
      if (bakedMesh) bakedMesh.material = bakedMaterial;

      const aoMesh = gltf.scene.children.find(
        (child) => child.name === "Plane"
      );
      if (aoMesh) aoMesh.material = aoMaterial;

      scene.add(gltf.scene);
    });

    // ─── Sizes ──────────────────────────────────────────────────────
    const sizes = {
      width: container.clientWidth || window.innerWidth,
      height: container.clientHeight || window.innerHeight,
    };

    // ─── Camera ─────────────────────────────────────────────────────
    camera = new THREE.PerspectiveCamera(
      45,
      sizes.width / sizes.height,
      0.1,
      100
    );
    camera.position.set(-4, 2, -4);
    scene.add(camera);

    // ─── Renderer ───────────────────────────────────────────────────
    renderer = new THREE.WebGLRenderer({ antialias: true });
    renderer.setSize(sizes.width, sizes.height);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    renderer.outputEncoding = THREE.sRGBEncoding;
    renderer.setClearColor(debugObject.clearColor);

    container.appendChild(renderer.domElement);

    // ─── Controls ───────────────────────────────────────────────────
    controls = new THREE.OrbitControls(camera, renderer.domElement);
    controls.enableDamping = true;

    // Don't go below the ground
    controls.maxPolarAngle = Math.PI / 2 - 0.1;

    // Clamp panning
    const minPan = new THREE.Vector3(-0.2, -0.2, -0.2);
    const maxPan = new THREE.Vector3(2, 2, 2);
    const _v = new THREE.Vector3();

    controls.addEventListener("change", function () {
      _v.copy(controls.target);
      controls.target.clamp(minPan, maxPan);
      _v.sub(controls.target);
      camera.position.sub(_v);
    });

    // ─── Resize handling ────────────────────────────────────────────
    const resizeObserver = new ResizeObserver(function () {
      sizes.width = container.clientWidth;
      sizes.height = container.clientHeight;

      camera.aspect = sizes.width / sizes.height;
      camera.updateProjectionMatrix();

      renderer.setSize(sizes.width, sizes.height);
      renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    });
    resizeObserver.observe(container);

    // ─── Animation loop ─────────────────────────────────────────────
    clock = new THREE.Clock();

    function tick() {
      controls.update();
      renderer.render(scene, camera);
      animationFrameId = requestAnimationFrame(tick);
    }
    tick();
  };

  /**
   * Update the baked texture with a user-selected image.
   * @param {string} dataUrl - Base64 data URL of the image.
   */
  window.updateLiveryTexture = function (dataUrl) {
    if (!bakedMaterial) {
      console.error("[TMS7] Scene not initialized — cannot update texture.");
      return;
    }

    const textureLoader = new THREE.TextureLoader();
    const userTexture = textureLoader.load(dataUrl);
    userTexture.encoding = THREE.sRGBEncoding;
    userTexture.flipY = false;

    bakedMaterial.map = userTexture;
    bakedMaterial.needsUpdate = true;
  };
})();
