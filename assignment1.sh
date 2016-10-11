#!/bin/bash
# Check if packages nginx, mysql-server and php are installed

packages=( nginx mysql-server php )
for package in "${packages[@]}"
do
	#echo $package
	echo "Checking if $package is installed"
	dpkg -l $package
	if [ $? -ne 0 ]
	then
		echo "$package is not installed.\nInstallling $package"
		apt-get install $package
	else
		echo "$package is already installed"
	fi
done