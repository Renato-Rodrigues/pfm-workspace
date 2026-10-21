// The shared figure style (../style/figure-style.json), for the PowerPoint schematics.
// The R builders read the same file (R/style.R), so diagrams and charts match.
const S = require("../style/figure-style.json");
const C = S.colour;

// A figure-sized layout: every schematic is drawn at its printed size, so the type sizes in
// the JSON are the printed sizes.
function figureDeck(pptxgen, name, heightIn) {
  const pres = new pptxgen();
  pres.defineLayout({ name, width: S.width_in, height: heightIn });
  pres.layout = name;
  pres.theme = { headFontFace: S.font.head, bodyFontFace: S.font.body };
  return pres;
}

// Text options with the shared defaults; margin 0 so text aligns with shapes.
function txt(extra) {
  return Object.assign({ fontFace: S.font.body, fontSize: S.size.body, color: C.ink, margin: 0, isTextBox: true,
                         valign: "top", align: "left" }, extra || {});
}

module.exports = { S, C, figureDeck, txt };
