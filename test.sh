#!/bin/bash
# Helper script to test vpn

############
# DEFAULTS #
############
BASTION="bastion.lagrangenumerique.fr"
LOCAL_PORT=22222
USER=rgarrigue
IP=10.0.1.193
PROTOCOL=udp

#############
# FUNCTIONS #
#############
usage(){
  echo "Helper script to fetch .ovpn config from AWS EC2 instance and test it"
  echo
  echo "Usage: $0 -h"
  echo "Usage: $0 [-l LOCAL_PORT] [-b BASTION] [-p PROTOCOL] IP USER"
  echo
  echo "  IP:		VPN server private IP, something like '10.0.1.82'"
  echo "  USER:	        User for both bastion connection and VPN config to test"
  echo
  echo "  -h    Display this help"
  echo "  -l   	Local port for SSH tunnel to listen on, default to 22222"
  echo "  -b    Bastion, default to bastion.lagrangenumerique.fr"
  echo "  -p    Protocol TCP or UDP, default to UDP"
  echo
}

##############
# PARAMETERS #
##############
while getopts hep:r:b:u: opt; do
    case $opt in
        h)
            usage
            exit 0
            ;;
        l)  LOCAL_PORT=$OPTARG
            ;;
        b)  BASTION=$OPTARG
            ;;
        p)  PROTOCOL=$OPTARG
            ;;
       * )  usage >&2
            exit 1
            ;;
    esac
done
shift "$((OPTIND-1))"

if [ $# -lt 1 ]
then
  usage >&2
  exit 2
else
  IP="$1"
  shift 1
  COMMAND=" $*"
fi

########
# MAIN #
########
sudo apt install -y network-manager-openvpn-gnome network-manager-openvpn
kill -9 $(lsof -i:$LOCAL_PORT -t) &>/dev/null
ssh -4 -f -N -L $LOCAL_PORT:$IP:22 $USER@$BASTION
scp -r -P $LOCAL_PORT ec2-user@localhost:/data/*/clients_keys_* .
nmcli con del $USER
nmcli con import type openvpn file clients_keys_$PROTOCOL/$USER.ovpn
nmcli con up $USER
