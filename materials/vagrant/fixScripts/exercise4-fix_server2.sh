#!/bin/bash

#add fix to exercise4-server2 here
echo "192.168.60.10 server1" | sudo tee -a /etc/hosts
sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo service ssh restart
