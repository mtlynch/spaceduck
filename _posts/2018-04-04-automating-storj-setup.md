---
title: Automating Storj Setup
comments: true
hide_description: true
layout: post
date: '2018-04-04'
description: Simplifying Storj headless farmer provisioning.
tags:
- ansible
- storj
- automation
permalink: "/automating-storj-setup/"
---

## Why automate Storj?

I ran a very early version of Storj in mid-2015 and haven't used it much since. I realized that though this is a blog about about decentralized storage in general, I've focused all of my attention on Sia, so it was time to reacquaint myself with Storj.

I tried actually running Storj and was quickly confused. The Github repo for the command-line interface has instructions for installing Storj on the command-line, but it never explains how to actually 

The step-by-step guide for setting up the Storj command-line server is over 9300 words! It's so bloated with information that it shows seven screenshots to explain to the reader how to install a graphical text editor:

TODO: Screenshot of that part

Apparently that guide was aimed at the rare user who's comfortable enough on the command line to eschew the Storj GUI client, but is also so clueless that they don't know how to install or use a text editor.

## Automated provisioning

As a Storj user, what do you actually want here?

What if, instead of constantly checking on the install to move it forward, you could just define the final state you wanted?

Now, you can! I present to you: [ansible-role-storj](https://github.com/mtlynch/ansible-role-storj).

## What is Ansible?

[Ansible](https://www.ansible.com/) is a lightweight server configuration tool. It allows you to define a sequence of actions on any major OS.

You can use Ansible to configure your local machine, a remote server, or many remote servers at once.

Ansible is [easy to install](https://docs.ansible.com/ansible/latest/intro_installation.html) on any major Linux distribution. Here are the install steps on an Ubuntu/Debian OS:

```bash
sudo apt-get update \
  && sudo apt-get install python-pip -y \
  && sudo pip install ansible
```

## The Ansible Storj role

In Ansible terms, a "role" is essentially a template for installing an application. The Storj role automates all of the following:

* Installing all of Storj's dependencies
* Version upgrades/downgrades
* Spinning up farmer nodes

Using the Storj role, you can provision many farmers at once. Farmers can be spread out across multiple machines or they can all be on the same machine.

## Installation

To install the Storj role, use Ansible Galaxy (included by default when you install Ansible):

```bash
sudo ansible-galaxy install mtlynch.storj
```

## Examples

Here are some examples of what you can do with ansible-role-storj:

### Example 1: Set up a Storj farmer on the local machine

I'll start with a simple example. The commands below install Storj on the same machine from which you're running Ansible:

```bash
# Create a minimal Ansible playbook to install Storj
echo "---
- hosts: localhost
  roles:
    - { role: mtlynch.storj }" > install.yml

# Run the playbook locally.
sudo ansible-playbook install.yml \
  --extra-vars "storj_seed_path=${HOME}/storj-test-seed.txt"
```

When the playbook completes,  `storjc` shows that the blockchain is fully synced and the wallet is unlocked:

```bash
$ /opt/storj/storjc
Synced: Yes
Block:      0000000000000001d79e02d419bf6ca7e697d1da530ac5ccb1d9b10fed5476a5
Height:     144762
Target:     [0 0 0 0 0 0 0 2 210 195 198 72 223 120 244 201 173 147 250 219 3 100 49 96 250 234 2 3 167 103 231 151]
Difficulty: 6533753230067179529

$ /opt/storj/storjc wallet
Wallet status:
Encrypted, Unlocked
Confirmed Balance:   0 H
Unconfirmed Delta:  +0 H
Exact:               0 H
Storjfunds:            0 SF
Storjfund Claims:      0 H

Estimated Fee:       30 mS / KB
```

The seed is saved in the path specified by the `storj_seed_path` parameter above:

```bash
$ cat ~/storj-test-seed.txt
localhost: rims chlorine obtains dauntless value ammo jury liar sayings fossil uncle shelter lids germs vipers estate firm karate limits thumbs pager sixteen phrases potato vegan cajun laboratory radar actress
```

### Example 2: Set up multiple Storj farmers on a remote machine

This example installs Storj on a remote machine and initializes its wallet using an existing seed passphrase.

To specify the remote machine and seed, create a file called `hosts` with the following contents:

```text
storj-from-seed ansible_ssh_host=1.2.3.4 storj_seed="thorn amnesty erase framed technical vampire cell hive sugar silk network soil athlete butter myth viewpoint womanly software rover village yellow ticket reruns cadets wrist sensible apricot theatrics across"
```

Replace `1.2.3.4` with the IP address of your remote host, and replace the 29-word seed passphrase with your own seed. `storj-from-seed` is simply the display name for the host, so you can change this to any name you want.

```bash
echo "---
- hosts: all
  become: True
  become_method: sudo
  become_user: root
  roles:
    - { role: mtlynch.storj }" > install.yml

ansible-playbook --inventory hosts install.yml
```

When the playbook completes, the Storj node's wallet will be initialized using the Storj seed you specified in the `hosts` file:

```bash
$ ansible all --inventory hosts --module-name command --args "/opt/storj/storjc wallet seeds"
storj-from-seed | SUCCESS | rc=0 >>
Primary Seed:
thorn amnesty erase framed technical vampire cell hive sugar silk network soil athlete butter myth viewpoint womanly software rover village yellow ticket reruns cadets wrist sensible apricot theatrics across
```

## Demo

This video shows the multiple-node scenario example above:

<script src="https://asciinema.org/a/Bp4oOefN6TEdbDGOZiprml2V9.js" id="asciicast-Bp4oOefN6TEdbDGOZiprml2V9" data-size="large" data-speed="1.6" async></script>

## A brief rant on Storj

Storj is really unfriendly to automation. While writing this Ansible role, I got the strong sense that the Storj developers put most of their effort into the GUI.

**Storj [doesn't set the exit code on failure](https://github.com/Storj/storjshare-daemon/issues/335)**

Most Linux applications set a failing exit code when they exit due to error. Storj doesn't do this, forcing the user, to parse console output to see if the command failed.

And even then, Storj sometimes reports "failure" for things that I as the developer wouldn't consider failure, such as `failed to start farmer: node is already running`. Is that *really* a failure Storj?

But then you're still stuck because Storj doesn't print "fail" in the output for every failure, like with this error message for invalid syntax `no payment address was given, try --help`.

But even if you knew every possible output message and whether they meant success or failure, you'd still have trouble parsing error messages because...

**Storj [writes output inconsistently](https://github.com/Storj/storjshare-daemon/issues/336)**

For some commands, Storj writes error messages to stdout. For others, it writes error messages to stderr.

```bash
$ storjshare create --noedit --outfile /tmp/a.json 1> /tmp/stdout-output.txt 2> /tmp/stderr-output.txt
$ cat /tmp/stdout-output.txt
$ cat /tmp/stderr-output.txt

  no payment address was given, try --help
```

```bash
$ storjshare create --noedit --outfile /notexists/a.json --storj "0x0000000000000000000000000000000000000000" 1> /tmp/stdout-output.txt 2> /tmp/stderr-output.txt
$ cat /tmp/stdout-output.txt

  failed to write config, reason: ENOENT: no such file or directory, open '/notexists/a.json'
$ cat /tmp/stderr-output.txt
```

## Open Source

ansible-role-storj is fully open-source and available on Github:

[https://github.com/mtlynch/ansible-role-storj](https://github.com/mtlynch/ansible-role-storj)

## Support

ansible-role-storj currently supports installing Storj on Ubuntu/Debian flavored OSes.

I don't plan to add support for other OSes, but I will happily accept pull requests if anyone would like to implement this.