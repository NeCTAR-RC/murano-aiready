#!/bin/bash -xe

USERNAME="$1"
ORIGUSER="ubuntu"

if [ "$USERNAME" != "$ORIGUSER" ]; then

  ORIGHOME=$(eval echo "~$ORIGUSER" )
  # Only if the user still exists and has their home directory, do the move
  # otherwise assume we've done it already
  if id $ORIGUSER && [ -d $ORIGHOME ]; then
    # Rename the user
    usermod --login $USERNAME $ORIGUSER

    if [ -d $MOUNT/$USERNAME ]; then
      # Set home dir to existing volume, and make 'users' the primary group
      usermod --home $MOUNT/$USERNAME --gid users --comment $USERNAME $USERNAME
      # Append cloud-init ssh key to authorized_keys file in existing home
      cat $ORIGHOME/.ssh/authorized_keys >> $MOUNT/$USERNAME/.ssh/authorized_keys
      # cloud-init home dir not needed so remove it
      rm -rf $ORIGHOME
    else
      # Set and move home dir to new location, and make 'users' the primary group
      usermod --home $MOUNT/$USERNAME --move-home --gid users --comment $USERNAME $USERNAME
    fi

    # Replace cloud user in cloud-init
    sed -i -e "s/name: $ORIGUSER/name: $USERNAME/g" -e "s/gecos: .*/gecos: $USERNAME/g" /etc/cloud/cloud.cfg
    sed -i "s/$ORIGUSER/$USERNAME/g" /etc/sudoers.d/90-cloud-init-users
  fi
fi

set +x
# Set password for user (and don't log it)
PASSWORD="$2"
echo "${USERNAME}:${PASSWORD}" | chpasswd

echo "Setup complete"
exit 0
