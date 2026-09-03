rm(list = ls())


####Read in Libraries####
# Impact Measurement Rubric — Shiny app
#
# Two tabs:
#   1. Explainer      — the static reference (definitions, matrix, detail entries)
#   2. Build Your Rubric — pick reform type(s), data accessibility, and bill
#                          status; get back the rubric filtered to what applies,
#                          with the right measurement type(s) highlighted.
#
# Requires: shiny, bslib, htmltools
#   install.packages(c("shiny", "bslib", "htmltools"))
#   shiny::runApp("app.R")

library(shiny)
library(bslib)
library(htmltools)

# ---------------------------------------------------------------------------
# Data: one entry per reform type. `matrix_*` are the short, one-line
# versions shown in the overview table; `full_*` are the fuller versions
# shown in the detail entries and in the builder tab.
# ---------------------------------------------------------------------------

reforms <- list(
  list(
    code = "SC",
    name = "Sentence Caps & Limits",
    def = "Caps or reduces the maximum sentence length for a category of offense.",
    matrix_actuals = "Sentencing counts by offense, before and after the effective date",
    matrix_estimates = "Affected population modeled from offense mix and admissions data",
    matrix_projections = "Multi-year prison-population reduction if the pattern holds",
    full_actuals = list(
      lead = "Sentencing or disposition data by offense category, typically available from state court or DOC reporting systems:",
      items = c(
        "Sentence lengths for the offense category before the effective date",
        "Sentence lengths for the same offense category after the effective date"
      )
    ),
    full_estimates = list(
      lead = "When disposition data isn't broken out cleanly enough, model the affected population from two inputs:",
      items = c(
        "The offense mix \u2014 how sentences currently break down by offense",
        "Admissions data, to size the population the new cap would touch"
      )
    ),
    full_projections = "Extend the actual or estimated reduction forward to project multi-year prison-population (average daily population) or bed-space savings.",
    passed_bill = "California AB 1950",
    passed_text = "we believe sentencing disposition data exists at the county/month level and is granular enough to calculate the real, actual effect once aggregated — Recidiviz simply hadn't run that calculation yet.",
    hypo_text = "A state caps felony theft sentences at three years. Court sentencing data by offense (an actual, if the state publishes it) would show how many current sentences exceed the new cap; where that data doesn't exist, arrest and conviction records combined with average sentence-length data could produce a defensible estimate instead."
  ),
  list(
    code = "PE",
    name = "Parole & Release Eligibility",
    def = "Expands who qualifies for parole or another release mechanism.",
    matrix_actuals = "Counts of people made eligible and people actually released",
    matrix_estimates = "Eligible population modeled from age, offense, and time-served filters",
    matrix_projections = "Growth of the eligible pool plus an expected grant rate over time",
    full_actuals = list(
      lead = "From agency or task-force reporting:",
      items = c(
        "The count of people who newly meet the eligibility criteria",
        "The count of people actually granted release under the new criteria"
      )
    ),
    full_estimates = list(
      lead = "Model the eligible population from DOC data filtered by the bill's criteria \u2014 age, offense type, time served. If DOC population data isn't available either, work down a weaker chain of proxies, roughly in this order:",
      items = c(
        "Published DOC aggregate reports or fact sheets with a partial breakdown (by age band or offense category), even without a full cross-tab",
        "A fiscal note or population estimate from a legislative or sentencing-commission analysis of the bill, if one exists",
        "Admissions or sentencing data \u2014 who's being sentenced each year, and for how long \u2014 used to reconstruct a population estimate instead of relying on a population snapshot",
        "National or peer-state benchmark rates (e.g., the share of a prison population in a given age band, from BJS or a similar source) applied to the state's total population, which is usually public even when its breakdowns aren't",
        "A direct records request to the agency for the specific cross-tab \u2014 many states don't publish this online but will produce it if asked"
      )
    ),
    full_projections = list(
      lead = "Combine two moving pieces:",
      items = c(
        "How the eligible pool grows year over year (as more people age into an elder-parole threshold, for example)",
        "An expected grant rate, drawn from board history"
      )
    ),
    passed_bill = "Mississippi SB 2795",
    passed_text = "a state oversight task force published both real numbers \u2014 9,339 people made eligible and 2,335 actually released \u2014 letting us distinguish eligibility from outcome directly.",
    hypo_text = "A state lowers its elder-parole age from 60 to 55. DOC population data filtered by age and time served (an estimate, since eligible-population counts aren't usually published outright) would size the newly eligible group, and a multi-year projection would track how that pool grows as more people cross the new threshold each year."
  ),
  list(
    code = "ET",
    name = "Early Termination & Supervision Length",
    def = "Shortens time spent under active probation or parole supervision.",
    matrix_actuals = "Early-termination counts by year, from the supervising agency",
    matrix_estimates = "Eligible population multiplied by an assumed grant rate",
    matrix_projections = "Cumulative terminations if the current grant-rate trend continues",
    full_actuals = "Early-termination counts by year, from the supervising agency's own reporting.",
    full_estimates = list(
      lead = "When usage isn't separately tracked, model it from two inputs:",
      items = c(
        "The eligible population",
        "An assumed grant rate, drawn from a comparable jurisdiction"
      )
    ),
    full_projections = list(
      lead = "Extend the actual or estimated grant rate forward to project either:",
      items = c(
        "Cumulative terminations over several years",
        "Years of supervision saved over the same period"
      )
    ),
    passed_bill = "Illinois SB 423",
    passed_text = "actual pre- and post-law termination counts exist, and they revealed a negative effect: terminations actually fell in the year the law took effect.",
    hypo_text = "A state creates automatic probation termination after 18 months without a violation. The state's baseline probation population and average term length (actuals, if published) would size the eligible group, and a projection \u2014 built on an assumed compliance rate \u2014 would estimate terminations in future years."
  ),
  list(
    code = "VR",
    name = "Violation Response & Individualized Conditions",
    def = "Changes how technical violations are penalized, or requires supervision conditions to be individualized.",
    matrix_actuals = "Revocation and technical-violation reincarceration counts",
    matrix_estimates = "Modeled from admission-reason breakdowns, case-file samples, or peer-state benchmarks",
    matrix_projections = "Projected reduction in revocation-driven admissions",
    full_actuals = list(lead = "When conditions data is readily available, report", 
                        items = c(
                          "Revocation counts", 
                          "Technical violation reincarceration counts", 
                          "Both of the above disaggregated by types and numbers of conditions"
                        )),
    full_estimates = list(
      lead = "This bundles two different levers, so the estimate depends on which one the bill touches:",
      items = c(
        "Individualized conditions: use the state's standard/default conditions template (usually public) as the \u201cbefore\u201d baseline, then estimate the shift from a modest case-file sample or practitioner interviews, since case-level conditions data almost never exists",
        "Violation response, e.g. a sentence cap or graduated sanctions: revocation and TV reincarceration counts rarely exist off the shelf, so build the baseline in stages \u2014 start with whatever admission-reason breakdown the DOC already publishes, since many report \u201ctechnical violation revocation\u201d as its own top-line admissions category, separate from revocations for a new crime; if only a population share is published instead of an admissions count (e.g., \u201cX% of the prison population is there on a technical violation\u201d), convert it using average length of stay, since admissions is roughly the population share divided by the average time served for a TV revocation; and if neither exists, sample case files or court dockets from a handful of counties, code each case's outcome, and scale the sample rate up using a known denominator like total probation/parole caseload in those counties",
        "Once you have that baseline count, size the new rule's effect by benchmarking against a peer state that's already implemented something similar \u2014 apply its published before/after percentage change to your own baseline, rather than trying to reconstruct a full severity-tier distribution from scratch"
      )
    ),
    full_projections = list(
      lead = "Extend the actual or estimated revocation-rate change forward to project any changes in either:",
      items = c(
        "Revocation-driven admissions",
        "Average daily population"
      )
    ),
    passed_bill = "Michigan SB 1051",
    passed_text = "no public data exists at all; establishing even a baseline actual would require direct outreach to MDOC for internal case-management data.",
    hypo_text = "A state caps technical-violation sentences at 30 days. The state's current average violation-sentence length (an actual, if DOC reports it) would let you calculate reduced bed-days directly; a projection would extend that reduction across future years."
  ),
  list(
    code = "RR",
    name = "Remote / Reduced-Contact Reporting",
    def = "Lets certain supervised individuals report remotely or less frequently.",
    matrix_actuals = "Almost never available without a new agency reporting requirement",
    matrix_estimates = "Supervision population multiplied by an assumed eligible share",
    matrix_projections = "Speculative absent a comparable state's adoption data",
    full_actuals = "Almost never available \u2014 requires the supervising agency to specifically track and report who's on remote-reporting status, which most agencies don't do.",
    full_estimates = list(
      lead = "The most that's usually possible, built from two inputs:",
      items = c(
        "Total supervision population",
        "An assumed share who meet the \u201clow-risk\u201d or eligibility criteria"
      )
    ),
    full_projections = "Genuinely speculative unless a comparable state has already implemented something similar and published real adoption data to benchmark against.",
    passed_bill = "Louisiana HB 77",
    passed_text = "no data source exists in any form; a defensible estimate isn't currently possible without a new data-collection effort.",
    hypo_text = "A state allows remote reporting for anyone employed full-time. The state's total supervision population is likely an actual; the employed share within it would have to come from an outside source like state labor data, since DOC records don't typically track employment status."
  ),
  list(
    code = "RC",
    name = "Record Relief (Expungement & Sealing)",
    def = "Clears, seals, or expands eligibility for clearing criminal records.",
    matrix_actuals = "Court or repository counts of records actually cleared",
    matrix_estimates = "Eligible population from docket sampling or conviction records",
    matrix_projections = "Future clearances as an eligible backlog is processed",
    full_actuals = "Court or state-repository counts of records actually expunged or sealed.",
    full_estimates = list(
      lead = "For populations the repository doesn't cleanly track, estimate from either:",
      items = c(
        "Docket sampling",
        "Conviction-record audits"
      )
    ),
    full_projections = "Project future clearances by projecting out the eligible population and assuming a steady rate of expungement for the eligible population, as some \u201cclean slate\u201d mechanisms can take years to fully implement.",
    passed_bill = "Maryland SB 432",
    passed_text = "an actual count exists for the marijuana-pardon population (175,000 convictions expunged); the broader population whose charges were marked STET still requires an estimate, since no repository number exists for it yet.",
    hypo_text = "A state passes automatic expungement for low-level convictions after seven crime-free years. Since most states don't publish an \u201celigible population\u201d figure, this would start as an estimate built from conviction records, with actuals only becoming available once the state repository begins reporting completed expungements."
  ),
  list(
    code = "DA",
    name = "Diversion & Alternatives to Incarceration",
    def = "Expands pre- or post-charge alternatives to traditional prosecution, probation, or incarceration.",
    matrix_actuals = "Program enrollment counts, where centrally reported (rare)",
    matrix_estimates = "Eligible population combined with a stakeholder-informed diversion rate",
    matrix_projections = "Future diversion volume if referral rates hold (most speculative)",
    full_actuals = "Program enrollment counts, on the rare occasions a diversion program reports centrally and consistently.",
    full_estimates = list(
      lead = "Requires first settling a genuinely contested definitional question \u2014 what counts as \u201cdiverted,\u201d and diverted from what \u2014 before modeling the shift in volume. Consult with stakeholders, experts, or statistics in comparable jurisdictions to estimate a ",
      items = c(
        "Eligible population for the diversion", 
        "A reasonable diversion rate"
      )
    ),
    full_projections = "The most speculative measurement type in this rubric, since it compounds definitional uncertainty with a forward-looking volume estimate. If we can find a reasonable estimate of the eligible population for the diversion, we can project that forward and use the agreed upon range of diversion rates to predict the affected population.",
    passed_bill = "California AB 3234",
    passed_text = "even Recidiviz's own approach embeds an assumption \u2014 treating all diversion as diversion specifically from probation \u2014 rather than an observed fact.",
    hypo_text = "A state creates a pre-charge diversion track for low-level drug offenses. Actual program-level tracking typically doesn't exist until well after launch, so the first year or two would rely on an estimate built from arrest data and an assumed diversion rate."
  ),
  list(
    code = "MM",
    name = "Mandatory Minimum Reform",
    def = "Eliminates or reduces mandatory minimum sentencing requirements.",
    matrix_actuals = "Sentence counts and average lengths, before and after the change",
    matrix_estimates = "Modeled from offense-mix ratios, floor-bunching patterns, or peer-state benchmarks",
    matrix_projections = "Future reduction in mandatory-minimum-driven admissions",
    full_actuals = list(
      lead = "Sentencing data for the specific affected offenses \u2014 cleanest when the reform is a statutory change rather than an administrative one:",
      items = c(
        "Sentence counts and average sentence lengths from before the change",
        "Sentence counts and average sentence lengths from after the change"
      )
    ),
    full_estimates = list(
      lead = "The right proxy depends on what's actually missing:",
      items = c(
        "Administrative workaround instead of a statute: estimate the share of cases actually following the new guidance, since prosecutors retain discretion to route around it",
        "Counts missing: apportion whatever aggregate admissions reporting already exists down to the specific offense, using a known offense-mix ratio from arrest or charging data",
        "Average length missing: check how much pre-reform sentences clustered right at the old statutory floor \u2014 heavy bunching means the minimum was binding and lengths will likely fall toward what comparable non-mandatory-minimum offenses get; a flatter distribution means judges already had discretion, so the reform may move the average less than a naive before/after comparison would suggest",
        "Either gap: benchmark against a peer state that's already eliminated a similar mandatory minimum, using its published before/after change as a proxy",
        "Cross-check the charge mix for the offense pre/post reform \u2014 prosecutors can partially offset a repeal by stacking a different enhancement, which would understate the reform's real effect if you only look at sentence length"
      )
    ),
    full_projections = "Extend the actual or estimated shift forward to project future reductions in mandatory-minimum-driven admissions.",
    passed_bill = "New Jersey A3469",
    passed_text = "the bill itself never passed; it was implemented through an Attorney General directive instead, so actuals are muddied by prosecutorial discretion to work around it.",
    hypo_text = "A state statutorily eliminates mandatory minimums for drug possession. Because it's a clean statutory change rather than a directive, it would allow a genuine actual-to-actual comparison of pre- and post-law sentencing data \u2014 a cleaner picture than New Jersey's administrative version."
  )
)

reform_codes <- vapply(reforms, function(r) r$code, character(1))
reform_names <- vapply(reforms, function(r) r$name, character(1))
reform_choices <- setNames(reform_codes, reform_names)

# ---------------------------------------------------------------------------
# Rule engine: given data accessibility + bill status, decide which
# measurement type is primary, which (if any) is secondary, and what to
# tell the user in plain language. This logic is the same across every
# reform type — reform type only decides which rows are shown.
# ---------------------------------------------------------------------------

get_rule <- function(data_access, bill_status) {
  key <- paste(data_access, bill_status)
  switch(key,
         "good passed" = list(
           primary = "actuals", secondary = "projections",
           message = "Solid data on a passed bill \u2014 go get the actuals. Once you have them, projecting the trend forward is a natural next step."
         ),
         "stretch passed" = list(
           primary = "estimates", secondary = "projections",
           message = "No clean actuals here, but there's enough to build a defensible estimate. That estimate can also anchor a rough forward projection."
         ),
         "none passed" = list(
           primary = NULL, secondary = NULL,
           message = "Not currently measurable. There's no data and no realistic way to get it without new data collection or an agency partnership."
         ),
         "good future" = list(
           primary = "projections", secondary = "estimates",
           message = "The reform hasn't happened yet, so there's no actuals to find. But strong baseline data means a well-grounded projection is possible \u2014 and a near-term estimate can size the affected population now."
         ),
         "stretch future" = list(
           primary = "projections", secondary = "estimates",
           message = "The reform hasn't happened yet, so the number you're ultimately after is a projection. With only partial data to build from, start by estimating the affected population, then treat the projection built on top of it as low-confidence."
         ),
         "none future" = list(
           primary = NULL, secondary = NULL,
           message = "Not currently measurable. Without a data source to build from, even a projection would be closer to a guess than an estimate."
         )
  )
}

# ---------------------------------------------------------------------------
# UI-building helpers
# ---------------------------------------------------------------------------

legend_block <- function() {
  div(class = "legend",
      div(class = "legend-item actuals",
          h2("Actuals"),
          p("Directly observed and reported by an official source. Retrieval and aggregation only \u2014 no modeling required.")
      ),
      div(class = "legend-item estimates",
          h2("Estimates"),
          p("A number that exists in the world but can't be directly observed, inferred from proxy data and stated assumptions.")
      ),
      div(class = "legend-item projections",
          h2("Projections"),
          p("Forward-looking. Describes an outcome that hasn't happened yet, built by extending a current trend or rate.")
      )
  )
}

matrix_table <- function() {
  rows <- lapply(reforms, function(r) {
    tags$tr(
      tags$td(
        div(class = "row-name",
            span(class = "code-chip", r$code),
            tags$a(href = paste0("#detail-", tolower(r$code)), r$name)
        )
      ),
      tags$td(r$matrix_actuals),
      tags$td(r$matrix_estimates),
      tags$td(r$matrix_projections)
    )
  })
  div(class = "matrix-wrap",
      tags$table(class = "matrix",
                 tags$thead(
                   tags$tr(
                     tags$th("Reform type"),
                     tags$th(class = "actuals", "Actuals"),
                     tags$th(class = "estimates", "Estimates"),
                     tags$th(class = "projections", "Projections")
                   )
                 ),
                 tags$tbody(rows)
      )
  )
}

# Renders a full_* value that is either a plain string (-> one <p>) or a
# list(lead=, items=) (-> optional lead <p> followed by a numbered list).
render_full <- function(val) {
  if (is.character(val)) return(p(val))
  out <- tagList()
  if (!is.null(val$lead)) out <- tagAppendChild(out, p(val$lead))
  if (!is.null(val$items)) {
    out <- tagAppendChild(out, tags$ol(class = "num-list",
                                       lapply(val$items, tags$li)
    ))
  }
  out
}

detail_entry <- function(r) {
  div(class = "entry", id = paste0("detail-", tolower(r$code)),
      div(class = "entry-head",
          span(class = "code-chip", r$code),
          h3(r$name)
      ),
      p(class = "entry-def", r$def),
      div(class = "entry-cols",
          div(class = "col actuals", h4("Actuals"), render_full(r$full_actuals)),
          div(class = "col estimates", h4("Estimates"), render_full(r$full_estimates)),
          div(class = "col projections", h4("Projections"), render_full(r$full_projections))
      ),
      div(class = "examples",
          div(class = "example passed",
              span(class = "example-label", "Already passed"),
              p(tags$strong(r$passed_bill), " \u2014 ", r$passed_text)
          ),
          div(class = "example hypo",
              span(class = "example-label", "Hypothetical"),
              p(r$hypo_text)
          )
      )
  )
}

explainer_tab <- function() {
  div(class = "wrap",
      tags$header(
        h1("Impact Measurement Rubric"),
        p(class = "dek", "A working reference for what kind of number a reform actually calls for \u2014 actual, estimate, or projection \u2014 and what data that number depends on, before we ask Recidiviz or anyone else to go find it."),
        legend_block()
      ),
      div(class = "section",
          h2(class = "section-title", "The rubric"),
          p(class = "section-note", "Find a reform type, then read across. Click a name to jump to the full breakdown and examples below."),
          matrix_table()
      ),
      div(class = "section",
          h2(class = "section-title", "Reform types in detail"),
          p(class = "section-note", "Each entry below breaks the rubric out in full, then shows a bill we've already passed and a hypothetical bill, so the difference is concrete rather than abstract."),
          lapply(reforms, detail_entry)
      ),
      div(class = "foot",
          "Built from our bill-by-bill data review across 12 states. Reform categories are groupings for this rubric, not official legislative classifications \u2014 a given bill can span more than one row."
      )
  )
}

# A single builder card: same shape as detail_entry(), but each measurement
# column carries an is-primary / is-secondary / is-muted state from the rule.
builder_card <- function(r, rule) {
  state_of <- function(type) {
    if (!is.null(rule$primary) && identical(type, rule$primary)) "is-primary"
    else if (!is.null(rule$secondary) && identical(type, rule$secondary)) "is-secondary"
    else "is-muted"
  }
  badge_of <- function(type) {
    st <- state_of(type)
    if (st == "is-primary") span(class = "focus-badge primary", "Focus here")
    else if (st == "is-secondary") span(class = "focus-badge secondary", "Also useful")
    else span(class = "focus-badge muted", "Not the priority")
  }
  col <- function(type, label, text) {
    div(class = paste("col", type, state_of(type)),
        badge_of(type),
        h4(label),
        render_full(text)
    )
  }
  div(class = "entry builder-card",
      div(class = "entry-head",
          span(class = "code-chip", r$code),
          h3(r$name)
      ),
      p(class = "entry-def", r$def),
      div(class = "entry-cols",
          col("actuals", "Actuals", r$full_actuals),
          col("estimates", "Estimates", r$full_estimates),
          col("projections", "Projections", r$full_projections)
      )
  )
}

builder_tab <- function() {
  div(class = "wrap",
      tags$header(
        h1("Build Your Rubric"),
        p(class = "dek", "Describe a bill, and this pulls the parts of the rubric that actually apply \u2014 with the numbers worth chasing highlighted.")
      ),
      div(class = "builder-grid",
          div(class = "builder-controls",
              div(class = "control-block",
                  div(class = "control-label-row",
                      tags$label("Type of reform (select all that apply)"),
                      div(class = "control-links",
                          actionLink("select_all", "Select all"),
                          span(" \u00b7 "),
                          actionLink("clear_all", "Clear")
                      )
                  ),
                  checkboxGroupInput("reform_types", label = NULL, choices = reform_choices)
              ),
              div(class = "control-block",
                  tags$label("Data accessibility"),
                  radioButtons("data_access", label = NULL,
                               choices = c("Good data" = "good", "Could stretch" = "stretch", "No path" = "none"),
                               selected = "good"
                  ),
                  div(class = "hint",
                      p(tags$strong("Good data"), " \u2014 we have it, or could reasonably get it with outreach or public-records work."),
                      p(tags$strong("Could stretch"), " \u2014 no data today, but something defensible is buildable with real assumptions."),
                      p(tags$strong("No path"), " \u2014 no data, and no credible way to get it, even with more time.")
                  )
              ),
              div(class = "control-block",
                  tags$label("Bill status"),
                  radioButtons("bill_status", label = NULL,
                               choices = c("Already passed" = "passed", "Not yet passed" = "future"),
                               selected = "passed"
                  ),
                  div(class = "hint",
                      p(tags$strong("Already passed"), " \u2014 the reform has taken effect; we're measuring what actually happened."),
                      p(tags$strong("Not yet passed"), " \u2014 the reform is proposed or pending; we're anticipating what would happen.")
                  )
              )
          ),
          div(class = "builder-output",
              uiOutput("builder_result")
          )
      )
  )
}

app_css <- "
:root{
  --font-serif: 'IBM Plex Serif', Georgia, 'Times New Roman', serif;
  --font-sans: 'IBM Plex Sans', system-ui, -apple-system, 'Segoe UI', sans-serif;
  --ink: #1A2233;
  --ink-soft: #565F70;
  --ink-faint: #8891A0;
  --paper: #F6F7F5;
  --panel: #FFFFFF;
  --rule: #DCDFD9;
  --rule-strong: #C4C8C0;
  --muted-soft: #F1F1EF;

  --actuals: #3F6B4F;
  --actuals-soft: #E7F0EA;
  --actuals-line: #BFD6C6;

  --estimates: #A66A2C;
  --estimates-soft: #F5EADB;
  --estimates-line: #E1C89E;

  --projections: #514E82;
  --projections-soft: #EAE9F1;
  --projections-line: #C7C5DA;
}

body{ background: var(--paper); color: var(--ink); font-family: var(--font-sans); }
/* Bootstrap ships `.navbar.navbar-default { background-color: ... !important }`
   at specificity (0,2,0). Matching that selector (rather than plain `.navbar`)
   is what lets our override actually win instead of silently losing. */
.navbar.navbar-default{ background: var(--ink) !important; border: none; }
.navbar.navbar-default .navbar-brand{ font-family: var(--font-serif); }
.navbar.navbar-default .navbar-brand, .navbar.navbar-default .nav-link{ color: #F1F2EF !important; font-weight: 600; }
.navbar.navbar-default .nav-link.active{ color: #FFFFFF !important; border-bottom: 2px solid var(--projections); }

.wrap{ max-width: 1040px; margin: 0 auto; padding: 48px 24px 88px; }

header h1{ font-family: var(--font-serif); font-weight: 700; font-size: clamp(28px, 4vw, 40px); margin: 0 0 12px; letter-spacing: -0.01em; }
header .dek{ font-size: 17px; color: var(--ink-soft); max-width: 66ch; margin: 0 0 32px; }

.legend{ display: grid; grid-template-columns: repeat(3, 1fr); gap: 24px; padding-top: 24px; border-top: 1px solid var(--rule); }
.legend-item h2{ font-size: 14px; font-weight: 700; margin: 0 0 6px; padding-bottom: 8px; border-bottom: 2px solid currentColor; display: inline-block; }
.legend-item.actuals h2{ color: var(--actuals); }
.legend-item.estimates h2{ color: var(--estimates); }
.legend-item.projections h2{ color: var(--projections); }
.legend-item p{ margin: 10px 0 0; font-size: 14px; color: var(--ink-soft); }

.section{ margin-top: 60px; }
.section > h2.section-title{ font-family: var(--font-serif); font-weight: 600; font-size: 24px; margin: 0 0 6px; }
.section > p.section-note{ margin: 0 0 24px; color: var(--ink-soft); max-width: 62ch; font-size: 14.5px; }

.matrix-wrap{ overflow-x: auto; border: 1px solid var(--rule); border-radius: 3px; }
table.matrix{ width: 100%; border-collapse: collapse; min-width: 720px; background: var(--panel); }
table.matrix thead th{ text-align: left; font-weight: 700; font-size: 13px; padding: 14px 16px; border-bottom: 1px solid var(--rule-strong); }
table.matrix thead th.actuals{ color: var(--actuals); }
table.matrix thead th.estimates{ color: var(--estimates); }
table.matrix thead th.projections{ color: var(--projections); }
table.matrix tbody td{ padding: 14px 16px; border-bottom: 1px solid var(--rule); font-size: 13.5px; color: var(--ink-soft); vertical-align: top; }
table.matrix tbody tr:last-child td{ border-bottom: none; }
table.matrix tbody tr:hover{ background: #FBFBFA; }
.row-name{ display: flex; align-items: baseline; gap: 8px; }
.row-name a{ font-weight: 600; font-size: 14px; color: var(--ink); text-decoration: none; }
.row-name a:hover{ text-decoration: underline; }

.code-chip{ font-weight: 700; font-size: 11px; letter-spacing: 0.03em; color: var(--ink-faint); border: 1px solid var(--rule-strong); border-radius: 3px; padding: 1px 5px; flex: none; }

.entry{ padding-top: 40px; margin-top: 40px; border-top: 1px solid var(--rule); scroll-margin-top: 20px; }
.entry:first-of-type{ margin-top: 32px; }
.entry-head{ display: flex; align-items: baseline; gap: 10px; margin-bottom: 6px; }
.entry-head h3{ font-family: var(--font-serif); font-weight: 600; font-size: 20px; margin: 0; }
.entry-def{ margin: 0 0 22px; color: var(--ink-soft); max-width: 66ch; font-size: 14.5px; }

.entry-cols{ display: grid; grid-template-columns: repeat(3, 1fr); gap: 18px; margin-bottom: 22px; }
.entry-cols .col{ background: var(--panel); border: 1px solid var(--rule); border-radius: 3px; padding: 14px 16px; }
.entry-cols .col h4{ font-size: 12.5px; font-weight: 700; margin: 0 0 6px; }
.entry-cols .col.actuals h4{ color: var(--actuals); }
.entry-cols .col.estimates h4{ color: var(--estimates); }
.entry-cols .col.projections h4{ color: var(--projections); }
.entry-cols .col p{ margin: 0; font-size: 13.5px; color: var(--ink-soft); }
.entry-cols .col p + .num-list{ margin-top: 8px; }
.entry-cols .col .num-list{ margin: 0; padding-left: 18px; font-size: 13.5px; color: var(--ink-soft); }
.entry-cols .col .num-list li{ margin-bottom: 5px; }
.entry-cols .col .num-list li:last-child{ margin-bottom: 0; }
.entry-cols .col.actuals .num-list li::marker{ color: var(--actuals); font-weight: 700; }
.entry-cols .col.estimates .num-list li::marker{ color: var(--estimates); font-weight: 700; }
.entry-cols .col.projections .num-list li::marker{ color: var(--projections); font-weight: 700; }

.examples{ display: grid; grid-template-columns: 1fr 1fr; gap: 18px; }
.example{ padding: 16px 18px; border-radius: 3px; }
.example.passed{ background: var(--actuals-soft); border: 1px solid var(--actuals-line); }
.example.hypo{ background: transparent; border: 1px dashed var(--rule-strong); }
.example-label{ display: block; font-size: 12px; font-weight: 700; margin-bottom: 6px; }
.example.passed .example-label{ color: var(--actuals); }
.example.hypo .example-label{ color: var(--ink-faint); }
.example p{ margin: 0; font-size: 13.5px; color: var(--ink); }
.example p strong{ font-weight: 700; }

.foot{ margin-top: 56px; padding-top: 20px; border-top: 1px solid var(--rule); font-size: 13.5px; color: var(--ink-faint); }

/* ---- Builder tab ---- */

.builder-grid{ display: grid; grid-template-columns: 300px 1fr; gap: 36px; align-items: start; }

.builder-controls{ position: sticky; top: 16px; background: var(--panel); border: 1px solid var(--rule); border-radius: 4px; padding: 22px; }
.control-block{ margin-bottom: 26px; }
.control-block:last-child{ margin-bottom: 0; }
.control-block > label{ font-weight: 700; font-size: 13.5px; color: var(--ink); display: block; margin-bottom: 8px; }
.control-label-row{ display: flex; justify-content: space-between; align-items: baseline; gap: 8px; margin-bottom: 8px; }
.control-label-row label{ margin: 0; }
.control-links{ font-size: 12px; color: var(--ink-faint); white-space: nowrap; }
.control-links a{ color: var(--projections); text-decoration: none; cursor: pointer; }
.control-links a:hover{ text-decoration: underline; }

.builder-controls .shiny-options-group{ margin-top: 2px; }
.builder-controls .checkbox, .builder-controls .radio{ margin-bottom: 4px; font-size: 13.5px; }

.hint{ margin-top: 10px; padding-top: 10px; border-top: 1px solid var(--rule); }
.hint p{ margin: 0 0 6px; font-size: 12px; color: var(--ink-soft); }
.hint p:last-child{ margin-bottom: 0; }

.builder-output{ min-height: 200px; }

.empty-state{ border: 1px dashed var(--rule-strong); border-radius: 4px; padding: 40px 24px; text-align: center; color: var(--ink-faint); font-size: 14.5px; }

.rule-message{ background: var(--panel); border: 1px solid var(--rule-strong); border-left: 3px solid var(--projections); border-radius: 3px; padding: 16px 20px; margin-bottom: 28px; font-size: 14.5px; color: var(--ink); }

.builder-card .entry-cols .col.is-muted{ opacity: 0.5; }
.builder-card .entry-cols .col.is-primary.actuals{ border: 2px solid var(--actuals); background: var(--actuals-soft); }
.builder-card .entry-cols .col.is-primary.estimates{ border: 2px solid var(--estimates); background: var(--estimates-soft); }
.builder-card .entry-cols .col.is-primary.projections{ border: 2px solid var(--projections); background: var(--projections-soft); }
.builder-card .entry-cols .col.is-secondary.actuals{ border: 1px dashed var(--actuals-line); }
.builder-card .entry-cols .col.is-secondary.estimates{ border: 1px dashed var(--estimates-line); }
.builder-card .entry-cols .col.is-secondary.projections{ border: 1px dashed var(--projections-line); }

.focus-badge{ display: inline-block; font-size: 10.5px; font-weight: 700; padding: 2px 7px; border-radius: 3px; margin-bottom: 8px; letter-spacing: 0.01em; }
.col.is-primary.actuals .focus-badge{ background: var(--actuals); color: #fff; }
.col.is-primary.estimates .focus-badge{ background: var(--estimates); color: #fff; }
.col.is-primary.projections .focus-badge{ background: var(--projections); color: #fff; }
.col.is-secondary .focus-badge{ background: transparent; border: 1px solid var(--rule-strong); color: var(--ink-soft); }
.col.is-muted .focus-badge{ background: transparent; border: 1px solid var(--rule); color: var(--ink-faint); }

@media (max-width: 860px){
  .builder-grid{ grid-template-columns: 1fr; }
  .builder-controls{ position: static; }
}
@media (max-width: 700px){
  .wrap{ padding: 36px 16px 64px; }
  .legend{ grid-template-columns: 1fr; gap: 18px; }
  .entry-cols{ grid-template-columns: 1fr; }
  .examples{ grid-template-columns: 1fr; }
}
"

theme <- bs_theme(
  version = 5,
  bg = "#F6F7F5",
  fg = "#1A2233",
  primary = "#514E82"
)

# Fonts are loaded client-side (browser fetches from Google Fonts directly)
# rather than via bslib's font_google(), which asks the R process itself to
# download font files at app-start and fails on any machine or server
# without outbound access to fonts.googleapis.com.
font_links <- tags$head(
  tags$link(rel = "preconnect", href = "https://fonts.googleapis.com"),
  tags$link(rel = "preconnect", href = "https://fonts.gstatic.com", crossorigin = "anonymous"),
  tags$link(
    href = "https://fonts.googleapis.com/css2?family=IBM+Plex+Serif:wght@400;600;700&family=IBM+Plex+Sans:wght@400;500;600;700&display=swap",
    rel = "stylesheet"
  )
)

ui <- page_navbar(
  title = "Impact Measurement Rubric",
  theme = theme,
  header = tagList(font_links, tags$head(tags$style(HTML(app_css)))),
  nav_panel("Explainer", explainer_tab()),
  nav_panel("Build Your Rubric", builder_tab())
)

server <- function(input, output, session) {
  
  observeEvent(input$select_all, {
    updateCheckboxGroupInput(session, "reform_types", selected = reform_codes)
  })
  observeEvent(input$clear_all, {
    updateCheckboxGroupInput(session, "reform_types", selected = character(0))
  })
  
  output$builder_result <- renderUI({
    selected <- input$reform_types
    if (is.null(selected) || length(selected) == 0) {
      return(div(class = "empty-state",
                 "Select at least one reform type to see what numbers you'll need."
      ))
    }
    
    rule <- get_rule(input$data_access, input$bill_status)
    selected_reforms <- Filter(function(r) r$code %in% selected, reforms)
    
    tagList(
      div(class = "rule-message", rule$message),
      lapply(selected_reforms, function(r) builder_card(r, rule))
    )
  })
}

shinyApp(ui, server)