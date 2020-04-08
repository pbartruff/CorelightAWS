#!/bin/sh
###############################################################################
# NAME
#     connconf.sh - Create a local ssh.conf and an "all" file for the
#                   group_vars folder in an ansible directory structure.
#
# SYNOPSIS
#
#     connconf.sh [-hvV] [-s | -g] <-k /path/to/SSH-KEY> <-u USERNAME> BASTION-HOSTNAME 
#
# DESCRIPTION
#
#     This script creates a custom ssh.conf file and/or an Ansible group_vars
#     file.  By default the script will create both files unless specified on
#     the command line.
#
# OPTIONS
#     usage: connconf.sh [-hvV] [-s | -g] <-k /path/to/SSH-KEY> <-u USERNAME> BASTION-HOSTNAME 
#
#     Optional Options:
#       -g    Only create global_vars file for Ansible
#       -h    Show this help message and exit
#       -s    Only create ssh.conf file
#       -v    Print Version String and exit
#       -V    Set Verbose mode
#
#     Required Options:
#       -k    Path and key file used for the ssh connection
#       -u    User name for the ssh connection
#
#     Required arguments:
#       Bastion Hostname that ssh will connect through
#
# EXAMPLES
#
#     $> connconf.sh -V -k mykey.pem -u ec2-user awsbastion.com
#
#     $> connconf.sh -g -k mykey.pem -u ec2-user awsbastion.com
#
# EXIT STATUS
#
#     List exit codes
#     -1    Failure
#      0    Success
#
# AUTHOR
#
#     Name <paul@corelight.com>
#
# LICENSE
#
#     Copyright (c) 2020, Paul Bartruff
#     All rights reserved.
#
#     Redistribution and use in source and binary forms, with or without
#     modification, are permitted provided that the following conditions are met:
#
#     1. Redistributions of source code must retain the above copyright notice, this
#        list of conditions and the following disclaimer.
#
#     2. Redistributions in binary form must reproduce the above copyright notice,
#        this list of conditions and the following disclaimer in the documentation
#        and/or other materials provided with the distribution.
#
#     3. Neither the name of the copyright holder nor the names of its
#        contributors may be used to endorse or promote products derived from
#        this software without specific prior written permission.
#
#     THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#     AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#     IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#     DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
#     FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
#     DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
#     SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
#     CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
#     OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
#     OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# VERSION
#     V1.0
#     
###############################################################################
VERSION="V1.0"
USAGE="Usage: $0 [-hvV] [-s | -g] <-k /path/to/SSH-KEY> <-u USERNAME> BASTION-HOSTNAME"

# Program Variables
VERBOSE=0
GROUP=1
SSH=1
KEY=corelight-demo
USER=ec2-user
BAST=

# FIXME Add a check here for less and if it exists pipe head -n 68 to less
printHelp () {
  if [ $(which less) ]; then
    head -n 64 $1 | less
    exit 1
  else
    head -n 46 $1
    exit 1
  fi
}

printVersion () {
  echo $VERSION
  exit 1
}

mk_ssh () {
cat << EOF > ssh.cfg
Host 10.0.*
IdentityFile %d/corelight-demo
  ProxyCommand ssh -i ${KEY} -W %h:%p ${USER}@${BAST}

Host ${BAST}
  Hostname ${BAST}
  User ${USER}
  IdentityFile ${KEY}
  ControlMaster auto
  ControlPath ~/.ssh/ansible-%r@%h:%p
  ControlPersist 5m
EOF
}

mk_groupvar() {
cat << EOF > ./group_vars/all
ansible_ssh_common_args: '-i ${KEY} -o ProxyCommand="ssh -C -W %h:%p -q -i ${KEY} ${USER}@${BAST}"'
EOF
}

# FIXME Add verbosity code through out script if VERBOSE is set
main(){
  BAST=$1
  mk_ssh
  mk_groupvar
# echo $VERBOSE
# echo $GROUP
# echo $SSH
# echo $KEY
# echo $USER
# echo $BAST
}


while getopts ":hgk:su:vV" OPT; do
  case $OPT in
    g  ) SSH=0 ;;
    h  ) printHelp $0 ;;
    k  ) KEY=$OPTARG ;;
    s  ) GROUP=0 ;;
    u  ) USER=$OPTARG ;;
    v  ) printVersion ;;
    V  ) VERBOSE=1 ;;
    /? ) echo $USAGE
         exit 1 ;;
  esac
done

shift $(($OPTIND -1))

if [ -z "$@" ]; then
  echo $USAGE
  echo "A Bastion Hostname is required"
  exit 1
fi

main $1

################################################################################
