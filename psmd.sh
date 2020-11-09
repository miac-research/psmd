#!/bin/bash
#
# PSMD processing pipeline, v 1.0 (first release 2016-08)
#
# This script is provided under the revised BSD (3-clause) license
#
# Copyright (c) 2016, Institute for Stroke and Dementia Research, Munich
# http://www.isd-muc.de  All rights reserved. 
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the “Institute for Stroke and Dementia Reseearch”
#       nor the names of its contributors may be used to endorse or promote
#       products derived from this software without specific prior written
#       permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 
# The use of the software needs to be acknowledged through proper citations:
# 
# For the PSMD pipeline:
# Baykara E, Gesierich B, Adam R, Tuladhar AM, Biesbroek JM, Koek HL, Ropele S, 
# Jouvent E, Alzheimer’s Disease Neuroimaging Initiative (ADNI), Chabriat H, 
# Ertl-Wagner B, Ewers M, Schmidt R, de Leeuw FE, Biessels GJ, Dichgans M, Duering M
# A novel imaging marker for small vessel disease based on skeletonization of white 
# matter tracts and diffusion histograms. Annals of Neurology 2016 (in press)
# 
# For FSL-TBSS:
# Follow the guidelines at http://fsl.fmrib.ox.ac.uk/fsl/fslwiki/TBSS
# 


# Functions

usage(){
echo ""
echo "Usage:"
echo ""
echo "  From unprocessed DTI data (recommended):"
echo "  psmd.sh -d DTI-data -b bvals -r bvecs -s skeleton_mask"
echo ""
echo "    DTI-data: Unprocessed DTI data, after conversion from DICOM to Nifti"
echo "    bvals: Text file containing b-values (created during DICOM conversion)"
echo "    bvecs: Text file containing diffusion vectors (created during DICOM conversion)"
echo "    skeleton_mask: Mask file provided with the psmd script (or custom mask)"
echo ""
echo ""
echo "  From processed DTI data, i.e. FA and MD images (NOT recommended):"
echo "  psmd.sh -f FA-image -m MD-image -s skeleton_mask"
echo ""
echo "    FA-image: The fractional anisotropy image, brain extracted, Nifti format"
echo "    MD-image: The mean diffusivity image, brain extracted, Nifti format"
echo "    skeleton_mask: Mask file provided with the psmd script (or custom mask)"
echo ""
echo "  Options (nonmandatory):"
echo "    -q    quiet operation (no status messages are displayed, only PSMD result)"
echo "    -v    verbose (very detailed status and error messages are displayed)"
echo "    -t    troubleshooting/debug (don't delete temporary files)"
echo ""
exit
}

# Function for absolute file names
get_abs_filename() {
  # $1 : relative filename
  if [ -d "$(dirname "$1")" ]; then
    echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
  fi
}

# Function for reporting level (redirect stdout/stderr)
redirect_cmd() {
    if [ $verbose == true ]; then
        "$@"
    else
        "$@" > /dev/null 2>&1
    fi
}

# Check options
[[ $# -eq 0 ]] && usage 

#Check for FSL
[ -z "${FSLDIR}" ] && { echo ""; echo "ERROR: This script requires a working installation of FSL 5"; echo "Please see http://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation";echo ""; exit 1; }

# Empty/reset variables
mask=
dtiraw=
bval=
bvec=
faimage=
mdimage=
silent=false
verbose=false
debug=false
basedir=$(pwd)

# Get command-line options
while getopts ":d:b:r:f:m:s:tqvh" opt; do
  case $opt in
    d)
      dtiraw=${OPTARG}
      [ -r $dtiraw ] && dtirawfile=$(get_abs_filename "$dtiraw") || { echo ""; echo "ERROR: DTI raw file not found";echo ""; exit 1; }
      ;;
	b)
      bval=${OPTARG}
      [ -r $bval ] && bvalfile=$(get_abs_filename "$bval") || { echo ""; echo "ERROR: Bval file not found";echo ""; exit 1; }
      ;;
    r)
      bvec=${OPTARG}
      [ -r $bvec ] && bvecfile=$(get_abs_filename "$bvec") || { echo ""; echo "ERROR: Bvec file not found";echo ""; exit 1; }
      ;;
    f)
      faimage=${OPTARG}
      [ -r $faimage ] && faimagefile=$(get_abs_filename "$faimage") || { echo ""; echo "ERROR: FA image file not found";echo ""; exit 1; }
      ;;
    m)
      mdimage=${OPTARG}
      [ -r $mdimage ] && mdimagefile=$(get_abs_filename "$mdimage") || { echo ""; echo "ERROR: MD image file not found";echo ""; exit 1; }
      ;;
    s)
      mask=${OPTARG}
      [ -r $mask ] && maskfile=$(get_abs_filename "$mask") || { echo ""; echo "ERROR: Skeleton_mask file not found";echo ""; exit 1; }
      ;;
    t)
      debug=true
      ;;
    q)
      silent=true
      ;;
    v)
      verbose=true
      ;;
    h)
      usage
      ;;
    \?)
      echo ""
      echo "ERROR: Invalid option. Type 'psmd.sh -h' for help" >&2
      usage
      ;;
    :)
	  echo ""
	  echo "ERROR: Option -$OPTARG requires an argument. Type 'psmd.sh -h' for help" >&2
	  Echo ""
      exit 1
      ;;
  esac
done

# Check option combinations
if [ -n "${dtiraw}" -o -n "${bval}" -o -n  "${bvec}" ]; then
    pipeline=unprocessed
	[ -z "${dtiraw}" -o -z "${bval}" -o -z  "${bvec}" ] && { echo ""; echo "ERROR: When using raw DTI data, all options (-d -b -r) are required. Type 'psmd.sh -h' for help.";echo ""; exit 1; }
fi
if [ -n "${faimage}" -o -n "${mdimage}" ]; then
    pipeline=processed
	[ -z "${faimage}" -o -z "${mdimage}" ] && { echo ""; echo "ERROR: When using processed DTI data, both options (-f and -m) are required. Type 'psmd.sh -h' for help.";echo ""; exit 1; }
fi

# Check for skeleton_mask
[ -z $mask ] && { echo ""; echo "ERROR: Skeleton_mask (option -s) not defined. This is mandatory! Type 'psmd.sh -h' for help";echo ""; exit 1; }

# Check for previous script run, which might interfere
[ -r psmdtemp ] && { echo ""; echo "ERROR: 'psmdtemp' folder in current directory. Delete before running this script!";echo ""; exit 1; }

# Set reporting level from options
[ ${verbose} == true ] && { silent=false; echo "Reporting level: Verbose (all status and error messages are displayed)"; }
[ ${silent} == false ] && { echo "";echo "PSMD processing pipeline, v 0.95 (first release)"; } 

redirect_cmd mkdir psmdtemp
cd psmdtemp

# Raw DTI pipeline
if [ ${pipeline} == unprocessed ];then
[ ${silent} == false ] && echo "Pipeline for unprocessed DTI"
[ ${silent} == false ] && echo "...Eddy-correcting DTI data (this step will take a few minutes)"
redirect_cmd eddy_correct ${dtirawfile} data 1
[ ${silent} == false ] && echo "...Running brain extraction"
redirect_cmd bet data nodiff_brain_F -F -m
[ ${silent} == false ] && echo "...Running tensor calculation"
redirect_cmd dtifit -k data -o temp-DTI -m nodiff_brain_F_mask -r ${bvecfile} -b ${bvalfile}
faimagefile=$(get_abs_filename temp-DTI_FA.nii.gz)
mdimagefile=$(get_abs_filename temp-DTI_MD.nii.gz)
fi

redirect_cmd mkdir tbss
redirect_cmd cp ${faimagefile} tbss/
redirect_cmd cd tbss
tbssfile=$(ls)

# Processed DTI pipeline
# TBSS
[ ${pipeline} == processed -a ${silent} == false ] && echo "Calculating PSMD from already processed DTI"
[ ${silent} == false ] && echo "...Skeletonizing FA image (this step will take a few minutes)"
redirect_cmd tbss_1_preproc ${tbssfile}
redirect_cmd tbss_2_reg -T
redirect_cmd tbss_3_postreg -T
redirect_cmd tbss_4_prestats 0.2

[ ${silent} == false ] && echo "...Projecting MD image"
newname=$(ls origdata/)
redirect_cmd mkdir MD 
redirect_cmd cp ${mdimagefile} MD/${newname}
redirect_cmd tbss_non_FA MD

# Histogram analysis
[ ${silent} == false ] && echo "...Histogram analysis"
redirect_cmd fslmaths stats/all_MD_skeletonised.nii.gz -mas ${maskfile} -mul 1000000 temp_skel_mask.nii.gz
a=$(fslstats temp_skel_mask.nii.gz -P 95)
b=$(fslstats temp_skel_mask.nii.gz -P 5)
psmd=$(echo - | awk "{print ( ${a} - ${b} ) / 1000000 }" | sed 's/,/./')

[ ${silent} == false ] && { echo ""; echo "PSMD is ${psmd}"; echo ""; }
[ ${silent} == true ] && echo ${psmd}

cd ${basedir}
[ ${debug} == false ] && rm -r psmdtemp