# This script installs nextcloud and dependencies including apache, php, and mariadb 
# Modified instructions from https://docs.rockylinux.org/guides/cms/cloud_server_using_nextcloud/
# Used https://github.com/chris-calmatlas/lab-setup/blob/main/scripts/install_nextcloud.sh as an initial base
# because the dependencies seem to be the same. 

# variables
SITENAME="nextcloud"
DOMAIN="calmatlas.com"
# email address needed for letsencrypt, if you comment the last part of this
EMAIL=chris@calmatlas.com

FQDN="$SITENAME.$DOMAIN"
DB_USER="$SITENAME"
DB="$SITENAME"

# First update packages
sudo dnf update -y

# Rocky 8 on Google Cloud did not come with semanage installed. semanage comes from the policyutils-python-utils package
sudo dnf install policycoreutils-python-utils -y

#-----------------------------------------------------# 
# php
#-----------------------------------------------------# 
# The instructions from docs.rockylinux.org describe using the remi repo
# The default appstream repo on a fresh install of rocky 8 will have php 7.2. At the time of this writing, the latest supported version is 8.
# Rocky 8 defaults to php 7.2 while rocky 9 defualts to php 8.  I won't be suing remi repos
# Set php 8 as desired version from appstream repo. These commands will fail on fresh install of rocky 9
# Since we're not using remi repos set the desired version here.
sudo dnf module reset php -y
sudo dnf module enable php:8.0 -y
sudo dnf install php php-ctype php-curl php-gd php-iconv php-json php-libxml php-mbstring php-openssl php-posix php-session php-xml php-zip php-zlib php-pdo php-mysqlnd php-intl php-bcmath php-gmp 

#----------------------------------------------------# 
# Database
#----------------------------------------------------# 
# install mariadb
sudo dnf install mariadb-server -y

# start and enable the mariadb
sudo systemctl enable --now mariadb

# Remove the mysql root password first if it exists. This is to allow the script to run more than once.
# To install a second instance of nextcloud on the same server, for example. The root password will be changed
# There's probably a better way to do this.
sudo mysql --defaults-file=/root/db_root.pass --execute="ALTER USER 'root'@'localhost' IDENTIFIED BY ''"

# Create a databsae
sudo mysql --user="root" --execute "CREATE DATABASE $DB"

# Create random password for the nextcloud user - You'll need this later and will see it on script run.
db_user_pass=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32};echo;)

# Create the user
sudo mysql --user="root" --database="$DB" --execute="CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$db_user_pass'"

# Grant the user privileges
sudo mysql --user="root" --database="$DB" --execute="GRANT ALL ON $DB.* TO '$DB_USER'@'localhost'"
sudo mysql --user="root" --database="$DB" --execute="FLUSH PRIVILEGES"

# We should improve the security of the mariadb installation, the following command promps the user with questions
# sudo mysql_secure_installation

# The mysql_secure_installation is just a bash script. We can accomplish the same thing with the following lines
# Remover anonymous users
sudo mysql --user="root" --execute="DELETE FROM mysql.user WHERE User=''"
# allow root login from localhost only
sudo mysql --user="root" --execute="DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
# delete test database
sudo mysql --user="root" --execute="DROP DATABASE IF EXISTS test"
sudo mysql --user="root" --execute="DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'"

# Generate a root password and save to a file
sudo sh -c 'db_root_pass=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32});
cat > /root/db_root.pass << EOF
[client]
user=root
password=$db_root_pass
EOF'
sudo chmod 400 /root/db_root.pass

# Set root password
sudo mysql --user="root" --execute="ALTER USER 'root'@'localhost' IDENTIFIED BY '$db_root_pass'"
sudo mysql --user="root" --password="$db_root_pass" --execute="FLUSH PRIVILEGES"

#----------------------------------------------------# 
# Webserver and Nextcloud
#----------------------------------------------------# 
# This install method uses the zip from nextcloud and not the packages from the epel repo because the nextcloud-stable module doesn't seem to exist.

# Install apache and mod_ssl for 443
sudo dnf install httpd mod_ssl -y

# enable apache server
sudo systemctl enable --now httpd

# Downlaod the latest nextcloud
curl https://download.nextcloud.com/server/releases/latest.tar.bz2 --output ~/nextcloud.tar.bz2

# Extract the Nextcloud files to apache directory
sudo tar -xjf ~/nextcloud.tar.bz2 -C /var/www/html
sudo mv /var/www/html/nextcloud /var/www/html/$SITENAME

# give apapche ownership to nextcloud
sudo chown -R apache:apache /var/www/html/$SITENAME

# set permissions to nextcloud
sudo chmod -R 775 /var/www/html/$SITENAME

#selinux - give httpd rights to html folder
sudo semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/html/$SITENAME(/.*)?"
sudo restorecon -Rv /var/www/html/
 
# Create an apache virtual host file to point to the nextcloud install
# We're writing it to the home directory of whoever ran the script first
cat > ~/$SITENAME.conf << EOF
<VirtualHost *:80>
  ServerName $FQDN
  Redirect permanent / https://$FQDN/
</VirtualHost>

<VirtualHost *:443>
  ServerName $FQDN

  DocumentRoot /var/www/html/$SITENAME
  ErrorLog /var/log/httpd/nextcloud_error.log
  CustomLog /var/log/httpd/nextcloud_access.log common

  <Directory "/var/www/html/$SITENAME">
    Options Indexes FollowSymLinks
    AllowOverride all
    Require all granted
  </Directory>

  SSLCertificateFile /etc/pki/tls/certs/localhost.crt
  SSLCertificateKeyFile /etc/pki/tls/private/localhost.key

</VirtualHost>
EOF

# Move the file we just created and give it the appropriate permissions
sudo chown root:root ~/$SITENAME.conf
sudo mv ~/$SITENAME.conf /etc/httpd/conf.d/

#selinux - label the conf file as a system file.
sudo semanage fcontext -a -t httpd_config_t -s system_u /etc/httpd/conf.d/$SITENAME.conf
sudo restorecon -Fv /etc/httpd/conf.d/$SITENAME.conf

# reset apache
sudo systemctl restart httpd

#----------------------------------------------------# 
# Security
#----------------------------------------------------# 

# open firewall ports
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo systemctl restart firewalld

# Additional selinux rules - files relabeled as needed above
# Without this setting the plugin and theme page does not work
#sudo setsebool -P httpd_can_network_connect 1

# Configure letsencrypt for a cert - this requires that your DNS settings are already done. 

# Install epel repo
#sudo dnf install epel-release -y

# Install certbot
#sudo dnf install certbot python3-certbot-apache -y

# Retrieve and install the first cert.
#sudo certbot --apache --non-interactive --agree-tos -m $EMAIL --domain $FQDN

# Disable rocky default welcome page
sudo sed -i'' 's/^\([^#]\)/#\1/g' /etc/httpd/conf.d/welcome.conf

# Disable directory browsing
sudo sed -i'' 's/Options Indexes/Options/g' /etc/httpd/conf/httpd.conf

#----------------------------------------------------# 
#  Output
#----------------------------------------------------# 
# Give username and password
echo ""
echo "Navigate to your site in a browser and use the following information"
echo "Database: $DB"
echo "Database User: $DB_USER"
echo "Password: $db_user_pass"
echo ""
echo "Copy this info. You won't see it again."
