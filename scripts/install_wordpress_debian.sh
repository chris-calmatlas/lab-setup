#This scripts get's a wordpress site up and running with valid ssl certs at he given FQDN. 

#Incomplete instructions and inspiration found here: https://linuxways.net/red-hat/how-to-install-wordpress-on-rocky-linux-8/
#This script adapted from Rocky 9 GCP Optimized (Google Cloud Compute e2 medium instance) to Debian 11 bullseye (Google Cloud COmpute e2 medium instance)

#variables
SERVER_FQDN="blog.calmatlas.com"
#email address needed for letsencrypt, if you comment the last part of this
#script, then you can also leave this variable blank
EMAIL=chris@calmatlas.com

#First update packages
sudo apt update -y sudo apt upgrade -y

#The repos included in this image of Debian include php 7.4
sudo apt install php php-cli php-json php-gd php-mbstring php-xml -y

#Install the webserver
sudo apt install apache2 -y

#install mariadb
sudo apt install mariadb-server -y

#start and enable the mariadb
sudo systemctl enable --now mariadb

#Create a databsae
sudo mysql --user="root" --execute "CREATE DATABASE wordpressdb"

#We're going to use a random password for the wordpress user for this script
wp_db_user_pass=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32};echo;)

#Create the user
sudo mysql --user="root" --database="wordpressdb" --execute="CREATE USER 'wp_user'@'localhost' IDENTIFIED BY '$wp_db_user_pass'"

#Grant the user privileges
sudo mysql --user="root" --database="wordpressdb" --execute="GRANT ALL ON wordpressdb.* TO 'wp_user'@'localhost'"
sudo mysql --user="root" --database="wordpressdb" --execute="FLUSH PRIVILEGES"

#We should improve the security of the mariadb installation, the following command promps the user
#sudo mysql_secure_installation

#Do the above command  without prompting.
#Save the password to a file
sudo sh -c 'wp_db_root_pass=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32});
cat > /root/wp_root.pass << EOF
[client]
user=root
password=$wp_db_root_pass
EOF'
sudo chmod 400 /root/wp_root.pass

sudo mysql --user="root" --execute="DELETE FROM mysql.user WHERE User=''"
sudo mysql --user="root" --execute="DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
sudo mysql --user="root" --execute="DROP DATABASE IF EXISTS test"
sudo mysql --user="root" --execute="DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'"
sudo mysql --user="root" --execute="ALTER USER 'root'@'localhost' IDENTIFIED BY '$wp_db_root_pass'"
sudo mysql --user="root" --password="$wp_db_root_pass" --execute="FLUSH PRIVILEGES"

#Download the latest worpdress
curl https://wordpress.org/latest.tar.gz --output wordpress.tar.gz

#Extract the wordpress files to apache directory
sudo tar -xf wordpress.tar.gz -C /var/www/html

#give apapche ownership to wordpress
sudo chown -R apache:apache /var/www/html/wordpress

#set permissions to wordpress
sudo chmod -R 775 /var/www/html/wordpress

#Create an apache virtual host file to point to the wordpress install
cat > ./wordpress.conf << EOF
<VirtualHost *:80>
  ServerName $SERVER_FQDN
  Redirect permanent / https://$SERVER_FQDN/
</VirtualHost>

<VirtualHost *:443>
  ServerName $SERVER_FQDN

  ServerAdmin root@localhost
  DocumentRoot /var/www/html/wordpress
  ErrorLog /var/log/httpd/wordpress_error.log
  CustomLog /var/log/httpd/wordpress_access.log common

  <Directory "/var/www/html/wordpress">
    Options Indexes FollowSymLinks
    AllowOverride all
    Require all granted
  </Directory>

</VirtualHost>
EOF

#Move the file we just created and give it the appropriate permissions
sudo chown root:root ./wordpress.conf
sudo mv ./wordpress.conf /etc/apache2/sites-available
sudo a2ensite $SERVER_FQDN

#we have a working webserver at this point point but can't login to wordpress admin because of cert errors
#Let's use letsencrypt to get some valid certs.

#next let's install the letsencrypt stuff
sudo apt install certbot python3-certbot-apache -y

#retrieve and install the first cert.
sudo certbot --apache --non-interactive --agree-tos -m $EMAIL --domain $SERVER_FQDN

#give username and password
echo ""
echo "Navigate to your site in a browser and use the following information"
echo "Wordpress User: wp_user"
echo "Password: $wp_db_user_pass"
echo ""
echo "Copy this info. You won't see it again."
