#Instructions followed from https://www.howtoforge.com/how-to-install-freeipa-on-rocky-linux/
#pre-reqs: Rocky LInux 8+ and non-root user with sudo

#Variables
HOST="ipa01"
DOMAIN="nix.calmatlas.com"
IP="10.7.6.7"
#"At first, you will be setting up the FQDN"
sudo hostnamectl set-hostname "$HOST.$DOMAIN"
echo "$IP	$HOST.$DOMAIN $HOST"| sudo tee -a /etc/hosts

#"Run the following command to enable the idm:DL1 module on your Rocky Linux system."
sudo dnf module enable idm:DL1 -y

#"Next, install FreeIPA packages using the dnf command below"
sudo dnf install ipa-server ipa-server-dns -y

#"Configuring FreeIPA Server"
#"Check your server IP address to verify the IPv6 is available on your network interface."

#"run the ipa-server-install command below to start configuring the FreeIPA server"
#"The FreeIPA server will automatically detect the server FQDN and use it as the default server host name. Press ENTER to confirm and continue."

#add --external-ca per manpage. I have a pki already setup and need to make this a subca. 
#additionally systutorials.com/docs/linux/man/1-ipa-server-install/ says --allow-zone-overlap is bad idea. removing it. 
#Finally setup-dns requires --forward option or --no-forwarders at linux.die.net/man/1/ipa-server-install
sudo ipa-server-install --setup-dns --external-ca --no-forwarders

#accept the defaults and type yes at the "Continue to configure the system with these values?"

#"Setting Up Firewalld"
sudo firewall-cmd --add-service={http,https,dns,ntp,freeipa-ldap,freeipa-ldaps} --permanent
sudo firewall-cmd --reload

#The next steps in the instructions simply verify things went according to plan.


