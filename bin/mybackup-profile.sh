####################################################
# MYBACKUP Profile Script
####################################################

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

alias mybackup="$MYBACKUP_HOME/bin/mybackup.sh"

if [ -x "$MYBACKUP_HOME/bin/mybackup.sh" ]
then
  echo "MYBACKUP is ready on: $MYBACKUP_HOME."
else
  echo "MYBACKUP: Initialization failure!"
fi
echo
