#!/usr/bin/bash
set -x

# set pyenv path and checkout repo to that path
pyenv_path="/toolbox/pyenv"
git clone https://github.com/pyenv/pyenv $pyenv_path

# export these variables now for potential convenience
export PYENV_ROOT="$pyenv_path"
export PATH="$PYENV_ROOT/bin:$PATH"

# init pyenv if it isn't already
eval "$(pyenv init -)"

# install and set python version
pyenv install 3.7.3
pyenv global  3.7.3
