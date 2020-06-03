#!/bin/bash
# 
# build.sh
#

set -exu -o pipefail

scriptdir=$(pwd)

build() {
    local pkg
    pkg=$1

    cd $pkg

    local log
    log=build.log
    if [[ -f $log ]]; then
        rm $log
    fi

    makepkg -scCf --nocheck --noconfirm &>> $log
}

case $1 in
    linux)
        pkgs="$scriptdir"/../linux
        ;;
    core|extra)
        pkgs=$(ls -d $scriptdir/../$1/[d-z]*)
        ;;
    *)
        # unknow repo
        exit 1
        ;;
esac

for p in ${pkgs[@]}; do
    build $p
done
