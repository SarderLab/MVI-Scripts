#!/bin/bash
# SLURM job for mvi_pipeline.py on a HiPerGator GPU.
#
#   sbatch run_mvi.sh                          # whole folder (or ITEM_ID) as set in mvi_pipeline.py
#   sbatch run_mvi.sh --item-id <ID>           # one slide
#   sbatch --array=0-3 run_mvi.sh              # split the folder over 4 GPUs (each job does every 4th slide)
#
# Afterwards:  python validate_iptcr.py
#SBATCH --job-name=mvi_iptcr
#SBATCH --partition=gpu
#SBATCH --gpus=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=64G
#SBATCH --time=24:00:00
#SBATCH --output=mvi_iptcr_%A_%a.log

module load conda
# use the SAME environment the Final_Pipeline notebook used (TensorFlow version that saved the .h5 models)
TF_ENV="your-tensorflow-env"     # <- CHANGE to your environment name
conda activate "$TF_ENV"
# needed once in that env:
#   pip install girder-client openslide-python openslide-bin opencv-python-headless scikit-image scipy pandas openpyxl matplotlib

cd "$SLURM_SUBMIT_DIR"           # folder with mvi_pipeline.py (and common.py for the Athena key)

if [ -n "$SLURM_ARRAY_TASK_ID" ]; then
    python mvi_pipeline.py --shard "${SLURM_ARRAY_TASK_ID}/${SLURM_ARRAY_TASK_COUNT}" "$@"
else
    python mvi_pipeline.py "$@"
fi
