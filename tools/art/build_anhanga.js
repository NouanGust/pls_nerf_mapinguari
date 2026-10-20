(() => {
  if (!Project || Format.id !== 'free') throw new Error('Expected empty Generic Model');
  if (Outliner.elements.length) throw new Error('Refusing to replace existing geometry');
  const made = [], groups = {};
  Undo.initEdit({elements: made, outliner: true});
  Project.texture_width = Project.texture_height = 256;
  function group(name, origin, parent) {
    const g = new Group({name, origin});
    if (parent) g.addTo(groups[parent]);
    g.init(); groups[name] = g; return g;
  }
  group('anhanga_root', [0,0,0]);
  group('body', [0,14,0], 'anhanga_root');
  group('chest', [0,15,4], 'body');
  group('neck', [0,17,5], 'chest');
  group('head', [0,22,8], 'neck');
  group('jaw', [0,21.4,9], 'head');
  group('ear_l', [1.9,24,7.6], 'head');
  group('ear_r', [-1.9,24,7.6], 'head');
  group('tail', [0,15,-7], 'body');
  const vec = a => new THREE.Vector3(...a);
  function mesh(name, vertices, faces, parent) {
    const m = new Mesh({name, vertices:{}, origin:[0,0,0], color:0});
    const keys = m.addVertices(...vertices);
    for (const face of faces) {
      const f = new MeshFace(m, {vertices:face.map(i=>keys[i])});
      const center = face.reduce((v,i)=>v.add(vec(vertices[i])),new THREE.Vector3()).divideScalar(face.length);
      const all = vertices.reduce((v,p)=>v.add(vec(p)),new THREE.Vector3()).divideScalar(vertices.length);
      if (vec(f.getNormal()).dot(center.sub(all)) < 0) f.invert();
      m.addFaces(f);
    }
    m.addTo(groups[parent]).init(); made.push(m); return m;
  }
  function ellipsoid(name, c, r, parent, seg=8, rings=3) {
    const vs=[[c[0],c[1]-r[1],c[2]]], fs=[];
    for(let j=1;j<=rings;j++){
      const phi=-Math.PI/2+j*Math.PI/(rings+1);
      for(let i=0;i<seg;i++){
        const t=2*Math.PI*i/seg;
        vs.push([c[0]+Math.cos(t)*Math.cos(phi)*r[0],c[1]+Math.sin(phi)*r[1],c[2]+Math.sin(t)*Math.cos(phi)*r[2]]);
      }
    }
    vs.push([c[0],c[1]+r[1],c[2]]);
    for(let i=0;i<seg;i++){
      const n=(i+1)%seg;
      fs.push([0,1+n,1+i]);
      for(let j=0;j<rings-1;j++) fs.push([1+j*seg+i,1+j*seg+n,1+(j+1)*seg+n,1+(j+1)*seg+i]);
      fs.push([vs.length-1,1+(rings-1)*seg+i,1+(rings-1)*seg+n]);
    }
    return mesh(name,vs,fs,parent);
  }
  function branch(name, points, radii, parent, seg=5) {
    const vs=[],fs=[];
    for(let j=0;j<points.length;j++){
      const p=vec(points[j]);
      const tangent=vec(points[Math.min(j+1,points.length-1)]).sub(vec(points[Math.max(j-1,0)])).normalize();
      const side=new THREE.Vector3(0,0,1);
      if(Math.abs(tangent.dot(side))>.94) side.set(1,0,0);
      const u=new THREE.Vector3().crossVectors(tangent,side).normalize();
      const v=new THREE.Vector3().crossVectors(tangent,u).normalize();
      for(let i=0;i<seg;i++) vs.push(p.clone().addScaledVector(u,Math.cos(i*2*Math.PI/seg)*radii[j]).addScaledVector(v,Math.sin(i*2*Math.PI/seg)*radii[j]).toArray());
    }
    // Triangulated end caps keep every face supported by Blockbench/glTF.
    for(let i=1;i<seg-1;i++) fs.push([0,i+1,i]);
    for(let j=0;j<points.length-1;j++) for(let i=0;i<seg;i++) fs.push([j*seg+i,j*seg+(i+1)%seg,(j+1)*seg+(i+1)%seg,(j+1)*seg+i]);
    const b=(points.length-1)*seg;
    for(let i=1;i<seg-1;i++) fs.push([b,b+i,b+i+1]);
    return mesh(name,vs,fs,parent);
  }
  ellipsoid('fur_torso',[0,14,-1],[3.25,3.9,7.4],'body',10,3);
  ellipsoid('fur_chest',[0,15.1,4.1],[3.1,4.6,3.7],'chest',8,3);
  branch('fur_neck',[[0,16,4.4],[0,20,6.2],[0,23,8]],[2.65,2.15,1.6],'neck',8);
  ellipsoid('fur_head',[0,23,9],[2.25,2.55,3.3],'head',8,3);
  branch('fur_muzzle',[[0,22.6,10],[0,21.8,12.7],[0,21.7,13.4]],[1.7,1.15,.85],'head',6);
  ellipsoid('nose_velvet',[0,22,13.15],[1.12,.66,.7],'head',6,2);
  ellipsoid('fur_jaw',[0,20.85,11.3],[1.12,.6,2.05],'jaw',6,2);
  ellipsoid('mouth_lower',[0,21.35,11.65],[.85,.16,1.55],'jaw',6,1);
  branch('fur_tail',[[0,15.4,-7],[0,16.7,-9],[0,18,-10]],[.85,.65,.10],'tail',5);
  for(const [side,s] of [['l',1],['r',-1]]) {
    // Leaf-shaped ears, thicker at the base, with inset colored inner surface.
    const ear=[[s*1.7,24,7.7],[s*4.7,26,7.5],[s*6.0,26.2,7.6],[s*4.1,23.6,8.2],[s*3.6,24.9,8.65],[s*3.6,24.9,7.3]];
    mesh('fur_ear_'+side,ear,[[0,1,4],[1,2,4],[2,3,4],[3,0,4],[0,5,1],[1,5,2],[2,5,3],[3,5,0]],'ear_'+side);
    mesh('inner_ear_'+side,[[s*2.4,24.2,8.18],[s*5.3,25.8,7.95],[s*4.0,24.25,8.45]],[[0,1,2]],'ear_'+side);
    ellipsoid('eye_socket_'+side,[s*1.92,23.55,10.15],[.42,.65,.68],'head',6,2);
    ellipsoid('eye_ember_'+side,[s*2.18,23.6,10.25],[.16,.35,.39],'head',6,2);
    ellipsoid('eye_core_'+side,[s*2.27,23.68,10.34],[.08,.18,.18],'head',5,1);
    const p = arr => arr.map(a=>[s*a[0],a[1],a[2]]);
    branch('antler_main_'+side,p([[1.35,24.7,7.5],[2.1,27,7],[4.9,28.3,6.7],[7.2,30.5,6.4],[8,33,6.5]]),[.75,.65,.49,.28,.035],'head',5);
    branch('antler_brow_'+side,p([[2.0,26.5,7.1],[2.8,28.4,9.3],[2.7,30.5,9.7]]),[.43,.26,.025],'head',5);
    branch('antler_inner_'+side,p([[4.5,28.2,6.8],[4.6,30.2,7.8],[4.1,32,8.3]]),[.4,.21,.025],'head',5);
    branch('antler_outer_'+side,p([[6.8,30,6.5],[9.3,30.4,5.6],[10.1,32.4,5.3]]),[.33,.18,.025],'head',5);
    for(const kind of ['fore','hind']) {
      const front=kind==='fore', x=s*2.15;
      const top=[x,front?14:14.2,front?4:-5.2];
      const knee=[x,front?7.8:9.5,front?4.3:-3.7];
      const ankle=[x,2.2,front?4.5:-6.0];
      const hoof=[x,.6,front?5.0:-5.5];
      group(kind+'_upper_'+side,top,'body');
      group(kind+'_lower_'+side,knee,kind+'_upper_'+side);
      group(kind+'_hoof_'+side,ankle,kind+'_lower_'+side);
      branch('fur_'+kind+'_upper_'+side,[top,knee],[front?1.15:1.55,front?.63:.8],kind+'_upper_'+side,6);
      branch('fur_'+kind+'_lower_'+side,[knee,ankle],[front?.65:.8,.43],kind+'_lower_'+side,5);
      branch('fur_'+kind+'_pastern_'+side,[ankle,[hoof[0],.9,hoof[2]]],[.46,.55],kind+'_hoof_'+side,5);
      // Cloven hoof halves: strong dark silhouette, flat contact at ground.
      for(let half=-1;half<=1;half+=2){
        const cx=x+half*.30, z=hoof[2];
        mesh('hoof_'+kind+'_'+side+'_'+half,[[cx-.27,0,z-.6],[cx+.27,0,z-.6],[cx+.27,0,z+.8],[cx-.27,0,z+.8],[cx-.24,1.25,z-.4],[cx+.24,1.25,z-.4],[cx+.26,.8,z+.65],[cx-.26,.8,z+.65]],[[0,3,2,1],[4,5,6,7],[0,1,5,4],[1,2,6,5],[2,3,7,6],[3,0,4,7]],kind+'_hoof_'+side);
      }
    }
  }
  // Small frontal spirit mark, geometry separated to retain color at distance.
  mesh('mark_forehead',[[0,25.1,10.45],[.32,24.35,11.05],[0,23.6,11.45],[-.32,24.35,11.05]],[[0,1,2],[0,2,3]],'head');
  Canvas.updateAll();
  Undo.finishEdit('Model Anhangá low poly', {elements:made,outliner:true});
  const tris=made.reduce((n,m)=>n+Object.values(m.faces).reduce((a,f)=>a+Math.max(0,f.vertices.length-2),0),0);
  return {project:Project.uuid,meshes:made.length,groups:Object.keys(groups).length,triangles:tris};
})()
