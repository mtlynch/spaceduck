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
# Replace with your own Storj ERC20 address
PAYMENT_ADDRESS="0x161441Efd42171687dd1468A9e23E74226541c38"

# Create a minimal Ansible playbook to install Storj
echo "---
- hosts: localhost
  vars:
    storj_farmer_configs:
      - payment_address: \"$PAYMENT_ADDRESS\"
        rpc_port: 6000
        share_size: 1GB
  pre_tasks:
    - uri:
        url: http://whatismyip.akamai.com/
        return_content: yes
      register: external_ip
    - set_fact:
        storj_farmer_default_rpc_address: \"{{ external_ip.content }}\"
  roles:
    - { role: mtlynch.storj }" > install.yml

# Run the playbook locally.
sudo ansible-playbook install.yml
```

The video below demonstrates these commands running within a real Google Compute Engine server:

<script src="https://asciinema.org/a/HN4J3oqKURIXueHqSmmuuAs3H.js" id="asciicast-HN4J3oqKURIXueHqSmmuuAs3H" async></script>

### Example 2: Set up multiple Storj farmers on a remote machine

This example installs Storj on a remote machine using multiple farmers, each with independent payment addresses and storage directories:

```bash
# Replace with your server's IP or hostname.
STORJ_SERVER="1.2.3.4"

# Replace with your own Storj ERC20 addresses
PAYMENT_ADDRESS_A="0x161441Efd42171687dd1468A9e23E74226541c38"
PAYMENT_ADDRESS_B="0xe2c1042ae7192dcae902cffe67a30c7f2c8b2e1b"

echo "storj-server ansible_host=\"${STORJ_SERVER}\"" > hosts

# Create a minimal Ansible playbook to install Storj
echo "---
- hosts: all
  become: True
  become_method: sudo
  become_user: root
  vars:
    storj_farmer_configs:
      - payment_address: \"$PAYMENT_ADDRESS_A\"
        rpc_address: \"$STORJ_SERVER\"
        rpc_port: 6000
        storage_dir: /mnt/path1
        share_size: 5GB
      - payment_address: \"$PAYMENT_ADDRESS_B\"
        rpc_address: \"$STORJ_SERVER\"
        rpc_port: 6001
        storage_dir: /mnt/path2
        share_size: 1GB
  roles:
    - { role: mtlynch.storj }" > install.yml

# Run the playbook.
ansible-playbook install.yml -i hosts
```

When the playbook completes, you can check the status remotely using `storjshare status`:

```bash
$ ansible all --inventory hosts --module-name command --args "storjshare status"
storj-server | SUCCESS | rc=0 >>

┌─────────────────────────────────────────────┬─────────┬──────────┬──────────┬─────────┬───────────────┬─────────┬──────────┬───────────┬──────────────┐
│ Node                                        │ Status  │ Uptime   │ Restarts │ Peers   │ Allocs        │ Delta   │ Port     │ Shared    │ Bridges      │
├─────────────────────────────────────────────┼─────────┼──────────┼──────────┼─────────┼───────────────┼─────────┼──────────┼───────────┼──────────────┤
│ a89d2d31de737f4a7f2879eb3e1da0cbc7846f43    │ running │ 12s      │ 0        │ 6       │ 0             │ 16ms    │ 6000     │ ...       │ connected    │
│   → /mnt/path1                              │         │          │          │         │ 0 received    │         │ (uPnP)   │ (...%)    │              │
├─────────────────────────────────────────────┼─────────┼──────────┼──────────┼─────────┼───────────────┼─────────┼──────────┼───────────┼──────────────┤
│ bbfafb3dddc20ac76dc1766357401e2ed91d6f9b    │ running │ 10s      │ 0        │ 135     │ 0             │ 15ms    │ 6001     │ ...       │ connected    │
│   → /mnt/path2                              │         │          │          │         │ 0 received    │         │ (uPnP)   │ (...%)    │              │
└─────────────────────────────────────────────┴─────────┴──────────┴──────────┴─────────┴───────────────┴─────────┴──────────┴───────────┴──────────────┘
```

The video below demonstrates these commands running against a real Google Compute Engine server:

<script src="https://asciinema.org/a/IuSde3JEpeu00kff68L8AujYv.js" id="asciicast-IuSde3JEpeu00kff68L8AujYv" async></script>

## A brief rant on Storj

Storj is really unfriendly to automation. While writing this Ansible role, I got the strong sense that the Storj developers put most of their effort into the GUI.

**[Storj doesn't set the exit code on failure](https://github.com/Storj/storjshare-daemon/issues/335)**

Most Linux applications set a failing exit code when they exit due to error. Storj doesn't, so I can't tell whether a command succeeded unless I parse Storj's output.

And even then, Storj sometimes reports "failure" for things that I as the developer wouldn't consider failure, such as `failed to start farmer: node is already running`. Is that *really* a failure, Storj? To me, that's success with a warning.

But then you're still stuck because Storj doesn't print "fail" in the output for every failure, like with this error message for invalid syntax:

```
no payment address was given, try --help
```

So that means that to determine whether a command succeeded or failed, you have to know every possible error message Storj can produce.

And even then, you'd *still* have trouble because...

**[Storj writes output inconsistently](https://github.com/Storj/storjshare-daemon/issues/336)**

For some commands, Storj writes error messages to stdout. For others, it writes error messages to stderr.

See for example the following two calls to `storjshare create`. In the first case, Storj writes the error message to stdout:

```bash
$ storjshare create --noedit --outfile /tmp/a.json 1> /tmp/stdout-output.txt 2> /tmp/stderr-output.txt
$ cat /tmp/stdout-output.txt
$ cat /tmp/stderr-output.txt

  no payment address was given, try --help
```

In a very similar case, Storj writes the nothing to stdout and instead writes the error to stderr:

```bash
$ storjshare create --noedit --outfile /notexists/a.json --storj "0x0000000000000000000000000000000000000000" 1> /tmp/stdout-output.txt 2> /tmp/stderr-output.txt
$ cat /tmp/stdout-output.txt

  failed to write config, reason: ENOENT: no such file or directory, open '/notexists/a.json'
$ cat /tmp/stderr-output.txt
```

**The config files are all sorts of awful**

And then JSON is a poor choice because it's a pain to edit by hand

For example this is what the end of the Storj config file looks like:

```json
  // Valid units are B, KB, MB, GB, TB
  "storageAllocation": "5GB"
  // Max size of shards that will be accepted and stored
  // Use this and make this lower if you don't have a strong internet connection
  // "maxShardSize": "100MB"
}
```

What happens if I uncomment the `maxShardSize` line? Whoops, now my config file is invalid because I forgot to add a trailing comma to the `storageAllocation` line. For a config file that requires

Notice those `//` comments? Those are [not valid in JSON](https://stackoverflow.com/q/244777/90388), which means that if you try to read these files using a real JSON library, everything blows up:

```bash
$ python -c "import json; print json.load(open('/opt/storj/configs/0x161441Efd42171687dd1468A9e23E74226541c38.config'))"
Traceback (most recent call last):
  File "<string>", line 1, in <module>
  File "/usr/lib/python2.7/json/__init__.py", line 291, in load
    **kw)
  File "/usr/lib/python2.7/json/__init__.py", line 339, in loads
    return _default_decoder.decode(s)
  File "/usr/lib/python2.7/json/decoder.py", line 364, in decode
    obj, end = self.raw_decode(s, idx=_w(s, 0).end())
  File "/usr/lib/python2.7/json/decoder.py", line 380, in raw_decode
    obj, end = self.scan_once(s, idx)
ValueError: Expecting property name: line 2 column 3 (char 4)
```


I can't generate the config file myself because it includes the field `networkPrivateKey`, which expects a private key that I don't know how to generate unless I dive into the Storj implementation.

It also doesn't include

**And other annoyances**

* Storj farmers run off of config files, but you can't create these config files yourself because 
*  
*  JSON is also a poor choice because 
* Storj doesn't have a documented API

## Open Source

ansible-role-storj is fully open-source and available on Github:

[https://github.com/mtlynch/ansible-role-storj](https://github.com/mtlynch/ansible-role-storj)

## Support

ansible-role-storj currently supports installing Storj on Ubuntu/Debian flavored OSes.

I don't plan to add support for other OSes, but I will happily accept pull requests if anyone would like to implement this.