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
	${MKDIR} ${TEST}/bin
	${MKDIR} ${TEST}/SOURCE
	${MKDIR} ${TEST}/TARGET
}

function build_cleanup() {
	${RMDIR} ${BUILD}
	${RMDIR} ${TEST}
	rm build.out
}

function build_all() {
	build_init $@
	build_test_sourcefileset
	${CPDIR} ./bin $TEST
	${CCD}/$TEST/bin
	. ./mybackup-profile.sh      # set environment 
	${CCD}/$TEST/SOURCE          # goto SOURCE folder
	mybackup.sh                  # show Usage of mybackup.sh 
	echo "Build completed."; echo "Start test workflow using: mybackup init --save"; echo
}

function build_test() {
	echo "TEST: $@"; echo
}

function build_test_sourcefileset() {
	touch $TEST/SOURCE/file1.tst
	touch $TEST/SOURCE/file2.tst
	mkdir $TEST/SOURCE/folder1
	touch $TEST/SOURCE/folder1/file1.tst
	touch $TEST/SOURCE/folder1/file2.tst
}

function build_() {
	echo "Usage: build.sh all|cleanup|test"
	echo
}

# Standard-Ausgabe 
echo; echo "BUILD: `uname -a`"; echo

# MAIN: Aufruf von Kommando-Modul ${1}
build_${1} $@ | tee -a build.out
