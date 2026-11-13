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
| [`ptc_model_training`](https://github.com/SarderLab/MVI-Scripts/tree/3d073e0454750281dc6f8d96a7ebf6b1a3fd4511/ptc_model_training) | `Dataset_Creation.ipynb`, `PTC_Model_Training.ipynb` | How the PTC segmentation model (`best_model.h5`) was built and trained | Reference / retraining |
| [`legacy_notebooks`](https://github.com/SarderLab/MVI-Scripts/tree/3d073e0454750281dc6f8d96a7ebf6b1a3fd4511/legacy_notebooks) | `WSI_To_XML.ipynb`, `Final_Pipeline.ipynb` | Earlier versions of the slide pipeline | Replaced by `iptcr_pipeline` |
| [`iptcr_pipeline`](https://github.com/SarderLab/MVI-Scripts/tree/3d073e0454750281dc6f8d96a7ebf6b1a3fd4511/iptcr_pipeline) | `mvi_pipeline.ipynb`, `validate_iptcr.ipynb`, `run_mvi.sh` | Segment glomeruli, arteries, PTCs and leukocytes on Athena slides, compute iptcr, upload layers, validate | **Use this** |
| [`clinical_data`](https://github.com/SarderLab/MVI-Scripts/tree/3d073e0454750281dc6f8d96a7ebf6b1a3fd4511/clinical_data) | `clinical_match.ipynb` | Check which slides have clinical data in the MVI Excel and which data is missing | Use this |

Each folder has its own README with step-by-step instructions.

### How the pieces fit together
 
```
ptc_model_training/Dataset_Creation.ipynb    ->  TFRecords (training patches)
ptc_model_training/PTC_Model_Training.ipynb  ->  best_model.h5 (PTC model)
(separate project)                           ->  transunet_multiclass_denseNet_dice_newdata.h5 (glomerulus/artery model)
                                   |
                                   v
iptcr_pipeline/mvi_pipeline.ipynb    ->  iptcr per slide + AI layers on Athena + Excel + QC images
iptcr_pipeline/validate_iptcr.ipynb  ->  compares iptcr with existing scores and Banff ptc / AMR / DSA
clinical_data/clinical_match.ipynb   ->  which slides have / lack clinical data in the MVI Excel
```
 
---
 
## One-time setup
 
### 1. Jupyter on HiPerGator
 
1. Open Jupyter on HiPerGator (Open OnDemand → Jupyter).
2. For `mvi_pipeline.ipynb`, request a **GPU** (GPU partition, 1 GPU). The other notebooks run on CPU.
3. Choose the kernel / environment that has **TensorFlow**: the same one the model notebooks ran in,
   because it has the TensorFlow version that saved the `.h5` models.
### 2. Install the packages (once, in that environment)
 
Run this in a notebook cell:
```python
%pip install girder-client openslide-python openslide-bin opencv-python-headless scikit-image scipy pandas openpyxl matplotlib
```
Then restart the kernel (Kernel → Restart).
 
### 3. Get the notebooks
 
```bash
git clone <this-repo-url>
```
or download the repo as a ZIP from GitHub and upload the folder to HiPerGator.
 
### 4. Log in to Athena
 
The notebooks log in with **one** of:
- an API key in the environment variable `ATHENA_API_KEY` (create the key on Athena: your name →
  **My account** → **API keys**). DevAthena: `DEVATHENA_API_KEY`.
- or nothing: the notebook asks for your Athena **username and password** when it runs (password is hidden).
**Never type an API key into a notebook cell you commit.**
 
### 5. Find the IDs the notebooks ask for
 
| You need | Where to find it |
|---|---|
| **Folder ID** | Open the folder in Athena's data browser: the part of the URL after `folder/`, or the folder's **ⓘ** icon |
| **Item (slide) ID** | Open the slide in HistomicsUI: the part of the URL after `?image=` |
 
### 6. Models and data (not in this repo)
 
| What | Where it is | Why it's not in Git |
|---|---|---|
| PTC model `best_model.h5` | HiPerGator (path set in `mvi_pipeline.ipynb`) | Too large for GitHub |
| Glom/artery model `transunet_multiclass_denseNet_dice_newdata.h5` | HiPerGator (path set in `mvi_pipeline.ipynb`) | Too large for GitHub |
| Clinical Excel `MVI_DeID_*.xlsx` | HiPerGator | Clinical data |
| Slides | Athena | Patient data |
 
---
 
## Ground rules
 
- **Test on one slide first** (the notebooks have an `ITEM_ID` setting), then run the whole folder.
- **No patient data in this repo:** no slides, Excel/CSV results, QC images, or notebook outputs.
  **Clear all outputs before committing** (Jupyter: Edit → Clear All Outputs, then save): saved outputs contain
  slide names, which include accession numbers, and tissue images.
- AI layers on Athena always start with **`AI `** so they can never overwrite the approved layers.
