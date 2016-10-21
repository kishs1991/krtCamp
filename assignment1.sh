#!/bin/bash
####################################################################
# This script is made for Ubuntu distribution and will install nginx, mysql-server , php and wordpress.
# More it will ask for new domain and make related configuration.
# Author - kishor shelke kishs1991@gmail.com
#
# this branch will use wpcli to install wordpress
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

# install wp cli

curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp
if [ $? -ne 0 ]
then
	echo "Failed to install wp-cli"
	exit 1
else
	echo -e "wp-cli installed successfully.\nAvailable at path /usr/local/bin/wp"
fi

# Ask user for domain name to point
echo "Enter domain name:"
read domainName
echo "Domain name = ${domainName}"
domainName1="www.${domainName}"

# take a backup and make entry in /etc/hosts
cp -p /etc/hosts /etc/hosts_"backup_$(date +%Y%m%d_%H%M%S)"
echo "127.0.0.1	${domainName}" >> /etc/hosts


# Create nginx config file for example.com
mkdir -p /var/www/${domainName}/html

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

# Create databse for wordpress
mysql -h localhost -u ${mysqlDBUser} -p${mysqlDBPassword} -e "CREATE DATABASE ${mysqlDBName};"

# use wpcli to install wordpress

chown -R www-data /var/www/${domainName}/html
cd /var/www/${domainName}/html
wp core download
wp core config --dbname=${mysqlDBName} --dbuser=${mysqlDBUser} --dbpass=${mysqlDBPassword} --dbhost=${domainName} --dbprefix=wp_
wp core install --url="http://${domainName}" --title="${domainName}" --admin_user="root" --admin_password="root@123" --admin_email="email@${domainName}"
chmod -R g+w /var/www/${domainName}/html

echo "All done"

# restart nginx service
service nginx restart

# Open web browser
#firefox $domainName &













