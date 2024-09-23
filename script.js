document.addEventListener('DOMContentLoaded', () => {
  const photoInput = document.getElementById('photoInput');
  const uploadedPhoto = document.getElementById('uploadedPhoto');

  photoInput.addEventListener('change', (e) => {
    const file = e.target.files[0];
    if (file) {
      const reader = new FileReader();

      reader.onload = (event) => {
        uploadedPhoto.src = event.target.result;

        // Load the user-selected image as a texture
        const textureLoader = new THREE.TextureLoader();
        const userImageTexture = textureLoader.load(event.target.result);
        userImageTexture.encoding = THREE.sRGBEncoding;
        userImageTexture.flipY = false;

        // Update bakedMaterial to use the user's selected image
        bakedMaterial.map = userImageTexture;
        bakedMaterial.needsUpdate = true;
      };

      reader.readAsDataURL(file);
    } else {
      uploadedPhoto.src = '';
    }
  });
});

const debugObject = {
  clearColor: "#888888",
  portalColorStart: "#b91fac",
  portalColorEnd: "#ffebf3" };


// Canvas
const canvas = document.querySelector("canvas.webgl");

// Scene
const scene = new THREE.Scene();

/**
 * Loaders
 */
// Texture loader
const textureLoader = new THREE.TextureLoader();

// GLTF loader
const gltfLoader = new THREE.GLTFLoader();

const bakedTexture = textureLoader.load("texture.jpg");
const aoTexture = textureLoader.load("ao.jpg");

bakedTexture.encoding = THREE.sRGBEncoding;

/**
 * Materials
 */

// baked material
const bakedMaterial = new THREE.MeshBasicMaterial({ map: bakedTexture });
const aoMaterial = new THREE.MeshBasicMaterial({ map: aoTexture });

// Do not flip the Y axes of the texture which is on by default for some reason
bakedTexture.flipY = false;



/**
 * Model
 */
gltfLoader.load("tms7.glb", gltf => {
  const bakedMesh = gltf.scene.children.find(child => child.name == "baked");
  bakedMesh.material = bakedMaterial;
  const aoMesh = gltf.scene.children.find(child => child.name == "Plane");
  aoMesh.material = aoMaterial;
 
  scene.add(gltf.scene);
});

/**Sizes
*/
const sizes = {
  width: window.innerWidth,
  height: window.innerHeight };

window.addEventListener("resize", () => {
  // Update sizes
  sizes.width = window.innerWidth;
  sizes.height = window.innerHeight;

  // Update camera
  camera.aspect = sizes.width / sizes.height;
  camera.updateProjectionMatrix();

  // Update renderer
  renderer.setSize(sizes.width, sizes.height);
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));


});




/** Camera
 */
// Base camera
const camera = new THREE.PerspectiveCamera(
45,
sizes.width / sizes.height,
0.1,
100);

camera.position.x = -4;
camera.position.y = 2;
camera.position.z = -4;
scene.add(camera);

// Controls
const controls = new THREE.OrbitControls(camera, canvas);
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

/**Renderer
 */
const renderer = new THREE.WebGLRenderer({
  canvas: canvas,
  antialias: true });

renderer.setSize(sizes.width, sizes.height);
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 1));
renderer.outputEncoding = THREE.sRGBEncoding;
renderer.setClearColor(debugObject.clearColor);


/**Animate
 */
const clock = new THREE.Clock();

const tick = () => {
  const elapsedTime = clock.getElapsedTime();

  // Update controls
  controls.update();

  // Render
  renderer.render(scene, camera);

  // Call tick again on the next frame
  window.requestAnimationFrame(tick);
};

tick();