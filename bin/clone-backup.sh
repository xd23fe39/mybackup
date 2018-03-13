#!/usr/bin/env /bin/bash
#
# REV.18.0313
# Kopiere/Klone Backup auf weiteres Zielmedium

# Quellverzeichnis ohne Schrägstrich am Ende angeben
SOURCE_DIR=user@hostname:/mnt/vol1/users

# Zielverzeichnis
TARGET_DIR=/media/user/mountName/optional/path

# Default options for rsync (n = Simulation/try run)
RSYNC_OPTS="-n --archive --verbose"

# Konfigurationsdatei
CONFIG="${MYBACKUP_HOME}/etc/clone-backup.conf"

# Überschreiben der Default-Einstellungen per Konfigurationsdatei
if [ -f "$CONFIG" ]
then
	. ./${CONFIG}
else
	echo "  No configuration file available!"
	echo
	exit 2
fi

# Auswerten der Kommandozeilenargumente, wie z.B. $1 = Operation
if [ "$1" == "push" ]
then
	# Ausführen der Datensicherung
	RSYNC_OPTS="--archive --verbose"
else
	# zur Sicherheit nur ein try run (Simulation)
	RSYNC_OPTS="-n --archive --verbose"
	echo
	echo "Use 'push' for start the real backup procedure!"
	echo
	echo "  Usage: ./clone-backup push "
	echo
fi

# Datensicherung gem. der aktuellen Konfiguration ausführen
if [ -d "$TARGET_DIR" ]
then
	/usr/bin/rsync $RSYNC_OPTS $SOURCE_DIR $TARGET_DIR
	exit $?
else
	echo
	echo "FREENAS: Backup Directory not available: $TARGET_DIR"
	echo
	echo "   Source: $SOURCE_DIR"
	exit 1
fi

# Fehlercode 9 - unbekannter Fehler
exit 9
