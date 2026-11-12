# PTC Model Training

How the **PTC segmentation model** (`best_model.h5`) used by `iptcr_pipeline` was built.
Run these only to rebuild or retrain the model.

| Notebook | Step |
|---|---|
| `Dataset_Creation.ipynb` | 1. Slides + hand-drawn PTC XML → masks → 224×224 patches → train / val / test TFRecords |
| `PTC_Model_Training.ipynb` | 2. Train the model on the TFRecords, then (later cells) predict on slides, score iptcr and plot ROC |

Run them **in this order**. File paths inside the notebooks point to HiPerGator folders; change them to yours.
Slide file names were replaced with `<SLIDE_NAME>` for privacy: put your own file names back in.

---

## 1. `Dataset_Creation.ipynb`

- **Input:** 11 CD34-LCA slides (`.ndpi`) with matching XML files of hand-drawn PTC outlines.
- Draws the outlines into masks at **level 2** (4× downscaled, ~0.91 µm/px).
- Cuts slide + mask into **224×224** patches (25% overlap), keeping patches that contain a PTC.
- Splits **by slide** (8 train / 2 validation / 1 test) so no slide appears in two sets.
- **Output:** `train.tfrecord`, `val.tfrecord`, `test.tfrecord`.

## 2. `PTC_Model_Training.ipynb`

- **Model:** U-Net with an **EfficientNet-B4** encoder (ImageNet weights), attention gates on the skip
  connections and residual decoder blocks; the first 100 encoder layers are frozen.
- **Input:** 224×224 RGB scaled to 0–1. **Output:** PTC probability per pixel.
- **Loss:** weighted Dice (50%) + weighted Tversky (40%, favours recall) + focal BCE (10%).
- **Training:** Adam (learning rate 1e-5), up to 100 epochs, early stopping on validation Dice; best model saved
  as `best_model.h5`.
- **Recorded result** (1 test slide, pixel level): ROC AUC 0.98, average precision 0.77.
- Later cells are an older version of slide prediction and iptcr scoring; use `iptcr_pipeline` instead.

---

## Requirements

GPU environment with TensorFlow (the version used to save `best_model.h5`), `openslide-python`, `opencv-python`,
`scikit-image`, `numpy`, `matplotlib`.

## Known limitations (fix these when retraining)

| Limitation | Effect | Fix |
|---|---|---|
| Only patches containing a PTC are kept | Model never sees PTC-free tissue → false positives on whole slides | Add 30–50% tissue patches without PTCs |
| Masks drawn with `cv.fillConvexPoly` | Irregular PTCs become too fat in the masks | Use `cv.fillPoly` |
| Inputs divided by 255 before EfficientNet | Keras EfficientNet expects 0–255; pretrained features are weakened | Remove `/255` (and in the pipeline, for the new model) |
| Flips/rotations only | Sensitive to stain differences between batches | Add colour / stain augmentation |
| Augmentation also applied to validation/test | Evaluation not clean | Augment the training set only |
| 1 test slide | Results say little about other slides | Cross-validation across slides |

Stronger alternatives to compare against: **nnU-Net**, instance models (**StarDist**, **Cellpose**),
or a U-Net with a pathology-pretrained encoder.

**Before committing:** clear outputs (`jupyter nbconvert --clear-output --inplace *.ipynb`): saved outputs
contain slide names and tissue images.
