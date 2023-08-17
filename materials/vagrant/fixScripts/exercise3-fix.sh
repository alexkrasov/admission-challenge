#!/bin/bash
#add fix to exercise3 here
sudo sed -i 's/denied/granted/' /etc/apache2/sites-available/000-default.conf
sudo service apache2 reload

