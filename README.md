# PSMD (Peak width of Skeletonized Mean Diffusivity)

PSMD is a robust, fully-automated and easy-to-implement marker for cerebral small vessel disease based on diffusion tensor imaging, white matter tract skeletonization (as implemented in FSL-TBSS) and histogram analysis.

For more information on usage, including FAQ, please visit [www.psmd-marker.com](https://www.psmd-marker.com).


## Contents

* `psmd.sh` - Main analysis script
* `skeleton_mask_2019.nii.gz` - Updated (2019) skeleton mask image
* `LICENSE` - Please have a look at the license file
* Folder `examples` - Sample dataset for testing


## Version history

### 1.6 (2020-11)

- Ability to run on already pre-processed DWI data (option `-p`)
- Option to output PSMD (or MSMD) separately for each hemisphere, comma-separated (left,right - option `-g`)

### 1.5.1 (2020-02)

- Fixed a bug related to the parsing of options
- Added a check for FSL version 6

### 1.5 (2019)

- A refined skeleton mask (`skeleton_mask_2019.nii.gz`) to further improve the exclusion of areas prone to CSF contamination.
- An additional, enhanced masking method (option `-e`). Intended to further improve the exclusion of problematic areas, i.e. areas with CSF contamination as well as hyperintense regions on DWI raw images (e.g. susceptibility artefacts and acute infarcts).  
There are two drawbacks when using this option: It only works when using unprocessed data as input and processing time is longer (approx. doubled).
- The possibility to include your own lesion mask to exclude brain areas from analysis, e.g. large haemorrhages. A mask in DTI space needs to be supplied by the user (option `-l mask`) .
- The possibility to output median skeletonized mean diffusivity (**MSMD**) instead of PSMD (option `-o`). MSMD might provide more stable results in certain scenarios.
- New naming scheme for temporary files for a better overview during troubleshooting.
- Minor code improvements for better compatibility.

### 1.0 (2016)

- First release, used in the original PSMD paper.
- [Download v1.0](https://bitbucket.org/miac-research/psmd/downloads/psmd_v1.0_2016.zip) (for legacy support).


## Roadmap of future development

- In progress: Containerized version of PSMD using Singularity


## License

Please see the `LICENSE` file provided in this repository.


## Support

The ongoing development of PSMD is supported by Medical Image Analysis Center (MIAC), Basel, Switzerland.

<img alt="MIAC logo" src="https://miac.swiss/gallery/normal/116/miaclogo@2x.png" width="400" href="http://miac.swiss">