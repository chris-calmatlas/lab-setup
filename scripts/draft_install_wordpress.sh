#This scripts get's a wordpress site up and running with valid ssl certs at he given FQDN. 
#Some admin screen report config errors and plugin installs don't work.

#Incomplete instructions and inspiration found here: https://linuxways.net/red-hat/how-to-install-wordpress-on-rocky-linux-8/
#This script orginally written and tested on Rocky 9 GCP Optimized (Google Cloud Compute e2 medium instance)
#Additionally tested and modifed to work with Rocky 8 GCP Optimzed (Google Cloud Compute e2 medium instance)

#variables
SITENAME="blog"
FQDN="$SITENAME.calmatlas.com"
#email address needed for letsencrypt, if you comment the last part of this
#script, then you can also leave this variable blank
EMAIL=chris@calmatlas.com
WP_USER=wp_$SITENAME

#First update packages
sudo dnf update -y

#The instructions from linuxways.net tell you to "reset the default php 7.2" without describing why or what that is. 
#The default appstream repo on a fresh install of rocky 8 will have php 7.2. At the time of this writing, the latest supported version is 8.
#If we needed the latest and greatest we'd install the remi repo here. As of this writing Rocky 9 defaults to PHP 8, while Rocky 8 defaults to PHP 7.2
#TODO - Check for current version and get it.

#Rocky 9 already has php 8 so let's just install from the appstream repo
sudo dnf install php php-cli php-json php-gd php-mbstring php-pdo php-xml php-mysqlnd php-pecl-zip -y

#Rocky 9 came with apache installed by default. Let's run it anyway
sudo dnf install httpd -y

#install mariadb
sudo dnf install mariadb-server -y

#start and enable the mariadb
sudo systemctl enable --now mariadb

#Remove the mysql root password first if it exists
sudo mysql --defaults-file=/root/wp_root.pass --execute="ALTER USER 'root'@'localhost' IDENTIFIED BY ''"

#Create a databsae
sudo mysql --user="root" --execute "CREATE DATABASE wp_$SITENAME"

#We're going to use a random password for the wordpress user for this script
wp_db_user_pass=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32};echo;)

#Create the user
sudo mysql --user="root" --database="wp_$SITENAME" --execute="CREATE USER '$WP_USER'@'localhost' IDENTIFIED BY '$wp_db_user_pass'"

#Grant the user privileges
sudo mysql --user="root" --database="wp_$SITENAME" --execute="GRANT ALL ON wp_$SITENAME.* TO '$WP_USER'@'localhost'"
sudo mysql --user="root" --database="wp_$SITENAME" --execute="FLUSH PRIVILEGES"

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

#Install apache and mod_ssl for 443
sudo dnf install httpd mod_ssl -y

#enable apache server
sudo systemctl enable --now httpd

#Download the latest worpdress
curl https://wordpress.org/latest.tar.gz --output wordpress.tar.gz

#Extract the wordpress files to apache directory
sudo tar -xf wordpress.tar.gz -C /var/www/html

#give apapche ownership to wordpress
sudo chown -R apache:apache /var/www/html/wordpress

#set permissions to wordpress
sudo chmod -R 775 /var/www/html/wordpress

#Rocky 8 on Google Cloud did not come with semanage installed. semanage comes from the policyutils-python-utils package
sudo dnf install policycoreutils-python-utils -y

#Configure SELinux context
sudo semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/html/wordpress(/.*)?"
sudo restorecon -Rv /var/www/html/wordpress

#Create an apache virtual host file to point to the wordpress install
cat > ./wordpress.conf << EOF
<VirtualHost *:80>
  ServerName $FQDN
  Redirect permanent / https://$FQDN/
</VirtualHost>

<VirtualHost *:443>
  ServerName $FQDN

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
sudo mv ./wordpress.conf /etc/httpd/conf.d/
sudo restorecon -Rv /etc/httpd/conf.d/

#open firewall ports
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https

#reset apache
sudo systemctl restart httpd

#we have a working webserver at this point point but can't login to wordpress admin because of cert errors
#Let's use letsencrypt to get some valid certs.

#First we need the epel-release repo
sudo dnf install epel-release -y

#next let's install the letsencrypt stuff
sudo dnf install certbot python3-certbot-apache -y

#retrieve and install the first cert.
sudo certbot --apache --non-interactive --agree-tos -m $EMAIL --domain $FQDN

#give username and password
echo ""
echo "Navigate to your site in a browser and use the following information"
echo "Wordpress User: $WP_USER"
echo "Password: $wp_db_user_pass"
echo ""
echo "Copy this info. You won't see it again."
