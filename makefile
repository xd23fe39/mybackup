# Makefile
SHELL=/usr/bin/env /bin/bash
MKDIR=mkdir -p
RMDIR=rm -Rf

all: compile

test:
	@echo "Test..."
	@echo "`uname -a`"
	$(MKDIR) ./test

test-init:
	. ./bin/mybackup-profile.sh 
	cd ./test
	mybackup init --save
	cd ..

cleanup:
	@echo "Cleanup..."
	$(RMDIR) ./test

compile:
	@echo "Compile..."
	@echo "Nothing to do!"

sample:
	@echo "This Target: " $@