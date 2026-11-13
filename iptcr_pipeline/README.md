# iptcr Pipeline

Computes **iptcr** for CD34-LCA slides stored on Athena, and draws the result on the slides.

| File | What it does |
|---|---|
| `mvi_pipeline.ipynb` | The pipeline: download slide → segment → iptcr → save results / upload layers |
| `validate_iptcr.ipynb` | Checks whether the iptcr is trustworthy (vs. existing scores and Banff ptc / AMR / DSA) |
| `run_mvi.sh` | Runs `mvi_pipeline.py` as a SLURM GPU job on HiPerGator (optional; for long runs) |

---

## What `mvi_pipeline.py` does, per slide

1. Downloads the slide from Athena to `WORK_DIR` (deleted again afterwards).
2. Reads it at **0.912 µm/px**, the resolution both models were trained at, whatever the scanner or file
   type (`.ndpi`, `.svs`); background is skipped.
3. **PTCs:** PTC U-Net (`best_model.h5`) on overlapping 224 px tiles; overlaps are blended, centre-weighted.
4. **Glomeruli and arteries:** TransUNet on its own 512 px tiles so whole glomeruli fit in one tile.
5. **Leukocytes (brown):** colour deconvolution with stain vectors measured on our slides, plus a hue check,
   so red CD34 walls are not mistaken for brown.
6. **PTCs not counted:** specks, PTCs inside glomeruli/arteries, PTCs embedded in brown aggregates,
   and (optional) PTCs outside an ROI layer such as "cortex".
7. **iptcr** = PTCs with ≥ 1 leukocyte inside or touching them ÷ PTCs counted.
   Also reported with the older "≥ 3 / 8 / 15 % of the PTC is brown" rules for comparison.

### Layers (same 5 as the approved data, with an `AI ` prefix)

| Layer | Contents |
|---|---|
| `AI glomerulus` | Glomeruli |
| `AI artery` | Arteries |
| `AI ptc` | Counted peritubular capillaries |
| `AI dab_inflamed` | Dense brown infiltrate regions (≥ 24,000 µm², as in the approved data) |
| `AI dab_normal` | All other brown (individual leukocytes) |

---

## Step 1: Configure

Open `mvi_pipeline.py` and set, at the top:

| Setting | What to put |
|---|---|
| `INSTANCE` | `"athena"` or `"devathena"` |
| `FOLDER_IDS` | The Athena folder ID(s); subfolders are included |
| `ITEM_ID` | One slide's item ID for a test. **Comment out the second `ITEM_ID` line to run the whole folder.** |
| `WORK_DIR` | A folder on `/blue` for downloads and results |
| `PTC_MODEL_PATH`, `GLOM_MODEL_PATH` | Paths to the two `.h5` models |
| `ACTION` | `"check"`, `"run"` or `"upload"` (see below) |
| `RERUN` | `True` = process slides again; `False` = skip slides already done |
| `UPLOAD_TO_ATHENA` | `True` = add the AI layers to the slide on Athena after each slide |

Most other settings can stay as they are; the ones worth tuning are under **Tuning** below.

## Step 2: Run

**In Jupyter** (GPU session, TensorFlow kernel): put `mvi_pipeline.py` next to the notebook and run
```python
%run mvi_pipeline.py
```
(or paste the whole file into one cell).

**As a batch job** (recommended for a whole folder, keeps running if you close the browser):
1. In `run_mvi.sh`, set `TF_ENV` to your TensorFlow environment name.
2. From this folder:
   ```bash
   sbatch run_mvi.sh                       # what mvi_pipeline.py is set to
   sbatch run_mvi.sh --item-id <ID>        # one slide
   sbatch --array=0-3 run_mvi.sh           # split the folder over 4 GPUs
   sbatch run_mvi.sh --action upload --yes # upload saved results (no keyboard in batch jobs)
   ```
3. Progress: `tail -f mvi_iptcr_<jobid>_*.log`

### The three actions

| `ACTION` | Changes Athena? | What it does |
|---|---|---|
| `check` | No | Lists the slides and which already have iptcr (from this pipeline, Athena metadata, or `REFERENCE_CSV`) |
| `run` | Only if `UPLOAD_TO_ATHENA` / `WRITE_METADATA` are `True` | Runs the pipeline |
| `upload` | Yes (asks for `YES`) | Uploads the layers of slides that already ran, without running the models again |

## Step 3: Results (in `WORK_DIR`)

| File | Contents |
|---|---|
| `iptcr_results.xlsx` | One row per slide: iptcr, PTCs counted / inflamed / excluded, glomeruli, arteries, leukocytes. Sheets for errors and the settings used |
| `iptcr_results.csv` | Same numbers as CSV (used by `validate_iptcr.py`) |
| `tables/<slide>.xlsx` | One row per PTC: status, position (level-0 pixels), area, leukocyte pixels, % brown |
| `xml/<slide>.xml` | The 5 layers as Aperio XML (used by `upload`; can also be imported into HistomicsUI) |
| `qc/<slide>_overview.png`, `_crop1-4.png` | Pictures of the detections: PTC green, inflamed red, glomerulus blue, artery magenta, leukocyte yellow |

**Always look at the QC images and the AI layers on Athena for the first slides before trusting the numbers.**

## Step 4: Validate

Open `validate_iptcr.py`, set `RESULTS_CSV`, `OUTPUT_DIR`, `CLINICAL_XLSX` and (if you have older scores)
`REFERENCE_CSV`, then:
```bash
python validate_iptcr.py
```
`validation_summary.txt` reports, in plain language:
- agreement with existing iptcr scores (Pearson / Spearman, error, Bland–Altman),
- correlation of iptcr with the pathologists' **Banff ptc** and **g**, AUC for **ptc ≥ 2** and **AMR**,
- iptcr by **DSA strength**,

for each iptcr rule, so you can see which rule matches the pathologists best.
A working model shows iptcr rising with Banff ptc and DSA strength, as in Delsante et al. 2019.

---

## Tuning (compare with approved layers on a few slides first)

| Problem seen on Athena / QC images | Setting to change |
|---|---|
| Glomeruli in pieces | `GLOM_READ_SIZE = 1024` |
| Too many / too few PTCs | Raise / lower `PTC_THRESHOLD` (default 0.5) |
| Red capillary walls marked as brown | Raise `DAB_THRESHOLD` (e.g. 0.35) |
| Faint brown cells missed | Lower `DAB_THRESHOLD` (e.g. 0.18) |
| `AI dab_inflamed` regions too small / too few | Lower `INFILTRATE_MIN_AREA_UM2` |
| Separate brown clusters joined | Lower `INFILTRATE_MERGE_PX` (e.g. 3) |
| Only cortex should count | `ROI_LAYER_NAME = "cortex"` (name of an Athena layer on each slide) |

After changing settings, re-run with `RERUN = True`; the old AI layers are replaced, not duplicated.

## Troubleshooting

| Message | Fix |
|---|---|
| `unrecognized arguments: -f ...kernel.json` | Old copy of the script: use this version (it ignores Jupyter's arguments) |
| `UnboundLocalError ... 'ptc'` | Part of `analyse()` is missing: replace the whole function from this file |
| `'polygon' is not one of ['polyline']` | Old copy: this version uploads closed polylines |
| `HTTP error 401` / `403` | Not logged in / no permission on that folder |
| `GPUs: none` | Start Jupyter / the job on a GPU partition |
| `No keyboard (batch job)` | Add `--yes` to upload from a batch job |
