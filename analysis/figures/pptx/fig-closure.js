// How a closure works: the price one region is allowed (left) and what gives in response (right).
//   node fig-closure.js <price|budget> <out.pptx>
// One editable slide at the printed size: every curve, band, arrow and label is a named native shape (objectName).
// A schematic, no data: the curves are stylised (docs/SCENARIOS.md 1.2, COUPLING.md; P = min(A, Pref + φ·max(A − Pref, 0))).
const pptxgen = require("pptxgenjs");
const { S, C, figureDeck, txt } = require("./style");

const CL = process.argv[2] === "budget" ? "budget" : "price";
const OUT = process.argv[3] || `fig-closure-${CL}.pptx`;
const H = 3.55;
const pres = figureDeck(pptxgen, "FIG_CLOSURE", H);
pres.title = CL === "price" ? "Hold the price" : "Hold the budget";
const s = pres.addSlide();
s.background = { color: "FFFFFF" };

// ---------- helpers ----------
const label = (name, t, o) => s.addText(t, txt(Object.assign({ objectName: name }, o)));
const seg = (name, x1, y1, x2, y2, l) => s.addShape(pres.shapes.LINE, {
  objectName: name, x: Math.min(x1, x2), y: Math.min(y1, y2), w: Math.max(Math.abs(x2 - x1), 0.001), h: Math.max(Math.abs(y2 - y1), 0.001),
  flipH: x2 < x1, flipV: y2 < y1, line: l });
const poly = (name, pts, opt, close = false) => {
  const xs = pts.map((p) => p[0]), ys = pts.map((p) => p[1]);
  const x = Math.min(...xs), y = Math.min(...ys), w = Math.max(Math.max(...xs) - x, 0.01), h = Math.max(Math.max(...ys) - y, 0.01);
  const points = pts.map((p) => ({ x: p[0] - x, y: p[1] - y }));
  if (close) points.push({ close: true });
  s.addShape(pres.shapes.CUSTOM_GEOMETRY, Object.assign({ x, y, w, h, points, objectName: name }, opt));
};
const box = (name, x, y, w, h, o = {}) => s.addShape(pres.shapes.ROUNDED_RECTANGLE, {
  objectName: name, x, y, w, h, rectRadius: o.r ?? 0.05,
  fill: { color: o.fill ?? C.panel }, line: { color: o.line ?? C.frame, width: o.lw ?? 0.75, dashType: o.dash ?? "solid" } });
const badge = (name, n, x, y) => {
  s.addShape(pres.shapes.OVAL, { objectName: name + " badge", x, y, w: 0.22, h: 0.22, fill: { color: C.deep }, line: { color: C.deep, width: 0 } });
  label(name + " number", String(n), { x, y, w: 0.22, h: 0.22, fontSize: S.size.small, bold: true, color: "FFFFFF", align: "center", valign: "middle" });
};

// ---------- left: the price one region may charge ----------
const X0 = 0.45, XE = 3.45, YT = 0.55, YB = 2.75;
const xt = (t) => X0 + ((t - 2025) / 75) * (XE - X0);
const yv = (v) => YB - v * (YB - YT);                       // v in [0, 1] of the panel height
const T = [2025, 2030, 2040, 2050, 2060, 2070, 2080, 2090, 2100];
const A = (t) => 0.06 + 0.62 * Math.pow((t - 2025) / 75, 0.85);            // the anchor, cost-optimal
const A2 = (t) => A(t) * (1 + 0.24 * Math.min(1, (t - 2025) / 25));        // the raised anchor (hold the budget)
const R = (t) => 0.06 + 0.12 * ((t - 2025) / 75);                          // current policies, Pref
const phi = 0.55;
const Pc = (t, a) => R(t) + phi * Math.max(a(t) - R(t), 0);               // the capped region's price
badge("Left", 1, 0.04, 0.08);
label("Left title", "The price one region may charge", { x: 0.32, y: 0.06, w: 3.1, h: 0.26, fontSize: S.size.title, bold: true, color: C.deep, valign: "middle" });
seg("Left y axis", X0, YT - 0.05, X0, YB, { color: C.muted, width: 0.75 });
seg("Left x axis", X0, YB, XE, YB, { color: C.muted, width: 0.75 });
label("Left y title", "carbon price", { x: X0 - 0.42, y: yv(0.5) - 0.09, w: 0.62, h: 0.18, fontSize: S.size.small, color: C.muted, rotate: 270, align: "center" });
for (const t of [2025, 2050, 2075, 2100]) label(`Left x ${t}`, String(t), { x: xt(t) - 0.22, y: YB + 0.03, w: 0.44, h: 0.16, fontSize: S.size.tiny, color: C.muted, align: "center" });
// what politics removes: the band between A and the capped price
const aUsed = CL === "price" ? A : A2;
poly("Band removed by politics", T.map((t) => [xt(t), yv(aUsed(t))]).concat(T.slice().reverse().map((t) => [xt(t), yv(Pc(t, aUsed))])),
  { fill: { color: C.coral, transparency: 80 }, line: { type: "none" } }, true);
poly("Pref current policies", T.map((t) => [xt(t), yv(R(t))]), { line: { color: C.stringency, width: 1.5, dashType: "dash" } });
poly("A anchor", T.map((t) => [xt(t), yv(A(t))]), { line: { color: C.deep, width: 2 } });
if (CL === "budget") poly("A raised anchor", T.map((t) => [xt(t), yv(A2(t))]), { line: { color: C.deep, width: 2, dashType: "sysDash" } });
poly("P capped region", T.map((t) => [xt(t), yv(Pc(t, aUsed))]), { line: { color: C.coral, width: 2 } });
// end labels
const e = 2100, lx = XE + 0.04;
label("Label A", CL === "price" ? "A: cost-optimal price (the anchor), unchanged" : "A: the anchor without politics",
  { x: lx, y: yv(A(e)) - 0.09, w: 1.3, h: 0.18, fontSize: S.size.tiny, color: C.deep, valign: "middle" });
if (CL === "budget") label("Label A raised", "A′: the anchor rises until the budget holds; a region without a limit (φ = 1) pays it",
  { x: lx, y: yv(A2(e)) - 0.2, w: 1.35, h: 0.4, fontSize: S.size.tiny, bold: true, color: C.deep, valign: "middle" });
label("Label P", CL === "price" ? "the capped region pays Pref + φ·(A − Pref)" : "the capped region pays Pref + φ·(A′ − Pref)", { x: lx, y: yv(Pc(e, aUsed)) - 0.14, w: 1.3, h: 0.28, fontSize: S.size.tiny, color: C.coral, bold: true, valign: "middle" });
label("Label Pref", "Pref: current policies", { x: lx, y: yv(R(e)) - 0.09, w: 1.3, h: 0.18, fontSize: S.size.tiny, color: C.stringency, valign: "middle" });
const bandT = 2078, bandY = (yv(aUsed(bandT)) + yv(Pc(bandT, aUsed))) / 2;
label("Label band", (CL === "price" ? "(1 − φ)·(A − Pref)" : "(1 − φ)·(A′ − Pref)") + ": the part of the extra price politics does not deliver",
  { x: xt(2028), y: YT - 0.02, w: 1.55, h: 0.4, fontSize: S.size.tiny, italic: true, color: C.coral });
seg("Label band leader a", xt(2028) + 1.58, YT + 0.18, xt(bandT), YT + 0.18, { color: C.coral, width: 0.75 });
seg("Label band leader b", xt(bandT), YT + 0.18, xt(bandT), bandY, { color: C.coral, width: 0.75 });
label("Phi note", "φ = 1 − θ · k(t) · u, per region and sector: u the region's rank, k(t) how its limit moves, θ how hard it bites",
  { x: 0.04, y: YB + 0.26, w: 4.75, h: 0.3, fontSize: S.size.tiny, color: C.muted, valign: "top" });

// ---------- right: what gives ----------
const RX = 4.85, RW = 1.6;
badge("Right", 2, RX - 0.02, 0.08);
label("Right title", "What gives", { x: RX + 0.26, y: 0.06, w: 1.4, h: 0.26, fontSize: S.size.title, bold: true, color: C.deep, valign: "middle" });
if (CL === "price") {
  // the budget bar: the reference meets it; the capped run overshoots
  const bx = RX + 0.1, bw = 0.5, b0 = 2.75, unit = 1.45;
  const bar = (name, x, h, fill, line, t) => {
    s.addShape(pres.shapes.RECTANGLE, { objectName: name, x, y: b0 - h, w: bw, h, fill: { color: fill }, line: { color: line, width: 0.5 } });
    if (t) label(name + " label", t, { x: x - 0.1, y: b0 + 0.03, w: bw + 0.2, h: 0.3, fontSize: S.size.tiny, color: C.muted, align: "center" });
  };
  s.addShape(pres.shapes.RECTANGLE, { objectName: "Bar reference", x: bx, y: b0 - unit, w: bw, h: unit, fill: { color: C.institution }, line: { color: C.institutionLine, width: 0.5 } });
  label("Bar reference label", "no politics (θ = 0)", { x: bx - 0.12, y: b0 + 0.03, w: bw + 0.24, h: 0.3, fontSize: S.size.tiny, color: C.muted, align: "center" });
  const bx2 = bx + 0.85;
  s.addShape(pres.shapes.RECTANGLE, { objectName: "Bar capped base", x: bx2, y: b0 - unit, w: bw, h: unit, fill: { color: C.institution }, line: { color: C.institutionLine, width: 0.5 } });
  s.addShape(pres.shapes.RECTANGLE, { objectName: "Bar capped overshoot", x: bx2, y: b0 - unit - 0.32, w: bw, h: 0.32, fill: { color: C.coral }, line: { color: C.coral, width: 0.5 } });
  label("Bar capped label", "with the limit", { x: bx2 - 0.12, y: b0 + 0.03, w: bw + 0.24, h: 0.3, fontSize: S.size.tiny, color: C.muted, align: "center" });
  seg("Budget line", bx - 0.06, b0 - unit, bx2 + bw + 0.06, b0 - unit, { color: C.deep, width: 1, dashType: "dash" });
  label("Budget label", "1000 Gt budget", { x: bx - 0.06, y: b0 - unit - 0.2, w: 0.85, h: 0.16, fontSize: S.size.tiny, color: C.deep });
  label("Overshoot label", "extra CO₂: the headline", { x: bx2 - 0.12, y: b0 - unit - 0.62, w: 0.74, h: 0.28, fontSize: S.size.tiny, bold: true, color: C.coral, align: "center" });
  label("Bar title", "cumulative CO₂ 2020–2100", { x: RX, y: 0.4, w: RW, h: 0.18, fontSize: S.size.tiny, color: C.muted, align: "center" });
  label("Right text", "The anchor is held at the no-politics price; the budget is not enforced. What the limit removes is not made up elsewhere, so emissions rise.",
    { x: RX - 0.05, y: b0 + 0.3, w: RW + 0.1, h: 0.5, fontSize: S.size.tiny, color: C.ink });
} else {
  // two groups of regions and the abatement that moves between them
  const bw = 1.5, bh = 0.62;
  box("Capped regions", RX, 0.55, bw, bh, { fill: "FBE7DE", line: C.coral });
  label("Capped regions text", [{ text: "regions held back most", options: { bold: true, breakLine: true } }, { text: "pay less than without politics: emit more" }],
    { x: RX + 0.06, y: 0.55, w: bw - 0.12, h: bh, fontSize: S.size.tiny, align: "center", valign: "middle" });
  box("Free regions", RX, 1.72, bw, bh, { fill: C.interest, line: C.interestLine });
  label("Free regions text", [{ text: "regions with little or no limit", options: { bold: true, breakLine: true } }, { text: "pay the raised anchor: abate more" }],
    { x: RX + 0.06, y: 1.72, w: bw - 0.12, h: bh, fontSize: S.size.tiny, align: "center", valign: "middle" });
  seg("Moved arrow", RX + bw / 2, 0.55 + bh + 0.02, RX + bw / 2, 1.72 - 0.02, { color: C.deep, width: 1.75, endArrowType: "triangle" });
  label("Moved label", "abatement moves", { x: RX + bw / 2 + 0.06, y: 0.55 + bh + 0.08, w: 0.9, h: 0.3, fontSize: S.size.tiny, italic: true, color: C.deep });
  box("Budget box", RX, 2.5, bw, 0.3, { fill: "FFFFFF", line: C.deep, dash: "dash" });
  label("Budget box text", "the 1000 Gt budget holds", { x: RX, y: 2.5, w: bw, h: 0.3, fontSize: S.size.tiny, bold: true, color: C.deep, align: "center", valign: "middle" });
  label("Right text", "The anchor rises until cumulative CO₂ meets the budget; the cap is rebuilt from it every iteration.",
    { x: RX - 0.05, y: 2.86, w: RW + 0.1, h: 0.4, fontSize: S.size.tiny, color: C.ink });
}

pres.writeFile({ fileName: OUT }).then((f) => console.log("wrote " + f));
