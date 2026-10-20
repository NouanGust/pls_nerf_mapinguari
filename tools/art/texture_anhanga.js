(async function textureAnhanga() {
  const size = 256;
  if (!Project || Format.id !== 'free') throw new Error('Open the Anhangá Generic Model before texturing.');
  if (Texture.all.some(t => t.name === 'anhanga_albedo.png')) throw new Error('Anhangá atlas already exists; undo its previous application before rerunning.');
  const regions = {
    fur: {rect: [0, 0, 160, 144], color: '#DDD8C9', detail: 3},
    fur_shadow: {rect: [0, 144, 128, 256], color: '#C5C0C1', detail: 3},
    antler: {rect: [160, 0, 256, 128], color: '#785142', detail: 4},
    antler_tip: {rect: [128, 144, 192, 200], color: '#E7D5AC', detail: 2},
    hoof: {rect: [192, 128, 256, 192], color: '#34262F', detail: 2},
    inner_ear: {rect: [128, 200, 192, 256], color: '#A94E43', detail: 3},
    nose: {rect: [192, 192, 224, 224], color: '#34262F', detail: 0},
    eye: {rect: [224, 192, 256, 224], color: '#F29A35', detail: 0},
    mark: {rect: [192, 224, 224, 256], color: '#FFD473', detail: 0},
    mouth: {rect: [224, 224, 256, 256], color: '#4A2029', detail: 0}
  };
  const density = Object.fromEntries(Object.keys(regions).map(k => [k, 4]));
  const plans = [];
  const skipped = [];
  const failures = [];
  const elements = [];
  const margin = 5;
  const v3 = p => new THREE.Vector3(p[0], p[1], p[2]);
  for (const mesh of Mesh.all) {
    const prefix = ['antler_tip', 'inner_ear', 'antler', 'hoof', 'nose', 'eye', 'mark', 'mouth', 'fur'].find(k => mesh.name.startsWith(k + '_'));
    if (!prefix) { skipped.push(mesh.name); continue; }
    elements.push(mesh);
    for (const [faceKey, face] of Object.entries(mesh.faces)) {
      const keys = face.getSortedVertices();
      if (keys.length < 3) continue;
      const points = keys.map(key => v3(mesh.vertices[key]));
      const origin = points[0];
      const basisU = points[1].clone().sub(origin).normalize();
      let normal;
      for (let i = 2; i < points.length; i++) {
        const candidate = new THREE.Vector3().crossVectors(basisU, points[i].clone().sub(origin));
        if (candidate.lengthSq() > 1e-12) { normal = candidate.normalize(); break; }
      }
      if (!normal) { failures.push(mesh.name + ':' + faceKey + ':degenerate'); continue; }
      const basisV = new THREE.Vector3().crossVectors(normal, basisU).normalize();
      const xy = points.map(p => {
        const delta = p.clone().sub(origin);
        return [delta.dot(basisU), delta.dot(basisV)];
      });
      const min = [Math.min(...xy.map(p => p[0])), Math.min(...xy.map(p => p[1]))];
      const max = [Math.max(...xy.map(p => p[0])), Math.max(...xy.map(p => p[1]))];
      const spans = max.map((n, i) => n - min[i]);
      const type = prefix === 'fur' && normal.y < -0.35 ? 'fur_shadow' : prefix;
      const [x0, y0, x1, y1] = regions[type].rect;
      const fit = Math.min((x1 - x0 - 2 * margin) / Math.max(spans[0], 1e-8), (y1 - y0 - 2 * margin) / Math.max(spans[1], 1e-8));
      density[type] = Math.min(density[type], fit);
      plans.push({mesh, face, faceKey, keys, points, origin, xy, min, spans, type, normal});
    }
  }
  if (!plans.length || failures.length) throw new Error('Invalid geometry: ' + JSON.stringify({faces: plans.length, failures}));
  const furDensity = Math.min(density.fur, density.fur_shadow);
  density.fur = density.fur_shadow = furDensity;
  const canvas = document.createElement('canvas');
  canvas.width = canvas.height = size;
  const ctx = canvas.getContext('2d');
  ctx.fillStyle = '#DDD8C9';
  ctx.fillRect(0, 0, size, size);
  let seed = 22062026;
  function random() {
    seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0;
    return seed / 4294967296;
  }
  for (const region of Object.values(regions)) {
    const [x0, y0, x1, y1] = region.rect;
    ctx.fillStyle = region.color;
    ctx.fillRect(x0, y0, x1 - x0, y1 - y0);
    if (!region.detail) continue;
    const rgb = [1, 3, 5].map(offset => parseInt(region.color.slice(offset, offset + 2), 16));
    for (let y = y0; y < y1; y++) {
      for (let x = x0; x < x1; x++) {
        if (random() > 0.3) continue;
        const delta = Math.round((random() * 2 - 1) * region.detail);
        ctx.fillStyle = 'rgb(' + rgb.map(c => Math.max(0, Math.min(255, c + delta))).join(',') + ')';
        ctx.fillRect(x, y, 1, 1);
      }
    }
  }
  const texture = new Texture({name: 'anhanga_albedo.png', uv_width: size, uv_height: size});
  await new Promise((resolve, reject) => {
    const timeout = setTimeout(() => reject(new Error('Atlas image decoding timed out')), 10000);
    texture.img.addEventListener('load', () => { clearTimeout(timeout); resolve(); }, {once: true});
    texture.img.addEventListener('error', () => { clearTimeout(timeout); reject(new Error('Atlas image decoding failed')); }, {once: true});
    texture.fromDataURL(canvas.toDataURL('image/png'));
  });
  Undo.initEdit({textures: [], elements, uv_only: true});
  texture.add(false);
  texture.uv_width = texture.uv_height = size;
  const audit = {};
  let minEdgeRatio = Infinity;
  let maxEdgeRatio = 0;
  let maxPlanarityError = 0;
  let boundsFailures = 0;
  for (const plan of plans) {
    const {mesh, face, keys, points, origin, xy, min, spans, type, normal} = plan;
    const [x0, y0, x1, y1] = regions[type].rect;
    const d = density[type];
    const offset = [x0 + (x1 - x0 - spans[0] * d) / 2, y0 + (y1 - y0 - spans[1] * d) / 2];
    face.texture = texture.uuid;
    for (let i = 0; i < keys.length; i++) {
      const uv = [offset[0] + (xy[i][0] - min[0]) * d, offset[1] + (xy[i][1] - min[1]) * d];
      face.uv[keys[i]] = uv;
      if (uv[0] < x0 + margin - 0.001 || uv[0] > x1 - margin + 0.001 || uv[1] < y0 + margin - 0.001 || uv[1] > y1 - margin + 0.001) boundsFailures++;
      maxPlanarityError = Math.max(maxPlanarityError, Math.abs(points[i].clone().sub(origin).dot(normal)));
    }
    for (let i = 0; i < keys.length; i++) {
      const j = (i + 1) % keys.length;
      const length = points[i].distanceTo(points[j]);
      if (length < 1e-8) continue;
      const a = face.uv[keys[i]], b = face.uv[keys[j]];
      const ratio = Math.hypot(a[0] - b[0], a[1] - b[1]) / length;
      minEdgeRatio = Math.min(minEdgeRatio, ratio);
      maxEdgeRatio = Math.max(maxEdgeRatio, ratio);
    }
    if (!audit[type]) audit[type] = {faces: 0, pixelsPerBlockbenchUnit: d, pixelsPerGodotUnit: d * 16, exampleMesh: mesh.name, exampleFace: plan.faceKey, exampleSpanBB: spans, exampleSpanPixels: spans.map(v => v * d)};
    audit[type].faces++;
  }
  texture.select();
  Canvas.updateAllFaces();
  UVEditor.loadData();
  Undo.finishEdit('Paint Anhangá atlas and proportionate UVs', {textures: [texture], elements, uv_only: true});
  return {
    texture: texture.name,
    uuid: texture.uuid,
    bitmap: [texture.width, texture.height],
    logicalUV: [texture.getUVWidth(), texture.getUVHeight()],
    meshes: elements.length,
    faces: plans.length,
    skipped,
    boundsFailures,
    edgePixelsPerUnitRange: [minEdgeRatio, maxEdgeRatio],
    maxPlanarityError,
    materialRegions: regions,
    audit
  };
})();
