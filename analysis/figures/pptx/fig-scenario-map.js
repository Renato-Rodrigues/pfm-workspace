// The v8 coupled scenario set: what each family of runs varies, against the central run (docs/SCENARIOS.md 2.3, 2.6).
//   node fig-scenario-map.js <out.pptx>
// One editable slide at the printed size: every box, curve and label is a named native shape (objectName). A schematic:
// the persistence sketches are stylised shapes of k(t), not data.
const pptxgen = require("pptxgenjs");
const { S, C, figureDeck, txt } = require("./style");

const OUT = process.argv[2] || "fig-scenario-map.pptx";
const H = 4.3;
const pres = figureDeck(pptxgen, "FIG_SCEN_MAP", H);
pres.title = "The coupled scenario set";
const s = pres.addSlide();
s.background = { color: "FFFFFF" };

const label = (name, t, o) => s.addText(t, txt(Object.assign({ objectName: name }, o)));
const box = (name, x, y, w, h, o = {}) => s.addShape(pres.shapes.ROUNDED_RECTANGLE, {
  objectName: name, x, y, w, h, rectRadius: o.r ?? 0.04,
  fill: { color: o.fill ?? "FFFFFF" }, line: { color: o.line ?? C.frame, width: o.lw ?? 0.75 } });
const poly = (name, pts, opt) => {
  const xs = pts.map((p) => p[0]), ys = pts.map((p) => p[1]);
  const x = Math.min(...xs), y = Math.min(...ys), w = Math.max(Math.max(...xs) - x, 0.01), h = Math.max(Math.max(...ys) - y, 0.01);
  s.addShape(pres.shapes.CUSTOM_GEOMETRY, Object.assign({ x, y, w, h, points: pts.map((p) => ({ x: p[0] - x, y: p[1] - y })), objectName: name }, opt));
};

// ---------- the formula ----------
box("Formula box", 0.04, 0.04, 6.42, 0.5, { fill: C.panel, line: C.frame });
label("Formula", [{ text: "φ = 1 − θ · k(t) · u", options: { bold: true, color: C.deep, fontSize: S.size.title } },
                  { text: "     the share of the extra carbon price a region's politics delivers, per region and sector",
                    options: { color: C.ink } }],
  { x: 0.14, y: 0.04, w: 6.25, h: 0.28, fontSize: S.size.small, valign: "middle" });
label("Formula parts", "θ how hard the limit bites (declared)  ·  k(t) how the region's limit moves over time  ·  u the region's 2023 rank (estimated)",
  { x: 0.14, y: 0.29, w: 6.25, h: 0.22, fontSize: S.size.tiny, color: C.muted, valign: "middle" });

// ---------- the families ----------
const fams = [
  ["Severity", "θ", "how hard the limit bites", [["0.325", false], ["0.50", true], ["0.675", false]], "EU21, H12"],
  ["Persistence", "k(t), κ", "whether the limit lasts", null, "EU21 (2.7% also H12)"],
  ["Strength form", "k(t)", "whose path sets the limit's movement", [["regional", true], ["common (the world's)", false], ["gap first", false]], "EU21 (common also H12)"],
  ["Rents", "B&T slack", "how REMIND's fossil rents are valued", [["regional price", true], ["world price", false]], "EU21, H12"],
  ["Institutions", "k(t)", "how institutions develop after 2023", [["gap closure 0.6%/yr", true], ["held at 2023", false], ["Andrijevic", false], ["storyline", false]], "EU21, H12 (storyline EU21)"],
];
const LX = 0.04, LW = 1.45, OX = 1.6, OW = 4.86, Y0 = 0.68, RH = 0.5, PH = 0.95, G = 0.1;
let y = Y0;
fams.forEach(([name, sym, what, opts, res], i) => {
  const h = opts ? RH : PH;
  box(`${name} family`, LX, y, LW, h, { fill: C.deep, line: C.deep });
  label(`${name} family text`, [{ text: name, options: { bold: true, breakLine: true } }, { text: `${sym}: ${what}`, options: { fontSize: S.size.tiny } }],
    { x: LX + 0.08, y, w: LW - 0.12, h, fontSize: S.size.small, color: "FFFFFF", valign: "middle" });
  label(`${name} resolutions`, res, { x: OX, y: y + h - 0.15, w: OW, h: 0.14, fontSize: S.size.tiny, italic: true, color: C.muted, align: "right" });
  if (opts) {
    const ow = (OW - 0.06 * (opts.length - 1)) / opts.length;
    opts.forEach(([t, central], j) => {
      const x = OX + j * (ow + 0.06);
      box(`${name} option ${j + 1}`, x, y + 0.04, ow, h - 0.22, { fill: central ? C.coral : C.institution, line: central ? C.coral : C.institutionLine, lw: 0.5 });
      label(`${name} option ${j + 1} text`, central ? `${t}  (central)` : t,
        { x, y: y + 0.04, w: ow, h: h - 0.22, fontSize: S.size.tiny, bold: central, color: central ? "FFFFFF" : C.ink, align: "center", valign: "middle" });
    });
  } else {
    // persistence: a sketch of k(t) for each option
    const P = [["growing", (f) => 1 + 0.5 * f, false], ["constant", () => 1, false], ["fading", (f) => 1 - 0.35 * f, true],
               ["fading + erosion: 2%, 2.7%, 5% a year, historical rates", (f) => (1 - 0.35 * f) * Math.pow(0.55, f), false]];
    const ow = (OW - 0.06 * 3) / 4, sh = h - 0.22;
    P.forEach(([t, k, central], j) => {
      const x = OX + j * (ow + 0.06), yy = y + 0.04;
      box(`Persistence option ${j + 1}`, x, yy, ow, sh, { fill: central ? "FBE7DE" : C.institution, line: central ? C.coral : C.institutionLine, lw: central ? 1 : 0.5 });
      const gx0 = x + 0.12, gx1 = x + ow - 0.12, gy0 = yy + 0.08, gy1 = yy + sh - 0.36;
      const ky = (v) => gy1 - ((v - 0.3) / 1.3) * (gy1 - gy0);
      poly(`Persistence option ${j + 1} axis`, [[gx0, gy0], [gx0, gy1], [gx1, gy1]], { line: { color: C.faint, width: 0.5 } });
      poly(`Persistence option ${j + 1} k=1`, [[gx0, ky(1)], [gx1, ky(1)]], { line: { color: C.faint, width: 0.5, dashType: "dash" } });
      const pts = []; for (let f = 0; f <= 1.0001; f += 0.1) pts.push([gx0 + f * (gx1 - gx0), ky(k(f))]);
      poly(`Persistence option ${j + 1} curve`, pts, { line: { color: central ? C.coral : C.deep, width: 1.75 } });
      label(`Persistence option ${j + 1} text`, central ? `${t}  (central)` : t,
        { x: x + 0.03, y: gy1 + 0.02, w: ow - 0.06, h: 0.32, fontSize: S.size.tiny, bold: central, color: central ? C.coral : C.ink, align: "center", valign: "middle" });
    });
    label("Persistence note", "sketches of k(t), 2025 to 2100; dashed: today's limit (k = 1)", { x: OX, y: y + h - 0.15, w: 2.8, h: 0.14, fontSize: S.size.tiny, italic: true, color: C.muted });
  }
  y += h + G;
});
label("Footer", "Every run is compared with the no-politics reference (θ = 0) of its closure. Each family changes one setting of the central run.",
  { x: 0.04, y: y - 0.02, w: 6.42, h: 0.2, fontSize: S.size.tiny, color: C.muted });

pres.writeFile({ fileName: OUT }).then((f) => console.log("wrote " + f));
