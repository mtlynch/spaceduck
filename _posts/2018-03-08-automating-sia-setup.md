---
title: Automating Sia Setup
layout: post
date: '2018-03-08'
description: How to make Sia server provisioning less of a headache.
tags:
- ansible
- sia
- automation
permalink: "/automating-sia-setup/"
---

One of the biggest headaches in using Sia is how long it takes to complete the initial setup. Unfortunately, I can't solve that problem. What I can do is make it less tedious and labor-intensive.

## Sia is needy

In theory, provisioning a Sia server takes about 10 hours from start to finish. In practice, the process is significantly longer because Sia demands you give it attention every few minutes to see if it's ready to be nudged along to the next step.

The process looks like this:

1. Download the Sia binary
1. Start downloading the Sia blockchain
1. Check on download progress once an hour for 8 hours.
1. Download is complete! Create a new wallet.
1. Wait for wallet creation to complete. This takes 30-90 minutes but there's no status indicator, so you check every five minutes to see if it's done.
1. Unlock the wallet. Bizarrely, this is a separate step from wallet creation. Check progress every five minutes to see if your wallet is ready yet.
1. Wallet unlock is complete. You can now use Sia.

This is a terrible workflow.

I do experiments with Sia frequently, so I've performed these steps dozens of times manually. It never becomes fun.

## Automated provisioning

As a Sia user, what do you actually want here?

What if, instead of constantly checking on the install to move it forward, you could just define the final state you wanted?

Now, you can! I present to you: [ansible-role-sia](https://github.com/mtlynch/ansible-role-sia).

## What is Ansible?

[Ansible](https://www.ansible.com/) is a lightweight server configuration tool. It allows you to define a sequence of actions on any major OS.

You can use Ansible to configure your local machine, a remote server, or many remote servers at once.

Ansible is [easy to install](https://docs.ansible.com/ansible/latest/intro_installation.html) on any major Linux distribution. Here are the install steps on an Ubuntu/Debian OS:

```bash
sudo apt-get update \
  && sudo apt-get install python-pip -y \
  && sudo pip install ansible
```

## The Ansible Sia role

In Ansible terms, a "role" is essentially a template for installing an application. The Sia role automates all of the following:

* Initial provisioning / setup
* Version upgrades/downgrades
* Blockchain sync
* Wallet creation
* Wallet unlock

The role installs Sia as a systemd service and sets it to automatically run in the background. This allows you to use standard systemd utilities to start or stop Sia and view its logs:

```bash
$ sudo systemctl start sia
$ sudo journalctl -u sia
-- Logs begin at Thu 2018-03-08 03:10:17 UTC, end at Thu 2018-03-08 11:40:23 UTC. --
Mar 08 03:14:35 sia-multiple-c systemd[1]: Started Sia Distributed Storage Service.
Mar 08 03:14:35 sia-multiple-c siad[6344]: Sia Daemon v1.3.1
Mar 08 03:14:35 sia-multiple-c siad[6344]: Loading...
Mar 08 03:14:35 sia-multiple-c siad[6344]: (0/6) Loading siad...
Mar 08 03:14:35 sia-multiple-c siad[6344]: (1/6) Loading gateway...
Mar 08 03:14:35 sia-multiple-c siad[6344]: (2/6) Loading consensus...
Mar 08 03:14:35 sia-multiple-c siad[6344]: (3/6) Loading transaction pool...
Mar 08 03:14:35 sia-multiple-c siad[6344]: (4/6) Loading wallet...
Mar 08 03:14:35 sia-multiple-c siad[6344]: (5/6) Loading host...
Mar 08 03:14:36 sia-multiple-c siad[6344]: (6/6) Loading renter...
Mar 08 03:14:36 sia-multiple-c siad[6344]: Finished loading in 0.10183626 seconds
```

Using the Sia role, you can provision many Sia nodes at once and perform actions on each in parallel. If you manage Sia hosts on multiple machines or perform an experiment using multiple instances of Sia, the Sia role allows you to do that easily and efficiently.

## Installation

To install the Sia role, use Ansible Galaxy (included by default when you install Ansible):

```bash
sudo ansible-galaxy install mtlynch.sia
```

## Examples

Here are some examples of what you can do with ansible-role-sia:

### Example 1: Set up a Sia node on the local machine

I'll start with a simple example. The commands below install Sia on the same machine from which you're running Ansible:

```bash
# Create a minimal Ansible playbook to install Sia
echo "---
- hosts: localhost
  roles:
    - { role: mtlynch.sia }" > install.yml

# Run the playbook locally.
sudo ansible-playbook install.yml \
  --extra-vars "sia_seed_path=${HOME}/sia-test-seed.txt"
```

When the playbook completes,  `siac` shows that the blockchain is fully synced and the wallet is unlocked:

```bash
$ /opt/sia/siac
Synced: Yes
Block:      0000000000000001d79e02d419bf6ca7e697d1da530ac5ccb1d9b10fed5476a5
Height:     144762
Target:     [0 0 0 0 0 0 0 2 210 195 198 72 223 120 244 201 173 147 250 219 3 100 49 96 250 234 2 3 167 103 231 151]
Difficulty: 6533753230067179529

$ /opt/sia/siac wallet
Wallet status:
Encrypted, Unlocked
Confirmed Balance:   0 H
Unconfirmed Delta:  +0 H
Exact:               0 H
Siafunds:            0 SF
Siafund Claims:      0 H

Estimated Fee:       30 mS / KB
```

The seed is saved in the path specified by the `sia_seed_path` parameter above:

```bash
$ cat ~/sia-test-seed.txt
localhost: rims chlorine obtains dauntless value ammo jury liar sayings fossil uncle shelter lids germs vipers estate firm karate limits thumbs pager sixteen phrases potato vegan cajun laboratory radar actress
```

### Example 2: Create a remote Sia node from an existing seed

This example installs Sia on a remote machine and initializes its wallet using an existing seed passphrase.

To specify the remote machine and seed, create a file called `hosts` with the following contents:

```
sia-from-seed ansible_ssh_host=1.2.3.4 sia_seed="thorn amnesty erase framed technical vampire cell hive sugar silk network soil athlete butter myth viewpoint womanly software rover village yellow ticket reruns cadets wrist sensible apricot theatrics across"
```

Replace `1.2.3.4` with the IP address of your remote host, and replace the 29-word seed passphrase with your own seed. `sia-from-seed` is simply the display name for the host, so you can change this to any name you want.

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

When the playbook completes, the Sia node's wallet will be initialized using the Sia seed you specified in the `hosts` file:

```bash
$ ansible all --inventory hosts --module-name command --args "/opt/sia/siac wallet seeds"
sia-from-seed | SUCCESS | rc=0 >>
Primary Seed:
thorn amnesty erase framed technical vampire cell hive sugar silk network soil athlete butter myth viewpoint womanly software rover village yellow ticket reruns cadets wrist sensible apricot theatrics across
```

### Example 3: Create a remote Sia node using the bootstrapped consensus file

This example installs Sia on a remote machine and uses the [bootstrap method](https://siawiki.tech/daemon/bootstrapping_the_blockchain) for syncing the Sia blockchain, which speeds up initial sync.

To specify the remote machine, create a file called `hosts` with the following contents:

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

When the playbook completes, the Sia node's blockchain will be synchronized with the Sia network:

```bash
$ ansible all --inventory hosts --module-name command --args "/opt/sia/siac"
sia-bootstrapped | SUCCESS | rc=0 >>
Synced: Yes
Block:      00000000000000008b1c6a7daf53375e69d0731c92bf6fb35403647a200c253a
Height:     144850
Target:     [0 0 0 0 0 0 0 2 189 170 152 52 96 206 37 211 83 232 136 163 206 113 199 134 80 20 241 53 30 243 1 77]
Difficulty: 6730216216860473400
```

### Example 4: Create multiple Sia nodes on remote machines

This example installs Sia on multiple remote machines, allowing you to run commands on them all in parallel.

To specify the remote machines, create a file called `hosts` with the following contents:

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
  --extra-vars "sia_seed_path=${HOME}/sia-test-seeds.txt"
```

When the process completes, the seeds for each node will be in `${HOME}/sia-test-seeds.txt`:

```bash
$ cat "${HOME}/sia-test-seeds.txt"
sia-multiple-a: onslaught exult january smash opposite stunning paradise apply jubilee revamp nephew space jeopardy mohawk jellyfish malady splendid bypass august mural agreed warped vulture suddenly sulking habitat fuselage queen agenda
sia-multiple-b: altitude bawled uphill guru punch narrate catch lamb foxes irony fleet weird oscar bias puffin coal reunion pierce arsenic yesterday inexact bicycle tawny rotate lamb husband debut hornet adept
sia-multiple-c: neither kitchens utmost trying inbound duties soccer enforce summon ascend obedient daily because lush soda needed puddle omnibus cupcake knee update cement acquire reduce joyous dolphin lukewarm symptoms ablaze
```

These values match the output produced by the `siac wallet seeds` command:

```bash
$ ansible all --inventory hosts --module-name command --args "/opt/sia/siac wallet seeds"
sia-multiple-a | SUCCESS | rc=0 >>
Primary Seed:
onslaught exult january smash opposite stunning paradise apply jubilee revamp nephew space jeopardy mohawk jellyfish malady splendid bypass august mural agreed warped vulture suddenly sulking habitat fuselage queen agenda

sia-multiple-b | SUCCESS | rc=0 >>
Primary Seed:
altitude bawled uphill guru punch narrate catch lamb foxes irony fleet weird oscar bias puffin coal reunion pierce arsenic yesterday inexact bicycle tawny rotate lamb husband debut hornet adept

sia-multiple-c | SUCCESS | rc=0 >>
Primary Seed:
neither kitchens utmost trying inbound duties soccer enforce summon ascend obedient daily because lush soda needed puddle omnibus cupcake knee update cement acquire reduce joyous dolphin lukewarm symptoms ablaze
```

Ansible makes it easy to perform tasks across multiple nodes in parallel, such as creating a new wallet address:

```bash
$ ansible all --inventory hosts --module-name command --args "/opt/sia/siac wallet address"
sia-multiple-a | SUCCESS | rc=0 >>
Created new address: b0785be0a00038dc8838573673dbba066005119af23171e0d5afc5b9082035d2370303bd93ab

sia-multiple-b | SUCCESS | rc=0 >>
Created new address: ac00254703c5cbb09e295f46b487d87393cf66db0a31ccf985b9f927c2a9e5b2d8bb3c375639

sia-multiple-c | SUCCESS | rc=0 >>
Created new address: 9bb1b3e720083f433b5c6e604104a613f86e85ac7b693850d5b9928fd47b574955555ca8c6fe
```

## Demo

This video shows the multiple-node scenario example above:

<script src="https://asciinema.org/a/Bp4oOefN6TEdbDGOZiprml2V9.js" id="asciicast-Bp4oOefN6TEdbDGOZiprml2V9" data-size="large" data-speed="1.6" async></script>

You probably don't want to watch 10 hours of console output, so the video below skips ahead to the point where the Ansible playbook completes. The user hasn't had to interact with the installation at all since the initial launch of the playbook. When it's complete, each node has the blockchain synced and the wallet initialized:

<script src="https://asciinema.org/a/Bp4oOefN6TEdbDGOZiprml2V9.js" id="asciicast-Bp4oOefN6TEdbDGOZiprml2V9" data-t="630m30s" data-size="large" data-speed="1.6" async></script>

## Support

ansible-role-sia currently supports installing Sia on Ubuntu/Debian flavored OSes.

I don't plan to add support for other OSes, but I will happily accept pull requests if anyone would like to implement this.