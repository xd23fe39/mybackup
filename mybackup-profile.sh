####################################################
# MYBACKUP Profile Script
####################################################

# set Path to mybackup-Directory
if [ -f "./bin/mybackup.sh" ]; then
  export MYBACKUP_HOME="`pwd`"
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
