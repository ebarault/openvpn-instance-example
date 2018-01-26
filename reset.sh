#!/bin/bash
# Helper script to wipe current, pull new sources and restart

docker rm -f $(docker ps -aq)
rm -rf clients_keys* openvpn
git pull
./start.sh
