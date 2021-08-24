#!/bin/sh
#-----------------------------------------------------------------------------
# Discover VirtualBox shared folders and mount them if it makes sense
#-----------------------------------------------------------------------------

if  !  type  VBoxControl  > /dev/null;  then
  echo  'VirtualBox Guest Additions NOT found'  > /dev/stderr
  exit 1
fi

MY_UID="$(id -u)"
MY_GID="$(id -g)"

( set -x;  sudo  VBoxControl  sharedfolder  list; )  |  \
grep      '^ *[0-9][0-9]* *- *'                      |  \
sed  -e 's/^ *[0-9][0-9]* *- *//'                    |  \
while  read  SHARED_FOLDER
do
  MOUNT_POINT="$HOME/$SHARED_FOLDER"
  if  [ -d "$MOUNT_POINT" ];  then
    MOUNTED="$(mount  |  grep  "$MOUNT_POINT")"
    if  [ "$MOUNTED" ];  then
      echo  "Already mounted :  $MOUNTED"
    else
      (
        set -x
        sudo  mount  -t vboxsf  -o "nosuid,uid=$MY_UID,gid=$MY_GID"  "$SHARED_FOLDER"  "$MOUNT_POINT"
      )
    fi
  fi
done