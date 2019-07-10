#!/usr/bin/bash
set -x

# set pyenv path and checkout repo to that path
mkdir -p "/toolbox"

pyenv_path="/toolbox/pyenv"
git clone https://github.com/pyenv/pyenv $pyenv_path

# export these variables now for potential convenience
export PYENV_ROOT="$pyenv_path"
export PATH="$PYENV_ROOT/bin:$PATH"

# init pyenv if it isn't already
eval "$(pyenv init -)"
