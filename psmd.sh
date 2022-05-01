#!/bin/bash
#
# FOR MORE INFORMATION, PLEASE VISIT: http://www.psmd-marker.com
#
# PSMD processing pipeline, v1.8.3 (2021-04)
#
# IMPORTANT: This tool is NOT a medical device and for research use only!
# Do NOT use this tool for diagnosis, prognosis, monitoring or any other
# purpose in clinical use.
#
# This script is provided under the revised BSD (3-clause) license
# 
# Copyright (c) 2016-2020, Institute for Stroke and Dementia Research, Munich, 
# Germany, http://www.isd-muc.de
# Copyright (c) 2020, MIAC AG Basel, Switzerland, https://miac.swiss
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the “Institute for Stroke and Dementia Research”
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
# A novel imaging marker for small vessel disease based on skeletonization of 
# white matter tracts and diffusion histograms
# Annals of Neurology 2016, 80(4):581-92, DOI: 10.1002/ana.24758
# 
# For FSL-TBSS:
# Follow the guidelines at http://fsl.fmrib.ox.ac.uk/fsl/fslwiki/TBSS

usage(){
cat <<USAGE

PSMD - Peak width of Skeletonized Mean Diffusivity - pipeline version 1.8.3 (2022-05)
http://www.psmd-marker.com

Disclaimer:
PSMD is not a medical device and for research use only!

Usage:

  From unprocessed DWI data:
  psmd.sh -d <DWI_data> -b <bvals> -r <bvecs> -s <skeleton_mask>

    -d <DWI_data>      Unprocessed DWI data in Nifti format
    -b <bvals>         Text file containing b-values (in FSL format)
    -r <bvecs>         Text file containing diffusion vectors (in FSL format)
    -s <skeleton_mask> Skeleton mask file, e.g. the mask provided with the PSMD tool

  From pre-processed (distortion, motion & eddy corrected) DWI data (RECOMMENDED!):
  psmd.sh -p <PP_DWI_data> -b <bvals> -r <bvecs> -s <skeleton_mask>

    -p <PP_DWI_data>   Pre-processed DWI data in Nifti format
    -b <bvals>         Text file containing b-values (in FSL format)
    -r <bvecs>         Text file containing diffusion vectors (in FSL format)
    -s <skeleton_mask> Skeleton mask file, e.g. the mask provided with the PSMD tool

  From fully processed and fitted DTI images (FA and MD images):
  psmd.sh -f <FA_image> -m <MD_image> -s <skeleton_mask>

    -f <FA_image>      The fractional anisotropy image, brain extracted, Nifti format
    -m <MD_image>      The mean diffusivity image, brain extracted, Nifti format
    -s <skeleton_mask> Skeleton mask file, e.g. the mask provided with the PSMD tool

  Options (non-mandatory):
    -e <bvalue>        Enhanced masking of CSF and hyperintense voxels (e.g. certain artefacts)
                       Please specify <b-value> of the diffusion shell to use (usually 1000)
                       (requires unprocessed or pre-processed DWI data)

    -l <lesion_mask>   Supply custom lesion mask in order to exclude a region from analysis

    -o  Output mean skeletonized mean diffusivity (MSMD) instead of PSMD

    -g  Output PSMD (or MSMD) separately for each hemisphere, comma-separated (left,right)

    -c  Clear temporary psmdtemp folder from previous run (if present)
    -q  Quiet: No messages are displayed, only result (suitable for writing result into file)
    -v  Verbose: Very detailed status and error messages are displayed
    -t  Troubleshooting: Temporary files (folder psmdtemp) will not be deleted

USAGE
exit 1
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
  if [ "$verbose" == true ]; then
    "$@"
  else
    "$@" > /dev/null 2>&1
  fi
}

# Function for PSMD calculation
psmdcalc(){
[ "${silent}" == false ] && echo "...Histogram analysis"
  unset psmdresult
  a=$(fslstats "${mdskel}" -P 95)
  b=$(fslstats "${mdskel}" -P 5)
  psmdresult=$(echo - | awk "{print ( ${a} - ${b} ) / 1000000 }" | sed 's/,/./')
}

# Function for MSMD calculation
msmdcalc(){
  unset msmdresult
  [ "${silent}" == false ] && echo "...Skeleton analysis"
  a=$(fslstats "${mdskel}" -M)
  msmdresult=$(echo - | awk "{print ${a} / 1000000 }" | sed 's/,/./')
}

# Check options
[[ $# -eq 0 ]] && usage 

# Check for FSL
[ -z "${FSLDIR}" ] && { echo ""; echo "ERROR: This script requires a working installation of FSL 5 or newer"; echo "Please see http://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation";echo ""; exit 1; }

# Check for dc
command -v dc > /dev/null || { echo ""; echo "ERROR: This script requires the program 'dc' to work."; echo "Please install dc, e.g. in Ubuntu Linux via 'apt install dc'";echo ""; exit 1; }

# Set default values for variables
unset mask rawdwi ppdwi bval bvec faimage mdimage mask enhmasb bcheck pipeline
metric=PSMD
enhmask=false
lesionmasking=false
hemispheres=false
cleartemp=false
silent=false
verbose=false
debug=false
basedir=$(pwd)

# Get command-line options
while getopts ":d:p:b:r:f:m:s:e:l:ogtcqvh" opt; do
  case $opt in
    d)
      rawdwi=${OPTARG}
      if [ -r "$rawdwi" ]; then rawdwifile=$(get_abs_filename "$rawdwi"); else { echo ""; echo "ERROR: Unprocessed DWI data file not found";echo ""; exit 1; }; fi
      ;;
    p)
      ppdwi=${OPTARG}
      if [ -r "$ppdwi" ]; then ppdwifile=$(get_abs_filename "$ppdwi"); else { echo ""; echo "ERROR: Pre-processed DWI data file not found";echo ""; exit 1; }; fi
      ;;
	  b)
      bval=${OPTARG}
      if [ -r "$bval" ]; then bvalfile=$(get_abs_filename "$bval"); else { echo ""; echo "ERROR: Bval file not found";echo ""; exit 1; }; fi
      ;;
    r)
      bvec=${OPTARG}
      if [ -r "$bvec" ]; then bvecfile=$(get_abs_filename "$bvec"); else { echo ""; echo "ERROR: Bvec file not found";echo ""; exit 1; }; fi
      ;;
    f)
      faimage=${OPTARG}
      if [ -r "$faimage" ]; then faimagefile=$(get_abs_filename "$faimage"); else { echo ""; echo "ERROR: FA image file not found";echo ""; exit 1; }; fi
      ;;
    m)
      mdimage=${OPTARG}
      if [ -r "$mdimage" ]; then mdimagefile=$(get_abs_filename "$mdimage"); else { echo ""; echo "ERROR: MD image file not found";echo ""; exit 1; }; fi
      ;;
    s)
      mask=${OPTARG}
      if [ -r "$mask" ]; then maskfile=$(get_abs_filename "$mask"); else { echo ""; echo "ERROR: Skeleton_mask file not found";echo ""; exit 1; }; fi
      ;;
    e)
      enhmask=true
      enhmasb=${OPTARG}
      ;;
    l)
      lesionmasking=true
      lesionmask=${OPTARG}
      if [ -r "$lesionmask" ]; then lesionmaskfile=$(get_abs_filename "$lesionmask"); else { echo ""; echo "ERROR: Lesion_mask file not found";echo ""; exit 1; }; fi
      ;;
    o)
      metric=MSMD
      ;;
    g)
      hemispheres=true
      ;;
    t)
      debug=true
      ;;
    c)
      cleartemp=true
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
      exit 1
      ;;
    :)
	  echo ""
	  echo "ERROR: Option -$OPTARG requires an argument. Type 'psmd.sh -h' for help" >&2
	  echo ""
      exit 1
      ;;
  esac
done

# Check option combinations
if [ -n "${rawdwi}" ]; then
  pipeline=unprocessed
  if [ -z "${rawdwi}" ] || [ -z "${bval}" ] || [ -z "${bvec}" ]; then { echo ""; echo "ERROR: When using raw DWI data, all options (-d -b -r) are required. Type 'psmd.sh -h' for help.";echo ""; exit 1; }; fi
fi

if [ -n "${ppdwi}" ]; then
  pipeline=preprocessed
  if [ -z "${ppdwi}" ] || [ -z "${bval}" ] || [ -z "${bvec}" ]; then { echo ""; echo "ERROR: When using pre-processed DWI data, all options (-p -b -r) are required. Type 'psmd.sh -h' for help.";echo ""; exit 1; }; fi
fi

if [ -n "${faimage}" ] || [ -n "${mdimage}" ]; then
  pipeline=processed
  if [ -z "${faimage}" ] || [ -z "${mdimage}" ]; then { echo ""; echo "ERROR: When using processed DTI data, both options (-f and -m) are required. Type 'psmd.sh -h' for help.";echo ""; exit 1; }; fi
fi

[ -z "$pipeline" ] && { echo ""; echo "ERROR: Not enough arguments provided! Type 'psmd.sh -h' for help";echo ""; exit 1; }

if [ "${enhmask}" == "true" ] && [ "${pipeline}" == "processed" ];then
	echo ""; echo "ERROR: Unprocessed or pre-processed (not fully processed) DWI data needed for enhanced masking.";echo ""; exit 1
fi

# Check for skeleton_mask
[ -z "$mask" ] && { echo ""; echo "ERROR: Skeleton_mask (option -s) not defined. This is mandatory! Type 'psmd.sh -h' for help";echo ""; exit 1; }

# Checks for enhanced masking
if [ ${enhmask} == true ];then

  # Check b-value
  bcheck=$(grep "$enhmasb" "$bvalfile")
  [ -z "$bcheck" ] && { echo ""; echo "ERROR: Specified b-value (for enhanced masking) not found in ${bvalfile}"; echo ""; exit 1; }
	
  # Check for FSL 6
  fslversion=$(cat "${FSLDIR}"/etc/fslversion)
  # shellcheck disable=SC2071
  [ "${fslversion}" \> 6 ] || { echo ""; echo "ERROR: FSL version 6.0 or newer required for enhanced masking. Your version is ${fslversion}."; echo ""; exit 1; }
fi

# Check for previous script run, which might interfere
if [ -r psmdtemp ];then
  [ ${cleartemp} == false ] && { echo ""; echo "ERROR: 'psmdtemp' folder in current directory. Delete before running this script!";echo ""; exit 1; }
  [ ${cleartemp} == true  ] && { rm -r psmdtemp; }
fi

# Set reporting level from options
[ ${silent} == false ] && { echo "";echo "${metric} processing pipeline, v1.8.3"; } 
[ ${verbose} == true ] && { silent=false;echo "";echo "Reporting level: Verbose (all status and error messages are displayed)"; }

redirect_cmd mkdir psmdtemp
cd psmdtemp || exit 1

# Raw DWI pipeline
if [ ${pipeline} == unprocessed ];then
  [ ${silent} == false ] && echo "Pipeline for unprocessed DWI data"
  [ ${silent} == false ] && echo "...Eddy-correcting DWI data (this step will take a few minutes)"
  redirect_cmd eddy_correct "${rawdwifile}" data 1
  ppdwifile=$(get_abs_filename data.nii.gz)
fi

if [ ${pipeline} == unprocessed ] || [ ${pipeline} == preprocessed ];then
  [ ${silent} == false ] && echo "...Running brain extraction on b=0"
  redirect_cmd select_dwi_vols "${ppdwifile}" "${bvalfile}" nodiff 0 -m
  redirect_cmd bet nodiff nodiff_brain_F -F -m
  [ ${silent} == false ] && echo "...Running tensor calculation"
  redirect_cmd dtifit -k "${ppdwifile}" -o temp-DTI -m nodiff_brain_F_mask -r "${bvecfile}" -b "${bvalfile}"
  faimagefile=$(get_abs_filename temp-DTI_FA.nii.gz)
  mdimagefile=$(get_abs_filename temp-DTI_MD.nii.gz)
fi

# Optional (-e): Enhanced masking (new in version 1.5)
if [ ${enhmask} == true ];then
  [ ${silent} == false ] && echo "...Enhanced masking: Calculation trace image from shells with b-value ${enhmasb}"
  redirect_cmd select_dwi_vols "${ppdwifile}" "${bvalfile}" trace "${enhmasb}" -m
  redirect_cmd fslmaths trace -mas nodiff_brain_F_mask trace_brain
  [ ${silent} == false ] && echo "...Bias correction and tissue segmentation"
  redirect_cmd select_dwi_vols "${ppdwifile}" "${bvalfile}" meanb0 0 -m
  redirect_cmd fslmaths meanb0 -mas nodiff_brain_F_mask meanb0_brain
  redirect_cmd fast -t 2 -b -B -p meanb0_brain
  redirect_cmd fslmaths meanb0_brain_prob_0 -thr 0.5 -bin seg_meanb0
  redirect_cmd fslmaths trace.nii.gz -div meanb0_brain_bias.nii.gz -mas nodiff_brain_F_mask.nii.gz trace_unbiased.nii.gz
  redirect_cmd fast -n 2 -N -p trace_unbiased
  redirect_cmd fslmaths trace_unbiased_prob_0 -thr 0.3 -bin seg_trace
  redirect_cmd fslmaths trace_unbiased -mas seg_trace trace_unbiased_seg
  redirect_cmd fslmaths seg_meanb0 -add seg_trace -thr 2 -bin -fillh enhmask
fi

redirect_cmd mkdir tbss
redirect_cmd cp "${faimagefile}" tbss/
redirect_cmd cd tbss 
tbssfile=$(ls)

# TBSS on FA
[ ${pipeline} == processed ] && [ ${silent} == false ] && echo "Calculating ${metric} from already processed DTI"
[ ${silent} == false ] && echo "...Skeletonizing FA image (this step will take a few minutes)"
redirect_cmd tbss_1_preproc "${tbssfile}"
redirect_cmd tbss_2_reg -T
redirect_cmd tbss_3_postreg -T
redirect_cmd tbss_4_prestats 0.2

# TBSS on MD
[ ${silent} == false ] && echo "...Projecting MD image"
newname=$(ls origdata/)
redirect_cmd mkdir MD 
redirect_cmd cp "${mdimagefile}" MD/"${newname}"
redirect_cmd tbss_non_FA MD

finalmask=${maskfile}

# Optional (-e): TBSS on trace and enhanced mask
if [ ${enhmask} == true ];then
  [ ${silent} == false ] && echo "...Projecting enhanced mask"
  redirect_cmd mkdir trace 
  redirect_cmd cp ../trace_unbiased.nii.gz trace/"${newname}"
  redirect_cmd tbss_non_FA trace
  redirect_cmd mkdir mask 
  redirect_cmd cp ../enhmask.nii.gz mask/"${newname}"
  redirect_cmd tbss_non_FA mask
  redirect_cmd fslmaths stats/all_mask_skeletonised -thr 0.05 -bin stats/all_mask_skeletonised_bin.nii.gz
  redirect_cmd fslmaths "${maskfile}" -sub stats/all_mask_skeletonised_bin.nii.gz -bin stats/skeleton_enhanced_bin.nii.gz
  finalmask=$(get_abs_filename stats/skeleton_enhanced_bin.nii.gz)
fi

# Optional (-l): TBSS on lesion_mask
if [ ${lesionmasking} == true ];then
  redirect_cmd mkdir lesionmask
  redirect_cmd cp "${lesionmaskfile}" lesionmask/"${newname}"
  redirect_cmd tbss_non_FA lesionmask
  redirect_cmd fslmaths stats/all_lesionmask_skeletonised -thr 0.05 -bin stats/all_lesionmask_skeletonised_bin.nii.gz
  redirect_cmd fslmaths "${maskfile}" -sub stats/all_lesionmask_skeletonised_bin.nii.gz -bin stats/skeleton_lesionmask_bin.nii.gz
  if [ ${enhmask} == true ];then
    fslmaths stats/skeleton_enhanced_bin.nii.gz -mul stats/skeleton_lesionmask_bin.nii.gz -bin stats/skeleton_combined_bin.nii.gz
    finalmask=$(get_abs_filename stats/skeleton_combined_bin.nii.gz)
  else
    finalmask=$(get_abs_filename stats/skeleton_lesionmask_bin.nii.gz)
  fi
fi

# Histogram analysis
redirect_cmd fslmaths stats/all_MD_skeletonised.nii.gz -mas "${finalmask}" -mul 1000000 MD_skeletonized_masked.nii.gz


# Whole brain metrics
if [ ${hemispheres} == false ] && [ ${metric} == PSMD ];then
  mdskel=MD_skeletonized_masked.nii.gz
  psmdcalc
  [ ${silent} == false ] && { echo ""; echo "${metric} is ${psmdresult}"; echo ""; }
  [ ${silent} == true ] && echo "${psmdresult}"
fi

if [ ${hemispheres} == false ] && [ ${metric} == MSMD ];then
  mdskel=MD_skeletonized_masked.nii.gz
  msmdcalc
  [ ${silent} == false ] && { echo ""; echo "${metric} is ${msmdresult}"; echo ""; }
  [ ${silent} == true ] && echo "${msmdresult}"
fi

# Left and right hemisphere metrics (new in version 1.6)
if [ ${hemispheres} == true ] && [ ${metric} == PSMD ];then
  fslmaths MD_skeletonized_masked.nii.gz -roi  0 90 0 -1 0 -1 0 -1 MD_skeletonized_masked_R.nii.gz
  fslmaths MD_skeletonized_masked.nii.gz -roi 91 90 0 -1 0 -1 0 -1 MD_skeletonized_masked_L.nii.gz
fi

if [ ${hemispheres} == true ] && [ ${metric} == PSMD ];then
  mdskel=MD_skeletonized_masked_L.nii.gz
  psmdcalc
  psmdL="${psmdresult}"
  mdskel=MD_skeletonized_masked_R.nii.gz
  psmdcalc
  psmdR="${psmdresult}"	
  [ ${silent} == false ] && { echo ""; echo "${metric} is (left,right) ${psmdL},${psmdR}"; echo ""; }
  [ ${silent} == true ] && echo "${psmdL},${psmdR}"
fi
if [ ${hemispheres} == true ] && [ ${metric} == MSMD ];then
  mdskel=MD_skeletonized_masked_L.nii.gz
  msmdcalc
  msmdL="${psmdresult}"
  mdskel=MD_skeletonized_masked_R.nii.gz
  msmdcalc
  msmdR="${psmdresult}"	
  [ ${silent} == false ] && { echo ""; echo "${metric} is (left,right) ${msmdL},${msmdR}"; echo ""; }
  [ ${silent} == true ] && echo "${msmdL},${msmdR}"
fi

cd "${basedir}" || exit 1
[ ${debug} == false ] && rm -r psmdtemp

exit 0
