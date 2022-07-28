#instructions from https://www.tecmint.com/install-docker-in-rocky-linux-and-almalinux/
USER="ansible"
echo "User set to $USER"

#"On your terminal, run the following command to add the Docker repository"
sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo

#"we are going to install the Docker community edition which is freely available for download and use. But first, update the packages."
sudo dnf update -y
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
docker --version

#Start and Enable Docker
sudo systemctl enable docker
sudo systemctl start docker
sudo systemctl status docker |grep Active:

#"To use or run docker as a regular user, you need to add the user to the ‘docker‘ group which is automatically created during installation. Otherwise, you will keep on running into permission errors."
sudo usermod -aG docker "$USER"
echo "You must log out and log back if you run into permissions errors"



