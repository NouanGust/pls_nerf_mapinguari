(() => {
  const texture = Texture.all.find(t => t.name === 'anhanga_albedo.png');
  if (!texture || texture.width !== 256 || texture.height !== 256) throw new Error('Expected the original 256px Anhangá atlas.');
  const elements = Mesh.all.filter(m => /^(eye_|antler_)/.test(m.name));
  const eyes = {
    socket: {rect: [224, 192, 234, 224], color: '#552F32', center: [229, 208]},
    ember: {rect: [234, 192, 245, 224], color: '#E94A29', center: [239.5, 208]},
    core: {rect: [245, 192, 256, 224], color: '#FFD473', center: [250.5, 208]}
  };
  const changes = [];
  const counts = {socket: 0, ember: 0, core: 0, antler_tip: 0};
  for (const mesh of elements) {
    const eyeType = Object.keys(eyes).find(k => mesh.name.startsWith('eye_' + k + '_'));
    for (const face of Object.values(mesh.faces)) {
      const keys = face.getSortedVertices();
      if (eyeType) {
        const center = eyes[eyeType].center;
        const oldCenter = [
          keys.reduce((sum, key) => sum + face.uv[key][0], 0) / keys.length,
          keys.reduce((sum, key) => sum + face.uv[key][1], 0) / keys.length
        ];
        const uv = Object.fromEntries(keys.map(key => [key, [
          center[0] + (face.uv[key][0] - oldCenter[0]) * 0.1,
          center[1] + (face.uv[key][1] - oldCenter[1]) * 0.1
        ]]));
        changes.push({face, uv});
        counts[eyeType]++;
      } else if (mesh.name.startsWith('antler_')) {
        const meanY = keys.reduce((sum, key) => sum + mesh.vertices[key][1], 0) / keys.length;
        const threshold = mesh.name.startsWith('antler_brow_') ? 29.3 : 31;
        if (meanY > threshold) {
          const uv = Object.fromEntries(keys.map(key => [key, [face.uv[key][0] - 48, face.uv[key][1] + 108]]));
          if (Object.values(uv).some(p => p[0] < 133 || p[0] > 187 || p[1] < 149 || p[1] > 195)) throw new Error('Antler tip UV exceeds its padded swatch: ' + mesh.name);
          changes.push({face, uv});
          counts.antler_tip++;
        }
      }
    }
  }
  if (!counts.socket || !counts.ember || !counts.core || !counts.antler_tip) throw new Error('Expected eye layers and upper antler faces.');
  Undo.initEdit({textures: [texture], bitmap: true, elements, uv_only: true});
  for (const region of Object.values(eyes)) {
    const [x0, y0, x1, y1] = region.rect;
    texture.ctx.fillStyle = region.color;
    texture.ctx.fillRect(x0, y0, x1 - x0, y1 - y0);
  }
  for (const {face, uv} of changes) {
    for (const [key, value] of Object.entries(uv)) face.uv[key] = value;
  }
  texture.updateChangesAfterEdit();
  Canvas.updateAllFaces();
  UVEditor.loadData();
  Undo.finishEdit('Refine Anhangá ember eyes and ivory antler tips');
  return {texture: texture.name, counts, changedFaces: changes.length, eyes, tipsPreserveDensity: 4, eyeUniformSwatchDensity: 0.4};
})();
