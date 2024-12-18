# PSMD (Peak width of Skeletonized Mean Diffusivity)

PSMD is a robust, fully-automated and easy-to-implement marker for cerebral small vessel disease based on diffusion tensor imaging, white matter tract skeletonization (as implemented in FSL-TBSS) and histogram analysis.

**For more information on usage, including FAQ, please visit [www.psmd-marker.com](https://www.psmd-marker.com).**


## IMPORTANT DISCLAIMER  

PSMD is NOT a medical device and therefore **for research use only**. Do not use PSMD for diagnosis, prognosis, monitoring or any other clinical routine use. Any application in clinical routine is forbidden by law, e.g. by Medical Device Regulation article 5 in the EU.


## Usage

Download one of our [releases](https://github.com/miac-research/psmd/releases). For a new project, take the latest release. It is best practice to stick with one release version throughout a project.  

For even better replicability and traceability, we strongly recommend using a container for the software dependencies, e.g. the **[PSMD container recipe](https://github.com/miac-research/psmd/tree/main/container)** for Apptainer/Singularity.

For more information, please see the project website at [www.psmd-marker.com](https://www.psmd-marker.com) or type `./psmd.sh -h` at the command line.


## Contents of download packages

* `psmd.sh` - PSMD script
* `skeleton_mask_2019.nii.gz` - Updated (2019) skeleton mask image
* `LICENSE` - Please take a minute to read the license file
* Folder `examples` - Sample dataset for testing
* Folder `container` - Apptainer/Singularity container recipe


## Version history

Starting with version 1.6, all development is done in this GitHub repository. 
See the [GitHub releases page](https://github.com/miac-research/psmd/releases) for the latest and previous releases. 


## Roadmap of future development

See the [GitHub issues page](https://github.com/miac-research/psmd/issues) for current development topics. If you found a bug or have suggestions for new features, please feel free to open an issue.


## License

The script itself is published under the BSD 3-clause license. Please see the `LICENSE` file provided in this repository.

An [FSL license](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/Licence) is required to run PSMD.


## Support

The PSMD project was initiated at the Institue for Stroke and Dementia Research (ISD), Munich, Germany, with funding support by the LMU FöFoLe program (grant 808), the Else Kröner-Fresenius-Stiftung (EKFS, grant 2014_A200), and the Vascular Dementia Research Foundation.

The ongoing development of PSMD is supported by Medical Image Analysis Center (MIAC), Basel, Switzerland.
