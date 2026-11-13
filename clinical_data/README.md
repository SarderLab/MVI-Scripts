# Clinical Data Check

`clinical_match.ipynb` compares the slides in an Athena folder with the clinical Excel
(`MVI_DeID_*.xlsx`) and tells you:

1. **Missing slides:** DeIDs that are in the Excel but have no slide in the folder.
2. **Missing data:** slides whose clinical data is incomplete, naming the blank columns
   (or "No clinical data in Excel" if the slide has no row at all).

Read-only: nothing on Athena or in the Excel is changed.

---

## How slides are matched

The DeID is read from the slide name: `JHH_DS_12 CD34LCA.ndpi` → `JHH_DS_12`, and looked up in the Excel's
`DeID` column. `JHH-DS-012`, `jhh ds 12` etc. also match. Non-image files (e.g. `.xml`) are ignored.

## Step 1: Configure

Open `clinical_match.ipynb` and set:

| Setting | What to put |
|---|---|
| `EXCEL_PATH` | Path to the clinical Excel on HiPerGator |
| `HEADER_ROW` | `1` for the MVI file (column names are on the 2nd row) |
| `FOLDER_IDS` | The Athena folder ID(s) with the slides |
| `CHECK_COLUMNS` | Columns that must be filled in (default: biopsy days, AMR, TCMR and the Banff scores) |
| `CHECK_DSA` | `True` to also check the DSA columns (they are often blank because no test was done) |

Log in as described in the [main README](../README.md#3-log-in-to-athena).


## Step 2: Output

Printed on screen and saved as `clinical_check.xlsx`:

| Sheet | Columns |
|---|---|
| Missing slides | `DeID` |
| Missing data | `DeID`, `Slide`, `Missing` (e.g. `v, cv`) |

A cell containing only a space counts as blank.

**`clinical_check.xlsx` contains clinical information: keep it on HiPerGator, never commit it.**
