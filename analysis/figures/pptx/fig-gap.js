// The feasibility frontier and the gap, observed and projected, for one country (power and industry).
// One editable slide at the printed size: every series, band, label and leader line is a named native
// shape (objectName). The data come from R (fig-doc.R docGapData -> gap-data.json); no value is printed.
//   node fig-gap.js <gap-data.json> <out.pptx>
const pptxgen = require("pptxgenjs");
const { S, C, figureDeck, txt } = require("./style");

const D = require(require("path").resolve(process.argv[2] || "gap-data.json"));
const OUT = process.argv[3] || "fig-gap.pptx";
const H = 3.95;
const pres = figureDeck(pptxgen, "FIG_GAP", H);
pres.title = "Feasibility frontier and the gap";
const s = pres.addSlide();
s.background = { color: "FFFFFF" };

// ---------- geometry (inches) ----------
const X0 = 0.62, W1 = 1.5, XE = 6.2, YT = 0.86, YB = 3.12, U = (YB - YT) / 10;
const xt = (t) => (t <= 2023 ? X0 + ((t - 2001) / 22) * W1 : X0 + W1 + ((t - 2023) / 77) * (XE - X0 - W1));
const yv = (v) => YB - v * U;

// ---------- series ----------
const hist = D.hist.year.map((t, i) => ({ t, S: D.hist.S[i], Ss: D.hist.Sstar[i] }));
const a = hist[hist.length - 1];
const proj = [{ t: 2023, S: a.S, Ss: a.Ss, Sk: a.S }].concat(
  D.proj.year.map((t, i) => ({ t, S: D.proj.S[i], Ss: D.proj.Sstar[i], Sk: D.proj.Sk[i] })));
const all = hist.concat(proj.slice(1));
const at = (t) => proj.reduce((b, p) => (Math.abs(p.t - t) < Math.abs(b.t - t) ? p : b));

// ---------- helpers ----------
const poly = (name, pts, opt, close = false) => {
  const xs = pts.map((p) => p[0]), ys = pts.map((p) => p[1]);
  const x = Math.min(...xs), y = Math.min(...ys), w = Math.max(Math.max(...xs) - x, 0.01), h = Math.max(Math.max(...ys) - y, 0.01);
  const points = pts.map((p) => ({ x: p[0] - x, y: p[1] - y }));
  if (close) points.push({ close: true });
  s.addShape(pres.shapes.CUSTOM_GEOMETRY, Object.assign({ x, y, w, h, points, objectName: name }, opt));
};
const seg = (name, x1, y1, x2, y2, l) => s.addShape(pres.shapes.LINE, {
  objectName: name, x: Math.min(x1, x2), y: Math.min(y1, y2), w: Math.max(Math.abs(x2 - x1), 0.001), h: Math.max(Math.abs(y2 - y1), 0.001),
  flipH: x2 < x1, flipV: y2 < y1, line: l });
const label = (name, t, o) => s.addText(t, txt(Object.assign({ objectName: name }, o)));
// a callout: text box plus an elbow leader (horizontal from the text, then vertical to the point)
const callout = (name, t, tx, ty, tw, th, px, py, color, o = {}) => {
  label(name, t, Object.assign({ x: tx, y: ty, w: tw, h: th, fontSize: S.size.small, color: o.textColor ?? C.ink, valign: "middle" }, o));
  const lx = o.leaderFromRight ? tx + tw + 0.04 : tx - 0.04, ly = ty + th / 2;
  seg(name + " leader a", lx, ly, px, ly, { color, width: 0.75 });
  seg(name + " leader b", px, ly, px, py, { color, width: 0.75 });
};

// ---------- frame: projection background, grid, axes ----------
s.addShape(pres.shapes.RECTANGLE, { objectName: "Projection background", x: xt(2023), y: YT, w: XE - xt(2023), h: YB - YT,
  fill: { color: C.panel, transparency: 30 }, line: { color: C.panel, width: 0 } });
for (let v = 0; v <= 10; v += 2) {
  seg(`Grid ${v}`, X0, yv(v), XE, yv(v), { color: C.grid, width: v === 0 ? 1 : 0.5 });
  label(`y label ${v}`, String(v), { x: X0 - 0.3, y: yv(v) - 0.09, w: 0.22, h: 0.18, fontSize: S.size.small, color: C.muted, align: "right", valign: "middle" });
}
label("y title", "CAPMF stringency (0–10)", { x: X0 - 1.32, y: yv(5) - 0.09, w: 1.7, h: 0.18, fontSize: S.size.small, color: C.muted,
  align: "center", valign: "middle", rotate: 270 });
for (const t of [2001, 2011, 2023, 2040, 2060, 2080, 2100]) {
  label(`x label ${t}`, String(t), { x: xt(t) - 0.25, y: YB + 0.05, w: 0.5, h: 0.18, fontSize: S.size.small,
    color: t === 2023 ? C.ink : C.muted, bold: t === 2023, align: "center" });
}
seg("Divider 2023", xt(2023), YT - 0.42, xt(2023), YB, { color: C.muted, width: 0.6, dashType: "dash" });
label("Header observed", "Observed\n2001–2023", { x: xt(2023) - 0.95, y: YT - 0.44, w: 0.88, h: 0.38, fontSize: S.size.body, bold: true, color: C.deep, align: "right" });
label("Header projected", "Projected\n2023–2100", { x: xt(2023) + 0.07, y: YT - 0.44, w: 0.9, h: 0.38, fontSize: S.size.body, bold: true, color: C.deep });
label("Axis note", "time axis: 2001–2023 drawn at a larger scale than 2023–2100", { x: XE - 3.0, y: YB + 0.24, w: 3.0, h: 0.16,
  fontSize: S.size.tiny, italic: true, color: C.muted, align: "right" });
// 'Preliminary results' is set above the figure by the document build (D3.3 build.py), not drawn here

// ---------- areas ----------
poly("Area below S", all.map((p) => [xt(p.t), yv(p.S)]).concat([[XE, YB], [X0, YB]]),
  { fill: { color: C.stringency, transparency: 88 }, line: { type: "none" } }, true);
poly("Gap band S to S*", all.map((p) => [xt(p.t), yv(p.Ss)]).concat(all.slice().reverse().map((p) => [xt(p.t), yv(p.S)])),
  { fill: { color: C.deep, transparency: 82 }, line: { type: "none" } }, true);
poly("Gap reduced by scenario assumption", proj.map((p) => [xt(p.t), yv(p.Sk)]).concat(proj.slice().reverse().map((p) => [xt(p.t), yv(p.S)])),
  { fill: { color: C.coral, transparency: 80 }, line: { type: "none" } }, true);

// ---------- lines ----------
poly("Ceiling S* (estimated)", hist.map((p) => [xt(p.t), yv(p.Ss)]), { line: { color: C.deep, width: 2 } });
poly("Observed S", hist.map((p) => [xt(p.t), yv(p.S)]), { line: { color: C.stringency, width: 2 } });
poly("Ceiling S* projected", proj.map((p) => [xt(p.t), yv(p.Ss)]), { line: { color: C.deep, width: 2, dashType: "dash" } });
poly("S projected endogenously", proj.map((p) => [xt(p.t), yv(p.S)]), { line: { color: C.stringency, width: 2, dashType: "dash" } });
poly("S projected with scenario assumption", proj.map((p) => [xt(p.t), yv(p.Sk)]), { line: { color: C.coral, width: 1.75, dashType: "sysDot" } });

// ---------- 2023 points and the gap ----------
for (const [nm, v, c] of [["S*", a.Ss, C.deep], ["S", a.S, C.stringency]]) {
  s.addShape(pres.shapes.OVAL, { objectName: `Point ${nm} 2023`, x: xt(2023) - 0.05, y: yv(v) - 0.05, w: 0.1, h: 0.1,
    fill: { color: c }, line: { color: "FFFFFF", width: 0.75 } });
}
seg("Gap arrow 2023", xt(2023) + 0.1, yv(a.Ss) + 0.06, xt(2023) + 0.1, yv(a.S) - 0.06,
  { color: C.deep, width: 1.25, beginArrowType: "triangle", endArrowType: "triangle" });
label("Gap label", "gap", { x: xt(2023) + 0.16, y: (yv(a.Ss) + yv(a.S)) / 2 - 0.09, w: 0.4, h: 0.18, fontSize: S.size.body, bold: true, color: C.deep });

// ---------- projected gaps ----------
const pA = at(2035), pB = at(2050);
seg("Gap arrow endogenous", xt(pA.t), yv(pA.Ss) + 0.015, xt(pA.t), yv(pA.S) - 0.015,
  { color: C.deep, width: 1, beginArrowType: "triangle", endArrowType: "triangle" });
seg("Gap arrow scenario", xt(pB.t), yv(pB.Ss) + 0.015, xt(pB.t), yv(pB.Sk) - 0.015,
  { color: C.coral, width: 1, beginArrowType: "triangle", endArrowType: "triangle" });

// ---------- callouts ----------
const h1 = hist.find((p) => p.t === 2019) || hist[18], h2 = hist.find((p) => p.t === 2008) || hist[7];
callout("Callout ceiling", "Estimated ceiling", X0 + 0.04, yv(7.6) - 0.09, 0.85, 0.18, xt(h1.t), yv(h1.Ss), C.deep,
  { textColor: C.deep, leaderFromRight: true });
callout("Callout observed", "Observed CAPMF", xt(2010), yv(0.9) - 0.09, 0.85, 0.18, xt(h2.t), yv(h2.S), C.stringency,
  { textColor: C.stringency });
callout("Callout endogenous", "Projection that keeps the 2023 position relative to the ceiling (logistic scale): the ceiling moves with the energy system and the SSP institutions",
  xt(pA.t) + 0.12, yv(2.6) - 0.17, 2.6, 0.34, xt(pA.t), yv((pA.S + pA.Ss) / 2), C.deep);
callout("Callout scenario", "Projection with an additional, declared gap reduction (scenario assumption)",
  xt(pB.t) + 0.12, yv(5.1) - 0.17, 2.3, 0.34, xt(pB.t), yv((pB.Sk + pB.Ss) / 2), C.coral);
label("End label ceiling", "Ceiling", { x: XE - 0.62, y: yv(proj[proj.length - 1].Ss) - 0.24, w: 0.58, h: 0.18, fontSize: S.size.small,
  color: C.deep, align: "right" });

// ---------- legend ----------
const LY = H - 0.22;
const leg = [["solid", "observed / fitted", { color: C.ink, width: 1.75 }, 1.35],
  ["dash", "projected with the drivers", { color: C.ink, width: 1.75, dashType: "dash" }, 1.7],
  ["dot", "projected with an additional scenario assumption", { color: C.coral, width: 1.75, dashType: "sysDot" }, 2.95]];
let lx = X0;
leg.forEach(([k, t, l, w]) => {
  seg(`Legend ${k}`, lx, LY, lx + 0.3, LY, l);
  label(`Legend ${k} label`, t, { x: lx + 0.36, y: LY - 0.09, w: w - 0.4, h: 0.18, fontSize: S.size.small, valign: "middle" });
  lx += w;
});

pres.writeFile({ fileName: OUT }).then((f) => console.log("wrote " + f));
