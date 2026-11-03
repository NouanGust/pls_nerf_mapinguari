(() => {
  "use strict";
  const names = [
    "anhanga_root", "body", "chest", "neck", "head", "jaw", "ear_l", "ear_r", "tail",
    "fore_upper_l", "fore_lower_l", "fore_hoof_l",
    "fore_upper_r", "fore_lower_r", "fore_hoof_r",
    "hind_upper_l", "hind_lower_l", "hind_hoof_l",
    "hind_upper_r", "hind_lower_r", "hind_hoof_r"
  ];
  const groups = Object.fromEntries(names.map(name => {
    const matches = Group.all.filter(g => g.name === name);
    if (matches.length !== 1) throw new Error("Expected one rig group: " + name);
    return [name, matches[0]];
  }));
  if (Format.id !== "free" || !Format.animation_mode) {
    throw new Error("Anhangá requires the free format with animation support.");
  }
  if (typeof Animation !== "function" || typeof BoneAnimator !== "function") {
    throw new Error("Native animation classes unavailable.");
  }
  const r = 180 / Math.PI;
  const round = n => Math.round(n * 100000) / 100000;
  const smooth = t => t * t * (3 - 2 * t);
  const mix = (a, b, t) => a + (b - a) * t;
  const phase = (time, duration, offset = 0) => ((time / duration + offset) % 1 + 1) % 1;
  const legs = ["fore_l", "fore_r", "hind_l", "hind_r"].map(id => {
    const [type, side] = id.split("_");
    const upper = groups[type + "_upper_" + side];
    const lower = groups[type + "_lower_" + side];
    const hoof = groups[type + "_hoof_" + side];
    if (lower.parent !== upper || hoof.parent !== lower || upper.parent !== groups.body) {
      throw new Error("Unexpected leg hierarchy: " + id);
    }
    if (Math.abs(upper.origin[0] - lower.origin[0]) > 0.001 ||
        Math.abs(lower.origin[0] - hoof.origin[0]) > 0.001 ||
        [upper, lower, hoof].some(g => g.rotation.some(v => Math.abs(v) > 0.001))) {
      throw new Error("Leg IK requires neutral, coplanar YZ pivots: " + id);
    }
    const uy = lower.origin[1] - upper.origin[1];
    const uz = lower.origin[2] - upper.origin[2];
    const ly = hoof.origin[1] - lower.origin[1];
    const lz = hoof.origin[2] - lower.origin[2];
    return {
      id, upper, lower, hoof, a: Math.hypot(uy, uz), b: Math.hypot(ly, lz),
      thetaUpper: Math.atan2(uz, -uy), thetaLower: Math.atan2(lz, -ly),
      restY: hoof.origin[1] - upper.origin[1],
      restZ: hoof.origin[2] - upper.origin[2],
      bend: type === "fore" ? -1 : 1
    };
  });
  const clips = [];
  const diagnostic = { unitsPerMetre: 16, walkMetresPerSecond: 2, ikClamps: 0 };
  function makeClip(name, length, loop) {
    const tracks = {};
    for (const bone of names) {
      tracks[bone] = {
        rotation: [[0, [0, 0, 0]], [length, [0, 0, 0]]],
        position: [[0, [0, 0, 0]], [length, [0, 0, 0]]]
      };
    }
    const clip = { name, length, loop: loop ? "loop" : "once", tracks };
    clips.push(clip);
    return clip;
  }
  function sample(clip, bone, channel, evaluate, subdivisions) {
    const count = subdivisions || Math.round(clip.length * 60);
    clip.tracks[bone][channel] = Array.from({ length: count + 1 }, (_, i) => {
      const time = i === count ? clip.length : i * clip.length / count;
      return [round(time), evaluate(time).map(round)];
    });
  }
  function authored(clip, bone, channel, points) {
    clip.tracks[bone][channel] = points.map(([time, value]) => [time, value]);
  }
  function interpolate(points, time) {
    if (time <= points[0][0]) return points[0][1];
    for (let i = 1; i < points.length; i++) {
      if (time <= points[i][0]) {
        const p = points[i - 1], n = points[i];
        return mix(p[1], n[1], smooth((time - p[0]) / (n[0] - p[0])));
      }
    }
    return points[points.length - 1][1];
  }
  function rotationCurve(clip, bone, axis, points) {
    sample(clip, bone, "rotation", time => {
      const value = [0, 0, 0];
      value[axis] = interpolate(points, time);
      return value;
    });
  }
  function solveLeg(leg, bodyY, zOffset, lift) {
    const y = leg.restY - bodyY + lift;
    const z = leg.restZ + zOffset;
    const distance = Math.hypot(y, z);
    const minimum = Math.abs(leg.a - leg.b) + 0.001;
    const maximum = leg.a + leg.b - 0.001;
    const d = Math.max(minimum, Math.min(maximum, distance));
    if (Math.abs(distance - d) > 0.005) diagnostic.ikClamps++;
    const theta = Math.atan2(z, -y);
    const elbow = leg.bend * Math.acos(Math.max(-1, Math.min(1,
      (d * d - leg.a * leg.a - leg.b * leg.b) / (2 * leg.a * leg.b))));
    const shoulder = theta - Math.atan2(leg.b * Math.sin(elbow),
      leg.a + leg.b * Math.cos(elbow));
    const upper = -(shoulder - leg.thetaUpper) * r;
    const lower = -(elbow - (leg.thetaLower - leg.thetaUpper)) * r;
    return { upper, lower, hoof: -upper - lower };
  }
  function animateLegs(clip, targets) {
    for (const leg of legs) {
      for (const joint of ["upper", "lower", "hoof"]) {
        sample(clip, leg[joint].name, "rotation", t => {
          const target = targets(leg, t);
          return [solveLeg(leg, target.bodyY, target.z, target.lift)[joint], 0, 0];
        });
      }
    }
  }
  const idle = makeClip("Idle", 2, true);
  sample(idle, "chest", "rotation", t => [0.55 * (1 - Math.cos(t * Math.PI)), 0, 0]);
  sample(idle, "neck", "rotation", t => [-0.45 * (1 - Math.cos(t * Math.PI)), 0, 0]);
  sample(idle, "head", "rotation", t => [0, 1.5 * Math.sin(t * Math.PI), 0]);
  sample(idle, "tail", "rotation", t => [0, 4 * Math.sin(t * Math.PI), 0]);
  rotationCurve(idle, "ear_l", 2, [[0, 0], [0.40, 0], [0.57, -12], [0.8, 2], [1.05, 0], [2, 0]]);
  rotationCurve(idle, "ear_r", 2, [[0, 0], [1.05, 0], [1.22, 10], [1.52, 0], [2, 0]]);

  const walk = makeClip("Walk", 0.8, true);
  const stride = diagnostic.walkMetresPerSecond * diagnostic.unitsPerMetre * walk.length;
  const stance = 0.6;
  function footPath(p) {
    const reach = stride * stance / 2;
    if (p < stance) return { z: reach - stride * p, lift: 0 };
    const u = (p - stance) / (1 - stance);
    const h00 = 2 * u ** 3 - 3 * u ** 2 + 1;
    const h10 = u ** 3 - 2 * u ** 2 + u;
    const h01 = -2 * u ** 3 + 3 * u ** 2;
    const h11 = u ** 3 - u ** 2;
    const derivative = -stride * (1 - stance);
    return {
      z: h00 * -reach + h10 * derivative + h01 * reach + h11 * derivative,
      lift: 2.4 * Math.sin(Math.PI * u) ** 2
    };
  }
  const maxReach = Math.max(...Array.from({ length: 1001 }, (_, i) =>
    Math.abs(footPath(i / 1000).z)));
  const requiredLowering = Math.min(...legs.map(leg => {
    const safeLength = (leg.a + leg.b) * 0.985;
    const z = maxReach + Math.abs(leg.restZ);
    if (z >= safeLength) throw new Error("Walk stride exceeds leg reach: " + leg.id);
    return Math.sqrt(safeLength * safeLength - z * z) + leg.restY - 0.15;
  }), -0.4);
  diagnostic.walkBodyOffset = round(requiredLowering);
  diagnostic.walkStride = stride;
  diagnostic.walkStanceFraction = stance;
  const walkBodyY = t => requiredLowering - 0.12 * (1 - Math.cos(t / walk.length * Math.PI * 8));
  sample(walk, "body", "position", t => [0, walkBodyY(t), 0], 48);
  const offsets = { hind_l: 0, fore_l: 0.75, hind_r: 0.5, fore_r: 0.25 };
  animateLegs(walk, (leg, t) => ({
    ...footPath(phase(t, walk.length, offsets[leg.id])), bodyY: walkBodyY(t)
  }));
  sample(walk, "chest", "rotation", t => [0.5 * Math.sin(4 * Math.PI * t / walk.length), 0, 0], 48);
  sample(walk, "neck", "rotation", t => [-0.5 * Math.sin(4 * Math.PI * t / walk.length), 0, 0], 48);
  sample(walk, "head", "rotation", t => [0, 0.6 * Math.sin(2 * Math.PI * t / walk.length), 0], 48);
  sample(walk, "tail", "rotation", t => [0, 7 * Math.sin(2 * Math.PI * t / walk.length), 0], 48);

  const attack = makeClip("Punch_Jab", 0.7, false);
  rotationCurve(attack, "neck", 0, [[0, 0], [0.08, -5], [0.2, 27], [0.28, 23], [0.46, 6], [0.7, 0]]);
  rotationCurve(attack, "head", 0, [[0, 0], [0.08, 4], [0.2, 14], [0.30, 8], [0.52, -3], [0.7, 0]]);
  rotationCurve(attack, "chest", 0, [[0, 0], [0.08, -1], [0.2, 4], [0.32, 3], [0.7, 0]]);
  rotationCurve(attack, "ear_l", 2, [[0, 0], [0.14, -15], [0.32, -15], [0.7, 0]]);
  rotationCurve(attack, "ear_r", 2, [[0, 0], [0.14, 15], [0.32, 15], [0.7, 0]]);
  rotationCurve(attack, "tail", 0, [[0, 0], [0.18, -10], [0.35, -6], [0.7, 0]]);

  const roar = makeClip("Spell_Simple_Shoot", 0.5, false);
  rotationCurve(roar, "neck", 0, [[0, 0], [0.1, -12], [0.2, -15], [0.33, -11], [0.5, 0]]);
  rotationCurve(roar, "head", 0, [[0, 0], [0.1, -7], [0.20, -9], [0.33, -6], [0.5, 0]]);
  rotationCurve(roar, "jaw", 0, [[0, 0], [0.1, 21], [0.2, 25], [0.33, 20], [0.5, 0]]);
  rotationCurve(roar, "chest", 0, [[0, 0], [0.1, -1], [0.2, -1.6], [0.33, -1], [0.5, 0]]);
  rotationCurve(roar, "ear_l", 2, [[0, 0], [0.1, -8], [0.33, -8], [0.5, 0]]);
  rotationCurve(roar, "ear_r", 2, [[0, 0], [0.1, 8], [0.33, 8], [0.5, 0]]);

  const hit = makeClip("Hit", 0.2, false);
  rotationCurve(hit, "neck", 0, [[0, 0], [1 / 15, -8], [0.12, -4], [0.2, 0]]);
  rotationCurve(hit, "head", 0, [[0, 0], [1 / 15, -6], [0.12, -2], [0.2, 0]]);
  rotationCurve(hit, "chest", 0, [[0, 0], [1 / 15, -1.5], [0.2, 0]]);
  rotationCurve(hit, "ear_l", 2, [[0, 0], [1 / 15, -15], [0.2, 0]]);
  rotationCurve(hit, "ear_r", 2, [[0, 0], [1 / 15, 15], [0.2, 0]]);

  const death = makeClip("Death01", 1.2, false);
  const deathDrop = Math.min(6.5, ...legs.map(leg => -leg.restY * 0.55));
  const deathY = t => interpolate([[0, 0], [0.2, -0.8],
    [0.47, -deathDrop * 0.75], [0.8, -deathDrop],
    [1.07, -deathDrop + 0.15], [1.2, -deathDrop + 0.15]], t);
  diagnostic.deathBodyDrop = deathDrop;
  sample(death, "body", "position", t => [0, deathY(t), 0]);
  animateLegs(death, (leg, t) => ({ bodyY: deathY(t), z: 0, lift: 0 }));
  rotationCurve(death, "neck", 0, [[0, 0], [0.2, 6], [0.47, 20], [0.8, 32], [1.07, 29], [1.2, 29]]);
  rotationCurve(death, "head", 0, [[0, 0], [0.2, -3], [0.47, -12], [0.8, -19], [1.07, -17], [1.2, -17]]);
  rotationCurve(death, "ear_l", 2, [[0, 0], [0.2, -8], [0.8, -22], [1.2, -22]]);
  rotationCurve(death, "ear_r", 2, [[0, 0], [0.2, 8], [0.8, 22], [1.2, 22]]);
  rotationCurve(death, "tail", 0, [[0, 0], [0.47, 9], [0.8, 15], [1.2, 15]]);

  const targetNames = new Set(clips.map(c => c.name));
  const existing = Animation.all.filter(a => targetNames.has(a.name));
  if (existing.some(a => !Object.keys(a.animators).every(id =>
    id === "effects" || names.some(name => groups[name].uuid === id)))) {
    throw new Error("Existing named clips affect another rig; refusing replacement.");
  }
  for (const clip of clips) {
    for (const [bone, tracks] of Object.entries(clip.tracks)) {
      for (const [channel, keys] of Object.entries(tracks)) {
        if (!keys.every(([time, value], i) =>
          Number.isFinite(time) && time >= 0 && time <= clip.length &&
          (!i || time > keys[i - 1][0]) && value.every(Number.isFinite))) {
          throw new Error("Invalid track " + clip.name + "/" + bone + "/" + channel);
        }
      }
    }
  }
  if (diagnostic.ikClamps > 12) {
    throw new Error("Unexpected unreachable IK targets: " + diagnostic.ikClamps);
  }
  const created = [];
  Undo.initEdit({ animations: existing });
  try {
    existing.forEach(a => a.remove(false));
    for (const clip of clips) {
      const animation = new Animation({
        name: clip.name, length: clip.length, loop: clip.loop, snapping: 60
      }).add(false);
      created.push(animation);
      for (const [bone, tracks] of Object.entries(clip.tracks)) {
        const animator = animation.getBoneAnimator(groups[bone]);
        for (const [channel, keys] of Object.entries(tracks)) {
          for (const [time, value] of keys) {
            animator.addKeyframe({
              channel, time, interpolation: "linear",
              data_points: [{ x: value[0], y: value[1], z: value[2] }]
            });
          }
        }
      }
      animation.setLength(clip.length);
    }
    Undo.finishEdit("Create six Anhangá alpha animations", { animations: created });
  } catch (error) {
    Undo.cancelEdit();
    throw error;
  }
  created[0].select();
  Timeline.setTime(0);
  Animator.preview();
  return JSON.stringify({
    animations: created.map(a => ({
      name: a.name, uuid: a.uuid, length: a.length, loop: a.loop,
      keyframes: Object.values(a.animators).reduce((n, b) => n + b.keyframes.length, 0)
    })),
    diagnostic,
    verification: "Native authoring completed. Inspect sampled poses and exported motion before delivery."
  });
})()
