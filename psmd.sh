#!/bin/bash
# shellcheck disable=SC2166,SC2015,SC2071
#
# FOR MORE INFORMATION, PLEASE VISIT: http://www.psmd-marker.com
#
# PSMD processing pipeline, v 1.5.1 (2020-02)
#
# This script is provided under the revised BSD (3-clause) license
#
# Copyright (c) 2016-2020 Institute for Stroke and Dementia Research, Munich
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
# matter tracts and diffusion histograms. Annals of Neurology 2016, 80(4):581-92
# DOI: 10.1002/ana.24758
# 
# For FSL-TBSS:
# Follow the guidelines at http://fsl.fmrib.ox.ac.uk/fsl/fslwiki/TBSS

usage(){
echo ""
echo "PSMD - Peak width of Skeletonized Mean Diffusivity - pipeline version 1.5.1 (2019)"
echo "http://www.psmd-marker.com"
echo ""
echo "Usage:"
echo ""
echo "  From unprocessed DWI data (recommended):"
echo "  psmd.sh -d <DWI_data> -b <bvals> -r <bvecs> -s <skeleton_mask>"
echo ""
echo "    -d <DWI_data>      Unprocessed DWI data in Nifti format"
echo "    -b <bvals>         Text file containing b-values (in FSL format)"
echo "    -r <bvecs>         Text file containing diffusion vectors (in FSL format)"
echo "    -s <skeleton_mask> Skeleton mask file, e.g. the mask provided with the PSMD tool"
echo ""
echo "  From processed (corrected, brain extracted) DTI data (FA and MD) (NOT recommended):"
echo "  psmd.sh -f <FA_image> -m <MD_image> -s <skeleton_mask>"
echo ""
echo "    -f <FA_image>      The fractional anisotropy image, brain extracted, Nifti format"
echo "    -m <MD_image>      The mean diffusivity image, brain extracted, Nifti format"
echo "    -s <skeleton_mask> Skeleton mask file, e.g. the mask provided with the PSMD tool"
echo ""
echo "  Options (non-mandatory):"
echo "    -e <bvalue>        Enhanced masking of CSF and hyperintense voxels (e.g. certain artefacts)"
echo "                       Please specify <b-value> of the diffusion shell to use (usually 1000)"
echo "                       (only possible from unprocessed DWI data)"
echo "    -l <lesion_mask>   Supply custom lesion mask in order to exclude a region from analysis"
echo ""
echo "    -o  Output mean skeletonized mean diffusivity (MSMD) instead of PSMD"
echo ""
echo "    -c  Clear temporary psmdtemp folder from previous run (if present)"
echo "    -q  Quiet: No messages are displayed, only result (suitable for writing result into file)"
echo "    -v  Verbose: Very detailed status and error messages are displayed"
echo "    -t  Temporary files (folder psmdtemp) will not be deleted (for troubleshooting)"
echo ""
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

# Check options
[[ $# -eq 0 ]] && usage 

# Check for FSL
[ -z "${FSLDIR}" ] && { echo ""; echo "ERROR: This script requires a working installation of FSL 5 or newer"; echo "Please see http://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation";echo ""; exit 1; }

# Check for dc
command -v dc > /dev/null || { echo ""; echo "ERROR: This script requires the program 'dc' to work."; echo "Please install dc, e.g. in Ubuntu Linux via 'apt install dc'";echo ""; exit 1; }

# Set default values for variables
unset mask dtiraw bval bvec faimage mdimage enhmasb
metric=PSMD
enhmask=false
lesionmasking=false
cleartemp=false
silent=false
verbose=false
debug=false
basedir=$(pwd)

# Get command-line options
while getopts ":d:b:r:f:m:s:e:l:otcqvh" opt; do
  case $opt in
    d)
      dtiraw=${OPTARG}
      [ -r "$dtiraw" ] && dtirawfile=$(get_abs_filename "$dtiraw") || { echo ""; echo "ERROR: DWI data file not found";echo ""; exit 1; }
      ;;
	b)
      bval=${OPTARG}
      [ -r "$bval" ] && bvalfile=$(get_abs_filename "$bval") || { echo ""; echo "ERROR: Bval file not found";echo ""; exit 1; }
      ;;
    r)
      bvec=${OPTARG}
      [ -r "$bvec" ] && bvecfile=$(get_abs_filename "$bvec") || { echo ""; echo "ERROR: Bvec file not found";echo ""; exit 1; }
      ;;
    f)
      faimage=${OPTARG}
      [ -r "$faimage" ] && faimagefile=$(get_abs_filename "$faimage") || { echo ""; echo "ERROR: FA image file not found";echo ""; exit 1; }
      ;;
    m)
      mdimage=${OPTARG}
      [ -r "$mdimage" ] && mdimagefile=$(get_abs_filename "$mdimage") || { echo ""; echo "ERROR: MD image file not found";echo ""; exit 1; }
      ;;
    s)
      mask=${OPTARG}
      [ -r "$mask" ] && maskfile=$(get_abs_filename "$mask") || { echo ""; echo "ERROR: Skeleton_mask file not found";echo ""; exit 1; }
      ;;
    e)
      enhmask=true
      enhmasb=${OPTARG}
      ;;
    l)
      lesionmasking=true
      lesionmask=${OPTARG}
      [ -r "$lesionmask" ] && lesionmaskfile=$(get_abs_filename "$lesionmask") || { echo ""; echo "ERROR: Lesion_mask file not found";echo ""; exit 1; }
      ;;
    o)
      metric=MSMD
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
if [ -n "${dtiraw}" -o -n "${bval}" -o -n "${bvec}" ]; then
    pipeline=unprocessed
	[ -z "${dtiraw}" -o -z "${bval}" -o -z "${bvec}" ] && { echo ""; echo "ERROR: When using raw DWI data, all options (-d -b -r) are required. Type 'psmd.sh -h' for help.";echo ""; exit 1; }
fi

if [ -n "${faimage}" -o -n "${mdimage}" ]; then
    pipeline=processed
	[ -z "${faimage}" -o -z "${mdimage}" ] && { echo ""; echo "ERROR: When using processed DTI data, both options (-f and -m) are required. Type 'psmd.sh -h' for help.";echo ""; exit 1; }
fi

if [ ${enhmask} == true ] && [ ${pipeline} == processed ];then
echo ""; echo "ERROR: Unprocessed DWI data needed for enhanced masking.";echo ""; exit 1
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
	[ "${fslversion}" \> 6 ] || { echo ""; echo "ERROR: FSL version 6.0 or newer required for enhanced masking. Your version is ${fslversion}."; echo ""; exit 1; }
fi

# Check for previous script run, which might interfere
if [ -r psmdtemp ];then
[ ${cleartemp} == false ] && { echo ""; echo "ERROR: 'psmdtemp' folder in current directory. Delete before running this script!";echo ""; exit 1; }
[ ${cleartemp} == true  ] && { rm -r psmdtemp; }
fi

# Set reporting level from options
[ ${silent} == false ] && { echo "";echo "${metric} processing pipeline, v1.5.1 (2019)"; } 
[ ${verbose} == true ] && { silent=false;echo "";echo "Reporting level: Verbose (all status and error messages are displayed)"; }

redirect_cmd mkdir psmdtemp
cd psmdtemp || exit 1

# Raw DWI pipeline
if [ ${pipeline} == unprocessed ];then
[ ${silent} == false ] && echo "Pipeline for unprocessed DWI data"
[ ${silent} == false ] && echo "...Eddy-correcting DWI data (this step will take a few minutes)"
redirect_cmd eddy_correct "${dtirawfile}" data 1
[ ${silent} == false ] && echo "...Running brain extraction on b=0"
redirect_cmd select_dwi_vols data "${bvalfile}" nodiff 0 -m
redirect_cmd bet nodiff nodiff_brain_F -F -m
[ ${silent} == false ] && echo "...Running tensor calculation"
redirect_cmd dtifit -k data -o temp-DTI -m nodiff_brain_F_mask -r "${bvecfile}" -b "${bvalfile}"
faimagefile=$(get_abs_filename temp-DTI_FA.nii.gz)
mdimagefile=$(get_abs_filename temp-DTI_MD.nii.gz)
fi

# Optional (-e): Enhanced masking (new in version 1.5)
if [ ${enhmask} == true ];then
	[ ${silent} == false ] && echo "...Enhanced masking: Calculation trace image from shells with b-value ${enhmasb}"
	redirect_cmd select_dwi_vols data "${bvalfile}" trace "${enhmasb}" -m
	redirect_cmd fslmaths trace -mas nodiff_brain_F_mask trace_brain

	[ ${silent} == false ] && echo "...Bias correction and tissue segmentation"
	redirect_cmd select_dwi_vols data "${bvalfile}" meanb0 0 -m
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
[ ${pipeline} == processed -a ${silent} == false ] && echo "Calculating ${metric} from already processed DTI"
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

# Optional (-e): TBSS on trace and enhanced mask (new in version 1.5)
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

# Optional (-l): TBSS on lesion_mask (new in version 1.5)
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
if [ ${metric} == PSMD ];then
	[ ${silent} == false ] && echo "...Histogram analysis"
	a=$(fslstats MD_skeletonized_masked.nii.gz -P 95)
	b=$(fslstats MD_skeletonized_masked.nii.gz -P 5)
	psmd=$(echo - | awk "{print ( ${a} - ${b} ) / 1000000 }" | sed 's/,/./')
	[ ${silent} == false ] && { echo ""; echo "${metric} is ${psmd}"; echo ""; }
	[ ${silent} == true ] && echo "${psmd}"
fi

# Mean skeletonized mean diffusivity, MSMD (new in version 1.5)
if [ ${metric} == MSMD ];then
	[ ${silent} == false ] && echo "...Skeleton analysis"
	a=$(fslstats MD_skeletonized_masked.nii.gz -M)
	msmd=$(echo - | awk "{print ${a} / 1000000 }" | sed 's/,/./')
	[ ${silent} == false ] && { echo ""; echo "${metric} is ${msmd}"; echo ""; }
	[ ${silent} == true ] && echo "${msmd}"
fi

cd "${basedir}" || exit 1
[ ${debug} == false ] && rm -r psmdtemp
exit 0
