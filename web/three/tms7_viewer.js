/**
 * TMS7 Three.js Viewer — Flutter Web Interop Version
 *
 * Exposes two global functions callable from Dart via js_interop:
 *   - window.initTms7Scene(containerId) → creates the scene inside a DOM element
 *   - window.updateLiveryTexture(dataUrl) → swaps the baked texture with user image
 */

(function () {
  "use strict";

  let scene, camera, renderer, controls, bakedMaterial, aoMaterial, clock, resizeObserver;
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
    aoMaterial = new THREE.MeshBasicMaterial({ map: aoTexture });

    // ─── Model ──────────────────────────────────────────────────────
    gltfLoader.load("three/tms7.glb", function (gltf) {
      if (!scene) {
        gltf.scene.traverse(function (child) {
          if (child.isMesh) {
            if (child.geometry) child.geometry.dispose();
            if (child.material) {
              if (Array.isArray(child.material)) {
                child.material.forEach(function (m) { m.dispose(); });
              } else {
                child.material.dispose();
              }
            }
          }
        });
        return;
      }
      const bakedMesh = gltf.scene.children.find(
        (child) => child.name === "baked"
      );
      if (bakedMesh && bakedMaterial) bakedMesh.material = bakedMaterial;

      const aoMesh = gltf.scene.children.find(
        (child) => child.name === "Plane"
      );
      if (aoMesh && aoMaterial) aoMesh.material = aoMaterial;

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
    resizeObserver = new ResizeObserver(function () {
      if (!container || !camera || !renderer) return;
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

  /**
   * Dispose of the entire Three.js scene and free all resources.
   */
  window.disposeTms7Scene = function () {
    console.log("[TMS7] Disposing scene...");

    if (animationFrameId !== null) {
      cancelAnimationFrame(animationFrameId);
      animationFrameId = null;
    }

    if (resizeObserver) {
      resizeObserver.disconnect();
      resizeObserver = null;
    }

    if (controls) {
      controls.dispose();
      controls = null;
    }

    if (bakedMaterial) {
      if (bakedMaterial.map) {
        bakedMaterial.map.dispose();
      }
      bakedMaterial.dispose();
      bakedMaterial = null;
    }

    if (aoMaterial) {
      if (aoMaterial.map) {
        aoMaterial.map.dispose();
      }
      aoMaterial.dispose();
      aoMaterial = null;
    }

    if (scene) {
      scene.traverse(function (object) {
        if (!object.isMesh) return;

        if (object.geometry) {
          object.geometry.dispose();
        }

        if (object.material) {
          if (Array.isArray(object.material)) {
            object.material.forEach(function (material) {
              if (material.map) material.map.dispose();
              material.dispose();
            });
          } else {
            if (object.material.map) object.material.map.dispose();
            object.material.dispose();
          }
        }
      });

      while (scene.children.length > 0) {
        scene.remove(scene.children[0]);
      }
      scene = null;
    }

    if (renderer) {
      renderer.dispose();
      if (renderer.domElement && renderer.domElement.parentNode) {
        renderer.domElement.parentNode.removeChild(renderer.domElement);
      }
      renderer = null;
    }

    camera = null;
    clock = null;
  };
})();
