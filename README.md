# MVI-Scripts

Code for measuring **microvascular inflammation (MVI)** in kidney transplant biopsies stained with
**CD34-LCA** (CD34 = capillary walls, red; LCA/CD45 = leukocytes, brown), following
*Delsante et al., Transplant International 2019*.

The main output is the **iptcr** score: the fraction of peritubular capillaries (PTCs) that contain
at least one leukocyte. The slides live on the Digital Slide Archive (DSA / HistomicsUI):

| Server | API URL |
|---|---|
| Athena (official) | `https://athena.rc.ufl.edu/api/v1/` |
| DevAthena (testing) | `https://devathena.rc.ufl.edu/api/v1/` |

---

## Folders

| Folder | Files | Purpose | Status |
|---|---|---|---|
| [`[ptc_model_training]`](https://github.com/SarderLab/MVI-Scripts/tree/3d073e0454750281dc6f8d96a7ebf6b1a3fd4511/ptc_model_training) | `Dataset_Creation.ipynb`, `PTC_Model_Training.ipynb` | How the PTC segmentation model (`best_model.h5`) was built and trained | Reference / retraining |
| [`[legacy_notebooks]`](https://github.com/SarderLab/MVI-Scripts/tree/3d073e0454750281dc6f8d96a7ebf6b1a3fd4511/legacy_notebooks) | `WSI_To_XML.ipynb`, `Final_Pipeline.ipynb` | Earlier versions of the slide pipeline | Replaced by `iptcr_pipeline` |
| [`[iptcr_pipeline]`](https://github.com/SarderLab/MVI-Scripts/tree/3d073e0454750281dc6f8d96a7ebf6b1a3fd4511/iptcr_pipeline) | `mvi_pipeline.ipynb`, `validate_iptcr.ipynb`, `run_mvi.sh` | Segment glomeruli, arteries, PTCs and leukocytes on Athena slides, compute iptcr, upload layers, validate | **Use this** |
| [`clinical_data`](https://github.com/SarderLab/MVI-Scripts/tree/3d073e0454750281dc6f8d96a7ebf6b1a3fd4511/clinical_data) | `clinical_match.ipynb` | Check which slides have clinical data in the MVI Excel and which data is missing | Use this |

Each folder has its own README with step-by-step instructions.

### How the pieces fit together

```
ptc_model_training/Dataset_Creation.ipynb  ->  TFRecords (training patches)
ptc_model_training/PTC_Model_Training.ipynb  ->  best_model.h5 (PTC model)
(separate project)  ->  transunet_multiclass_denseNet_dice_newdata.h5 (glomerulus/artery model)
                                   |
                                   v
iptcr_pipeline/mvi_pipeline.py   ->  iptcr per slide + AI layers on Athena + Excel + QC images
iptcr_pipeline/validate_iptcr.py ->  compares iptcr with existing scores and Banff ptc / AMR / DSA
clinical_data/clinical_match.py  ->  which slides have / lack clinical data in the MVI Excel
```

---

## One-time setup

### 1. Python environment (HiPerGator)

Use the conda environment the notebooks ran in (it has the TensorFlow version that saved the `.h5` models),
then add the remaining packages:

```bash
module load conda
conda activate <your-tensorflow-env>
pip install -r requirements.txt
```

The slide pipeline needs a **GPU**: start Jupyter on the GPU partition, or submit `iptcr_pipeline/run_mvi.sh`.

### 2. Get the code

```bash
git clone <this-repo-url>
cd MVI-Scripts
```

### 3. Log in to Athena

Scripts log in with **one** of:
- an API key in an environment variable (create it on Athena: your name → **My account** → **API keys**):
  ```bash
  export ATHENA_API_KEY="paste-your-key-here"        # DevAthena: DEVATHENA_API_KEY
  ```
- or nothing: the script asks for your Athena **username and password** when it starts.

**Never write a key into a file you commit.** (`common.py` is in `.gitignore` for this reason.)

### 4. Find the IDs the scripts ask for

| You need | Where to find it |
|---|---|
| **Folder ID** | Open the folder in Athena's data browser: the part of the URL after `folder/`, or the folder's **ⓘ** icon |
| **Item (slide) ID** | Open the slide in HistomicsUI: the part of the URL after `?image=` |

### 5. Models and data (not in this repo)

| What | Where it is | Why it's not in Git |
|---|---|---|
| PTC model `best_model.h5` | HiPerGator (path in `mvi_pipeline.py`) | Too large for GitHub |
| Glom/artery model `transunet_multiclass_denseNet_dice_newdata.h5` | HiPerGator (path in `mvi_pipeline.py`) | Too large for GitHub |
| Clinical Excel `MVI_DeID_*.xlsx` | HiPerGator | Clinical data |
| Slides | Athena | Patient data |

---

## Ground rules

- **Test on one slide first** (every script has an `ITEM_ID` setting), then run the folder.
- **Nothing in this repo may contain patient data:** no slides, Excel/CSV results, QC images, or outputs
  with accession numbers. `.gitignore` blocks the usual files; **clear notebook outputs before committing**
  (`jupyter nbconvert --clear-output --inplace *.ipynb`).
- AI layers on Athena always start with **`AI `** so they can never overwrite the approved layers.
