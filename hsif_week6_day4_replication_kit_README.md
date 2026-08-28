# Aid Under Fire Replication Assessment: Kit README
HSIF Applied Causal Inference, Week 6 Day 4

## The repository
- Paper: Crost, Felter & Johnston (2014), "Aid under Fire: Development Projects
  and Civil Conflict," AER 104(6): 1833-56.
- Replication package: openICPSR project 112831, doi:10.3886/E112831V1
  (https://www.openicpsr.org/openicpsr/project/112831/version/V1/view).
  Free ICPSR login required. The instructor copy is posted on Canvas beside
  this README; do not redistribute outside the course.

## Before estimating: the variable map
The starter script (hsif_week6_day4_aidunderfire_helper.R) opens with a
VARIABLE MAP of placeholders. Fill it from the package codebook first:
running variable (reconstructed rank AND underlying poverty score), cutoff,
casualties (total and by initiator), program receipt, municipality id,
time period, program-start timing, pre-determined covariates.

## The assessment: four stages, one memo
Deliverable: a team memo, ~1,200 words plus figure arrays, 2-3 pages total.
Drafted by 11:45; the finalized memo is due by the end of the day.

- Stage 1 (9:30-9:55). Context and the ranking problem. No estimation.
  The ranking in the files is reconstructed from published poverty estimates;
  the program's internal list is unavailable. Write the consequences:
  misclassification near the cutoff, attenuation direction, which checks
  become indirect, and which specification targets the problem.
  -> Memo section 1 (~250 words).
- Stage 2 (9:55-10:40). Main results, modernized. Script Block 2.
  Replicate at the paper's spec (h = 6, triangular); RD plot; rdrobust at the
  MSE-optimal h (Robust row, h/2, 2h); donut r = 1, 2.
  -> Memo section 2 (~350 words) + figure array 1 (RD plot + specification
  chart: six estimates with CIs on one axis).
- Stage 3 (10:40-11:10). Timing and actor validity. Script Block 3.
  Initiator-split RDs with robust rows + the measurement question; the
  stage-window problem under staggered rollout.
  -> Memo section 3 (~300 words): two committed verdicts.
- Stage 4 (11:10-11:45). The complement and a better clock. Script Block 4.
  DiD event study (eligible vs ineligible, full Tuesday checklist) and the
  RD event study: period-by-period jumps at the cutoff, plotted as a path.
  -> Memo section 4 (~300 words) + figure array 2 (both event studies).

## Memo standard
Assumptions named. Verdicts committed. Figures carry the argument. Two to
three pages, readable in grayscale. Graded against the capstone rubric's
identification-precision language.
