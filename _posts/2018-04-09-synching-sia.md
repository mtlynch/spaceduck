---
title: Syncing Sia in 73 minutes
layout: post
date: "2018-04-09"
description: "An experiment to see how fast I can perform the initial Sia blockchain sync"
tags:
- sia
- blockchain
- benchmark
permalink: "/sia-sync-73-min/"
---

*This is a guest post by Sia community contributor [Thomas Bennett](https://github.com/tbenz9).*

I can sync Sia from a block height of 0 to 149000 in 73 minutes.  Here’s how I do it.

## Zero subscribers

As mentioned in my previous article [Benchmarking Sia’s Blockchain Sync](https://blog.spaceduck.io/sia-blockchain-sync/) Sia spends an average of 55 minutes or 19.1% of its time notifying subscribers.  I submitted the pull request [#2809](https://github.com/NebulousLabs/Sia/pull/2809) so Sia only notifies subscribers if there are any.  By running Sia with only the `consensus` and `gateway` modules loaded there will be zero subscribers.

My `siad` command with minimal modules loaded.
```Shell
./siad -M cg -d /root/Sia/
```

With zero subscribers Sia skips the notify subscribers functions and shaves 55 minutes off the synchronization time.  Note that with only the `consensus` and `gateway` modules loaded you cannot rent, host, or use the Sia wallet.

## Reduce RPC Timeouts

Sia has long timeouts when waiting for blocks to download.  I’ve submitted the pull request [#2922](https://github.com/NebulousLabs/Sia/pull/2922) to reduce some of the long timeouts.  In order to sync in 73 minutes, I dropped the timeouts in [syncronize.go](https://github.com/NebulousLabs/Sia/blob/master/modules/consensus/synchronize.go) **WAY** down.  I first tried setting `relayHeaderTimeout`, `sendBlkTimeout` and `sendBlocksTimeout` to 2 seconds, this was too low, I was timing out on all my peers and couldn’t download any blocks.  After bumping `sendBlkTimeout` and `sendBlocksTimeout` to 10 seconds I was able to stay connected to most peers and download the blocks very quickly.  Any peers that could not deliver my batch of 10 blocks in 10 seconds or less was disconnected and Sia would look for new peers.

Note that 10-second timeouts are not very friendly to the Sia network and 10 seconds is not feasible for users with slower internet connections.  For example, the average Tor user or 3rd world Internet user would not be able to sync Sia with `sendBlocksTimeout` set to 10 seconds.  For this reason, the default `sendBlocksTimeout` in my pull request has been set at 180 seconds to allow for users with slower internet connections.  The Sia devs and I think this is a good balance of accommodating users with slower connections, while not wasting too much time waiting for unresponsive peers.

My 73-minute sync only spent 168 seconds downloading blocks from peers.  This number is actually slightly confusing to me since if Sia downloaded 10GB of blocks it exceeded my advertised home internet speed.  A couple of things could have happened here:
The downloaded blocks could be less than 10GB in size when sent over the Internet, I never measured how much data I actually received from my NIC.
I could have a mistake in my timing function causing the elapsed download time to be reported wrong.
My ISP could allow me to burst into higher speed tiers during low network congestion.

Regardless of why my download speed seems off, I was able to sync from block 0 to current height in 73 minutes.

The timeouts I set in `synchronize.go` for my 73-minute sync.
```Go
        // relayHeaderTimeout is the timeout for the RelayHeader RPC.
        relayHeaderTimeout = build.Select(build.Var{
                Standard: 10 * time.Second,
                Dev:      20 * time.Second,
                Testing:  3 * time.Second,
        }).(time.Duration)

        // sendBlkTimeout is the timeout for the SendBlocks RPC.
        sendBlkTimeout = build.Select(build.Var{
                Standard: 10 * time.Second,
                Dev:      30 * time.Second,
                Testing:  4 * time.Second,
        }).(time.Duration)

        // sendBlocksTimeout is the timeout for the SendBlocks RPC.
        sendBlocksTimeout = build.Select(build.Var{
                Standard: 10 * time.Second,
                Dev:      40 * time.Second,
                Testing:  5 * time.Second,
        }).(time.Duration)

```Go

## Sync to a RAMDisk

Validating and Applying the transactions in Sia’s blockchain is a very I/O intensive process. To reduce the amount of time spent doing this I/O I created a 11GB RAMDisk and synced the blockchain to the RAMDisk.

Command to create an 11 GB RAMDisk and mount it at `Sia/consensus`.
```Shell
root@v132:~# mount -t tmpfs -o size=11000m tmpfs Sia/consensus/
root@v132:~# df -h
Filesystem                        Size  Used Avail Use% Mounted on
/dev/mapper/pve-vm--200--disk--1   32G  2.1G   28G   7% /
none                              492K     0  492K   0% /dev
tmpfs                              32G     0   32G   0% /dev/shm
tmpfs                              32G  8.2M   32G   1% /run
tmpfs                             5.0M     0  5.0M   0% /run/lock
tmpfs                              32G     0   32G   0% /sys/fs/cgroup
tmpfs                              11G     0   11G   0% /root/Sia/consensus
```

A RAMDisk has very fast I/O but is not persistent across reboots.  Most users are going to want to copy the `consensus.db` file to persistent storage after the sync is done.

## Future optimizations

### Increased batch size

Sia downloads blocks in batches of 10. That means Sia requests blocks at least 14,800 times for a full blockchain sync. I believe Sia could request blocks in batches of 25, or even 100 and reduce some of the overhead from making so many requests. I proposed that the devs raise the batch number to 25 but my proposal was denied. You can read the discussion and compelling arguments from both sides in my pull request [#2922](https://github.com/NebulousLabs/Sia/pull/2922).

### A consensus overhaul

Many optimizations such as parallel block downloads, smarter timeouts, I/O buffering, and header-first block retrieval could be added with a consensus package overhaul.  I don’t believe this is the best use of time for the limited dev resources Nebulous currently has, but I do believe an overhaul will be necessary if Sia and its blockchain continue to grow.

Concerns about the blockchain size and performance have been brought up several times, and the Sia devs have several ideas on how to support a large blockchain.  You can read some of the discussion on GitHub in issue [#2897](https://github.com/NebulousLabs/Sia/issues/2897).

## A 73-minute sync is mostly academic

The reality is that most users are not going to be able to synchronize the blockchain in 73 minutes.  I challenged myself to see how fast I was able to do a full sync, and 73 minutes was the number I got.  Most users aren’t going to want to run Sia with so few modules loaded, or modify the source code and recompile.  Most users aren’t going to have an extra 11GB of RAM lying around to create a RAMDisk, and most users aren’t going to have 200+Mbps Internet connections.

However, some users may be interested in a subset of the optimizations mentioned, perhaps they already run a custom version of Sia and can improve their performance with lower timeouts, or some users have lots of RAM, but are bottlenecked by the I/O performance of their hard drive.

An excerpt from my `consensus.log` file showing Sia startup, and IBD (Initial Blockchain Download) complete 73 minutes later with the elapsed time in seconds spent on each step.  Link to [full log](https://gist.github.com/tbenz9/6130ca40b94c6550b62b2ba65a7d77c8).
```Shell
2018/04/05 20:11:41.546036 persist.go:73: STARTUP: Logging has started. Siad Version 1.3.2
2018/04/05 20:11:49.321247 accept.go:275: Height 1000 at 1522959109
… TRUNCATED
2018/04/05 21:23:39.602232 accept.go:275: Height 148000 at 1522963419
2018/04/05 21:23:39.602263 accept.go:276: Download time: 168.738052889
2018/04/05 21:23:39.602270 accept.go:277: Validate time: 2631.783831114
2018/04/05 21:23:39.602274 accept.go:278: Apply time: 250.713886247
2018/04/05 21:23:39.602278 accept.go:279: Subscribers time: 0.01789937
… TRUNCATED
2018/04/05 21:24:57.406911 synchronize.go:642: INFO: IBD done, synced with 6 peers
```

If you’re frustrated with the Sia’s initial synchronization time I recommend you look into [bootstrapping the blockchain](Link to siasetup bootstrap).  Bootstrapping means you download a snapshot of the `consensus.db` file then only have to sync since the snapshot was taken.  Bootstrapping requires you to trust the person you download the `consensus.db` file from, but is undoubtedly the fastest method of syncing the Sia blockchain.

## About the author

**Thomas Bennett** is a Linux System Engineer with an interest in distributed systems, high-performance computing, and massive parallel storage systems. He has been involved in the Sia community for the last 9 months and is excited to see what Sia has to offer in the coming year.
If you enjoyed this article and would like to see more from Thomas, feel free to send a little Siacoin to his donation address below.
* Siacoin donations (Thomas Bennett)
 * `f63f6c5663efd3dcee50eb28ba520661b1cd68c3fe3e09bb16355d0c11523eebef454689d8cf`


