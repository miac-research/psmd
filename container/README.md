# Container for PSMD dependencies

**Please report any bugs with the Singularity container on the [issues page](https://github.com/miac-research/psmd/issues).**

Using containers can solve problems arising from inconsistent dependencies and heterogeneous environments.

Singularity or Apptainer (the Linux Foundation variant of Singularity) is a well-established container solution, developed with scientific computing and deployment on HPC infrastructure (compute cluster) in mind.

This container recipe installs the required system packages and FSL 6.0.3 on top of Ubuntu Bionic as operating system.

> **Please note**: As of version 1.8.3, the PSMD script itself is no longer part of the container. It needs to downloaded separately from the [releases page](https://github.com/miac-research/psmd/releases).


## IMPORTANT DISCLAIMER  

PSMD is NOT a medical device and therefore **for research use only**. Do not use PSMD for diagnosis, prognosis, monitoring or any other clinical routine use. Any application of the psmd script in clinical routine is forbidden by law, e.g. by Medical Device Regulation article 5 in the EU.


## Instructions

### Prerequisites

- Linux operating system
- For Windows or macOS: A Linux virtual machine
- Installation of [Singularity >3.6](https://github.com/sylabs/singularity) or [Apptainer](http://apptainer.org)

> In the following code examples, **if you are using Apptainer** always substitute `singularity` with `apptainer`.

### Build the container

- Download the cotnainer recipe file `psmd_container.txt`
- Build the container `psmd.sif` from the recipe file (as root or using sudo)

```
wget https://raw.githubusercontent.com/miac-research/psmd/main/singularity/singularity-psmd.txt
sudo singularity build psmd.sif psmd_container.txt
```

> Please note that the container will be quite large, usually around 2.5 GB. In order to save space, some parts of the FSL installation are deleted. The container does not contain a fully functional FSL installation, but a minimal installation suited for diffusion processing and PSMD calculation. You can modify the recipe file in order to retain a full FSL installation.

### Run the container

- All dependencies are within the container, but the PSMD script itself needs to be provided outside of the container. Please make sure not to switch the PSMD script version within one project!

- Example for a PSMD pipeline using the Singularity container, assuming the container, the PSMD script and the data are all in the current folder:

```bash
singularity exec -B $(pwd) psmd.sif psmd.sh -d data.nii.gz -b data.bvals \
  -r data.bvecs -s skeleton_mask_2019.nii.gz 
```

- **IMPORTANT**: By default, the container has access only to your home folder. If your data (or the skeleton) is in another folder, you need to make the folder available to the container using the bind option `-B`. This is why `-B $(pwd)` was added to the command above. It will bind the current folder into the container.

- You can also bind specific paths to the container. The following example works if subjectA (from the example subjects provided in this repository) is located at `/home/user/data/subjectA` and the PSMD script, the container and the skeleton mask are located at `/home/user/psmd`:

```bash
datafolder=/home/user/data/subjectA
psmdfolder=/home/user/psmd
singularity exec -B ${datafolder} -B ${psmdfolder} ${psmdfolder}/psmd.sif ${psmdfolder}/psmd.sh \
  -f ${datafolder}/subjectA_FA.nii.gz -m ${datafolder}/subjectA_MD.nii.gz \
  -s ${psmdfolder}/skeleton_mask_2019.nii.gz
```


## Acknowledgements

The container recipe was in part generated by [Neurodocker](https://github.com/ReproNim/neurodocker).


## License

While PSMD depends on FSL, it is not part of FSL. FSL is only used as a library/dependency in the container. Make sure to comply with the [FSL license conditions](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/Licence). **In particular, commercial use requires a paid license of FSL!**

