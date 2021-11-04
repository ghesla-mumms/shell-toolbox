#!/bin/bash

echo
echo '###'
echo 'Priming the sudo pump...'
echo '###'
sudo -v
echo

echo '###'
echo "Unloading existing port forwarding config..."
echo '###'
sudo pfctl -d
echo

if [[ ! -f /etc/pf.conf ]]; then
	echo "Port forwarding config file not found, making it now..."
	sudo touch /etc/pf.conf
else
	echo '###'
	echo 'Backing up current port farwarding config file...'
	echo '###'
	sudo mv /etc/pf.conf /etc/pf.conf.`date +%Y%m%d-%H%M%S`
fi
echo

echo '###'
echo 'Building new port forwarding config file...'
echo '###'
if [[ -f /etc/pf.anchors/dev-local-hbc ]]; then
	sudo rm /etc/pf.anchors/dev-local-hbc
fi
echo 'rdr-anchor "dev-local-hbc"' | sudo tee -a /etc/pf.conf
echo 'anchor "dev-local-hbc"' | sudo tee -a /etc/pf.conf
echo 'load anchor "dev-local-hbc" from "/etc/pf.anchors/dev-local-hbc"' | sudo tee -a /etc/pf.conf
echo 'rdr pass log (all) on lo0 inet proto tcp from any to any port 80 -> 127.0.0.1 port 8080' | sudo tee -a /etc/pf.anchors/dev-local-hbc
echo 'rdr pass log (all) on lo0 inet proto tcp from any to any port 443 -> 127.0.0.1 port 8443' | sudo tee -a /etc/pf.anchors/dev-local-hbc
echo

echo '###'
echo 'Verifying and loading new port fowarding configs...'
echo '###'
sudo pfctl -vnf /etc/pf.anchors/dev-local-hbc
sudo pfctl -evf /etc/pf.conf
echo
