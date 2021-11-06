#!/bin/bash

##############################################################
#
# file: d9.sh
# This script will configure the remaining pieces needed to create a copy of the example.org Drupal 9 website.
#
# The script expects these arguments:
# - Your Name: used in the git config
# - Your Email: used in the git config
# - Branch Name: the branch name to pull from GitLab  
#
# Example: /home/vagrant/scripts/d9.sh "RyanRobinson" "example@example.org" main
#
##############################################################

#Check for correct number of inputs
if (( $# != 3 ))
then
  echo "ERROR: Need to supply 3 arguments: your name, your email, and the branch name to pull from GitLab:"
  echo 'Example: /home/vagrant/scripts/d9.sh "RyanRobinson" "example@example.org" main'
  exit 1
fi

#Create self-signed certificate for https browsing
#The existing Apache conf for local.example.org references these keys
if [[ ! -d /etc/httpd/certs ]]
then
  sudo mkdir /etc/httpd/certs
fi
sudo openssl req -batch -newkey rsa:4096 -nodes -sha256 -keyout /etc/httpd/certs/local.example.org.key -x509 -days 3650 -out /etc/httpd/certs/local.example.org.crt -config /home/vagrant/openssl/openssl-config.txt
sudo firewall-cmd --add-service=http --permanent
sudo firewall-cmd --add-service=https --permanent
sudo firewall-cmd --reload


#Create filesystem and assign permissions
sudo mkdir -p /var/logs/local.example.org
sudo chown -R vagrant:vagrant /var/logs
sudo mkdir -p /opt/www/html/local.example.org/web
sudo mkdir -p /opt/www/html/local.example.org/backups
sudo chown -R vagrant:vagrant /opt/www/html

#Restart Apache to detect the changes
sudo systemctl restart httpd

#Navigate to the website folder
cd /opt/www/html/local.example.org

#Make the log files readable
#This resolves the error: Xdebug could not open the remote debug file '/var/log/xdebug.log'.
sudo chown vagrant:vagrant /opt/log/xdebug.log

#Move SSH key to correct location and set permissions
#This is needed to connect with GitLab
if [ -f /home/vagrant/ssh-sync/id_rsa ]
then
    cp /home/vagrant/ssh-sync/id_rsa /home/vagrant/.ssh/id_rsa
    chmod 700 /home/vagrant/.ssh/id_rsa
else
  echo "No SSH key found. The file must be named id_rsa and put in the conf/ssh folder. Exiting early."
  exit 1
fi

#Build codebase
cd /opt/www/html/local.example.org
git init
git remote add origin [git URL]
git config pull.rebase true
git config user.name $1
git config user.email $2
git pull origin $3

#Import database
#If there isn't a database provided, the script will finish but without a database imported
sudo cp /home/vagrant/backups/*.sql backups
sudo /home/vagrant/scripts/importdb.sh backups drupal

composer install
composer update

#Copy the Apache conf file
if [[ -f /home/vagrant/apache/example.org.conf ]]
then
  sudo cp /home/vagrant/apache/example.org.conf /etc/httpd/conf.d/local.example.org.conf
fi

sudo systemctl restart php-fpm
sudo systemctl restart apache

#Add drush location to PATH
echo 'export PATH="/opt/www/html/local.example.org/vendor/bin:$PATH"' >> /home/vagrant/.bashrc
source /home/vagrant/.bashrc

#Copy the Drupal files
if [[ -f /home/vagrant/drupal/settings.php ]]
then
  sudo cp /home/vagrant/drupal/settings.php web/sites/default/settings.php
fi
if [[ -f /home/vagrant/drupal/private.htaccess ]]
then
  sudo cp /home/vagrant/drupal/private.htaccess private/.htaccess
fi
if [[ ! -d sync/config ]]
then
  sudo mkdir -p sync/config
fi
if [[ ! -d sync/content ]]
then
  sudo mkdir -p sync/content
fi
drush cr #cache-rebuild