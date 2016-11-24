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

MYBACKUP_SERVER=".mybackup-server"
MYBACKUP_JOB=".mybackup-job"
MYBACKUP_EXCLUDES=".mybackup-excludes"

# RSYNC default options
#  -a, --archive  archive mode; equals -rlptgoD (no -H,-A,-X)
RSYNC="`which rsync`"
RSYNC_DRYRUN='-n --delete'
RSYNC_OPTS='--archive --verbose'
RSYNC_EXCLUDE="--exclude-from $MYBACKUP_JOB"

# Set relative to script_dir
CONFDIR="${SCRIPT_DIR}/../config"
LOGDIR="~"

# Load Backup Host configuration
function load_server
{
	if [ -f "${1}" ]
	then
		. ${1}
	else
		echo; echo "  No Backup configuration file found! File: ${1}"; echo
		exit 1
	fi
}

# Get/Show host configuration
function get_server
{
	load_server "./$MYBACKUP_SERVER"
	echo
	echo "   RSYNC Command:  ${RSYNC}"
	echo "      RSYNC Host:  ${RSYNC_HOST}"
	echo "      RSYNC User:  ${RSYNC_USER}"
	echo "   RSYNC Basedir:  ${RSYNC_BASE}"
	echo "   RSYNC Options:  ${RSYNC_OPTS}"
	echo
	echo "        Settings:  ./$MYBACKUP_SERVER"
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
		echo "$JOB" >./.mybackup-job
		echo "  Saved!"
		echo
	fi
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
		echo "  Saved!"
	else
		echo "  Use: '--save' to create file '$MYBACKUP_SERVER'"
	fi
	echo
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

	if [ ! -f "./$MYBACKUP_EXCLUDES" ]
	then
		echo "$EXCLUDES" >./$MYBACKUP_EXCLUDES
		echo "  Saved: ./$MYBACKUP_EXCLUDES"; echo
	else
		echo "  Excludes already exists!"; echo
	fi

}

# Load Backup job file (search also for mybackup.job if $1 is a directory)
function load_job
{
	JOB=$1
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
function get_job
{
	load_job "./$MYBACKUP_JOB"
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
	# echo "List exclude items:"
	# cat "$MYBACKUP_EXCLUDE"
	# echo
}

function func_remote
{
	load_server "./$MYBACKUP_SERVER"
	load_job "./$MYBACKUP_JOB"

	echo;echo "RSYNC/SSH: $RSYNC_USER@$RSYNC_HOST $1"
	echo "---"

	#### SSH Command ####
	ssh "$RSYNC_USER@$RSYNC_HOST" "ls -l $RSYNC_BASE/$MYBACKUP_PROJECT/$MYBACKUP_CLIENT/$1"
	EXIT_CODE=$?
	#### SSH Command ####

	echo "---"
	if [ "$EXIT_CODE" != "0" ]
	then
		echo "Check ssh login. Use: ssh $RSYNC_USER@$RSYNC_HOST or ssh-copy-id"
	fi

	return $EXIT_CODE
}

function test_server
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

#####################################################################
# MAIN Program

case "$1" in
	start)
		;;
	stop)
		;;
	get)
		# Create config-File on stdout for backup source $3
		if [ "$2" == "job" ]
		then
			get_job $3
			exit 0
		fi
		if [ "$2" == "server" ]
		then
			get_server $3
			exit 0
		fi
		echo; echo "  Use: 'get job | server'"; echo
		exit 1
		;;
	log)
		if [ -f "${2}/mybackup.log" ]
		then
			cat ${2}/mybackup.log
		else
			echo; echo "  No logfile found! File: ${2}/mybackup.log"; echo
			exit 1
		fi
		;;
	push)
		SOURCE_DIR="`pwd`"
		test_server
		if [ "$?" == "0" ]
		then
			load_server "./$MYBACKUP_SERVER"
	 		load_job "./$MYBACKUP_JOB"
			# TODO: Insert here RSYNC Backup
			CMD="$RSYNC $RSYNC_OPTS --exclude-from $MYBACKUP_EXCLUDES $SOURCE_DIR ${RSYNC_USER}@${RSYNC_HOST}:${RSYNC_BASE}/${MYBACKUP_PROJECT}/${MYBACKUP_CLIENT}"
			#### RUNNING RSYNC ####
			$CMD
			#### RUNNING RSYNC ####
			echo "---"
			echo "[`date '+%Y-%m-%d %H:%M:%S'` - CMD] $CMD"
			echo "---"
			echo "OK";
			exit 0;
		else
			echo "FAILURE";
			exit 10
		fi
		;;
	status)
		SOURCE_DIR="`pwd`"
		# Load backup job descriptor file if exists
		test_server
		if [ "$?" == "0" ]
		then
			load_server "./$MYBACKUP_SERVER"
	 		load_job "./$MYBACKUP_JOB"
			CMD="$RSYNC $RSYNC_DRYRUN $RSYNC_OPTS --exclude-from ./$MYBACKUP_EXCLUDES $SOURCE_DIR ${RSYNC_USER}@${RSYNC_HOST}:${RSYNC_BASE}/${MYBACKUP_PROJECT}/${MYBACKUP_CLIENT}"
			$CMD
			echo "---"
			echo "[`date '+%Y-%m-%d %H:%M:%S'` - CMD] $CMD"
			echo "---"
			echo "OK";
			exit 0;
		else
			echo "FAILURE";
			exit 10
		fi
	 	;;
	host)
		get_server
		exit 0
		;;
	create)
		if [ "$2" == "excludes" ]
		then
			create_excludes $3
			exit 0
		fi
		if [ "$2" == "job" ]
		then
			create_job $3
			exit 0
		fi
		if [ "$2" == "server" ]
		then
			create_server $3
			exit 0
		fi
		echo; echo "  Try: create job | server | excludes"; echo
		exit 1;
		;;
	test)
		# test call
		test_server
		if [ "$?" == "0" ]
		then
			echo "OK"
		else
			echo "FAILURE"
		fi
		;;
	remote)
		func_remote $2
		if [ "$?" == "0" ]
		then
			echo "OK"
		else
			echo "FAILURE"
		fi
		;;
	usage|help|*)
		echo
		echo "  Usage: mybackup create|get|help|log|push|status|test "
		echo
		echo "  Using: $RSYNC"
		echo
		exit 0
		;;
esac
