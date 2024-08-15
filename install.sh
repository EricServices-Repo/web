#!/usr/bin/env bash
#EricServic.es Web Server Install
#
#################
# Define Colors #
#################
RED="\e[31m"
GREEN="\e[32m"
BLUE="\e[34m"
ENDCOLOR="\e[0m"


echo -e "${GREEN}EricServic.es Email Server Build${ENDCOLOR}"

echo -e "${BLUE} ______      _       _____                 _                    ${ENDCOLOR}"  
echo -e "${BLUE}|  ____|    (_)     / ____|               (_)                   ${ENDCOLOR}"
echo -e "${BLUE}| |__   _ __ _  ___| (___   ___ _ ____   ___  ___   ___  ___    ${ENDCOLOR}"
echo -e "${BLUE}|  __| | '__| |/ __|\___ \ / _ \ '__\ \ / / |/ __| / _ \/ __|   ${ENDCOLOR}"
echo -e "${BLUE}| |____| |  | | (__ ____) |  __/ |   \ V /| | (__ |  __/\__ \   ${ENDCOLOR}"
echo -e "${BLUE}|______|_|  |_|\___|_____/ \___|_|    \_/ |_|\___(_)___||___/ \n${ENDCOLOR}"

################################
# Updates + Install + Firewall #
################################
echo -e "${GREEN}Process updates and install${ENDCOLOR}"
sleep 1

echo -e "Yum Update"
yum update -y

echo -e "Install epel-release"
yum install epel-release -y

echo -e "${GREEN}Check to see if required programs are installed.\n${ENDCOLOR}"
yum install firewalld certbot python3-certbot-nginx rsyslog nginx mariadb mariadb-server -y 

echo -e "${GREEN}Update Remi PHP and install PHP 8.2\n${ENDCOLOR}"
dnf -y install http://rpms.remirepo.net/enterprise/remi-release-8.rpm
dnf module reset php -y
dnf module install php:remi-8.2 -y
dnf -y install php php-fpm php-mbstring php-mysqlnd php-gd php-opcache php-json php-curl php-zip php-xml php-bz2 php-intl php-gmp php-pdo php-pdo_mysql
php -v

echo -e "${GREEN}Turning on the Firewall\n${ENDCOLOR}"
systemctl enable firewalld
systemctl restart firewalld

echo -e "${GREEN}Allow Ports for Email Server on Firewall\n${ENDCOLOR}"
firewall-cmd --permanent --add-port={80/tcp,443/tcp}

echo -e "${GREEN}Reload the firewall.\n${ENDCOLOR}"
firewall-cmd --reload

echo -e "${GREEN}Ports allowed on firewall.\n${ENDCOLOR}"
firewall-cmd --list-all

###################
# Permissive Mode #
###################
echo -e "${GREEN}Setting to Permissive Mode for install\n${ENDCOLOR}"
setenforce 0

echo -e "${GREEN}Setting Permissive SELINUX value.\n${ENDCOLOR}"
sed -i 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config

###################
# MySQL Databases #
###################
echo -e "${GREEN}Enable and start mysql\n${ENDCOLOR}"
systemctl enable mariadb
systemctl restart mariadb


##############################
#  MySQL Secure Installation #
##############################

echo -e "${GREEN}Configure mysql secure installation\n${ENDCOLOR}"
# Make sure that NOBODY can access the server without a password
mysql -e "UPDATE mysql.user SET Password = PASSWORD('$SQLPASSWORD') WHERE User = 'root'"
# Kill the anonymous users
mysql -e "DROP USER ''@'localhost'" 
#^ This one fails on fresh install

# Because our hostname varies we'll use some Bash magic here.
mysql -e "DROP USER ''@'$(hostname)'"
#^ This one fails on fresh install

# Kill off the demo database
mysql -e "DROP DATABASE test"
#^ This one fails on fresh install

# Make our changes take effect
mysql -e "FLUSH PRIVILEGES"
# Any subsequent tries to run queries this way will get access denied because lack of usr/pwd

