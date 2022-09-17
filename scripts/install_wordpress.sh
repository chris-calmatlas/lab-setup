#base install instructions here: https://linuxways.net/red-hat/how-to-install-wordpress-on-rocky-linux-8/
#but these are incomplete for a fresh install of rocky and we'll be using rocky 9 so there will be some differences.

#First update packages
sudo dnf update -y

#The instructions tell you to "reset the default php 7.2" without describing why or what that is. The default appstream repo on a fresh install of rocky 8 will have php 7.2. At the time of this writing, the latest supported version is 8.

#If we needed the latest and greatest we'd install the remi repo here.

#Rocky 9 already has php 8 so let's just install from the appstream repo
sudo dnf install php php-cli php-json php-gd php-mbstring php-pdo php-xml php-mysqlnd php-pecl-zip -y

#install mariadb
sudo dnf install mariadb-server -y

#start and enable the mariadb
sudo systemctl enable --now mariadb

#improve the security of the mariadb installation
sudo mysql_secure_installation

#
