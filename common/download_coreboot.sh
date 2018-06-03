#!/bin/bash
# SPDX-License-Identifier: GPL-3.0+
source "/home/coreboot/common_scripts/variables.sh"

IS_BUILD_DIR_EMPTY="$(ls -A $DOCKER_COREBOOT_DIR)"


################################################################################
## Update or clone git coreboot repo
################################################################################
function gitUpdate() {
  if [ -z "$IS_BUILD_DIR_EMPTY" ]; then
    # Clone Coreboot and fetch submodules
    git clone https://github.com/coreboot/coreboot.git $DOCKER_COREBOOT_DIR
    cd $DOCKER_COREBOOT_DIR || exit
    git submodule update --init --recursive --remote

    # blobs are ignored from updates.  Manually clone to prevent compile errors later from non empty directory cloning
    git clone https://github.com/coreboot/blobs.git 3rdparty/blobs/
  else
    cd $DOCKER_COREBOOT_DIR || exit
    git fetch --all --tags --prune

    cd "$DOCKER_COREBOOT_DIR/3rdparty/blobs/" || exit
    git fetch --all --tags --prune
  fi
}
################################################################################



################################################################################
##
################################################################################
function checkoutTag() {
  git checkout tags/$COREBOOT_TAG || exit
  git submodule update --recursive --remote
}
################################################################################



################################################################################
##
################################################################################
function checkoutCommit() {
#edge should checkout master
  git checkout $COREBOOT_COMMIT || exit
  git submodule update --recursive --remote
}
################################################################################


################################################################################
## Download the latest released version of Coreboot
################################################################################
function downloadCoreboot() {
  CB_RELEASES=$(wget -q -O- https://coreboot.org/releases/sha256sum.txt  | sed 's/[^*]*\*//')

  LATEST_RELEASE=$(echo -n "$CB_RELEASES" | fgrep "coreboot-" | fgrep -v "coreboot-blobs-" | sort -V | tail -n1)
  LATEST_BLOBS=$(echo -n "$CB_RELEASES" | fgrep "coreboot-blobs-" | sort -V | tail -n1)
  COREBOOT_VERSION=$(echo -n "$LATEST_RELEASE"  | sed 's/coreboot-//' | sed 's/.tar.xz//')

  wget -q -O- https://coreboot.org/releases/$LATEST_RELEASE | unxz -c | tar -C "$DOCKER_COREBOOT_DIR" -x --strip 1
  wget -q -O- https://coreboot.org/releases/$LATEST_BLOBS | unxz -c | tar -C "$DOCKER_COREBOOT_DIR" -x --strip 1

  export COREBOOT_VERSION;
}
################################################################################



################################################################################
## MAIN FUNCTION: download/clone/checkout appropriate version of CoreBoot
########################################
########################################################################################################################
function downloadOrUpdateCoreboot() {
  if [ -z $COREBOOT_COMMIT ] && [ -z $COREBOOT_TAG ] && [ -z "$IS_BUILD_DIR_EMPTY" ]; then
    # If a no commit nor tag is given and the directory is empty download Coreboot release
    downloadCoreboot;
  elif [ $COREBOOT_COMMIT ]; then
  #   DOCKER_COMMIT?=$(shell git log -n 1 --pretty=%h)
    gitUpdate
    checkoutCommit
  elif [ $COREBOOT_TAG ]; then
    gitUpdate
    checkoutTag
  fi
}
################################################################################
