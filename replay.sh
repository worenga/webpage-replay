#! /bin/bash
# Replay script for mininet

if [ $# -ne 8 ]; then
  echo "Enter site to fetch, hostmapping file, network path of mirror, mininet config, phantomjs path, quic path, congestion control, browser"
  exit 5;
fi

# Exterminate old versions of Mininet
./clean_up_mn.sh

# Kill old residues
sudo killall -s9 /usr/bin/python
sudo killall -s9 quic_server
sudo killall -s9 Xvfb
sudo service dnsmasq stop
sudo killall -s9 dnsmasq
sudo service apache2 stop
sudo killall -s9 apache2

# Remove old log
sudo rm /var/dnsmasq.log

set -e
# cmdline args
site=$1
hostmapping=$2
mirror_folder_network_path=$3
server_ips=$4
phantomjs=$5
quic_path=$6
cc=$7
browser=$8
# Rewrite /etc/hosts
scp $hostmapping /etc/hosts
cp /etc/resolv.conf /etc/resolv.conf_orig
cp resolv.conf.tmpl /etc/resolv.conf
if [ $cc == "cubic" ]; then
  mirror_root_folder=`echo $site | cut -f 3 -d '/'`
  rm -rf /var/www/$mirror_root_folder
  scp -r $mirror_folder_network_path /var/www/$mirror_root_folder
  #modify apache root folder
  sed s/"DocumentRoot \/var\/www"/"DocumentRoot \/var\/www\/$mirror_root_folder"/g default.backup > /etc/apache2/sites-available/default
elif [ $cc == "quic" ]; then
  mirror_root_folder=`echo $site | cut -f 3 -d '/'`
  scp -r $mirror_folder_network_path $quic_path/$mirror_root_folder
else
  exit 5;
fi

# Run Mininet
scp $server_ips server_ips.txt
python web_mirror_replay.py $server_ips $site $phantomjs $quic_path $cc $browser

# Restore etc hosts
cp hosts_default /etc/hosts

# Restore apache default file
if [ $cc == "cubic" ]; then
  cp default.backup /etc/apache2/sites-available/default
fi

#Restore resolv.conf
mv /etc/resolv.conf_orig /etc/resolv.conf
