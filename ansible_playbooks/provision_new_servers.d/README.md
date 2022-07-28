# Description
The idea is to spool up a linux server with a single user and no internet connection then use ansible to add a managment user, setup networking, harden the server some, and install some packages

This is version 1.

# Usage
ansible-playbook --vault-password-file /path/to/vault-password -e @/path/to/vars_file.yml -e @/path/to/vault.yml provision_new_linux_server.yml

# Info
## Image created with a fresh install of rocky.
  - root password in lastpass
  - user Created:
  - Username: provision
  - password: {added to vault.yml on ansible control server}
  - Network setup:
  - interface 1 static 192.168.3.3 no internet
  - interface 2 disabled
  - Added 2 additional interfaces for testing. 

# Roadmap
## Script/playbooks
### initConfig
[x] Create provision user on ansible control with a host key
[x] ~~send key to freshInstall to connect~~
[X] add users ansible ~~and kung~~ on freshInstall
[X] send key for ansible
[X] add ansible to visudo
[X] delete provision account from freshInstall
[X] ~~remove provision from visudo~~ provision was part of wheel group
[X] disable root and password login via ssh (send a new sshd and reboot)
[X] delete provision user on client

### networkSetup      
[X] Configure static ip on interface 2
[X] Disable interace 1
[X] set hostname
[ ] configure firewall to allow remote access from ansible IP only

## basicPackages     
[ ] Get updates
[ ] install vim, tmux, git, wget
