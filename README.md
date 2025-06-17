# PSMD (Peak width of Skeletonized Mean Diffusivity)

PSMD is a robust, fully-automated and easy-to-implement marker for cerebral small vessel disease based on diffusion tensor imaging, white matter tract skeletonization (as implemented in FSL-TBSS) and histogram analysis.

> [!CAUTION]
> PSMD is NOT a medical device and **for academic research use only**. Do not use PSMD for diagnosis, prognosis, monitoring or any other clinical routine use. Any application in clinical routine is forbidden by law, e.g. by Medical Device Regulation article 5 in the EU.

## Usage

**For detailed information on usage, including FAQ, please visit [the PSMD Wiki](https://github.com/miac-research/psmd/wiki/).**

As of version 1.9.0, the preferred way of using PSMD is a [pre-built container image](https://github.com/miac-research/psmd/pkgs/container/psmd), which can be used with Docker, Apptainer, and compatible container platforms. The usage is simple:

**Using Apptainer:**

```shell
# 1. Pull the container image and save as .sif file 
apptainer build psmd.sif docker://ghcr.io/miac-research/psmd:latest

# See available command line options:
apptainer run psmd.sif -h
```

**Using Docker**: 

```shell
# 1. Pull the container image into your local registry
docker pull ghcr.io/miac-research/psmd:latest
docker tag ghcr.io/miac-research/psmd:latest psmd:latest

# For advanced usage, see available command line options:
docker run --rm psmd:latest -h
```

**Local installation (not recommended)**: Alternatively, you can download the PSMD script from the [releases page](https://github.com/miac-research/psmd/releases) and run it in your local environment.

> [!NOTE]  
> For a new project, take the latest release. It is best practice to **stick with one release version or – even better – the same container image** throughout a project.

## Version history

Starting with version 1.6, all development is done in this GitHub repository. 
See the [releases page](https://github.com/miac-research/psmd/releases) for the version history and the [packages page](https://github.com/miac-research/psmd/pkgs/container/psmd) for available pre-built container images.

## License

The PSMD script itself is published under the BSD 3-clause license. Please see the `LICENSE` file provided in this repository.

> [!IMPORTANT]  
> Please note that an [FSL license](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/Licence) is required to run PSMD.

## Support

The PSMD project was initiated at the Institue for Stroke and Dementia Research (ISD), Munich, Germany, with funding support by the LMU FöFoLe program (grant 808), the Else Kröner-Fresenius-Stiftung (EKFS, grant 2014_A200), and the Vascular Dementia Research Foundation.

The ongoing development of PSMD is supported by Medical Image Analysis Center (MIAC AG), Basel, Switzerland.
