#!/usr/bin/env bash

# ------------------------------
# Overview

# This script retrieves a github repo and builds it with meson.


# ------------------------------
# Script configuration


# ------------------------------
# Variables

LOGTAG_MAIN="[Main]"
LOGTAG_DEBUG="[Debug]"
LOGTAG_BUILD="[Build]"
LOGTAG_REPO="[Repository]"


# ------------------------------
# Functions

# >> Error functions

# TODO
# function repo_err() { }

# >> Utility functions

# Logging functions
function log_tagstart() {
  log_tag="${1}"
  log_msg="${2}"

  echo -e "\t[${1}] > ${2}"
}

function log_tagstop() {
  log_tag="${1}"
  log_msg="${2}"

  echo -e "\t[${1}] | ${2}"
}

function log_tagmsg() {
  log_tag="${1}"
  log_msg="${2}"

  echo -e "\t[${1}]\t${2}"
}

# Directory functions
function change_workdir() {
  work_dir="${1:?"Missing: target working directory."}"

  pushd "${work_dir}" >/dev/null
  log_tagmsg "${LOGTAG_MAIN}" "Changed to directory: '${PWD}' (expected: '.../${work_dir}')"

  if [[ "${PWD}" -ef "${work_dir}" ]]; then
    log_tagstop "${LOGTAG_MAIN}" "Error: changed to incorrect working directory"
    return 1
  fi
}

# Repository functions
function repo_clone() {
  repo_uri="${1:?"Missing: repository URI"}"
  repo_tag="${2:?"Missing: repository tag"}"

  log_tagstart "${LOGTAG_REPO}" "cloning '${repo_uri}'"

  git clone --branch "${repo_tag}" \
            --recursive            \
            -- "${repo_uri}" "${PWD}"

  if [[ $? -ne 0 ]]; then
    log_tagstop "${LOGTAG_REPO}" "Error: failed to clone repository"
    return 1
  fi

  log_tagstop "${LOGTAG_REPO}" "cloned"
}

# Build functions
function project_prepare() {
  proj_srcdir="${1:?"Missing: source directory to use for build."}"
  repo_uri="${2:?"Missing: repository URI"}"
  repo_tag="${3:?"Missing: repository tag"}"

  if [[ -d "${proj_srcdir}" ]]; then
    echo "Error: source dir exists."
    return
  fi

  log_tagstart "${LOGTAG_BUILD}" "preparing source dir"

  # Create the directories
  mkdir -p "${proj_srcdir}"

  # Prepare the source directory
  pushd "${proj_srcdir}" >/dev/null
  repo_clone "${repo_uri}" "${repo_tag}"
  popd >/dev/null

  log_tagstop "${LOGTAG_BUILD}" "source dir prepared"
}

function project_build() {
  proj_builddir="${1:?"Missing: destination directory for build."}"
  proj_srcdir="${2:?"Missing: source directory to use for build."}"

  if [[ -d "${proj_builddir}" ]]; then
    echo -e "Error: build dir exists."
    return
  fi

  # go to the builddir and get PWD to handle relative vs absolute and symlinks
  mkdir -p "${proj_builddir}"
  pushd "${proj_builddir}" >/dev/null
  absolute_builddir="${PWD}"

  log_tagstart "${LOGTAG_BUILD}" "building project"

  pushd "${proj_srcdir}" >/dev/null

  meson setup "${absolute_builddir}"
  meson configure -D default_library=both "${absolute_builddir}"
  meson compile -C "${absolute_builddir}"
  # meson install -C "${absolute_builddir}"

  log_tagstop "${LOGTAG_BUILD}" "project built"
}


# ------------------------------
# Main

cli_repo_uri="${1:?"Missing argument: repository URI."}"
cli_repo_tag="${2:?"Missing argument: repository tag."}"
cli_workdir="${3:?"Missing argument: base work directory (necessary for relative paths)."}"
cli_srcdir="${4:?"Missing argument: source directory (where repo is cloned to)."}"
cli_builddir="${5:?"Missing argument: build directory (where build output goes)."}"


log_tagstart "${LOGTAG_MAIN}" "Building meson-based project from repository"

change_workdir "${cli_workdir}"
if [[ $? -ne 0 ]]; then
  log_tagstop "${LOGTAG_MAIN}" "Error: could not change to working directory"
  exit 1
fi

project_prepare "${cli_srcdir}" "${cli_repo_uri}" "${cli_repo_tag}"
if [[ $? -ne 0 ]]; then
  log_tagstop "${LOGTAG_MAIN}" "Error: could not prepare project source"
  exit 2
fi

project_build "${cli_builddir}" "${cli_srcdir}"
if [[ $? -ne 0 ]]; then
  log_tagstop "${LOGTAG_MAIN}" "Error: could not build project"
  exit 3
fi

log_tagstop "${LOGTAG_MAIN}" "finished building project"

