// The shrinking future: how the sequential chain of coupled runs is built (design note 0009 section 22, COUPLING.md 14.1).
// One editable slide at the printed size: every bar, arrow and label is a named native shape (objectName). A schematic,
// no data: the step years are those of the v8 chains (2030-2070, 10-year windows).
//   node fig-shrinking-future-chain.js <out.pptx>
const pptxgen = require("pptxgenjs");
const { S, C, figureDeck, txt } = require("./style");

const OUT = process.argv[2] || "fig-shrinking-future-chain.pptx";
const H = 4.12;
const pres = figureDeck(pptxgen, "FIG_SF_CHAIN", H);
pres.title = "The shrinking future: a chain of coupled runs";
const s = pres.addSlide();
s.background = { color: "FFFFFF" };

// ---------- geometry (inches) ----------
const X0 = 1.55, XE = 6.38, T0 = 2020, T1 = 2100;
const xt = (t) => X0 + ((t - T0) / (T1 - T0)) * (XE - X0);
const RH = 0.3, RG = 0.13, Y0 = 0.4;
const rowY = (i) => Y0 + i * (RH + RG);
const STEPS = [2030, 2040, 2050, 2060, 2070];

// ---------- helpers ----------
const rect = (name, x, y, w, h, fill, line, o = {}) => s.addShape(pres.shapes.RECTANGLE, Object.assign({
  objectName: name, x, y, w, h, fill: fill ? { color: fill, transparency: o.tr ?? 0 } : { type: "none" },
  line: line ? { color: line, width: o.lw ?? 0.75, dashType: o.dash ?? "solid" } : { type: "none" } }, {}));
const label = (name, t, o) => s.addText(t, txt(Object.assign({ objectName: name }, o)));
const seg = (name, x1, y1, x2, y2, l) => s.addShape(pres.shapes.LINE, {
  objectName: name, x: Math.min(x1, x2), y: Math.min(y1, y2), w: Math.max(Math.abs(x2 - x1), 0.001), h: Math.max(Math.abs(y2 - y1), 0.001),
  flipH: x2 < x1, flipV: y2 < y1, line: l });
const badge = (name, n, x, y) => {
  s.addShape(pres.shapes.OVAL, { objectName: name + " badge", x, y, w: 0.22, h: 0.22, fill: { color: C.deep }, line: { color: C.deep, width: 0 } });
  label(name + " number", String(n), { x, y, w: 0.22, h: 0.22, fontSize: S.size.small, bold: true, color: "FFFFFF", align: "center", valign: "middle" });
};
// the three kinds of segment
const past = (name, t0, t1, y, t) => {
  rect(name, xt(t0), y, xt(t1) - xt(t0), RH, C.institution, C.institutionLine, { lw: 0.5 });
  if (t) label(name + " text", t, { x: xt(t0), y, w: xt(t1) - xt(t0), h: RH, fontSize: S.size.tiny, color: C.muted, align: "center", valign: "middle" });
};
const limit = (name, t0, t1, y, t) => {
  rect(name, xt(t0), y, xt(t1) - xt(t0), RH, C.coral, C.coral, { lw: 0.5 });
  if (t) label(name + " text", t, { x: xt(t0), y, w: xt(t1) - xt(t0), h: RH, fontSize: S.size.tiny, bold: true, color: "FFFFFF", align: "center", valign: "middle" });
};
const plan = (name, t0, t1, y, t) => {
  rect(name, xt(t0), y, xt(t1) - xt(t0), RH, "FFFFFF", C.teal, { lw: 1, dash: "dash" });
  if (t) label(name + " text", t, { x: xt(t0), y, w: xt(t1) - xt(t0), h: RH, fontSize: S.size.tiny, color: C.teal, align: "center", valign: "middle" });
};

// ---------- time axis ----------
for (const t of [2020, 2030, 2040, 2050, 2060, 2070, 2080, 2090, 2100]) {
  seg(`Grid ${t}`, xt(t), Y0 - 0.06, xt(t), rowY(6) + 0.08 + RH, { color: C.grid, width: 0.5 });
  label(`x label ${t}`, String(t), { x: xt(t) - 0.25, y: Y0 - 0.27, w: 0.5, h: 0.18, fontSize: S.size.small, color: C.muted, align: "center" });
}
label("Header rows", "Run", { x: 0.04, y: Y0 - 0.27, w: 1.2, h: 0.18, fontSize: S.size.small, bold: true, color: C.deep });

// ---------- the five steps ----------
STEPS.forEach((tau, i) => {
  const y = rowY(i), last = i === STEPS.length - 1, end = last ? T1 : tau + 10;
  badge(`Step ${i + 1}`, i + 1, 0.04, y + (RH - 0.22) / 2);
  label(`Step ${i + 1} label`, [{ text: `Step ${i + 1}`, options: { bold: true, breakLine: true } }, { text: `decides ${tau} onward` }],
    { x: 0.32, y: y - 0.02, w: 1.2, h: RH + 0.04, fontSize: S.size.tiny, valign: "middle" });
  past(`Step ${i + 1} fixed past`, T0, tau, y, i === 0 ? "current policies" : `fixed: step ${i}`);
  limit(`Step ${i + 1} limit window`, tau, end, y, last ? "φ applies (to 2100)" : "φ applies");
  if (!last) plan(`Step ${i + 1} plan`, end, T1, y, "planned: limit lifted, φ = 1");
  // the next step inherits this step's decade
  if (!last) seg(`Inherit arrow ${i + 1}`, xt(end) - 0.05, y + RH + 0.01, xt(end) - 0.05, rowY(i + 1) - 0.01,
    { color: C.deep, width: 1, endArrowType: "triangle" });
});
label("Inherit note", "the next step inherits the decade as its fixed past", {
  x: xt(2040) + 0.02, y: rowY(0) + RH + 0.005, w: 2.6, h: RG, fontSize: S.size.tiny, italic: true, color: C.deep, valign: "middle" });

// ---------- separator and the two results ----------
const ySep = rowY(5) - RG / 2 + 0.02;
seg("Separator", 0.04, ySep, XE, ySep, { color: C.frame, width: 0.75 });
const yC = rowY(5) + 0.06, yO = rowY(6) + 0.08;
label("Chain result label", [{ text: "Chain result", options: { bold: true, breakLine: true } }, { text: "= step 5" }],
  { x: 0.04, y: yC - 0.02, w: 1.45, h: RH + 0.04, fontSize: S.size.tiny, color: C.deep, valign: "middle" });
past("Chain result current policies", T0, 2030, yC, "current policies");
STEPS.forEach((tau, i) => {
  const end = i === STEPS.length - 1 ? T1 : tau + 10;
  limit(`Chain result decade ${i + 1}`, tau, end, yC, i === STEPS.length - 1 ? "step 5" : String(i + 1));
  if (i > 0) seg(`Chain result divider ${i}`, xt(tau), yC, xt(tau), yC + RH, { color: "FFFFFF", width: 1.25 });
});
label("One-shot label", [{ text: "One-shot run", options: { bold: true, breakLine: true } }, { text: "the limit is known to last" }],
  { x: 0.04, y: yO - 0.02, w: 1.45, h: RH + 0.04, fontSize: S.size.tiny, color: C.deep, valign: "middle" });
past("One-shot current policies", T0, 2030, yO, "current policies");
limit("One-shot limit", 2030, T1, yO, "φ applies in every year, and every year knows it");

// ---------- the formula and the legend ----------
const LY = rowY(6) + 0.08 + RH + 0.22;
const leg = [["past", "past fixed (quantities, capacities, emissions)", 2.45],
  ["limit", "the political limit applies: P = min(A, Pref + φ·max(A − Pref, 0))", 3.5]];
let lx = 0.04;
leg.forEach(([k, t, w], j) => {
  if (k === "past") rect("Legend past", lx, LY - 0.07, 0.26, 0.14, C.institution, C.institutionLine, { lw: 0.5 });
  else rect("Legend limit", lx, LY - 0.07, 0.26, 0.14, C.coral, C.coral, { lw: 0.5 });
  label(`Legend ${k} label`, t, { x: lx + 0.32, y: LY - 0.09, w: w - 0.36, h: 0.18, fontSize: S.size.tiny, valign: "middle" });
  lx += w;
});
const LY2 = LY + 0.24;
rect("Legend plan", 0.04, LY2 - 0.07, 0.26, 0.14, "FFFFFF", C.teal, { lw: 1, dash: "dash" });
label("Legend plan label", "planned, not delivered: the step expects the limit to lift after its decade (hold the price: the full price A; hold the budget: the price that meets the budget)",
  { x: 0.36, y: LY2 - 0.14, w: 6.06, h: 0.28, fontSize: S.size.tiny, valign: "middle" });

pres.writeFile({ fileName: OUT }).then((f) => console.log("wrote " + f));
