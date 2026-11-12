# Impact Measurement Rubric

An R Shiny app that helps REFORM Alliance decide what kind of number a policy reform calls for (an actual, an estimate or a projection) and what data that number depends on. The idea is to work this out before we ask Recidiviz or anyone else to go find the number.

**Live app:** <https://bfs6-impact-measurement-rubric.share.connect.posit.cloud/>

The rubric is also written up as a Google Doc, "Internal Impact Measurement Rubric". The app is the interactive version. Its footer says the rubric is built from REFORM's bill-by-bill data review across 12 states, the same review behind the [Recidiviz projections dashboard](https://github.com/REFORM-Alliance/recidiviz-projections).

The repository holds only the app. It reads no data files and needs no secrets: all the content is written into `app.R`.

## The three measurement types

| Type | What it means |
| --- | --- |
| **Actuals** | Directly observed and reported by an official source. Retrieval and adding up only, with no modeling. |
| **Estimates** | A number that exists in the world but cannot be observed directly. It is inferred from proxy data and stated assumptions. |
| **Projections** | Forward-looking. Describes an outcome that has not happened yet, built by extending a current trend or rate. |

## What the app does

**Explainer tab.** A table with one row for each of eight reform types, showing the actual, the estimate and the projection each one calls for. Each name links to a detail entry below the table, which explains the three numbers in full and gives two examples: a bill that has already passed and a hypothetical bill.

**Build Your Rubric tab.** Choose one or more reform types, how accessible the data is, and whether the bill has passed. The app shows a card for each reform type chosen, with the measurement type to focus on marked "Focus here", a second type marked "Also useful" and the rest faded as "Not the priority". A sentence at the top explains the advice in plain language.

### The eight reform types

| Code | Reform type | Passed-bill example used in the app |
| --- | --- | --- |
| SC | Sentence Caps & Limits | California AB 1950 |
| PE | Parole & Release Eligibility | Mississippi SB 2795 |
| ET | Early Termination & Supervision Length | Illinois SB 423 |
| VR | Violation Response & Individualized Conditions | Michigan SB 1051 |
| RR | Remote / Reduced-Contact Reporting | Louisiana HB 77 |
| RC | Record Relief (Expungement & Sealing) | Maryland SB 432 |
| DA | Diversion & Alternatives to Incarceration | California AB 3234 |
| MM | Mandatory Minimum Reform | New Jersey A3469 |

The reform types are groupings made for this rubric, not official legislative categories. A bill can fit more than one row.

### The decision rule

The advice on the Build tab depends only on the two questions, not on the reform type. The reform type decides which cards are shown.

| Data accessibility | Bill status | Focus on | Also useful | What the app says |
| --- | --- | --- | --- | --- |
| Good data | Already passed | Actuals | Projections | Go and get the actuals, then project the trend forward |
| Could stretch | Already passed | Estimates | Projections | No clean actuals, but a defensible estimate can be built, and it can anchor a rough projection |
| No path | Already passed | None | None | Not currently measurable without new data collection or an agency partnership |
| Good data | Not yet passed | Projections | Estimates | There are no actuals yet, so build a projection and size the affected population with an estimate |
| Could stretch | Not yet passed | Projections | Estimates | Estimate the affected population first, and treat the projection on top of it as low-confidence |
| No path | Not yet passed | None | None | Not currently measurable, because even a projection would be closer to a guess |

On the Build tab, "Good data" means the data exists or could be had with outreach or public-records work. "Could stretch" means no data today but something defensible can be built with real assumptions. "No path" means no data and no credible way to get any.

## How the app is built

Everything is in one file, `app.R` (about 680 lines):

| Part | What it holds |
| --- | --- |
| `reforms` list | One entry per reform type with all of its text: code, name, one-line definition, the short versions for the table (`matrix_actuals`, `matrix_estimates`, `matrix_projections`), the full versions for the detail and Build cards (`full_*`), the passed-bill example (`passed_bill`, `passed_text`) and the hypothetical (`hypo_text`) |
| `get_rule()` | The decision rule in the table above |
| Helper functions | Build the table, the detail entries and the Build cards from the `reforms` list |
| `app_css` | The styling, written into the page |
| `ui` and `server` | A two-tab page (`bslib`), with a server that redraws the Build tab whenever a choice changes |

A `full_*` value is either one sentence (shown as a paragraph) or a list with a `lead` sentence and `items` (shown as a numbered list). The app needs `shiny`, `bslib` and `htmltools`. The fonts (IBM Plex) are loaded by the visitor's browser from Google Fonts, so the server needs no outbound access for them.

## Repository layout

| Path | What it is |
| --- | --- |
| `app.R` | The whole app |
| `manifest.json` | The list of files and packages Posit Connect Cloud uses to build the app |
| `renv.lock`, `renv/`, `.Rprofile` | Pinned package versions (R 4.5.0, 31 packages) and the startup file that turns `renv` on |
| `impact-measurement-rubric.Rproj` | RStudio / Workbench project file |

## Change the content

Edit the `reforms` list in `app.R`, then publish (below).

- **To reword a cell or an example,** change that field. The table, the detail entry and the Build card all read from it.
- **To add a reform type,** copy one `list(...)` entry, give it a new two-letter `code`, and fill in every field. The table, the detail entries, the checkbox list and the Build cards pick it up on their own.
- **To change the advice,** edit `get_rule()`. Keep the Google Doc's "Builder logic reference" table in step with it.
- **Keep the Google Doc and the app matching.** There is no link between them, so a change made in one has to be made by hand in the other. See [Known issues](#known-issues).

## Run it on your computer

1. Install R 4.5.0 and open `impact-measurement-rubric.Rproj` in RStudio.
2. Run `renv::restore()` once.
3. Run `shiny::runApp("app.R")`.

## Publish

The app is hosted on [Posit Connect Cloud](https://connect.posit.cloud). The live app is at <https://bfs6-impact-measurement-rubric.share.connect.posit.cloud/>. Connect Cloud copies the code from GitHub and builds the app itself, so publishing an update means getting the change onto the GitHub branch it follows (normally `main`; **Settings > Source** in Connect Cloud shows which). Nothing is uploaded from your computer. Addresses have the form `https://<account>-<custom name>.share.connect.posit.cloud`. This one uses the account name `bfs6`, the same as REFORM's other dashboards, and the custom name `impact-measurement-rubric`.

### Publish an update

1. Make and test the change on your computer.
2. If you added or upgraded an R package, run `renv::snapshot()` and then `rsconnect::writeManifest()` in the R console, and commit both `renv.lock` and `manifest.json`. Connect Cloud reads `manifest.json` for the package list, so a stale one gives the live app the wrong packages or fails the build.
3. Commit and push to `main`, or merge a pull request into it. "Automatically publish on push" is on by default, so Connect Cloud rebuilds and redeploys the app at the same address.
4. Open the live address and check both tabs, including the Build tab with a few combinations of choices.
5. If the live app did not change, sign in to Connect Cloud, open the app's card and look at the publish log for an error. **Republish** on the card redeploys from the latest code on GitHub.

### Publish for the first time, or re-create the app

1. Run `rsconnect::writeManifest()` in the R console. Commit and push `app.R` and `manifest.json`.
2. Sign in to [Connect Cloud](https://connect.posit.cloud) with the account named `bfs6`, which owns the `share.connect.posit.cloud` addresses.
3. Click **Publish** at the top of your Home page. The first time, Connect Cloud asks you to install its GitHub App; give it access to this repository. A repo owned by the REFORM-Alliance organization may need an organization owner to approve the app.
4. Choose **Shiny**, then select this repository.
5. Confirm the **Branch** is `main` and the **Primary file** is `app.R`. Leave **Automatically publish on push** on.
6. Click **Publish** and watch the build log.
7. Open the app's **Settings > URL** and set the custom name to `impact-measurement-rubric`. The address becomes `https://bfs6-impact-measurement-rubric.share.connect.posit.cloud`.
8. Open the address in a private browser window to check that someone who is not signed in to Connect Cloud can use it.

### If something goes wrong

- **The repository is missing from the Publish list.** Connect Cloud's GitHub App does not have access to it. Give the app access in GitHub, then reload the list.
- **Free accounts can publish only public repositories.** If this repository is ever made private, the account needs a paid plan.
- **The build fails after a package change.** Run `rsconnect::writeManifest()` again, commit `manifest.json` and push.
- **No secrets to set.** `app.R` reads no environment variables, so nothing is needed under Advanced settings.

## Known issues

These come from reading the code and the Google Doc. I could not run the app.

- **The app is behind the Google Doc.** The Doc was last edited on September 18, 2026 and the last app commit is from September 3, 2026. Differences I found:
  - The Doc names the early-termination row "Early Termination & Supervision Length, Including Incentives". The app leaves out "Including Incentives".
  - The Doc's early-termination actuals can come from "the supervising agency, courts, or other reliable source". The app says only the supervising agency.
  - The Doc's remote-reporting actuals in the overview table read "Agency-reported usage in total and per capita". The app says "Almost never available without a new agency reporting requirement".
  - The Doc says "agency or other reliable source reporting" and "correctional data" where the app says "agency or task-force reporting" and "DOC data" (parole and release eligibility).

  There may be more. Decide which version is right, then update the other.
- **The examples have no sources in the repository.** Bill numbers and figures (for example the 9,339 people made eligible and 2,335 released under Mississippi SB 2795, and the 175,000 expunged convictions in Maryland) are written into `app.R`. Check them against the data review before quoting them outside REFORM.
- **`manifest.json` is out of date.** The `app.R` checksum in it does not match the committed file. Run `rsconnect::writeManifest()` and commit the result before the next publish.
- **Nothing links the Doc and the app.** There is no test or check that they agree.

## Sources

- Internal Impact Measurement Rubric (Google Doc, last edited September 18, 2026)
- `app.R` and `manifest.json` in this repository