# instructions from https://docs.rockylinux.org/books/learning_ansible/01-basic/
# Pre-Reqs - ansible user has already been created, keys generated
# Connections to some servers has been verified


# "python3-argcomplete is provided by EPEL. Please install epel-release if not done yet. This package will help you complete Ansible commands."
sudo dnf install epel-release -y

# "As we want to use a newer version of Ansible, we will install it from python3-pip"
sudo dnf install python38 python38-pip python38-wheel python3-argcomplete rust cargo curl -y

# "Before we actually install Ansible, we need to tell Rocky Linux that we want to use the newly installed version of Python. The reason is that if we continue to the install without this, the default python3 (version 3.6 as of this writing), will be used instead of the newly installed version 3.8. Set the version you want to use by entering the following command:"

# In Rocky 8.5 it looks like only this first one is needed, buy we'll run both anyway
sudo alternatives --set python /usr/bin/python3.8
sudo alternatives --set python3 /usr/bin/python3.8

# "We can now install Ansible:"
sudo pip3 install ansible
sudo activate-global-python-argcomplete

# "An example of the ansible.cfg is given here and an example of the hosts file here.
# $ sudo mkdir /etc/ansible
# $ sudo curl -o /etc/ansible/ansible.cfg https://raw.githubusercontent.com/ansible/ansible/devel/examples/ansible.cfg
# $ sudo curl -o /etc/ansible/hosts https://raw.githubusercontent.com/ansible/ansible/devel/examples/hosts
# You can also use the ansible-config command to generate a new configuration file:"
#  No Worky-> ansible-config init --disabled > /etc/ansible/ansible.cfg
# The command given at this point fails with a "no such file or directory lets add it.
sudo mkdir /etc/ansible

# The command given still fails but now as command not found. Remember we're running as root.
# which ansible-config shows:
# no ansible-config in (/usr/local/sbin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin)
# while ansible-config lives in /usr/local/bin/

# An answer to why can be found here: https://unix.stackexchange.com/questions/115129/why-does-root-not-have-usr-local-in-path from 8 years ago (as of 2022)
# My guess is this is because we didn't install from the epel-release repo, we used pip3 instead
# We could add the /usr/local/bin to the root path, or leave it as is and move on.
sudo /usr/local/bin/ansible-config init --disabled > /etc/ansible/ansible.cfg

# We did it!
sudo /usr/local/bin/ansible --version
