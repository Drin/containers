FROM alpine:latest

# Image labels
LABEL      "maintainer"="Aldrin Montana <akmontan@ucsc.edu>"
LABEL            "name"="pybase"
LABEL         "version"="0.0.1"

# ------------------------------
# Setup base image packages and environment

# update and install needed packages
RUN        apk update
RUN        apk add --no-cache build-base  \
                              zlib-dev    \
                              libffi-dev  \
                              openssl-dev \
                              bzip2-dev   \
                              bash        \
                              python3     \
                              git

# prep basic directories and configs
WORKDIR    "/workspace"
RUN        mkdir -p "/toolbox"
COPY       scripts/get-poetry.py       /get-poetry.py
COPY       config/bash_environment     "/root/.bash_environment"

# ------------------------------
# Setup image tools

# prep pyenv and python default interpreter
COPY       scripts/install-pyenv.bash  /install-pyenv.bash
RUN        ["bash", "/install-pyenv.bash"]

# prep poetry
COPY       scripts/install-poetry.bash /install-poetry.bash
RUN        ["bash", "/install-poetry.bash", "local"]

# Prep entry script
COPY       scripts/entrypoint.bash     /entrypoint.bash
ENTRYPOINT ["bash", "/entrypoint.bash"]
