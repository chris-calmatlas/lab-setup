# Playing around with infrastructure
Included in this repo are bash scripts, docker files, and ansible playbooks I've built while putting together a lab/my home network.

# Chris Jaime
Software Engineer for hire

Currently employed in government as an Infrastructure Engineer

[www.calmatlas.com](https://www.calmatlas.com/)

[github](https://github.com/chris-calmatlas) 

[Discord](https://discord.com/invite/8UwSN7nCC7) 

# How It's Made:
bash, powershell, docker, ansible drafts and completed scripts to deploy various solutions

# Optimization
Most of the bash scripts should be converted to ansible playbooks. Ansible is predictable and intentionally leaves servers in a predictable state.
Some of these scripts will only work on the first run, so a gcloud CLI or AWS CLI script that stands up and snapshots a server would be a great alternative to deploying ansible and building an inventory, since I imagine plenty of users only need one of these types of servers. i.e. Who's building a wordpress farm? Not with these scripts...yet.

# ToDo

Sooooooo much. This is an ongoing project and I'm really looking forward to feedback. Really this is just a repo of stuff and not a "project" per-se. Reach out on [Discord](https://discord.com/invite/8UwSN7nCC7), let me know what you're workig on and how I can help!