#!/bin/bash

current_server="server2"
other_server="server1"
other_server_ip="192.168.60.10"

function update_hosts_and_ssh_config {
  echo "$other_server_ip $other_server" | sudo tee -a /etc/hosts
  sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
  sudo sed -i 's/#   StrictHostKeyChecking ask/StrictHostKeyChecking no/g' /etc/ssh/ssh_config
  sudo service ssh restart
}

function install_sshpass {
  sudo apt-get update
  sudo apt-get install -y sshpass
}

function generate_ssh_keys {
  echo -e 'n\n' | ssh-keygen -t rsa -f /home/vagrant/.ssh/id_rsa -N "" -C "vagrant@$current_server"
  sudo chown vagrant:vagrant /home/vagrant/.ssh/id_rsa**
  echo -e 'n\n' | sudo ssh-keygen -t rsa -f /root/.ssh/id_rsa -N ""
}

function add_authorized_keys {
  if ping -c 1 -W 1 "$other_server" >> /dev/null; then
    sshpass -p vagrant ssh-copy-id -o StrictHostKeyChecking=no vagrant@$other_server
    eval "ssh vagrant@$other_server 'echo $(cat /home/vagrant/.ssh/id_rsa.pub) | sudo tee -a /home/vagrant/.ssh/authorized_keys'"
    eval "ssh vagrant@$other_server 'echo $(sudo cat /root/.ssh/id_rsa.pub) | sudo tee -a /root/.ssh/authorized_keys'"
  else
    echo "$other_server is unavailable, public keys were not added..."
    return
  fi
}

function fix_concurrency_issue {
  if [ $# -eq 0 ] || [ "$1" != "propagateKeys" ]; then	
    if eval "ssh -o PasswordAuthentication=no -o BatchMode=yes $other_server exit &>/dev/null"; then
      if eval "ssh  -o PasswordAuthentication=no -o BatchMode=yes vagrant@$other_server 'ssh -o PasswordAuthentication=no -o BatchMode=yes $current_server exit'"; then
        echo "$other_server is able to auth by key with $current_server"
      else
        echo "$other_server is accessible but unable to auth by key with $current_server, fixing..."
        eval "ssh vagrant@$other_server 'sudo /vagrant/fixScripts/exercise5-fix_$other_server.sh propagateKeys'"
      fi
    else
      echo "unable to connect to $other_server..."
    fi
  fi
}

# Main script execution

#add fix to exercise5-$current_server here
update_hosts_and_ssh_config
install_sshpass
generate_ssh_keys
add_authorized_keys
fix_concurrency_issue $@