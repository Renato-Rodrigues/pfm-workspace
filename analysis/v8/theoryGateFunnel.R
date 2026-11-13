# The theory gate split into its parts: where the 5,786 admissible specifications drop out on the way to the 80.
#   Rscript analysis/v8/theoryGateFunnel.R [group]     (repo root; default v8) -> output/pfm/<group>/theory-gate-funnel.rds
# Offline, from sweep.rds only (no refit): the coefficient tables the sweep's theory screen reads (satP mean regression,
# cluster-robust p), on the pool that passes every gate before the theory gate (gateFailReason empty or "theory: ...").
# Per specification and sector the two requirements of ADR 0059, as .pfmTheoryScreen() applies them:
#   H1  the fossil term (the share, else the per-person form) is negative with p < alpha;
#   H2  at least one fossil x institution term has p < alpha / k, k = the sector's number of such terms (Bonferroni).
# Reported, at alpha 0.05 (the gate) and at 0.01 / 0.10 / 0.15 / 0.20:
#   1. the four-requirement matrix: H1 and H2 in power & industry (Bulk) and buildings & transport (Diffuse), 16 cells;
#   2. per sector, H1 x H2 (2 x 2); the two sectors, theory passed in each (2 x 2);
#   3. which requirement fails (order-free): among those removed, the failing requirements;
#   4. sequential funnels, each in its stated order: (a) H1 P&I, H1 B&T, H2 P&I, H2 B&T; (b) sector by sector,
#      P&I (H1, H2) then B&T (H1, H2); (c) B&T first; plus two softer intermediate steps: the fossil sign alone
#      (negative, any p) and H2 without the Bonferroni correction (some fossil x institution term at p < alpha).
# The check: at alpha 0.05 the screen reproduces the sweep's 80, and the reimplementation agrees with
# .pfmTheoryScreen() at every alpha.
source("analysis/_common/_loadPfm.R")
args <- commandArgs(trailingOnly = TRUE); g <- if (length(args)) args[1] else "v8"
GD <- file.path("output/pfm", g)
say <- function(...) message("[theory-funnel:", g, "] ", ...)
s <- readRDS(file.path(GD, "sweep.rds")); m <- s$maximin$PolicyStringency
why <- m$gateFailReason; why[is.na(why)] <- ""
pool <- m$model[!nzchar(why) | startsWith(why, "theory: ")]
say("specifications ", nrow(m), " | before the theory gate ", length(pool), " | after it ", sum(m$gatePass %in% TRUE))
SECTORS <- c(Bulk = "P&I", Diffuse = "B&T")
ALPHAS <- c(0.01, 0.05, 0.10, 0.15, 0.20)

# per specification and sector: the fossil term's estimate and p, the interaction p-values' minimum and their number
cf <- s$coefficients[s$coefficients$model %in% pool & s$coefficients$sector %in% names(SECTORS), ]
by <- split(cf, paste(cf$model, cf$sector, sep = "\r"))
terms <- do.call(rbind, lapply(by, function(x) {
  fos <- pfm:::.pfmFossilTerm(x$term); i <- match(fos, x$term)
  k <- which(startsWith(x$term, "Incumbent.Power_x_") | startsWith(x$term, "Incumbent.Power.pc_x_"))
  data.frame(model = x$model[1], sector = x$sector[1], fossilTerm = fos,
             fossil = if (is.na(i)) NA_real_ else x$estimate[i], pFossil = if (is.na(i)) NA_real_ else x$pValue[i],
             nInteractions = length(k), pInteractionMin = if (length(k)) min(x$pValue[k], na.rm = TRUE) else NA_real_,
             interactionMin = if (length(k)) x$term[k][which.min(x$pValue[k])] else NA_character_)
}))
rownames(terms) <- NULL
wide <- function(v) { w <- stats::reshape(terms[, c("model", "sector", v)], idvar = "model", timevar = "sector", direction = "wide")
  w[match(pool, w$model), ] }

flags <- function(a) {
  t <- terms
  t$sign <- is.finite(t$fossil) & t$fossil < 0
  t$H1 <- t$sign & is.finite(t$pFossil) & t$pFossil < a
  t$H2raw <- t$nInteractions > 0 & is.finite(t$pInteractionMin) & t$pInteractionMin < a
  t$H2 <- t$nInteractions > 0 & is.finite(t$pInteractionMin) & t$pInteractionMin < a / pmax(1, t$nInteractions)
  pick <- function(v, sec) { x <- t[t$sector == sec, ]; x[[v]][match(pool, x$model)] %in% TRUE }
  out <- data.frame(model = pool)
  for (sec in names(SECTORS)) for (v in c("sign", "H1", "H2raw", "H2")) out[[paste(v, SECTORS[[sec]])]] <- pick(v, sec)
  out$pass <- out$`H1 P&I` & out$`H2 P&I` & out$`H1 B&T` & out$`H2 B&T`
  out
}

funnel <- function(f, steps, label) {
  keep <- rep(TRUE, nrow(f)); n <- integer(0)
  for (st in steps) { keep <- keep & Reduce(`&`, lapply(st, function(v) f[[v]])); n <- c(n, sum(keep)) }
  data.frame(order = label, step = c("admissible (before the theory gate)", names(steps)),
             n = c(nrow(f), n), dropped = c(NA, -diff(c(nrow(f), n))))
}
ORDERS <- list(
  "a: H1 then H2" = list("H1 P&I" = "H1 P&I", "+ H1 B&T" = "H1 B&T", "+ H2 P&I" = "H2 P&I", "+ H2 B&T" = "H2 B&T"),
  "b: P&I then B&T" = list("H1 P&I" = "H1 P&I", "+ H2 P&I" = "H2 P&I", "+ H1 B&T" = "H1 B&T", "+ H2 B&T" = "H2 B&T"),
  "c: B&T then P&I" = list("H1 B&T" = "H1 B&T", "+ H2 B&T" = "H2 B&T", "+ H1 P&I" = "H1 P&I", "+ H2 P&I" = "H2 P&I"),
  "d: soft steps" = list("fossil negative P&I and B&T (any p)" = c("sign P&I", "sign B&T"),
                          "+ H1 both" = c("H1 P&I", "H1 B&T"),
                          "+ some fossil x institution p < alpha, both (no Bonferroni)" = c("H2raw P&I", "H2raw B&T"),
                          "+ H2 both (Bonferroni)" = c("H2 P&I", "H2 B&T")))

res <- list()
for (a in ALPHAS) {
  f <- flags(a)
  # the check against the package's screen
  ref <- pfm:::.pfmTheoryScreen(s$coefficients, pool, names(SECTORS), list(p = a))
  stopifnot(identical(ref$pass[match(pool, ref$model)], f$pass))
  if (a == 0.05) stopifnot(setequal(f$model[f$pass], m$model[m$gatePass %in% TRUE]))
  key <- function(v) ifelse(f[[v]], "pass", "fail")
  cells <- as.data.frame(table(`H1 P&I` = key("H1 P&I"), `H2 P&I` = key("H2 P&I"), `H1 B&T` = key("H1 B&T"),
                               `H2 B&T` = key("H2 B&T")), responseName = "n")
  perSector <- do.call(rbind, lapply(SECTORS, function(sx) {
    tb <- table(H1 = key(paste("H1", sx)), H2 = key(paste("H2", sx)))
    data.frame(sector = sx, H1 = rep(rownames(tb), 2), H2 = rep(colnames(tb), each = 2), n = as.integer(tb))
  }))
  pi <- f$`H1 P&I` & f$`H2 P&I`; bt <- f$`H1 B&T` & f$`H2 B&T`
  sectors <- data.frame(cell = c("theory holds in both", "in power & industry only", "in buildings & transport only", "in neither"),
                        n = c(sum(pi & bt), sum(pi & !bt), sum(!pi & bt), sum(!pi & !bt)))
  # order-free: among the removed, which requirements fail (each requirement over both sectors, then each sector)
  rm <- !f$pass
  h1 <- !(f$`H1 P&I` & f$`H1 B&T`); h2 <- !(f$`H2 P&I` & f$`H2 B&T`)
  fails <- data.frame(fails = c("H1 only", "H2 only", "H1 and H2", "removed, total"),
                      n = c(sum(rm & h1 & !h2), sum(rm & !h1 & h2), sum(rm & h1 & h2), sum(rm)))
  failsSector <- data.frame(fails = c("power & industry only", "buildings & transport only", "both sectors"),
                            n = c(sum(rm & !pi & bt), sum(rm & pi & !bt), sum(rm & !pi & !bt)))
  fun <- do.call(rbind, Map(funnel, list(f), ORDERS, names(ORDERS)))
  res[[format(a)]] <- list(alpha = a, flags = f, cells = cells, perSector = perSector, sectors = sectors,
                           fails = fails, failsSector = failsSector, funnel = fun, nPass = sum(f$pass))
  say(sprintf("alpha %.2f: %d pass | P&I theory %d, B&T theory %d | fails H1 only %d, H2 only %d, both %d",
              a, sum(f$pass), sum(pi), sum(bt), fails$n[1], fails$n[2], fails$n[3]))
}
# the thresholds side by side: each order's counts at every alpha
thr <- do.call(rbind, lapply(res, function(r) cbind(alpha = r$alpha, r$funnel)))
thrWide <- stats::reshape(thr[, c("alpha", "order", "step", "n")], idvar = c("order", "step"), timevar = "alpha",
                          direction = "wide")
names(thrWide) <- sub("^n\\.", "alpha ", names(thrWide))
# the binding p-values: the distribution of the smallest Bonferroni-scaled interaction p and of the fossil p, per sector
tm <- transform(terms, pH2scaled = pInteractionMin * pmax(1, nInteractions))
bind <- do.call(rbind, lapply(split(tm, tm$sector), function(x) data.frame(
  sector = SECTORS[[x$sector[1]]], fossilNegative = mean(x$fossil < 0, na.rm = TRUE),
  pFossilMedian = stats::median(x$pFossil[x$fossil < 0], na.rm = TRUE),
  pH2scaledMedian = stats::median(x$pH2scaled, na.rm = TRUE),
  nInteractions = paste(sort(unique(x$nInteractions)), collapse = "/"))))

out <- list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), nSpecs = nrow(m), pool = pool, terms = terms,
            byAlpha = res, thresholds = thrWide, binding = bind)
saveRDS(out, file.path(GD, "theory-gate-funnel.rds"))
say("wrote ", file.path(GD, "theory-gate-funnel.rds"))

options(width = 200)
r <- res[["0.05"]]
cat("\n== alpha 0.05: the four requirements (n per cell; pass in all four = ", r$nPass, ") ==\n", sep = "")
print(r$cells[order(-r$cells$n), ], row.names = FALSE)
cat("\n== per sector, H1 x H2 ==\n"); print(r$perSector, row.names = FALSE)
cat("\n== the two sectors ==\n"); print(r$sectors, row.names = FALSE)
cat("\n== removed: which hypothesis fails / which sector fails ==\n"); print(r$fails, row.names = FALSE); print(r$failsSector, row.names = FALSE)
cat("\n== funnels at every alpha (0.05 is the gate) ==\n"); print(thrWide, row.names = FALSE)
cat("\n== the pool, per sector ==\n"); print(bind, row.names = FALSE)
