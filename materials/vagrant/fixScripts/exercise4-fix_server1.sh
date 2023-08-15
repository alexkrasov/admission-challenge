#!/bin/bash

#add fix to exercise4-server1 here
echo "192.168.60.11 server2" | sudo tee -a /etc/hosts
sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo service ssh restart
