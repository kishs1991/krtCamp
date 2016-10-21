#!/bin/bash
####################################################################
# This script is made for Ubuntu distribution and will install nginx, mysql-server , php and wordpress.
# More it will ask for new domain and make related configuration.
# Author - kishor shelke kishs1991@gmail.com
#
#
#
#
####################################################################

# check if system is Ubuntu
osDistribution=`lsb_release -si`
if [ ${osDistribution} != "Ubuntu" ]
then
	echo -e "The system is not Ubuntu.\nExiting the script ...."
	exit 1
fi

# declare the variables Variables
mysqlDBUser="root"
mysqlDBName="wordpressDB"
mysqlDBPassword=`echo $(echo $RANDOM | md5sum | cut -c1-6 | tr [:lower:] [:upper:])$(echo $RANDOM | md5sum | cut -c1-6 )`
domainName=""

# save mysql credentials to a file and secure the file
echo -e "mysqlDBUser=root\nmysqlDBName=wordpressDB\nmysqlDBPassword=$mysqlDBPassword" > ~/.mysqlcred.inf
chmod 500 ~/.mysqlcred.inf

# Check if packages nginx, mysql-server and php are installed
packages=( nginx mysql-server php-fpm php-mysql )
for package in "${packages[@]}"
do
	#echo $package
	echo "Checking if ${package} is installed"
	dpkg -l ${package}
	if [ $? -ne 0 ]
	then
		# check if the package is mysql and pass the password to installer
		if [ "${package}" = "mysql-server" ]
		then
			sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password ${mysqlDBPassword}"
			sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password ${mysqlDBPassword}"
			sudo apt-get -y install mysql-server
			echo "Credentials are stored in ${HOME}/.mysqlcred.inf. Secure the file and prefer removing once you remember it"
			continue
		fi
		echo "${package} is not installed.\nInstallling $package"
		apt-get -y install ${package}
	else
		echo "${package} is already installed"
		if [ "${package}" = "mysql-server" ]
		then
			echo "Enter mysql root password:"
			read mysqlDBPassword
		fi
	fi
done

# Ask user for domain name to point
echo "Enter domain name:"
read domainName
echo "Domain name = ${domainName}"
domainName1="www.${domainName}"

# take a backup and make entry in /etc/hosts
cp -p /etc/hosts /etc/hosts_"backup_$(date +%Y%m%d_%H%M%S)"
echo "127.0.0.1	${domainName}" >> /etc/hosts


# Create nginx config file for example.com
mkdir -p /var/www/$domainName/html
#cp /etc/nginx/sites-available/default /etc/nginx/sites-available/$domainName
#sed -i "s/root \/var\/www\/html/root \/var\/www\/$domainName\/html/g" /etc/nginx/sites-available/$domainName
#sed -i "s/server_name localhost/server_name $domainName $domainName1/g" /etc/nginx/sites-available/$domainName
#sed -i "s/index index.html/index index.php index.html/g" /etc/nginx/sites-available/$domainName
#sed -i "s/        #location ~ \.php$ {/        location ~ \.php$ {/g" /etc/nginx/sites-available/$domainName
#sed -i "s/                #include snippets/fastcgi-php.conf/                include snippets/fastcgi-php.conf/g" /etc/nginx/sites-available/$domainName
#sed -i "s/index index.html/index index.php index.html/g" /etc/nginx/sites-available/$domainName
#sed -i "s/index index.html/index index.php index.html/g" /etc/nginx/sites-available/$domainName

echo "server {
        listen 80 default_server;
        listen [::]:80 default_server;
        root /var/www/$domainName/html;
        index index.php index.html index.htm index.nginx-debian.html;
        server_name $domainName;
        location / {        	
                try_files $uri $uri/ =404;
        }
        location ~ \.php$ {
                include snippets/fastcgi-php.conf;
                fastcgi_pass unix:/run/php/php7.0-fpm.sock;
        }
        location ~ /\.ht {
                deny all;
        }
}" > /etc/nginx/sites-available/${domainName}

ln -s /etc/nginx/sites-available/${domainName} /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default

# Download WordPress latest version
wget https://wordpress.org/latest.tar.gz
tar -xzvf latest.tar.gz
cp -r ./wordpress/* /var/www/${domainName}/html/

# Change permission
sudo chown -R ${USER}:${USER} /var/www/${domainName}/html
chmod -R 755 /var/www
#

# Create databse for wordpress
mysql -h localhost -u ${mysqlDBUser} -p${mysqlDBPassword} -e "CREATE DATABASE ${mysqlDBName};"

# Create wp-config.php
cp /var/www/${domainName}/html/wp-config-sample.php /var/www/${domainName}/html/wp-config.php

sed -i "s/database_name_here/${mysqlDBName}/g" /var/www/${domainName}/html/wp-config.php
sed -i "s/username_here/${mysqlDBUser}/g" /var/www/${domainName}/html/wp-config.php
sed -i "s/password_here/${mysqlDBPassword}/g" /var/www/${domainName}/html/wp-config.php
sed -i "s/localhost/${domainName}/g" /var/www/${domainName}/html/wp-config.php

# Cleanup directories
rm -rf latest.tar.gz* wordpress/

echo "All done"

# restart nginx service
service nginx restart

# Open web browser
#firefox $domainName &













