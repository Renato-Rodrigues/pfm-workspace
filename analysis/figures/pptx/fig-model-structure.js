// The feasibility frontier's structure: what sets the ceiling, what sets the distance below it, and what is observed.
//   node fig-model-structure.js <out.pptx>
// One editable slide at the printed size: every box, arrow and label is a named native shape (objectName). A schematic
// of the selected v8 specification (methods-v8.md sections 1-3), no data.
const pptxgen = require("pptxgenjs");
const { S, C, figureDeck, txt } = require("./style");

const OUT = process.argv[2] || "fig-model-structure.pptx";
const H = 3.9;
const pres = figureDeck(pptxgen, "FIG_MODEL", H);
pres.title = "The feasibility frontier";
const s = pres.addSlide();
s.background = { color: "FFFFFF" };

const label = (name, t, o) => s.addText(t, txt(Object.assign({ objectName: name }, o)));
const box = (name, x, y, w, h, o = {}) => s.addShape(pres.shapes.ROUNDED_RECTANGLE, {
  objectName: name, x, y, w, h, rectRadius: o.r ?? 0.05,
  fill: { color: o.fill ?? "FFFFFF" }, line: { color: o.line ?? C.frame, width: o.lw ?? 0.75, dashType: o.dash ?? "solid" } });
const arrow = (name, x1, y1, x2, y2, o = {}) => s.addShape(pres.shapes.LINE, {
  objectName: name, x: Math.min(x1, x2), y: Math.min(y1, y2), w: Math.max(Math.abs(x2 - x1), 0.001), h: Math.max(Math.abs(y2 - y1), 0.001),
  flipH: x2 < x1, flipV: y2 < y1, line: { color: o.color ?? C.frame, width: o.width ?? 1.25, endArrowType: "triangle", dashType: o.dash ?? "solid" } });
const head = (name, t, x, y, w, color) => label(name, t, { x, y, w, h: 0.2, fontSize: S.size.small, bold: true, color, valign: "middle" });
const item = (name, t1, t2, x, y, w, h, fill, line) => {
  box(name, x, y, w, h, { fill, line, lw: 0.5, r: 0.04 });
  label(name + " text", [{ text: t1, options: { bold: true, breakLine: true } }, { text: t2 }],
    { x: x + 0.05, y, w: w - 0.1, h, fontSize: S.size.tiny, align: "center", valign: "middle" });
};

// ---------- left: the drivers ----------
const X1 = 0.04, W1 = 1.55, IH = 0.42, IG = 0.06;
head("Interests head", "Interests (from the energy system)", X1, 0.04, 2.2, C.interestLine);
const ints = [["fossil dependence", "structural power"], ["fossil interests per person", "resources for instrumental power"],
              ["clean-energy build-out", "the clean-energy coalition"]];
ints.forEach(([a, b], i) => item(`Interest ${i + 1}`, a, b, X1, 0.27 + i * (IH + IG), W1, IH, C.interest, C.interestLine));
label("Interests note", "saturating; fossil terms bounded at the sample's cleanest 5%", { x: X1, y: 0.27 + 3 * (IH + IG) - 0.03, w: W1, h: 0.26,
  fontSize: 6.5, italic: true, color: C.muted });
const y2 = 1.95;
head("Institutions head", "Institutions (channels)", X1, y2, 2, C.institutionLine);
const ins = [["state capacity", "can the state deliver?"], ["rule of law", "are commitments credible?"],
             ["vertical accountability", "can voters sanction?"]];
ins.forEach(([a, b], i) => item(`Institution ${i + 1}`, a, b, X1, y2 + 0.23 + i * (IH + IG), W1, IH, C.institution, C.institutionLine));

// ---------- middle: interactions, weight, controls ----------
const X2 = 1.9, W2 = 1.6;
box("Interactions box", X2, 1.2, W2, 0.78, { fill: "FFFFFF", line: C.slate });
label("Interactions text", [{ text: "main effects + interest × institution", options: { bold: true, breakLine: true } },
  { text: "each driver on its own, and the weight of an interest depending on the institutions it meets (sign left to the data)" }],
  { x: X2 + 0.06, y: 1.2, w: W2 - 0.12, h: 0.78, fontSize: S.size.tiny, align: "center", valign: "middle" });
box("Weight box", X2, 2.1, W2, 0.55, { fill: "FBE7DE", line: C.coral });
label("Weight text", [{ text: "× freedom of expression (0–1)", options: { bold: true, breakLine: true } },
  { text: "carries the moderation only where citizens can know and say" }],
  { x: X2 + 0.06, y: 2.1, w: W2 - 0.12, h: 0.55, fontSize: S.size.tiny, align: "center", valign: "middle" });
arrow("Weight to interactions", X2 + W2 / 2, 2.1, X2 + W2 / 2, 1.99, { color: C.coral, width: 1 });
for (let i = 0; i < 3; i++) arrow(`Interest link ${i + 1}`, X1 + W1, 0.27 + i * (IH + IG) + IH / 2, X2, 1.45, { color: C.faint, width: 0.6 });
for (let i = 0; i < 3; i++) arrow(`Institution link ${i + 1}`, X1 + W1, y2 + 0.23 + i * (IH + IG) + IH / 2, X2, 1.75, { color: C.faint, width: 0.6 });
box("Controls box", X2, 2.8, W2, 1.02, { fill: C.panel, line: C.frame, dash: "dash" });
label("Controls text", [{ text: "controls and common terms", options: { bold: true, breakLine: true } },
  { text: "income · population · clean baseload (hydro, nuclear) · global diffusion trend (held at 2023 in projections) · EU / OECD / other" }],
  { x: X2 + 0.06, y: 2.8, w: W2 - 0.12, h: 1.02, fontSize: S.size.tiny, align: "center", valign: "middle" });

// ---------- right: the ceiling, the gap, the observation ----------
const X3 = 3.85, W3 = 2.6;
box("Ceiling box", X3, 0.27, W3, 0.72, { fill: C.deep, line: C.deep });
label("Ceiling text", [{ text: "The ceiling S*", options: { bold: true, breakLine: true, fontSize: S.size.body } },
  { text: "the most stringent policy that countries with comparable interests and institutions have sustained" }],
  { x: X3 + 0.08, y: 0.27, w: W3 - 0.16, h: 0.72, fontSize: S.size.tiny, color: "FFFFFF", align: "center", valign: "middle" });
arrow("Interactions to ceiling", X2 + W2, 1.45, X3, 0.75, { color: C.deep });
arrow("Controls to ceiling", X2 + W2, 3.1, X3 + 0.15, 0.99, { color: C.faint, width: 0.8, dash: "dash" });
const XG = X3 + 0.42, WG = W3 - 0.42;
box("Gap box", XG, 1.25, WG, 0.8, { fill: "FBE7DE", line: C.coral });
label("Gap text", [{ text: "The gap below the ceiling u ≥ 0", options: { bold: true, breakLine: true } },
  { text: "room a country's politics does not use (timing, attention, ideology). Its size grows with fossil rents (buildings and transport)" }],
  { x: XG + 0.06, y: 1.25, w: WG - 0.12, h: 0.8, fontSize: S.size.tiny, align: "center", valign: "middle" });
box("Noise box", XG, 2.2, WG, 0.42, { fill: C.institution, line: C.institutionLine });
label("Noise text", "noise v: measurement and scoring error, either sign", { x: XG + 0.06, y: 2.2, w: WG - 0.12, h: 0.42,
  fontSize: S.size.tiny, align: "center", valign: "middle" });
box("Observed box", X3, 2.85, W3, 0.6, { fill: "FFFFFF", line: C.stringency, lw: 1.25 });
label("Observed text", [{ text: "Observed stringency (CAPMF, logit)", options: { bold: true, breakLine: true } },
  { text: "= ceiling − gap + noise, per country, sector and year" }],
  { x: X3 + 0.08, y: 2.85, w: W3 - 0.16, h: 0.6, fontSize: S.size.tiny, align: "center", valign: "middle" });
arrow("Ceiling to observed", X3 + 0.2, 0.99, X3 + 0.2, 2.85, { color: C.deep });
arrow("Gap to observed", XG + WG / 2, 2.05, XG + WG / 2, 2.2, { color: C.coral });
arrow("Noise to observed", XG + WG / 2, 2.62, XG + WG / 2, 2.85, { color: C.institutionLine });
label("Output note", "share of its ceiling a country realises, E = S / S*  →  the regions' ranking  →  the feasibility share φ in REMIND",
  { x: X3 - 0.3, y: 3.52, w: W3 + 0.3, h: 0.32, fontSize: S.size.tiny, italic: true, color: C.deep, align: "right" });

pres.writeFile({ fileName: OUT }).then((f) => console.log("wrote " + f));
