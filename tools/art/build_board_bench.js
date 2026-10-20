(function () {
  "use strict";
  if (!Project || Format.id !== "free") throw new Error("Create an empty Generic Model project first.");
  if (Outliner.elements.length) throw new Error("This builder requires an empty project; existing content is protected.");

  const S = 16;
  const width = 14.838330249197703;
  const half = width / 2;
  const pitch = Math.sqrt(3) + 0.12;
  const created = [];
  const textures = [];
  let texture;
  let seed = 73109;
  const random = () => ((seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0) / 4294967296);
  const canvas = document.createElement("canvas");
  canvas.width = canvas.height = 512;
  const ctx = canvas.getContext("2d");
  ctx.fillStyle = "#332f29";
  ctx.fillRect(0, 0, 512, 512);
  const patches = {
    wood: [2, 2, 252, 252],
    stone: [258, 2, 252, 252],
    teal: [2, 258, 60, 60],
    earth: [66, 258, 60, 60],
    dark: [130, 258, 60, 60],
    brass: [194, 258, 60, 60],
    moss: [258, 258, 60, 60],
    warm: [2, 322, 508, 188],
    edge: [386, 258, 60, 60],
    reserve: [450, 258, 60, 60]
  };
  const colors = {
    wood: "#584638", stone: "#67675e", teal: "#4b777b", earth: "#74614f",
    dark: "#282723", brass: "#a28a54", moss: "#566245", warm: "#806546",
    edge: "#919080", reserve: "#77704f"
  };
  Object.entries(patches).forEach(([name, p]) => {
    ctx.fillStyle = colors[name];
    ctx.fillRect(p[0] - 2, p[1] - 2, p[2] + 4, p[3] + 4);
    for (let i = 0; i < (name === "wood" || name === "stone" ? 2100 : 40); i++) {
      ctx.fillStyle = random() > 0.5 ? "rgba(238,227,190,0.07)" : "rgba(19,23,19,0.09)";
      ctx.fillRect(p[0] + Math.floor(random() * p[2]), p[1] + Math.floor(random() * p[3]),
        name === "wood" ? 4 + Math.floor(random() * 20) : 1 + Math.floor(random() * 3), 1);
    }
  });
  ctx.save();
  ctx.beginPath();
  ctx.rect(2, 2, 252, 252);
  ctx.clip();
  for (let y = 15; y < 254; y += 31) {
    ctx.strokeStyle = "#352c26";
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(2, y);
    ctx.lineTo(254, y + 1);
    ctx.stroke();
    ctx.strokeStyle = "#75614a";
    ctx.beginPath();
    ctx.moveTo(2, y + 2);
    ctx.lineTo(254, y + 3);
    ctx.stroke();
    const x = 25 + random() * 180;
    ctx.strokeStyle = "#42362c";
    ctx.beginPath();
    ctx.ellipse(x, y + 16, 10, 3, 0, 0, Math.PI * 2);
    ctx.stroke();
  }
  ctx.restore();
  ctx.save();
  ctx.beginPath();
  ctx.rect(258, 2, 252, 252);
  ctx.clip();
  ctx.strokeStyle = "rgba(35,40,32,0.28)";
  ctx.lineWidth = 1;
  for (let i = 0; i < 27; i++) {
    const x = 260 + random() * 240, y = 4 + random() * 240;
    ctx.beginPath();
    ctx.moveTo(x, y);
    ctx.lineTo(x + 5, y + 3);
    ctx.lineTo(x + 7, y + 10);
    ctx.stroke();
  }
  ctx.restore();

  function group(name, parent) {
    const g = new Group({name: name, origin: [0, 0, 0]});
    if (parent) g.addTo(parent);
    g.init();
    return g;
  }
  function mesh(name, points, faces, parent, material) {
    const m = new Mesh({name: name, origin: [0, 0, 0], vertices: {}, faces: {}});
    const keys = m.addVertices(...points.map(p => p.map(v => v * S)));
    faces.forEach((indices) => {
      const selected = indices.map(i => points[i]);
      const a = selected[0], b = selected[1], c = selected[2];
      const ab = b.map((v, i) => v - a[i]), ac = c.map((v, i) => v - a[i]);
      const n = [ab[1]*ac[2]-ab[2]*ac[1], ab[2]*ac[0]-ab[0]*ac[2], ab[0]*ac[1]-ab[1]*ac[0]];
      const dominant = n.map(Math.abs).indexOf(Math.max(...n.map(Math.abs)));
      const axes = dominant === 1 ? [0, 2] : dominant === 0 ? [2, 1] : [0, 1];
      const min = axes.map(axis => Math.min(...selected.map(v => v[axis])));
      const p = patches[material];
      const uv = {};
      indices.forEach(i => {
        uv[keys[i]] = [p[0] + 2 + (points[i][axes[0]] - min[0]) * S,
          p[1] + 2 + (points[i][axes[1]] - min[1]) * S];
      });
      m.addFaces(new MeshFace(m, {vertices: indices.map(i => keys[i]), uv: uv, texture: texture.uuid}));
    });
    m.addTo(parent).init();
    created.push(m);
    return m;
  }
  function prism(name, ring, bottom, top, parent, material, closeBottom = true) {
    const n = ring.length;
    const points = ring.map(p => [p[0], bottom, p[1]]).concat(ring.map(p => [p[0], top, p[1]]));
    const faces = [];
    for (let i = 1; i < n - 1; i++) {
      faces.push([n, n + i + 1, n + i]);
      if (closeBottom) faces.push([0, i, i + 1]);
    }
    for (let i = 0; i < n; i++) {
      const j = (i + 1) % n;
      faces.push([j, i, n + i, n + j]);
    }
    return mesh(name, points, faces, parent, material);
  }
  function rectangle(x0, z0, x1, z1) {
    return [[x0,z0],[x1,z0],[x1,z1],[x0,z1]];
  }
  function box(name, x0, y0, z0, x1, y1, z1, parent, material) {
    return prism(name, rectangle(x0,z0,x1,z1), y0,y1,parent,material);
  }
  function bevelRect(x0,z0,x1,z1,c) {
    return [[x0+c,z0],[x1-c,z0],[x1,z0+c],[x1,z1-c],
      [x1-c,z1],[x0+c,z1],[x0,z1-c],[x0,z0+c]];
  }
  function hex(cx, cz, radius) {
    return Array.from({length:6}, (_,i) => {
      const angle = Math.PI / 6 + i * Math.PI / 3;
      return [cx + Math.cos(angle) * radius, cz + Math.sin(angle) * radius];
    });
  }
  function top(name, ring, y, parent, material) {
    const points = ring.map(p => [p[0],y,p[1]]);
    const faces = [];
    for (let i=1;i<ring.length-1;i++) faces.push([0,i+1,i]);
    return mesh(name,points,faces,parent,material);
  }

  Undo.initEdit({elements: [], textures: [], outliner: true, uv_mode: true});
  try {
    Project.texture_width = Project.texture_height = 512;
    texture = new Texture({name:"board_bench_albedo.png", width:512,height:512,uv_width:512,uv_height:512});
    texture.fromDataURL(canvas.toDataURL("image/png")).add(false);
    textures.push(texture);
    const root = group("board_bench_root");
    const shell = group("runtime_shell",root);
    const base = group("board_base",shell);
    const frame = group("board_frame",shell);
    const bench = group("bench_base",shell);
    const reserves = group("reserve_marks_9",shell);
    const accent = group("corner_stone_and_roots",shell);
    const preview = group("preview_hex_cells_REMOVE_FOR_RUNTIME",root);

    prism("slab_stone_chamfered",bevelRect(-half,-7.07,half,7.07,0.32),-0.60,-0.11,base,"stone");
    box("inlaid_wood_field",-half+0.20,-0.14,-6.87,half-0.20,-0.015,6.87,base,"wood");
    box("frame_left",-half,-0.22,-6.80,-half+0.31,0.035,6.80,frame,"wood");
    box("frame_right",half-0.31,-0.22,-6.80,half,0.035,6.80,frame,"wood");
    box("frame_far",-half+0.32,-0.22,-7.07,half-0.32,0.035,-6.76,frame,"wood");
    box("frame_near",-half+0.32,-0.22,6.76,half-0.32,0.035,7.07,frame,"wood");
    prism("bench_connected_stone",bevelRect(-half,7.07,half,9.37,0.26),-0.60,-0.14,bench,"stone");
    box("bench_timber_top",-half+0.15,-0.16,7.22,half-0.15,-0.015,9.22,bench,"wood");
    box("bench_edge_left",-half+0.04,-0.16,7.30,-half+0.29,0.02,9.05,bench,"warm");
    box("bench_edge_right",half-0.29,-0.16,7.30,half-0.04,0.02,9.05,bench,"warm");
    box("bench_edge_front",-half+0.30,-0.18,9.08,half-0.30,0.02,9.35,bench,"warm");

    for (let i=0;i<9;i++) {
      const x=(i-4)*1.55;
      prism("reserve_socket_"+String(i).padStart(2,"0"),hex(x,8.22,0.65),-0.04,0.005,reserves,"dark",false);
      top("reserve_inlay_"+String(i).padStart(2,"0"),hex(x,8.22,0.56),0.008,reserves,"reserve");
    }
    for (let row=0;row<8;row++) for (let col=0;col<7;col++) {
      const x=-6.019165124598851+col*pitch+(row%2 ? pitch*.5 : 0);
      const z=-5.67+row*1.62;
      const id=String(row).padStart(2,"0")+"_"+String(col).padStart(2,"0");
      prism("hex_outline_"+id,hex(x,z,1),0.0075,0.0625,preview,"dark",false);
      top("hex_surface_"+id,hex(x,z,.91),0.0925,preview,row>=4?"teal":"earth");
    }
    [-1,1].forEach((side) => {
      [-6.76,6.77,9.02].forEach((z,i) => {
        const x=side*(half-.27);
        prism("stone_corner_"+side+"_"+i,hex(x,z,.30),-.55,.045,accent,"edge");
      });
      [-3.4,3.4].forEach((z,i) => {
        const x0=side<0?-half:half-.115;
        box("side_binding_"+side+"_"+i,x0,-.53,z-.12,x0+.115,-.08,z+.12,accent,"brass");
      });
      [-6.4,6.3].forEach((z,i) => {
        const x=side*(half-.20);
        const ring=[[x-.10,z-.38],[x+.11,z-.33],[x+.17,z+.24],[x-.08,z+.36]];
        prism("low_root_"+side+"_"+i,ring,.02,.055,accent,"wood");
        top("moss_patch_"+side+"_"+i,[[x-.07,z-.29],[x+.09,z-.23],[x+.10,z+.12],[x-.05,z+.20]],
          .057,accent,"moss");
      });
    });

    const triangles=created.reduce((sum,m)=>sum+Object.values(m.faces).reduce((n,f)=>n+Math.max(0,f.vertices.length-2),0),0);
    const previewTriangles=created.filter(m=>m.parent===preview).reduce((sum,m)=>sum+Object.values(m.faces).reduce((n,f)=>n+f.vertices.length-2,0),0);
    if (triangles>1800) throw new Error("Triangle budget exceeded: "+triangles);
    const points=created.flatMap(m=>Object.values(m.vertices));
    const bounds={min:[0,1,2].map(axis=>Math.min(...points.map(p=>p[axis]))/S),
      max:[0,1,2].map(axis=>Math.max(...points.map(p=>p[axis]))/S)};
    Canvas.updateAll();
    Undo.finishEdit("Build textured low-poly board with integrated nine-slot bench",
      {elements:created,textures:textures,outliner:true,uv_mode:true});
    return {name:Project.name,meshes:created.length,triangles:triangles,
      runtime_shell_triangles:triangles-previewTriangles,preview_hex_triangles:previewTriangles,
      textures:1,atlas:[512,512],blockbench_units_per_godot_unit:S,bounds_godot:bounds,
      runtime_exclude_group:preview.name,root:root.uuid,texture:texture.uuid,
      note:"Static visual asset; gameplay bench remains the existing UI until integration."};
  } catch (error) {
    Undo.cancelEdit(true);
    throw error;
  }
})();
