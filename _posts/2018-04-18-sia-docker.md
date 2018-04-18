---
title: Fun with Sia and Docker
comments: true
hide_description: true
layout: post
date: '2018-04-18'
description: Testing Sia's maximum capacity under ideal conditions
tags:
- sia
- docker
image: https://asciinema.org/a/sfDVIHYX3KtS8im1U6GhwuTiG.png
---

Over the past few weeks, I've been working on a full-featured Docker image for Sia. If you have Docker, you can now spin up a Sia node in seconds with a single command. Running Sia within Docker gives you more power and provides helpful tools for development or experimentation.

In this blog post, I'll show you how to use the Sia Docker image to:

* Easily test pre-release versions of Sia
* Prevent Sia from hogging system resources
* Run Sia on a NAS device
* Automatically restart Sia on failure

## What is Docker?

[Docker](https://www.docker.com/) is a technology for building app containers. It allows you to build the minimal environment necessary to run an app, then run it on any OS that supports Docker.

{% include image.html file="docker-logo.png" alt="Docker logo" max_width="260px"  %}

## Following the examples

To follow the examples in this post, you'll need Docker. [Docker Community Edition](https://store.docker.com/search?offering=community&type=edition) is free and available for every major OS.

If you'd like to play with Docker before deciding whether to install it on your system, all of these examples work with [Play with Docker](https://labs.play-with-docker.com/), a Docker-enabled terminal that runs in your browser with no signup whatsoever.

{% include image.html file="play-with-docker.png" alt="Play with Docker screenshot" fig_caption="Running the Sia container on Play with Docker" img_link="true" %}

Play with Docker's disk is limited to ~10 GiB, so there's not enough space to fully sync the Sia blockchain, but you can test out the commands and see Sia begin its sync process.

## Sia Docker examples

### Basic usage

The commands below show basic usage of the Sia Docker image:

```bash
$ mkdir sia-data
$ docker run \
   --detach \
   --volume $(pwd)/sia-data:/sia-data \
   --publish 127.0.0.1:9980:9980 \
   --publish 9981:9981 \
   --publish 9982:9982 \
   --name sia-container \
    mtlynch/sia:latest
```

The shell capture below demonstrates these commands in action:

<script src="https://asciinema.org/a/sfDVIHYX3KtS8im1U6GhwuTiG.js" id="asciicast-sfDVIHYX3KtS8im1U6GhwuTiG" async></script>

In the session capture above, I:

1. created a `sia-data` directory on the host machine so that Sia can persist its data across containers.
1. launched a Docker container from the `mtlynch/sia` image, which always contains the latest release version of Sia.
1. ran `siac` from within the Docker container to check sync status.
1. ran `siac` from within the Docker container to verify the version of Sia running.
1. ran `ls sia-data` from the host terminal to verify that Sia's data folders appear from the host.

### Run the latest development build

Curious what the Sia dev team is putting into the next Sia release? The Sia Docker image supports the `dev` tag, which allows you to run the latest development version of Sia in seconds.

You don't have to set up a Go environment or compile any code. I configured a daily job to do that for you. Every day, it will pull down the latest source tree from Sia's [master branch](https://github.com/NebulousLabs/Sia) and build a fresh snapshot on [Docker Hub](https://hub.docker.com/r/mtlynch/sia/builds/).

To run the latest dev snapshot, enter the following commands:

```bash
$ mkdir sia-data
$ docker run \
  --detach \
  --volume $(pwd)/sia-data:/sia-data \
  --publish 127.0.0.1:9980:9980 \
  --publish 9981:9981 \
  --publish 9982:9982 \
  --name sia-container \
   mtlynch/sia:dev
$ docker exec -it sia-container ./siac version
Sia Client
        Version 1.3.2
        Git Revision 8533b8c0
        Build Time   Wed Apr 18 04:01:58 UTC 2018
Sia Daemon
        Version 1.3.2
        Git Revision 8533b8c0
        Build Time   Wed Apr 18 04:01:58 UTC 2018
```

The git revision shows that the build is based on [commit 8533b8c0](https://github.com/NebulousLabs/Sia/commit/8533b8c0), which was added on 2018-04-17, so this is indeed the latest dev branch at the time of this writing.

### Run old versions of Sia

If you want to run an old version of Sia, the Docker image makes it easy. It supports tags for every release back to 1.0.1:

```bash
$ mkdir sia-data
$ docker run \
  --detach \
  --volume $(pwd)/sia-data:/sia-data \
  --publish 127.0.0.1:9980:9980 \
  --publish 9981:9981 \
  --publish 9982:9982 \
  --name sia-container \
   mtlynch/sia:1.0.1
$ docker exec -it sia-container ./siac version
Sia Client v1.0.1
```

Sia versions prior to 1.3.1 can't fully sync the blockchain due to [the hardfork](https://redd.it/7p9ll1) that occurred at block 139,000, but it's still interesting to play with old versions to see how Sia has evolved.

### Run Sia with constrained resources

Sia's resource footprint can grow very large. Perhaps you'd like to prevent Sia from starving other processes on your server. Docker makes it easy to [limit the CPU and RAM resources](https://docs.docker.com/config/containers/resource_constraints/) that Sia consumes.

As an extreme example, I tried running Sia with only 20 MiB of RAM, no swap space, and half a CPU:

```bash
$ mkdir sia-data
$ docker run \
  --detach \
  --volume $(pwd)/sia-data:/sia-data \
  --publish 127.0.0.1:9980:9980 \
  --publish 9981:9981 \
  --publish 9982:9982 \
  --cpus "0.5" \
  --memory "20m" \
  --memory-swap "20m" \
  --name sia-container \
   mtlynch/sia
```

Surprisingly, Sia ran successfully. The blockchain sync was incredibly slow, but it ran overnight without ever crashing:

```bash
$ docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
CONTAINER           CPU %               MEM USAGE / LIMIT
bbcdc2a7bab4        0.57%               19.9MiB / 20MiB
$ docker exec -it sia-container ./siac
Synced: No
Height: 18940
Progress (estimated): 11.9%
```

### Setting up a Sia host

If you're running Sia as a data host, Docker is a highly useful tool. If Sia ever crashes, Docker can automatically restart and unlock your node,  preserving your host's uptime.

To begin, create a bare Sia node with the `wallet` module enabled:

```bash
$ mkdir sia-data
$ docker run \
  --detach \
  --volume $(pwd)/sia-data:/sia-data \
  --publish 127.0.0.1:9980:9980 \
  --publish 9981:9981 \
  --env SIA_MODULES="gctw" \
  --name sia-container \
   mtlynch/sia
```

Then wait for Sia to fully sync the blockchain:

```bash
$ docker exec -it sia-container ./siac consensus
Synced: Yes
Block:      0000000000000000e464b18e2baf219dde8570b54216fa4d9f8cefb5454aed4f
Height:     150773
Target:     [0 0 0 0 0 0 0 1 61 111 157 154 232 7 83 238 3 198 188 134 189 68 199 132 204 75 47 173 235 145 21 156]
Difficulty: 14876594033137897278
```

When `siac consensus` reports that your wallet is fully synced, initialize your wallet:

```bash
$ docker exec -it sia-container ./siac wallet init
Recovery seed:
niche lifestyle biology wept randomly wept plywood maverick dozen gnome sadness hunter directed never affair today business puffin orbit bunch serving rhino airport kitchens aphid eccentric unfit acquire afield

Wallet encrypted with password:
niche lifestyle biology wept randomly wept plywood maverick dozen gnome sadness hunter directed never affair today business puffin orbit bunch serving rhino airport kitchens aphid eccentric unfit acquire afield
```

In order for Sia to auto-unlock on restart, you'll need to copy your wallet seed into a file. Note that there is a risk in storing your wallet seed in plaintext. If an attacker gains physical access to your disk, they can recover your seed and steal the contents of your Sia wallet. You can mitigate this risk by storing the file on an encrypted filesystem and securely wiping the disk when you decommission the node.

To enable auto-unlock, follow the commands below:

```bash
$ SEED_FILE=wallet-seed.txt
$ touch $SEED_FILE
$ chmod 600 $SEED_FILE

# Write your wallet passphrase in this file.
$ vim $SEED_FILE
```

Finally, kill your old container and start a new one with the `host` module enabled:

```bash
# Kill the old container.
$ docker rm -f sia-container

# Start a new container with host settings.
$ docker run \
  --detach \
  --volume $(pwd)/sia-data:/sia-data \
  --publish 127.0.0.1:9980:9980 \
  --publish 9981:9981 \
  --publish 9982:9982 \
  --restart always \
  --env SIA_MODULES="gctwh" \
  --env SIA_WALLET_PASSWORD="$(cat $SEED_FILE)" \
  --name sia-container \
   mtlynch/sia
```

Now you have a Docker container optimized for Sia hosting. If Sia ever crashes, Docker will restart it and auto-unlock the wallet so that you can continue accepting new contracts.

When new versions of Sia are released, upgrading is easy. Just remove the container with `docker rm -f sia-container` and re-run the last `docker run` command shown above. Docker will automatically pull down the image of Sia that has the latest version of Sia. Your host will upgrade and come back online in seconds.

### Running Sia on a NAS

Two years ago, I wrote a tutorial for running Sia from a Synology NAS. I've kept this tutorial up to date for every version of Sia since then, and now I've updated it to use my pre-built Sia Docker image:

* [Running Sia on a Synology NAS via Docker](https://mtlynch.io/sia-via-docker/)

## Source code

The Sia Docker image is fully open-source and available under the MIT license. The images are built publicly on Docker Hub so you can verify their security and integrity:

* [Github](https://github.com/mtlynch/docker-sia)
* [Docker Hub](https://hub.docker.com/r/mtlynch/sia/)