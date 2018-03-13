#!/usr/bin/env /bin/bash
#
# REV.18.0313
# Umgebung initialisieren

# Aktuelles Verzeichnis merken, z.B. /a/b/c/mybackup/bin
cur_dir=$(pwd)

# set Path to mybackup-Directory
if [ -f "./mybackup.sh" ]; then
  export MYBACKUP_HOME=${cur_dir%%/bin}    # entferne /bin aus Pfad
elif [ -x "~/mybackup/bin/mybackup.sh" ]; then
  export MYBACKUP_HOME="~/mybackup"
fi

# PATH
export PATH="$PATH:$MYBACKUP_HOME/bin"

# Alias
alias mybackup="$MYBACKUP_HOME/bin/mybackup.sh"
alias clone-backup="$MYBACKUP_HOME/bin/clone-backup.sh"

# Ausgabe
if [ -x "$MYBACKUP_HOME/bin/mybackup.sh" ]
then
  echo "MYBACKUP is ready on: $MYBACKUP_HOME."
else
  echo "MYBACKUP: Initialization failure!"
fi
echo
