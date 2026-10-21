// The coupling between the Political Feasibility Model and REMIND, with what the PFM estimates.
// One editable slide at the printed size of the figure: every box, arrow and label is a named
// native shape (objectName), so it can be adjusted in PowerPoint.
//   node fig-coupling-estimation.js <out.pptx>
const pptxgen = require("pptxgenjs");
const { S, C, figureDeck, txt } = require("./style");

const OUT = process.argv[2] || "fig-coupling-estimation.pptx";
const H = 3.62;
const pres = figureDeck(pptxgen, "FIG_COUPLING", H);
pres.title = "Coupling between the Political Feasibility Model and REMIND";
const s = pres.addSlide();
s.background = { color: "FFFFFF" };

// ---------- helpers ----------
const box = (name, x, y, w, h, o = {}) => s.addShape(pres.shapes.ROUNDED_RECTANGLE, {
  objectName: name, x, y, w, h, rectRadius: o.r ?? 0.06,
  fill: { color: o.fill ?? C.panel }, line: { color: o.line ?? C.frame, width: o.lw ?? 1 } });
const badge = (name, n, x, y) => {
  s.addShape(pres.shapes.OVAL, { objectName: name + " badge", x, y, w: 0.22, h: 0.22, fill: { color: C.deep }, line: { color: C.deep, width: 0 } });
  s.addText(String(n), txt({ objectName: name + " number", x, y, w: 0.22, h: 0.22, fontSize: S.size.small, bold: true,
                             color: "FFFFFF", align: "center", valign: "middle" }));
};
const head = (name, t, x, y, w) => s.addText(t, txt({ objectName: name + " title", x, y, w, h: 0.22, fontSize: S.size.title,
                                                     bold: true, color: C.deep, valign: "middle" }));
const body = (name, t, x, y, w, h, o = {}) => s.addText(t, txt(Object.assign({ objectName: name, x, y, w, h }, o)));
// a straight connector with an arrow head at the end
const arrow = (name, x1, y1, x2, y2, o = {}) => s.addShape(pres.shapes.LINE, {
  objectName: name, x: Math.min(x1, x2), y: Math.min(y1, y2), w: Math.max(Math.abs(x2 - x1), 0.001), h: Math.max(Math.abs(y2 - y1), 0.001),
  flipH: x2 < x1, flipV: y2 < y1,
  line: { color: o.color ?? C.frame, width: o.width ?? 1.25, endArrowType: o.head === false ? undefined : "triangle",
          dashType: o.dash ?? "solid" } });
const line = (name, x1, y1, x2, y2, o = {}) => arrow(name, x1, y1, x2, y2, Object.assign({ head: false }, o));

// ---------- 1. Observed policy ----------
const A = { x: 0.04, y: 1.05, w: 1.3, h: 1.25 };
box("Observed policy box", A.x, A.y, A.w, A.h);
badge("Observed policy", 1, A.x + 0.08, A.y + 0.1);
s.addText("Observed\npolicy", txt({ objectName: "Observed policy title", x: A.x + 0.36, y: A.y + 0.06, w: A.w - 0.42, h: 0.4,
                                     fontSize: S.size.title, bold: true, color: C.deep, valign: "top" }));
body("Observed policy text", "CAPMF policy stringency, 48 countries, 2001–2023", A.x + 0.1, A.y + 0.52, A.w - 0.18, 0.65);

// ---------- 2. Political Feasibility Model ----------
const B = { x: 1.52, y: 0.04, w: 3.2, h: 2.95 };
box("PFM box", B.x, B.y, B.w, B.h);
badge("PFM", 2, B.x + 0.1, B.y + 0.1);
head("PFM", "Political Feasibility Model", B.x + 0.38, B.y + 0.1, 2.6);
body("PFM text", "Estimates a ceiling on policy stringency and derives each region’s distance below it (observed or assigned): a feasibility share per region and carbon market",
     B.x + 0.12, B.y + 0.38, B.w - 0.24, 0.5);

// column headers
const col = (name, t, x, w) => body(name, t, x, B.y + 0.97, w, 0.16, { fontSize: S.size.tiny, bold: true, color: C.muted, align: "center", charSpacing: 1 });
col("Header drivers", "VARIABLES", B.x + 0.1, 1.2);
col("Header politics", "ESTIMATION", B.x + 1.42, 0.85);
col("Header policy", "OUTPUT", B.x + 2.36, 0.76);

// drivers (left column)
const dx = B.x + 0.1, dw = 1.2, dh = 0.36, dg = 0.07, dy0 = B.y + 1.2;
const drivers = [
  ["State capability", "WGI gov. effectiveness", "inst"],
  ["Rule of law", "V-Dem", "inst"],
  ["Accountability", "V-Dem, vertical", "inst"],
  ["Economic interests", "fossil and clean energy", "int"],
];
drivers.forEach(([t1, t2, k], i) => {
  const y = dy0 + i * (dh + dg);
  const inst = k === "inst";
  box("Driver " + t1, dx, y, dw, dh, { fill: inst ? C.institution : C.interest, line: inst ? C.institutionLine : C.interestLine, lw: 0.75, r: 0.04 });
  s.addText([{ text: t1, options: { bold: true, breakLine: true } }, { text: t2 }],
    txt({ objectName: "Driver " + t1 + " text", x: dx, y, w: dw, h: dh, fontSize: S.size.tiny, align: "center", valign: "middle" }));
});
const driversMidY = drivers.map((_, i) => dy0 + i * (dh + dg) + dh / 2);

// politics: main effects + interactions
const P = { x: B.x + 1.42, y: dy0 + 0.55, w: 0.85, h: 0.5 };
box("Politics box", P.x, P.y, P.w, P.h, { fill: "FFFFFF", line: C.slate, lw: 0.75, r: 0.04 });
body("Politics text", "main effects\n+ interactions", P.x, P.y, P.w, P.h, { fontSize: S.size.small, align: "center", valign: "middle" });
driversMidY.forEach((y, i) => line("Driver link " + (i + 1), dx + dw, y, P.x, P.y + P.h / 2, { color: C.faint, width: 0.75 }));
body("Politics note", "interactions: interests conditioned by institutions", P.x - 0.2, P.y + P.h + 0.04, P.w + 0.4, 0.28,
     { fontSize: S.size.tiny, italic: true, color: C.muted, align: "center" });
body("Weight note", "interactions weighted by freedom of expression (V-Dem)", P.x, P.y - 0.46, P.w + 0.1, 0.42,
     { fontSize: S.size.tiny, color: C.muted, align: "center", valign: "bottom" });

// policy: the frontier
const F = { x: B.x + 2.36, y: P.y, w: 0.76, h: P.h };
box("Frontier box", F.x, F.y, F.w, F.h, { fill: C.institution, line: C.institutionLine, lw: 1, r: 0.04 });
s.addText([{ text: "feasibility frontier ", options: { bold: true } }, { text: "S*", options: { bold: true, italic: true } }],
  txt({ objectName: "Frontier text", x: F.x, y: F.y, w: F.w, h: F.h, fontSize: S.size.small, align: "center", valign: "middle" }));
arrow("Politics to frontier", P.x + P.w, P.y + P.h / 2, F.x, F.y + F.h / 2, { color: C.slate, width: 1 });

// ---------- 3. REMIND ----------
const R = { x: 4.96, y: 0.3, w: 1.5, h: 1.25 };
box("REMIND box", R.x, R.y, R.w, R.h);
badge("REMIND", 3, R.x + 0.08, R.y + 0.08);
head("REMIND", "REMIND", R.x + 0.36, R.y + 0.08, 1.0);
body("REMIND text", "Caps each region’s carbon price above current policy by its feasibility share", R.x + 0.1, R.y + 0.38, R.w - 0.18, 0.7);

// ---------- 4. Energy system ----------
const E = { x: 4.96, y: 1.85, w: 1.5, h: 1.25 };
box("Energy box", E.x, E.y, E.w, E.h);
badge("Energy", 4, E.x + 0.08, E.y + 0.08);
head("Energy", "Energy system", E.x + 0.36, E.y + 0.08, 1.05);
body("Energy text", "Fossil and clean-energy shares change; the ceilings move and the shares are recomputed", E.x + 0.1, E.y + 0.38, E.w - 0.18, 0.7);

// ---------- flows ----------
arrow("Observed to PFM", A.x + A.w, A.y + A.h / 2, B.x, A.y + A.h / 2);
arrow("PFM to REMIND", B.x + B.w, R.y + R.h / 2, R.x, R.y + R.h / 2);
arrow("REMIND to energy", R.x + R.w / 2, R.y + R.h, E.x + E.w / 2, E.y);
// feedback: energy system -> economic interests (down, left, up)
const fbY = 3.25, intX = dx + dw / 2, intBottom = dy0 + 3 * (dh + dg) + dh;
line("Feedback down", E.x + E.w / 2, E.y + E.h, E.x + E.w / 2, fbY, { color: C.teal, width: 1.25 });
line("Feedback across", intX, fbY, E.x + E.w / 2, fbY, { color: C.teal, width: 1.25 });
arrow("Feedback up", intX, fbY, intX, intBottom, { color: C.teal, width: 1.25 });
body("Feedback label", "feedback, repeated until the feasibility shares converge", intX + 0.12, fbY + 0.05, 3.4, 0.18,
     { fontSize: S.size.small, italic: true, color: C.teal });

// ---------- declared, not estimated ----------
body("Declared note", "Declared, not estimated: how severe the limit is, and how long it lasts", 0.04, 2.42, 1.3, 0.6,
     { fontSize: S.size.tiny, italic: true, color: C.muted });

pres.writeFile({ fileName: OUT }).then((f) => console.log("wrote " + f));
