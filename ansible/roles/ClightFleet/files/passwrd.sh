#!/usr/bin/bash

#  if id does not exist
#    create admin user
#    write id file
#    capture password
#    break
#  else 
#    reset admin password
#    write new id file
#    capture password
#    break
#
#  delete temp files
#  Use password with corelight client to set password to $1

if [ -e /etc/corelight-ID ]
then
  sudo -u corelight-fleetd /usr/bin/corelight-fleetd -c /etc/corelight-fleetd.conf reset-password admin > out.txt
  cat out.txt | grep ID|cut -f 2 -d":" | sed 's/^[ \t]*//' > /etc/corelight-ID
  PASSWD=$(cat out.txt | grep Password|cut -f 2 -d":" | sed 's/^[ \t]*//')
else
  sudo -u corelight-fleetd /usr/bin/corelight-fleetd -c /etc/corelight-fleetd.conf create-user -a admin > out.txt
  cat out.txt | grep ID|cut -f 2 -d":" | sed 's/^[ \t]*//' > /etc/corelight-ID
  PASSWD=$(cat out.txt | grep Password|cut -f 2 -d":" | sed 's/^[ \t]*//')
fi

rm out.txt
echo $PASSWD


