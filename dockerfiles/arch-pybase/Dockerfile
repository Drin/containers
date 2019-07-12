FROM archlinux/base:latest

# Image labels
LABEL   "maintainer"="Aldrin Montana <akmontan@ucsc.edu>"
LABEL         "name"="pybase"
LABEL      "version"="0.0.1"

# ------------------------------
# Image prep
# update packages then install needed packages
RUN     pacman -Syu --noconfirm base-devel openssl git tar

# Image mounts
WORKDIR "/workspace"
RUN     mkdir -p "/toolbox"
COPY    scripts/get-poetry.py       /get-poetry.py
COPY    config/bash_environment     "/root/.bash_environment"
COPY    config/bash_init            "/root/.bash_init"

# create directories and change directory

# install and setup pyenv
COPY    scripts/install-pyenv.bash  /install-pyenv.bash
RUN     ["bash", "/install-pyenv.bash"]

COPY    scripts/install-poetry.bash     /install-poetry.bash
RUN     ["bash", "/install-poetry.bash", "local"]
