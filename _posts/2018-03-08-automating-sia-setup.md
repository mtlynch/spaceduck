---
title: Automating Sia Setup
layout: post
date: '2018-03-08'
summary: How to make Sia server provisioning less of a headache.
tags:
- ansible
- sia
- automation
---

One of the biggest headaches in using Sia is how long it takes to install and set up a wallet. I haven't solved that problem, but-

## No wait, come back!

I can't do much to solve that problem. But the second biggest problem is that Sia does a terrible job of supporting unattended installation. In theory, the process takes about a day start to finish, but in practice, it usually takes much longer than that because there are several points in the installation where setup can't proceed without some input from you.

The process looks like this:

1. Download the Sia binary
1. Start downloading the Sia blockchain
1. Check on download progress once an hour for 18 hours.
1. Download is complete! Create a new wallet.
1. Wait for wallet creation to complete. This takes 30-90 minutes but there's no status indicator, so you check every five minutes to see if it's done.
1. Unlock the wallet, which is bizarrely, a separate step from wallet creation. Check progress every five minutes to see if your wallet is ready yet.
1. Wallet unlock is complete.

This is a terrible workflow. I frequently do experiments with Sia, so I've gone through these steps manually dozens of times. It never gets any more fun.

## Automated provisioning

As a Sia user, what do you actually want here? I'm not a genie, so I can't just make it happen instantly. I *can* still grant you a wish. What if, instead of constantly checking on the install to nudge it along to the next step, you could just define the what you wanted it to look like up front and find out when install was done?

Now, you can! That's exactly what [ansible-role-sia](https://github.com/mtlynch/ansible-role-sia) does.

## What is Ansible?

Ansible is a lightweight tool for server configuration. It's easy to install

## Support

Right now, ansible-role-sia only supports installing Sia on Ubuntu/Debian flavored OSes. I don't plan to add support for other OSes, but I will happily accept pull requests if anyone would like to implement this.

## Examples

Here are some examples of what you can do with ansible-role-sia:

### Set up a Sia node on the local machine

I'll start with a simple example.

```bash
sudo apt-get update

# Install Ansible and dependencies.
sudo apt-get install python-pip -y && sudo pip install ansible

# Install the Ansible Sia role
sudo ansible-galaxy install mtlynch.sia

# Create a minimal Ansible playbook to install Sia
echo "---
- hosts: localhost
  roles:
    - { role: mtlynch.sia }" > install.yml

# Run the playbook locally.
sudo ansible-playbook install.yml \
  --extra-vars "sia_seed_path=sia-test-seed.txt"
```

### Create a remote Sia node from an existing seed

Create a file called `hosts` with the following contents:

```
sia-from-seed ansible_ssh_host=1.2.3.4 sia_seed="thorn amnesty erase framed technical vampire cell hive sugar silk network soil athlete butter myth viewpoint womanly software rover village yellow ticket reruns cadets wrist sensible apricot theatrics across"
```

Replace `1.2.3.4` with the IP address of your remote host, and replace the 29-word seed passphrase with your own seed.

```bash
echo "---
- hosts: all
  become: True
  become_method: sudo
  become_user: root
  roles:
    - { role: mtlynch.sia }" > install.yml

ansible-playbook --inventory hosts install.yml
```

### Create a remote Sia node using the bootstrapped consensus file

Create a file called `hosts` with the following contents:

```
sia-bootstrapped ansible_ssh_host=1.2.3.4
```

Replace `1.2.3.4` with the IP address of your remote host.

```bash
echo "---
- hosts: all
  become: True
  become_method: sudo
  become_user: root
  vars:
    sia_bootstrap_blockchain: True
  roles:
    - { role: mtlynch.sia }" > install.yml

ansible-playbook --inventory hosts install.yml
```

### Create multiple Sia nodes on remote machines

```
sia-multiple-a ansible_ssh_host=1.2.3.4
sia-multiple-b ansible_ssh_host=1.2.3.5
sia-multiple-c ansible_ssh_host=1.2.3.6
```

```bash
echo "---
- hosts: all
  become: True
  become_method: sudo
  become_user: root
  roles:
    - { role: mtlynch.sia }" > install.yml

ansible-playbook --inventory hosts install.yml \
  --extra-vars "sia_seed_path=sia-test-seeds.txt"
```

The neat thing about using Ansible for this is that you can check status for each node with a single command:

```
$ ansible all --inventory hosts --module-name command --args "/opt/sia/siac"
sia-multiple-c | SUCCESS | rc=0 >>
Synced: No
Height: 21970
Progress (estimated): 14.4%

sia-multiple-a | SUCCESS | rc=0 >>
Synced: No
Height: 31610
Progress (estimated): 20.7%

sia-multiple-b | SUCCESS | rc=0 >>
Synced: No
Height: 31480
Progress (estimated): 20.7%
```