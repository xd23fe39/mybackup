#!/usr/bin/env /bin/bash
#
# REV.18.0313
# mybackup.sh

# SCRIPT_DIR setzen
SCRIPT_DIR="`dirname $0`"

# SCRIPT_DIR setzen
SCRIPT_NAME="`basename $0`"

# BASEDIR setzen
BASEDIR="`dirname $0`/.."

# Hostname/Nodename holen
HOSTNAME=$(hostname)

# Script directory, eg. /this/is/your/app/bin
script_dir=`dirname $0`

# MYBACKUP Project/Job Folder and Files
MYBACKUP_FOLDER="./.mybackup"
MYBACKUP_SERVER="$MYBACKUP_FOLDER/server.conf"
MYBACKUP_JOB="$MYBACKUP_FOLDER/job.conf"
MYBACKUP_EXCLUDES="$MYBACKUP_FOLDER/excludes.conf"
MYBACKUP_LOG="$MYBACKUP_FOLDER/mybackup.log"

# RSYNC default options
#  -a, --archive  archive mode; equals -rlptgoD (no -H,-A,-X)
RSYNC="`which rsync`"
RSYNC_DRYRUN='-n --delete --delete-excluded'
RSYNC_OPTS='--archive --verbose'
RSYNC_EXCLUDE="--exclude-from $MYBACKUP_JOB"
RSYNC_BASE="/mnt/vol1/users"

# Set relative to script_dir
CONFDIR="${SCRIPT_DIR}/../config"
LOGDIR="~"

SEPARATOR="---"

function mb_separator {
	echo $SEPARATOR
}

function mkdir_folder
{
	if [ ! -d "$MYBACKUP_FOLDER" ]
	then
		mkdir -p "$MYBACKUP_FOLDER"
		return 0
	fi
	return 1
}

# Load Backup Host configuration
function load_server
{
	if [ -f "$MYBACKUP_SERVER" ]
	then
		. $MYBACKUP_SERVER
	else
		echo; echo "  No Backup configuration file found! File: $MYBACKUP_SERVER"; echo
		exit 1
	fi
}

# Get/Show host configuration
function mb_get_server
{
	load_server
	echo
	echo "   RSYNC Command:  ${RSYNC}"
	echo "      RSYNC Host:  ${RSYNC_HOST}"
	echo "      RSYNC User:  ${RSYNC_USER}"
	echo "   RSYNC Basedir:  ${RSYNC_BASE}"
	echo "   RSYNC Options:  ${RSYNC_OPTS}"
	echo
	echo "        Settings:  $MYBACKUP_SERVER"
	echo
}

function create_job
{
JOB="#!`which bash`
# MyBackup JOB descriptor file (.mybackup-job)
# `uname -svm`
#
# Backup Job Descriptor
MYBACKUP_PROJECT=$USER
MYBACKUP_CLIENT=$HOSTNAME
MYBACKUP_SOURCE=\"`pwd`\"
MYBACKUP_EXCLUDES=\"$MYBACKUP_EXCLUDES\"
MYBACKUP_JOB=\"$MYBACKUP_JOB\"
MYBACKUP_SERVER=\"$MYBACKUP_SERVER\"
# EOF
"
	echo "$JOB"

	if [ "$1" == "--save" ]
	then
		echo "$JOB" >$MYBACKUP_JOB
	fi
}

function mb_get_excludes {
	$OPTIONS="$3"
	echo
	echo "  Excludes: ${MYBACKUP_EXCLUDES}"
	echo
	mb_separator
	cat ${MYBACKUP_EXCLUDES}
	mb_separator
	echo "EOF"
	echo
}

function create_server
{
	# Load Default MYBACKUP server template
	. ${CONFDIR}/default.mybackup-server
	# Create settings and print it on stdout

SERVER="#!`which bash`
# File: mybackup.config
# `uname -svm`
#
# MyBackup server settings for 'rsync'
#
RSYNC_HOST=$RSYNC_HOST
RSYNC_USER=$RSYNC_USER
RSYNC_PASSWORD=$RSYNC_PASSWORD
RSYNC_BASE=\"$RSYNC_BASE\"
RSYNC_ROPTS=\"$RSYNC_OPTS\"
#
"

	echo "$SERVER"
	if [ "$1" == "--save" ]
	then
		echo "$SERVER" > $MYBACKUP_SERVER
	fi
}

function create_excludes
{
EXCLUDES="# $MYBACKUP_EXCLUDES
# Ignore tagged Files and Directories
_*
&*
§*
\$*
# Ignore Build and Deploy
[Bb]uild
[Dd]eploy
# Ignore GIT
.git
.gitignore
.git*
"

	if [ ! -f "$MYBACKUP_EXCLUDES" ]
	then
		echo "$EXCLUDES" >./$MYBACKUP_EXCLUDES
	fi
}

function mb_init_project
{
	if [ -d "$MYBACKUP_FOLDER" ]
	then
		echo; echo "  Project '$MYBACKUP_FOLDER' allready exists!"; echo
		echo "  Nothing to initialize. Use 'get job'."; echo
		exit 1
	fi
	if [ "$1" == "--save" ]
	then
		mkdir_folder
		create_excludes --save
		create_job --save
		create_server --save
		return 0
	else
		create_job
		create_server
		echo; echo "  Use: init [--save]"; echo
		return 2
	fi
}

# Load Backup job file (search also for mybackup.job if $1 is a directory)
function load_job
{
	JOB=$MYBACKUP_JOB
	if [ -f "$JOB" ]
	then
		. $JOB
	elif [ -f "$JOB/mybackup.job" ]
	then
		. $JOB/mybackup.job
	else
		echo; echo "  Missing Backup Job File '$JOB' "
		if [ -d "$JOB" ]
		then
			echo; echo "  Try: $SCRIPT_NAME create job $1";
		fi
		echo
		return 2
	fi
	return 0
}

# Show job configuration
function mb_get_job
{
	OPTIONS="$3"
	load_job "$MYBACKUP_JOB"
	if [ "$?" == "0" ]
	then
		echo
		echo "   Backup Project:   $MYBACKUP_PROJECT"
		echo "    Backup Client:   $MYBACKUP_CLIENT"
		echo "    Backup Source:   $MYBACKUP_SOURCE"
		echo "   Backup Exclude:   $MYBACKUP_EXCLUDES"
		echo
		echo "       Backup Job:   $MYBACKUP_JOB"
		echo
	else
		echo "  No Backup Job/Project!"; echo
	fi
	if [ "$OPTIONS" == "--all" ]
	then
		mb_get_server
	fi
}

function mb_remote
{
	load_server "$MYBACKUP_SERVER"
	load_job "$MYBACKUP_JOB"

	echo;echo "RSYNC/SSH: $RSYNC_USER@$RSYNC_HOST $1"
	mb_separator

	#### SSH Command ####
	ssh "$RSYNC_USER@$RSYNC_HOST" "ls -l $RSYNC_BASE/$MYBACKUP_PROJECT/$MYBACKUP_CLIENT/$1"
	EXIT_CODE=$?
	#### SSH Command ####

	mb_separator
	if [ "$EXIT_CODE" != "0" ]
	then
		echo "Check ssh login. Use: ssh $RSYNC_USER@$RSYNC_HOST or ssh-copy-id"
	fi

	return $EXIT_CODE
}

function mb_test_server
{
	load_server "./$MYBACKUP_SERVER"
	EXIT_CODE=0
	if [ "${RSYNC_HOST}" == "" ]
	then
		EXIT_MESSAGE="Backup Host not defined!"
		EXIT_CODE=1
	else
		ping -c 1 ${RSYNC_HOST} >/dev/null
		if [ "$?" != "0" ]
		then
			EXIT_MESSAGE="Backup Host not available!"
			EXIT_CODE=2
		fi
	fi
	if [ "$EXIT_CODE" == "0" ]
	then
		return $EXIT_CODE
	fi
	# Error handling
	if [ "$3" == "--verbose" ]
	then
		return $EXIT_MESSAGE
	fi
	return $EXIT_CODE
}

function mb_usage {
	echo
	echo "  Usage: mybackup [init|get|help|log|push|remote|status|test] "
	echo
	echo "  Using: $RSYNC"
	echo
}

##
#
# http://www.linux-services.org/shell/
#
function mb_return {
	if [ "$?" == "0" ]
	then
		echo "OK"
	else
		echo "FAILURE"
		exit $1
	fi
}

function mb_get {
	COMMAND="$2"
	case "$COMMAND" in
		job)
			mb_get_job $@
		;;
		server)
			mb_get_server $@
		;;
		excludes)
			mb_get_excludes $@
		;;
		*)
		echo; echo "  Use: 'get [job|server|excludes]'"; echo
		exit 1
		;;
	esac
	exit 0
}

function mb_log {
	if [ -f "$MYBACKUP_LOG" ]
	then
		cat $MYBACKUP_LOG
	else
		echo; echo "  No logfile found! File: $MYBACKUP_LOG"; echo
		exit 1
	fi
}

function mb_printc {
	echo
	echo "MyBACKUP($COMMAND)... $OPTION $1"
	echo $SEPARATOR
}

# ========================================================================
# Command: push
#
# Lädt die JOB- und Server-Definitionsdatei und ruft dann RSYNC
# auf, um die Datensicherung zu starten.
#
# Options: --delete - entfernt verwaiste Dateien im Zielordner
#
function mb_push {
	SOURCE_DIR="`pwd`"
	mb_printc $SOURCE_DIR
	mb_test_server
	if [ "$?" == "0" ]
	then
		load_server "$MYBACKUP_SERVER"
		load_job "$MYBACKUP_JOB"
		if [ "$1" == "--delete" ]
		then
			RSYNC_OPTS="$RSYNC_OPTS --delete --force --delete-excluded "
		fi
		CMD="$RSYNC $RSYNC_OPTS --exclude-from $MYBACKUP_EXCLUDES $SOURCE_DIR ${RSYNC_USER}@${RSYNC_HOST}:${RSYNC_BASE}/${MYBACKUP_PROJECT}/${MYBACKUP_CLIENT}"
		#### RUNNING RSYNC ####
		$CMD
		#### RUNNING RSYNC ####
		mb_separator
		echo "[`date '+%Y-%m-%d %H:%M:%S'` - CMD] $CMD" | tee -a $MYBACKUP_LOG
		mb_separator
		echo "OK";
		exit 0;
	else
		echo "FAILURE";
		exit 10
	fi
}

# ========================================================================
# Command: status
#
# Lädt die JOB-Definitionsdatei und ruft dann RSYNC im Simulationsmodus
# mit der Option RSYNC_DRYRUN='-n --delete' auf.
#
function mb_status {
	SOURCE_DIR="`pwd`"
	mb_printc $SOURCE_DIR
	mb_test_server
	if [ "$?" == "0" ]
	then
		# Laden von JOB- und SERVER-Definitionsdatei
		load_server
		load_job
		#### RUNNING RSYNC ####
		CMD="$RSYNC $RSYNC_DRYRUN $RSYNC_OPTS --exclude-from ./$MYBACKUP_EXCLUDES $SOURCE_DIR ${RSYNC_USER}@${RSYNC_HOST}:${RSYNC_BASE}/${MYBACKUP_PROJECT}/${MYBACKUP_CLIENT}"
		$CMD
		#### RUNNING RSYNC ####
		mb_separator
		echo "[`date '+%Y-%m-%d %H:%M:%S'` - CMD] $CMD"
		mb_separator
		echo "OK";
		exit 0;
	else
		echo "FAILURE";
		exit 10
	fi
}

#####################################################################
# MAIN Program
COMMAND=$1
OPTION=$2
case "$COMMAND" in
	get)
		mb_get $@
		;;
	log)
		mb_log
		;;
	cleanup)
			mb_push $OPTION
			;;
	push)
		mb_push $OPTION
		;;
	status)
		mb_status $@
	 	;;
	host)
		mb_get_server $@
		;;
	init)
		mb_init_project $OPTION
		;;
	test)
		# test call
		mb_test_server
		mb_return 3
		;;
	remote)
		mb_remote $OPTION
		mb_return 4
		;;
	usage|help|*)
		mb_usage
		;;
esac

exit 0

# EOL 2016 fe
