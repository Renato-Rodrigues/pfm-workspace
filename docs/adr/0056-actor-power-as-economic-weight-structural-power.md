# ADR 0056 — Actor power is presented as the economic weight of interests (a proxy for structural power)

- **Status:** **Accepted 2026-10-12** (author). Wording for reader-facing text: the methodology, the
  paper, decks. The model, the code and the data names do not change.
- **Run-Groups:** all; it changes how a result is described, not a number.

## Decision

1. **Main text.** The actor-power drivers are described as **the economic weight of fossil and
   clean-energy interests**. In reader-facing text, "incumbents" and "innovators" become **fossil
   interests** and **clean-energy interests**. The measures behind them are named plainly:
   - **fossil dependence:** the incumbents' share;
   - **fossil interests per person:** the per-capita term;
   - **clean-energy build-out:** the innovators' share.
2. **Methods, one sentence.** "In political-economy terms this is a proxy for structural power, the
   leverage that comes from economic importance, not for instrumental power such as lobbying, finance
   or access, which we do not observe (Lindblom 1977; Culpepper & Reinke 2014; Fairfield 2015)."
   "Actor power" may appear once, as the model's own term.
3. **Discussion.**
   - The **fading limit** is read as structural power shifting with the energy system.
   - The declared **erosion rate κ** is the stand-in for the channels not measured: instrumental and
     discursive power, norms, and political learning.

## Context

- **What the drivers are.** Shares of REMIND's energy system:
  - fossil dependence, and fossil dependence × energy use per person;
  - renewables and electrification (plus biofuels in buildings & transport).

  They pass through a saturating transform (ADR 0040, 0044, 0052). No actor is observed: no firms,
  lobbying, donations or membership. The instrument that tests the energy-system feedback confirms
  endogeneity and identifies no effect (`MODEL.md` §8.1).
- **"Actor power" claims more than that.** "Actor" suggests agents with agency (parties, veto players,
  interest groups). "Power" suggests measured influence over outcomes. Both run against the project's
  rule that claims stay within the evidence.
- **"Incumbent" has two meanings.** In political science it means the officeholder, and incumbency
  the electoral advantage. In the transition literature it means the established fossil industry.
  Next to the model's accountability variables, the first reading is the likely one.
- **What the political-economy literature offers.**
  - It separates **instrumental power** (deliberate influence: lobbying, finance, access; Miliband
    1969) from **structural power** (leverage from economic importance: governments anticipate what
    would hurt investment, jobs or revenue, without anyone acting; Lindblom 1977; Block 1977;
    Przeworski & Wallerstein 1988).
  - Later work treats structural power as **contingent** on context and perception (Hacker & Pierson
    2002) and as **sector-specific** (Culpepper 2011; Culpepper & Reinke 2014), and measures the two
    separately (Fairfield 2015). Lukes and Fuchs (2007) add **discursive power**.
  - In climate politics: Newell & Paterson 1998; Meckling et al. 2015; Breetz, Mildenberger &
    Stokes 2018; Mildenberger 2020; Colgan, Green & Hale 2021.
- **The fit with this model.**
  - A share of the energy system is a proxy for the structural kind.
  - A frontier, a ceiling on what countries have sustained, is the natural form of power that works
    by anticipation.
  - Context-dependence is what the interactions with institutions, and the "only the pair is
    interpretable" result for the two fossil terms, show.

## Consequences

- The methodology (`communication/methodology/PFM-Methodology-v6.md`) uses this wording, with a short
  plain-language box on the two kinds of power.
- Unchanged:
  - model and code names: `actorPowerIndex`, `Innovator Power|<sector>`, `Incumbent Power pc`,
    `bothIncAP`, `satInn`, `satAP`, `apTransform`;
  - the symbols $A^{\text{in}}$, $A^{\text{ic}}$, $A^{\text{ic,pc}}$;
  - the figure ID `marginal-effect-incumbency`.
- The governed documents (`MODEL.md`, `DATA.md` …) still say innovators / incumbents, as model
  terms; `CONTEXT.md` gives the reading. Changing them is a separate step if wanted.
- **Expected referee question:** how do we know it is structural power and not something correlated
  with fossil dependence (income, energy security, geography)? The answer to give: we do not separate
  them. The term interprets a proxy, it is not a measured quantity.
- **Limits to state.**
  - Structural power classically concerns capital in general (the threat of disinvestment). Here it
    is used in its sector-level sense.
  - On the clean-energy side, early influence is mostly instrumental: structural power grows only as
    the sector becomes economically important.

## Alternatives rejected

- **Keep "actor power" / "incumbents" unqualified:** overclaims, and is ambiguous for
  political-science readers.
- **"Fossil incumbents / clean-energy challengers":** "challenger" is also an electoral term.
- **"Fossil / clean-energy coalitions":** implies organised groups, and "coalition" also means a
  governing coalition.
- **"Structural power" as the main label:** too technical for the main text, and it invites the
  debate. It is used in the methods sentence instead.
