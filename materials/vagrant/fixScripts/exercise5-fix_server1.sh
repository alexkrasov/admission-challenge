#!/bin/bash

current_server="server1"
other_server="server2"

#add fix to exercise5-$current_server here

#Got to do it again as it weren't propagated from exercise4-fix for some reason
echo "192.168.60.11 $other_server" | sudo tee -a /etc/hosts
sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

#Disable strict host key checking as required
sudo sed -i 's/#   StrictHostKeyChecking ask/StrictHostKeyChecking no/g' /etc/ssh/ssh_config
sudo service ssh restart

#Update and install sshpass to auto-provide password non-interactively
sudo apt-get update
sudo apt-get install -y sshpass

#SSH key gen for vagrant user (don't overwrite)
echo -e 'n\n' | ssh-keygen -t rsa -f /home/vagrant/.ssh/id_rsa -N "" -C "vagrant@$current_server"
sudo chown vagrant:vagrant /home/vagrant/.ssh/id_rsa**
#SSH key gen for root (don't overwrite)
echo -e 'n\n' | sudo ssh-keygen -t rsa -f /root/.ssh/id_rsa -N ""

if ping -c 1 -W 1 "$other_server" >> /dev/null; then
  #Add root@$current_server to authorized keys of vagrant@$other_server
  sshpass -p vagrant ssh-copy-id -o StrictHostKeyChecking=no vagrant@$other_server
  #Add vagrant@$current_server to authorized keys of vagrant@$other_server
  eval "ssh vagrant@$other_server 'echo $(cat /home/vagrant/.ssh/id_rsa.pub) | sudo tee -a /home/vagrant/.ssh/authorized_keys'"
  #Add root@$current_server to authorized keys of root@$other_server
  eval "ssh vagrant@$other_server 'echo $(sudo cat /root/.ssh/id_rsa.pub) | sudo tee -a /root/.ssh/authorized_keys'"
  #Workaround for concurrency issue with the second server still down while first one starts
  if [ $# -eq 0 ] || [ "$1" != "propagateKeys" ]; then	
	#Check if you can access the other server by key
	if eval "ssh -o PasswordAuthentication=no -o BatchMode=yes $other_server exit &>/dev/null"; then
		#Check if other server can access this server by key
		if eval "ssh  -o PasswordAuthentication=no -o BatchMode=yes vagrant@$other_server 'ssh -o PasswordAuthentication=no -o BatchMode=yes $current_server exit'"; then
			echo "$other_server is able to auth by key with $current_server"
		else
			#If not - execute the script again on other server to handle keys propogation to current server
			echo "$other_server is accessible but unable to auth by key with $current_server, fixing..."
			eval "ssh vagrant@$other_server 'sudo /vagrant/fixScripts/exercise5-fix_$other_server.sh propagateKeys'"
		fi
	else
		echo "unable to connect to $other_server..."
	fi
  fi
  
else
  echo "$other_server is unavailable, public keys were not added..."
fi
