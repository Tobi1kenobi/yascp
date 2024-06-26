#!/usr/bin/env bash
CWD1="$PWD"
parentdir="$(dirname "$CWD1")"
INPUT_FILE="$@"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export RUN_ID="${PWD##*/}"

# export SINGULARITY_CACHEDIR='/software/hgi/containers/yascp'

export NXF_OPTS="-Xms5G -Xmx5G"
export SINGULARITY_TMPDIR=$PWD/work/tmp
export TEMP=$PWD/work/tmp
export TMP_DIR=$PWD/work/tmp


sample="$RUN_ID.yascp"
echo -e "\nSubmitting yascp (https://github.com/wtsi-hgi/yascp) in JUST_CELLTYPES mode with input file $INPUT_FILE"
bsub -R'select[mem>4000] rusage[mem=4000]' -J yascp_celltypes -n 1 -M 4000 -o yascp_celltypes.o -e yascp_celltypes.e -q $QUEUE bash $SCRIPT_DIR/../../assets/deploy_scripts/nohup_start_nextflow_lsf_celltypes.sh  $INPUT_FILE
echo "Submitted job can be killed with: bkill -J yascp_celltypes"