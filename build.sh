#!/usr/bin/env /bin/bash

# Build Config
SHELL=$(which bash)
PWD=$(pwd)
MKDIR="mkdir -p"
RMDIR="rm -Rf"
CPDIR="cp -R "
BUILD="./BUILD"
TEST="./TEST"
CCD="cd $PWD"

function build_init() {
	${MKDIR} ${BUILD}
	${MKDIR} ${TEST}
}

function build_cleanup() {
	${RMDIR} ${BUILD}
	${RMDIR} ${TEST}
	rm build.out
}

function build_all() {
	build_init $@
	${CPDIR} ./bin $BUILD/
	${CCD}/$BUILD/bin
	. ./mybackup-profile.sh
	${CCD}/$TEST
	mybackup.sh
	mybackup.sh init --save
}

function build_test() {
	echo "TEST: $@"; echo
}

function build_() {
	echo "Usage: build.sh all|cleanup|test"
	echo
}

# Standard-Ausgabe 
echo; echo "BUILD: `uname -a`"; echo

# MAIN: Aufruf von Kommando-Modul ${1}
build_${1} $@ | tee -a build.out
