# mybackup.sh

# SCRIPT_DIR setzen
SCRIPT_DIR="`dirname $0`"

# SCRIPT_DIR setzen
SCRIPT_NAME="`basename $0`"

# BASEDIR setzen
BASEDIR="`dirname $0`/.."

# Logfile
LOGFILE="${SCRIPT_NAME}.log"

# Hostname/Nodename holen
HOSTNAME=$(hostname)

# Script directory, eg. /this/is/your/app/bin
script_dir=`dirname $0`

# RSYNC default options
#  -a, --archive  archive mode; equals -rlptgoD (no -H,-A,-X)
RSYNC="`which rsync`"
RSYNC_DRYRUN='-n'
RSYNC_OPTS='--archive --verbose'
RSYNC_EXCLUDE="--exclude-from ~/mybackup.excludes"

# Set relative to script_dir
CONFDIR="../config"
LOGDIR="~"

# Load Backup Host configuration
function load_settings
{
	if [ -f "${1}/mybackup.config" ]
	then
		. ${1}/mybackup.config
	else
		echo; echo "  No Backup configuration file found! File: ${1}/mybackup.config"; echo
		exit 1
	fi
}

# Get/Show host configuration
function get_settings
{
	load_settings $1
	echo
	echo "   RSYNC Command:  ${RSYNC}"
	echo "      RSYNC Host:  ${RSYNC_HOST}"
	echo "      RSYNC User:  ${RSYNC_USER}"
	echo "   RSYNC Basedir:  ${RSYNC_BASE}"
	echo "   RSYNC Options:  ${RSYNC_OPTS}"
	echo
	echo "        Settings:  $1/mybackup.config"
	echo
}

function create_job
{
	echo "#!`which bash`"
	echo "# MyBackup JOB descriptor file (mybackup.job)"
	echo "# `uname -svm`"
	echo
	echo "# Backup Job Descriptor"
	echo "MYBACKUP_PROJECT=$USER"
	echo "MYBACKUP_CLIENT=$HOSTNAME"
	echo "MYBACKUP_SOURCE=\"$1\""
	echo "MYBACKUP_EXCLUDE=\"$1/mybackup.excludes\""
	echo
}

function create_settings
{
	# Load Default host configuration profile
	. ${CONFDIR}/default-mybackup.profile
	# Create settings and print it on stdout
	echo "#!`which bash`"
	echo "# File: mybackup.config"
	echo "# `uname -svm`"
	echo
	echo "# MyBackup 'rsync' settings"
	echo "RSYNC_HOST=$RSYNC_HOST"
	echo "RSYNC_USER=$RSYNC_USER"
	echo "RSYNC_PASSWORD=$RSYNC_PASSWORD"
	echo "RSYNC_BASE=\"$RSYNC_BASE\" "
	echo "RSYNC_ROPTS=\"$RSYNC_OPTS\" "
	echo
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
		echo; echo "  Missing Backup Job File in: $JOB "
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
	load_job $1
	echo
	echo "   Backup Project:   $MYBACKUP_PROJECT"
	echo "    Backup Client:   $MYBACKUP_CLIENT"
	echo "    Backup Source:   $MYBACKUP_SOURCE"
	echo "   Backup Exclude:   $MYBACKUP_EXCLUDE"
	echo
	echo "       Backup Job:   $1/mybackup.job"
	echo
	# echo "List exclude items:"
	# cat "$MYBACKUP_EXCLUDE"
	# echo
}

function test_all
{
	load_settings $1
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
		if [ "$2" == "settings" ]
		then
			get_settings $3
			exit 0
		fi
		echo; echo "  Available 'get' options: job|settings"; echo
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
		SOURCE_DIR=$2
		test_all $SOURCE_DIR
		if [ "$?" == "0" ]
		then
			load_settings $SOURCE_DIR
	 		load_job $SOURCE_DIR
			# TODO: Insert here RSYNC Backup
			CMD="$RSYNC $RSYNC_OPTS --exclude-from $MYBACKUP_EXCLUDE $SOURCE_DIR ${RSYNC_USER}@${RSYNC_HOST}:${RSYNC_BASE}/${MYBACKUP_PROJECT}/${MYBACKUP_CLIENT}"
			echo "[`date '+%Y-%m-%d %H:%M:%S'` - CMD] $CMD">>$SOURCE_DIR/mybackup.log
			$CMD
			echo "OK";
			exit 0;
		else
			echo "FAILURE";
			exit 10
		fi
		;;
	status)
		SOURCE_DIR=$2
		# Load backup job descriptor file if exists
		test_all $SOURCE_DIR
		if [ "$?" == "0" ]
		then
			load_settings $SOURCE_DIR
		 	load_job $SOURCE_DIR
			CMD="$RSYNC $RSYNC_DRYRUN $RSYNC_OPTS --exclude-from $MYBACKUP_EXCLUDE $SOURCE_DIR ${RSYNC_USER}@${RSYNC_HOST}:${RSYNC_BASE}/${MYBACKUP_PROJECT}/${MYBACKUP_CLIENT}"
			# echo "[`date '+%Y-%m-%d %H:%M:%S'` - CMD] $CMD">>$SOURCE_DIR/mybackup.log
			$CMD
			echo "OK";
			exit 0;
		else
			echo "FAILURE";
			exit 10
		fi
	 	;;
	host)
		get_settings $@
		exit 0
		;;
	create)
		if [ "$2" == "job" ]
		then
			create_job $3
			exit 0
		fi
		if [ "$2" == "settings" ]
		then
			create_settings $2
			exit 0
		fi
		echo; echo "  Available 'create' options: job|settings"; echo
		exit 1;
		;;
	test)
		# test call
		test_all $2
		if [ "$?" == "0" ]
		then
			echo "OK"
		else
			echo "FAILURE"
		fi
		;;
	usage|help|*)
		echo
		echo "  Usage: $SCRIPT_NAME create|get|help|log|push|status|test "
		echo
		echo "  Using: $RSYNC"
		echo
		exit 0
		;;
esac
