FROM ubuntu:noble-20250529

LABEL org.opencontainers.image.authors="https://miac.swiss"
LABEL org.opencontainers.image.source="https://github.com/miac-research/psmd"
LABEL org.opencontainers.image.url="https://github.com/miac-research/psmd"
LABEL org.opencontainers.image.description="Ready-to-use container image for PSMD"
LABEL org.opencontainers.image.version="1.9.0"
LABEL version="1.9.0"

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    GIT_SSL_NO_VERIFY=1 \
    LANG="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8" \
    PATH="/opt/scripts:/opt/conda/bin:/opt/ants-2.4.3/bin:$PATH" \
    FSLOUTPUTTYPE="NIFTI_GZ" \
    FSLDIR="/opt/conda"

## Install OS dependencies and fix locale for Apptainer
RUN apt-get update -qq && apt-get install -y -q --no-install-recommends \
        adduser=3.137* \
        dc=1.07.1* \
        locales=2.39* \
        wget=1.21.4* \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
 && dpkg-reconfigure --frontend=noninteractive locales \
 && update-locale LANG="en_US.UTF-8"

## Install Conda 
RUN wget --progress=dot:giga --no-check-certificate https://repo.anaconda.com/miniconda/Miniconda3-py311_24.5.0-0-Linux-x86_64.sh -O /opt/miniconda.sh \
 && bash /opt/miniconda.sh -b -p /opt/conda \
 && rm /opt/miniconda.sh

## Conda install fsl-tbss & dipy
## Bump pillow and setuptools to mitigate CVEs
RUN conda install -y \
    -c https://fsl.fmrib.ox.ac.uk/fsldownloads/fslconda/public/ \
    -c conda-forge \
        fsl-data_standard=2208.0 \
        fsl-tbss=2111.1=hb6de94e_3 \
        pillow=10.4.0 \
        setuptools=71.0.4 \
 && sed -i -e '105s/^/# /' -e '106s/^/# /' -e '107s/^/# /' -e '108s/^/# /' -e '109s/^/# /' /opt/conda/bin/tbss_1_preproc

## PSMD pipeline
WORKDIR /opt/scripts
COPY psmd.sh /opt/scripts/psmd.sh
RUN chmod +x /opt/scripts/psmd.sh

RUN adduser --system --no-create-home nonroot
USER nonroot
ENTRYPOINT [ "/opt/scripts/psmd.sh" ]