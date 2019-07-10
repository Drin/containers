FROM archlinux/base:latest

# Image labels
LABEL "maintainer"="Aldrin Montana <akmontan@ucsc.edu>"
LABEL       "name"="pybase"
LABEL    "version"="0.0.1"

# Image mounts
COPY scripts/install-pyenv.bash  /install-pyenv.bash
COPY scripts/install-poetry.py   /install-poetry.py
COPY config/bashrc               "/root/.bashrc"

# ------------------------------
# Image prep
# update packages then install needed packages
RUN pacman -Syu --noconfirm base-devel zlib libffi openssl \
                            python git

# create directories and change directory
RUN     mkdir -p "/toolbox" "/workspace"
WORKDIR "/workspace"

# install and setup pyenv
RUN    source /install-pyenv.bash  \
    && pyenv install 3.7.3         \
    && pyenv global 3.7.3          \
    && pyenv local 3.7.3           \
    && python /install-poetry.py

# RUN    export PYENV_ROOT="/toolbox/pyenv"                 \
#     && export PATH="$PYENV_ROOT/bin:$PATH:/usr/local/bin" \
#     && eval   "$(pyenv init -)"                           \
#     && source $HOME/.poetry/env                           \
#     && poetry self:update

# Entry command
ENTRYPOINT ["bash"]
