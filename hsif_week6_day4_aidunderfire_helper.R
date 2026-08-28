# =====================================================================
# HSIF Applied Causal Inference, Week 6 Day 4
# Starter script: Aid Under Fire replication assessment
# Target: Crost, Felter & Johnston (2014, AER), openICPSR 112831
# Blocks match the assessment stages 2-4 (Stage 1 is written work)
# Packages: rdrobust + rddensity (RD), fixest (DiD), dplyr, ggplot2, haven
# =====================================================================

# install.packages(c("rdrobust", "rddensity", "fixest", "dplyr", "ggplot2", "haven"))
library(rdrobust)   # MSE-optimal bandwidths, robust bias-corrected inference
library(rddensity)  # density test on the underlying score
library(fixest)     # event study for the DiD complement
library(dplyr)
library(ggplot2)
library(haven)      # the package ships Stata .dta files

# ---------------------------------------------------------------------
# 0. VARIABLE MAP: fill from the package codebook before estimating
# ---------------------------------------------------------------------
DATA_FILE   <- "PASTE_MAIN_ANALYSIS_FILE.dta"
V_RANK      <- "poverty_rank"     # RECONSTRUCTED within-province rank
V_SCORE     <- "poverty_score"    # underlying poverty estimate behind ranks
V_CUT       <- "cutoff_rank"      # province quartile boundary
V_OUTCOME   <- "casualties"       # total conflict casualties
V_CAS_INS   <- "casualties_ins"   # insurgent-initiated
V_CAS_GOV   <- "casualties_gov"   # government-initiated
V_RECEIPT   <- "kalahi"           # actual program receipt
V_MUNI      <- "municipality_id"
V_TIME      <- "period"
V_START     <- "program_start"    # program start timing

df <- read_dta(DATA_FILE)
df <- df %>% mutate(r = .data[[V_RANK]] - .data[[V_CUT]])   # centered rank

# ---------------------------------------------------------------------
# BLOCK 2. MAIN RESULTS, MODERNIZED (Stage 2)
# ---------------------------------------------------------------------
# 2a. Replicate the paper's own specification FIRST: h = 6, triangular.
# If this does not hit the published estimate, fix the variable map,
# do not proceed.
summary(rdrobust(df[[V_OUTCOME]], df$r, c = 0, h = 6, kernel = "triangular"))

# 2b. The RD plot: the jump should be visible before any table.
rdplot(y = df[[V_OUTCOME]], x = df$r, c = 0,
       x.label = "poverty rank (centered at cutoff)",
       y.label = "conflict casualties")

# 2c. Modern inference: MSE-optimal h; report the Robust row.
main <- rdrobust(df[[V_OUTCOME]], df$r, c = 0)
summary(main)
h_opt <- main$bws["h", "left"]
summary(rdrobust(df[[V_OUTCOME]], df$r, c = 0, h = h_opt / 2))   # half
summary(rdrobust(df[[V_OUTCOME]], df$r, c = 0, h = h_opt * 2))   # double

# 2d. Donut: the targeted answer to Stage 1's misclassification concern.
for (r_hole in c(1, 2)) {
  d <- filter(df, abs(r) > r_hole)
  cat("\n--- donut r =", r_hole, "---\n")
  print(summary(rdrobust(d[[V_OUTCOME]], d$r, c = 0)))
}

# 2e. Figure array 1, panel 2: specification chart. Collect the six
# estimates (paper spec, MSE-optimal, h/2, 2h, donut 1, donut 2) with CIs
# into a data frame and plot on one axis with geom_pointrange().

# ---------------------------------------------------------------------
# BLOCK 3. TIMING AND ACTORS (Stage 3)
# ---------------------------------------------------------------------
# Initiator splits: separate outcomes, each its own RD, robust rows.
summary(rdrobust(df[[V_CAS_INS]], df$r, c = 0))
summary(rdrobust(df[[V_CAS_GOV]], df$r, c = 0))
# Measurement probe: does the sum of the splits track the total at the
# cutoff? A gap suggests initiator coding varies with program presence.

# ---------------------------------------------------------------------
# BLOCK 4. THE COMPLEMENT AND A BETTER CLOCK (Stage 4)
# ---------------------------------------------------------------------
# 4a. DiD event study: eligible vs ineligible around program start.
# Tuesday's checklist: reference period, window, endpoint bins, pre-trends.
df <- df %>%
  mutate(elig  = as.integer(r >= 0),
         k     = .data[[V_TIME]] - .data[[V_START]],
         k_bin = pmax(pmin(k, 8), -8),
         k_es  = if_else(elig == 1, k_bin, -1))
m_es <- feols(as.formula(paste0(V_OUTCOME, " ~ i(k_es, ref = -1) | ",
                                V_MUNI, " + ", V_TIME)),
              data = df, cluster = as.formula(paste0("~", V_MUNI)))
iplot(m_es, main = "DiD event study: eligible vs. ineligible")

# 4b. THE RD EVENT STUDY: one RD per event-time period.
# Replaces the paper's three coarse periods with the full dynamic path.
# Leads (k < 0) are built-in placebos: jumps before the program = 0.
rd_path <- lapply(sort(unique(df$k_bin)), function(kk) {
  d <- filter(df, k_bin == kk)
  if (nrow(d) < 100) return(NULL)          # skip thin cells
  fit <- tryCatch(rdrobust(d[[V_OUTCOME]], d$r, c = 0),
                  error = function(e) NULL)
  if (is.null(fit)) return(NULL)
  data.frame(k   = kk,
             est = fit$coef["Robust", 1],
             lo  = fit$ci["Robust", 1],
             hi  = fit$ci["Robust", 2])
}) %>% bind_rows()

ggplot(rd_path, aes(x = k, y = est)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "gray50") +
  geom_pointrange(aes(ymin = lo, ymax = hi), color = "#800000",
                  size = 0.35) +
  labs(x = "event time (periods since program start)",
       y = "RD estimate at the cutoff",
       title = "The RD event study: period-by-period jumps") +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(color = "#800000"))
ggsave("rd_event_study.png", width = 8, height = 4.2, dpi = 150)

# Reading: onset/peak/fade replace the three-period split. Expect wide
# intervals (one period's data per estimate); pair the flexible path with
# the pooled estimate: shape from one, precision from the other.
