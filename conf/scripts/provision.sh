#!/bin/bash

########################################################
#
# file: provision.sh
# This script will provision the VM.
#
########################################################

# main routine.
main() {
  sysinfo_go
  update_os_go
  selinux_go
  tools_go
  apache_go
  mysql_go
  php_go
  yum_clean_go
  complete_go
}

# print system info
sysinfo_go() {
  echo '===================================='
  echo 'System Info'
  echo '===================================='

  # print OS info
  cat /etc/*release
  # print network info
  ifconfig eth0 | grep inet | awk '{ print $2 }'

  echo '--'
}

# update the VM's OS
update_os_go() {
  echo '===================================='
  echo 'Update OS'
  echo '===================================='
  yum update
  echo '--'
  
}

# clean up after yum updates and installs
yum_clean_go() {
  yum clean all
  yum autoremove
  echo '--'
}

# set SELinux status
selinux_go() {
  echo '===================================='
  echo 'SELinux'
  echo '===================================='
  echo "Setting SELinux to disabled"
  echo ""
  setenforce 0
  sed -i 's/SELINUX=\(enforcing\|permissive\)/SELINUX=disabled/g' /etc/selinux/config
}

# Install any tools (from yum)
tools_go() {
  echo '===================================='
  echo 'Provision Tools'
  echo '===================================='

  if [[ "$(yum list --installed | grep curl.x86_64 | wc -l)" -eq 0 ]]; then
    sudo dnf install -y curl
  fi
  if [[ "$(yum list --installed | grep wget.x86_64 | wc -l)" -eq 0 ]]; then
    sudo dnf install -y wget
  fi
  if [[ "$(yum list --installed | grep git-core | wc -l)" -eq 0 ]]; then
    sudo dnf install -y git
  fi
  if [[ "$(yum list --installed | grep nano.x86_64 | wc -l)" -eq 0 ]]; then
    sudo dnf install -y nano
  fi
  if [[ "$(yum list --installed | grep zip.x86_64 | wc -l)" -eq 0 ]]; then
    sudo dnf install -y zip
  fi
  if [[ "$(yum list --installed | grep mod_ssl.x86_64 | wc -l)" -eq 0 ]]; then
    sudo dnf install -y mod_ssl
  fi
  echo '--'
}

# Install apache (httpd)
apache_go() {
  echo '===================================='
  echo 'Provision Apache'
  echo '===================================='

  if [[ "$(yum list --installed | grep httpd.x86_64 | wc -l)" -eq 0 ]]; then
    sudo dnf -y install httpd
  fi

  #Enable Apache
  sudo systemctl enable --now httpd.service
  echo ''
  sudo systemctl status httpd | grep 'Active:'
  
  httpd -v
  echo '--'
}

# Install MySQL.
# Perform mysql_secure_install tasks.
# Copy my.cnf if available.
mysql_go() {
  echo '===================================='
  echo 'Provision MySQL'
  echo '===================================='

  install_mysql
  copy_mycnf

  systemctl status mariadb
  echo '--'
}

# Install PHP and any php-related packages
# Configure PHP
php_go() {
  echo '===================================='
  echo 'Provision PHP'
  echo '===================================='

  install_php
  php_packages
  configure_php  
  install_xdebug
  install_composer
  php --version
  echo '--'
}

# print results of provision
complete_go() {
  echo ""
  echo "========================================="
  echo "Stack overview"
  echo "========================================="
  echo "OS:"
  cat /etc/*release | grep PRETTY
  echo "_________________________________________"
  echo "Network:"
  ifconfig eth0 | grep inet | awk '{ print $2 }'
  echo "_________________________________________"
  echo "Apache:"
  systemctl status httpd | grep 'Active:'
  httpd -v | grep version
  echo "_________________________________________"
  echo "MySQL:"
  systemctl status mariadb | grep 'Active:'
  systemctl status mariadb | head -n 1
  echo "_________________________________________"
  echo "PHP:"
  php -v | grep PHP | awk '{ print $1 $2 }' | head -1
  echo "_________________________________________"
  echo "Composer:"
  composer --version
  echo "_________________________________________"
  echo "Provisioning complete. Please visit"
  echo "http://localhost:[port]/ or access"
  echo "the VM with vagrant ssh"
  echo '========================================='
  echo ''

}

# MYSQL installation routine.
install_mysql() {
  echo "Installing mysql..."
  echo ''
  if [[ "$(yum list --installed | grep mariadb-server | wc -l)" -eq 0 ]]; then
    sudo dnf -y install mariadb mariadb-server
  fi
  sudo systemctl start mariadb.service
  sudo systemctl enable --now mariadb.service

  # Update database and users
  #TODO: can we check first to see if this was already done?
  echo "MySQL Root PW Change and Secure Install. Log into MySQL with root:root"
  sudo mysql -e "UPDATE mysql.user SET Password = PASSWORD('root') WHERE User = 'root'"
  sudo mysql -e "FLUSH PRIVILEGES"
  sudo systemctl restart mariadb.service
}

# Copy my.cnf if requested.
copy_mycnf() {
  echo 'Copying conf/mysql/my.cnf to /etc/my.cnf'
  echo ''
  mv /etc/my.cnf /etc/my_$(date +%F-%T).cnf.backup
  cp /home/vagrant/conf/mysql/my.cnf /etc/my.cnf
  sudo systemctl restart mariadb.service
}

# Install php.
install_php() {
  if [[ "$(yum list --installed | grep php-common | wc -l)" -eq 0 ]]; then
    #PHP 8 needs a different repository
    sudo dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
    sudo dnf -y install https://rpms.remirepo.net/enterprise/remi-release-8.rpm
    sudo dnf -y module reset php
    sudo dnf -y module enable php:remi-8.0
    sudo dnf -y install php
  fi
  sudo systemctl start php-fpm.service
  sudo systemctl enable --now php-fpm.service
}

# install required php packages.
php_packages() {
  #TODO: cleaner code would be a for loop going through all of them
  if [[ "$(yum list --installed | grep php-common | wc -l)" -eq 0 ]]; then
    sudo dnf install -y php-common
  fi
  if [[ "$(yum list --installed | grep php-opcache | wc -l)" -eq 0 ]]; then
    sudo dnf install -y php-opcache
  fi
  if [[ "$(yum list --installed | grep php-cli | wc -l)" -eq 0 ]]; then
    sudo dnf install -y php-cli
  fi
  if [[ "$(yum list --installed | grep php-gd | wc -l)" -eq 0 ]]; then
    sudo dnf install -y php-gd
  fi
  if [[ "$(yum list --installed | grep php-curl | wc -l)" -eq 0 ]]; then
    sudo dnf install -y php-curl
  fi
  if [[ "$(yum list --installed | grep php-pdo | wc -l)" -eq 0 ]]; then
    sudo dnf install -y php-pdo
  fi
  if [[ "$(yum list --installed | grep php-mbstring | wc -l)" -eq 0 ]]; then
    sudo dnf install -y php-mbstring
  fi
  if [[ "$(yum list --installed | grep php-zip | wc -l)" -eq 0 ]]; then
    sudo dnf install -y php-zip
  fi
  if [[ "$(yum list --installed | grep php-json | wc -l)" -eq 0 ]]; then
    sudo dnf install -y php-json
  fi
  if [[ "$(yum list --installed | grep php-xml | wc -l)" -eq 0 ]]; then
    sudo dnf install -y php-xml
  fi
  if [[ "$(yum list --installed | grep php-simplexml | wc -l)" -eq 0 ]]; then
    sudo dnf install -y php-simplexml
  fi
  if [[ "$(yum list --installed | grep php-mysqlnd | wc -l)" -eq 0 ]]; then
    sudo dnf install -y php-mysqlnd
  fi
  if [[ "$(yum list --installed | grep php-pecl-apcu | wc -l)" -eq 0 ]]; then
    sudo dnf install -y php-pecl-apcu
  fi
}

# configure php
configure_php() {
  #Newer version that provides a php.ini file rather than writing individual lines
  if [[ -f /home/vagrant/php/php.ini ]]; then
    cp /home/vagrant/php/php.ini /etc/php.ini
  fi
  if [[ -f /home/vagrant/php/www.conf ]]; then
    cp /home/vagrant/php/www.conf /etc/php-fpm.d
  fi

  sudo systemctl restart httpd.service
}

# Composer install routine
install_composer() {
  # Install latest version of Composer
  if [ ! -f "/usr/local/sbin/composer" ]; then
    cd /tmp
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    php composer-setup.php
    php -r "unlink('composer-setup.php');"
    sudo mv /tmp/composer.phar /usr/local/sbin/composer
  else
    composer self-update
  fi
  composer --version;
}

# install and configure xdebug
install_xdebug() {
  if [[ "$(yum list --installed | grep php-pecl-xdebug | wc -l)" -eq 0 ]]; then
    yum -y install php-pecl-xdebug
  fi
  if [ ! -f "/etc/php.d/xdebug.ini" ]; then 
    touch /etc/php.d/xdebug.ini
  fi
  #TODO: as with others above, this could be cleaned up using a for loop on an array
  if [ ! -z $(grep "xdebug.remote_enable = 1" /etc/php.d/xdebug.ini) ]; then
    echo "xdebug.remote_enable = 1" >> /etc/php.d/xdebug.ini
  fi
  if [ ! -z $(grep "xdebug.remote_connect_back = 1" /etc/php.d/xdebug.ini) ]; then
    echo "xdebug.remote_connect_back = 1" >> /etc/php.d/xdebug.ini
  fi
  if [ ! -z $(grep "xdebug.remote_port = 9000" /etc/php.d/xdebug.ini) ]; then
    echo "xdebug.remote_port = 9000" >> /etc/php.d/xdebug.ini
  fi
  if [ ! -z $(grep "xdebug.max_nesting_level = 512" /etc/php.d/xdebug.ini) ]; then
    echo "xdebug.max_nesting_level = 512" >> /etc/php.d/xdebug.ini
  fi
  if [ ! -z $(grep "xdebug.remote_autostart = true" /etc/php.d/xdebug.ini) ]; then
    echo "xdebug.remote_autostart = true" >> /etc/php.d/xdebug.ini
  fi
  if [ ! -z $(grep "xdebug.remote_host = 10.0.2.2" /etc/php.d/xdebug.ini) ]; then
    echo "xdebug.remote_host = 10.0.2.2" >> /etc/php.d/xdebug.ini
  fi
  if [ ! -f "/var/log/xdebug.log" ]; then 
    touch /var/log/xdebug.log
  fi
  if [ ! -z $(grep "xdebug.remote_log = /var/log/xdebug.log" /etc/php.d/xdebug.ini) ]; then
    echo "xdebug.remote_log = /var/log/xdebug.log" >> /etc/php.d/xdebug.ini
  fi
  sudo systemctl restart httpd.service
}

main

exit 0