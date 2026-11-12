# Legacy Notebooks

Earlier versions of the slide pipeline, kept for reference. **For new work use
[`iptcr_pipeline`](../iptcr_pipeline)**, which replaces both.

| Notebook | What it did | Replaced by |
|---|---|---|
| `WSI_To_XML.ipynb` | PTC model on local slides → PTC XML; brown-stain detection by HSV colour ranges; iptcr per slide | `mvi_pipeline.py` |
| `Final_Pipeline.ipynb` | Glom/artery TransUNet + PTC model + DAB colour deconvolution → 5-layer Aperio XML (no iptcr) | `mvi_pipeline.py` |

## Why they were replaced

| Issue in the legacy notebooks | In `iptcr_pipeline` |
|---|---|
| `WSI_To_XML`: 512 px tiles shrunk to 224 → PTCs ~2.3× too small for the model | Tiles read at the model's training resolution |
| Glom model fed 224 px tiles stretched to 512 → glomeruli in fragments | Glom model gets its own 512 px tiles |
| Brown detection counted red CD34 walls as brown | Measured stain vectors + hue check |
| "Large DAB" area computed with the wrong pixel size (16× off) | Correct µm² from the slide's pixel size |
| Fixed "level 2" breaks on `.svs` files (level 2 = 16× there) | Resolution chosen from each slide's pixel size |
| Inflamed cut-off varied (3 / 8 / 15 %) | Paper definition (≥ 1 leukocyte), old rules reported alongside |
| Overlapping tiles overwritten / "any tile wins" | Centre-weighted blending |
| No iptcr in `Final_Pipeline`; slides processed one tile at a time | iptcr, batching, Excel / QC outputs, upload to Athena |

## Running them anyway

Paths point to HiPerGator folders and slide names were replaced with `<SLIDE_NAME>`: put your own back in.
They need a GPU TensorFlow environment with `openslide-python`, `opencv-python`, `scikit-image`, `shapely`.
In `WSI_To_XML.ipynb`, the last cell calls the `main()` from cell 2; running cell 3 first redefines `main()` and breaks it.
