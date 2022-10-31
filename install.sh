#!/bin/bash
###
### Created by Nathan Wiens: https://github.com/nathanwiens
###
###

LOGFILE="/var/log/sdwanlog.txt"

#Check for root
if (( $EUID != 0 )); then
    echo "Please run as root"
    exit 1
fi

#Introduction
echo ""
echo "THIS SCRIPT ASSUMES YOU WILL USE WLAN0 FOR MANAGEMENT AND THAT WLAN0 IS ALREADY CONFIGURED"
echo "ETHERNET MANAGEMENT ACCESS TO THIS DEVICE WILL NOT BE POSSIBLE AFTER INSTALLATION"
echo ""
read -n 1 -s -r -p "Press any key to continue or Ctrl+C to exit..."

echo ""
read -r -p "First Ethernet interface (default: eth0)? " E0
if [ -z "$E0" ]; then E0="eth0"; fi
read -r -p "Second Ethernet interface (default: eth1)? " E1
if [ -z "$E1" ]; then E1="eth1"; fi

echo "auto br0
   iface br0 inet static
     bridge_ports $E0 $E1
     bridge_stp off
     address 1.1.1.1
     broadcast 1.1.1.3
     netmask 255.255.255.252" >> /etc/network/interfaces

#Install TC for WAN Emulation
echo ""
echo "INSTALLING TC AND BRIDGE-UTILS FOR WAN EMULATION..."
echo ""
apt-get update
apt-get install iproute2 bridge-utils -y

#Install HTTP server
echo ""
echo "INSTALLING HTTP SERVER..."
echo ""
apt-get install lighttpd -y

#Install web files
echo ""
echo "INSTALLING WEB FILES..."
echo ""
wget https://raw.githubusercontent.com/nathanwiens/cp-wanemulator/master/cp-wanemulator_files.tar.gz
FILE="./cp-wanemulator_files.tar.gz"
if [ -f $FILE ]; then
	tar -zxvf $FILE -C /var/www/html
	touch $LOGFILE
	chmod 777 $LOGFILE
else
	echo "File $FILE does not exist."
	echo "Check the GitHub repository link and try again."
	echo "Exiting..."
	exit 1
fi;

#Configure Bridge interface
echo ""
echo "RECONFIGURING NETWORK INTERFACES"
echo ""
#mv /var/www/html/interfaces /etc/network/
tc qdisc replace dev eth0 root pfifo_fast
tc qdisc replace dev eth1 root pfifo_fast

#Configure Permissions
echo ""
echo "SETTING PERMISSIONS"
echo "www-data        ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
echo ""

#Enable CGI
echo ""
echo "Enabling CGI"
lighty-enable-mod cgi
mv /var/www/html/cgi-bin/exectc /usr/lib/cgi-bin/
chown www-data:www-data /usr/lib/cgi-bin/exectc
chmod +x /usr/lib/cgi-bin/exectc
rm -r /var/www/html/cgi-bin
ln -s /usr/lib/cgi-bin /var/www/html/
echo ""

#Restart HTTP Server
echo ""
echo "RESTARTING HTTP SERVER..."
mv /var/www/html/lighttpd.conf /etc/lighttpd/lighttpd.conf
service lighttpd restart
echo ""

#Install cron script for automatic adjustments
echo ""
echo "AUTOMATIC PERFORMANCE ADJUSTMENTS"
echo "ENABLING THIS WILL SWITCH BETWEEN GOOD AND BAD PERFORMANCE AT REGULAR TIME INTERVALS"
echo ""
while true; do
    read -r -p "Would you like automatic performance adjustments? " yn

	if  [ "$yn" == "Y" ] || [ "$yn" == "y" ] || [ "$yn" == "Yes" ] || [ "$yn" == "yes" ] || [ "$yn" == "YES" ]; then
	  while true; do
		  read -r -p "How long should each interval be (in minutes) (2-30)? " interval
		  if ! [[ "$interval" =~ ^[0-9]+$ ]]; then
            echo "Sorry integers only"
		  elif [ "$interval" == "" ]; then
			echo "Please specify an interval."
		  elif [ "$interval" -lt 1 ] || [ "$interval" -gt 30 ]; then
		    echo "Interval is $interval."
			echo "Please specify an interval between 2 and 30."
		  else
			echo "Interval is $interval."
			echo "Adding cron scripts."
			#Delete old cron jobs
			crontab -l | sed '/sdwanlog.txt/d' | crontab -
			#Add new cron jobs
			GOOD="$interval"
			BAD="$[interval/2]"
			crontab -l | { cat; echo "*/$GOOD * * * * bash /var/www/html/cron/perf-good.sh >> /var/www/sdwanlog.txt"; } | crontab -
			crontab -l | { cat; echo "*/$BAD * * * * bash /var/www/html/cron/perf-bad.sh >> /var/www/sdwanlog.txt"; } | crontab -
			sed -i "s/eth0/$E0/g" /var/www/html/cron/perf-good.sh
			sed -i "s/eth0/$E1/g" /var/www/html/cron/perf-good.sh
			sed -i "s/eth0/$E0/g" /var/www/html/cron/perf-bad.sh
			sed -i "s/eth0/$E1/g" /var/www/html/cron/perf-bad.sh
			break
		  fi
	  done
	  break
	elif [ "$yn" == "N" ] || [ "$yn" == "n" ] || [ "$yn" == "No" ] || [ "$yn" == "no" ] || [ "$yn" == "NO" ]; then
	  echo "Skipping..."
	  break
	else
	  echo "Please answer yes or no."
	fi
done

#Installation Complete
echo ""
echo "INSTALLATION COMPLETE."
echo "Please reboot to finish the bridge configuration."
echo "Visit this IP address in a web browser to continue."
echo ""