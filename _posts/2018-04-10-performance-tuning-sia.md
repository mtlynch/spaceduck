---
title: Performance Tuning Sia's Blockchain Sync
layout: post
date: '2018-04-10'
description: "An experiment to see how fast I can perform the initial Sia blockchain sync"
tags:
- sia
- blockchain
- benchmark
---

*This is a guest post by Sia community contributor [Thomas Bennett](https://github.com/tbenz9).*

I've been frustrated with how long it takes to perform the initial Sia blockchain sync.  I decided to see how fast I could sync Sia if I tweaked the code and optimized my system for the initial sync.

Using a variety of techniques, I was able to reduce Sia's initial sync time by 76%.  Below, I'll explain how I did this and how you can apply these same techniques to speed up Sia on your own system.

## Reducing download timeouts

Sia syncs its blockchain by requesting batches of blocks from peer nodes. It uses several timeout values to decide when to give up on a peer connection and re-attempt the download from a new peer.

Ideally, Sia would use dynamic timeouts so that Sia would learn how long it takes the average peer to complete the action and adjust its expectations accordingly. On fast connections, Sia would learn to use short timeouts. On slow connections, Sia would wait longer for downloads to complete.

Currently, Sia's implementation is simpler and uses hard-coded timeouts. This means that every Sia user has to use the same timeout values regardless of their connection speed. To make Sia accessible to users with slow connections, Sia has to use slow timeouts for everyone.

I know that I have a fast connection so I tried recompiling Sia with more aggressive timeouts. I first tried reducing all sync-related timeouts to two seconds. This was too low, I was timing out on all my peers and couldn’t download any blocks.

Next, I tried [10-second timeouts](https://github.com/NebulousLabs/Sia/compare/fea834fcef00f7c0b712fd1751922bcc65623ed0...mtlynch:aggressive-timeouts?expand=1), which were successful. I was able to stay connected to most peers and download the blocks very quickly. Sia disconnected from any peers that could not deliver my batch of 10 blocks in 10 seconds or less.

## Switching to a RAMDisk

It is very disk-intensive to validate and apply the transactions in Sia’s blockchain. To reduce the amount of time spent blocked on disk I/O, I created an 11 GB RAMDisk and synced the blockchain to the RAMDisk:

```shell
# Create an 11 GB RAMDisk.
$ sudo mkdir /mnt/siatmpfs
$ sudo mount -t tmpfs -o size=11G tmpfs /mnt/siatmpfs/

# Create a symlink on local disk to the RAMDisk.
$ mkdir -p ~/sia-data/consensus
$ ln -s /mnt/siatmpfs/consensus.db ~/sia-data/consensus/consensus.db

# Start Sia using the RAMDisk for the consensus DB.
$ ./siad --sia-directory ~/sia-data
```

A RAMDisk has very fast I/O but is not persistent across reboots. After Sia completes its initial sync, you should shut down `siad`, then move the consensus database to your system's persistent disk:

```shell
# Move consensus DB to persistent disk.
$ rm ~/sia-data/consensus/consensus.db
$ mv /mnt/siatmpfs/consensus.db ~/sia-data/consensus/

# Remove RAMDisk.
$ sudo umount /mnt/siatmpfs/
```

Note that while a RAMDisk is an excellent method of improving the sync time, it requires at least 11 GB of available memory.

## Eliminating subscribers

In [my previous tests](https://blog.spaceduck.io/sia-blockchain-sync/), I found that Sia spends 19.1% of its time sending notifications across modules. After making this discovery, I submitted a [pull request](https://github.com/NebulousLabs/Sia/pull/2809) to skip the notifications step entirely when other modules are not running.

Starting with Sia v.1.3.2, you can take advantage of this optimization by performing the initial Sia sync with a minimal set of modules loaded:

```shell
./siad --modules cg
```

The command above launches Sia with only the `consensus` and `gateway` modules. With this set of modules, Sia has zero subscriber modules and thus never has to send notifications across modules. This reduced my initial sync by 55 minutes (18%).

Note that with only the `consensus` and `gateway` modules loaded you cannot rent, host, or access your wallet. When Sia finishes its initial sync, you can shut down `siad`, then reload it with your normal modules to regain normal functionality.

## Future optimizations

### Increased batch size

Sia downloads blocks in batches of 10. That means Sia requests blocks at least 14,800 times for a full blockchain sync. I believe Sia could request blocks in batches of 25, or even 100 and reduce some of the overhead from making so many requests. I proposed that the devs raise the batch number to 25, but my proposal was denied. You can read the discussion and compelling arguments from both sides in my pull request [#2922](https://github.com/NebulousLabs/Sia/pull/2922).

Note that even if I change my Sia daemon to ask for 100 blocks at a time, peer nodes will only respond with batches of 10. This is in contrast to a change like the timeout values above, where I can modify my local node without requiring any changes from any other nodes on the network.

### A consensus overhaul

Many optimizations such as parallel block downloads, smarter timeouts, I/O buffering, and header-first block retrieval could be added with a consensus package overhaul.  I don’t believe this is the best use of time for the limited dev resources Nebulous currently has, but I do believe an overhaul will be necessary if Sia and its blockchain continue to grow.

Concerns about the blockchain size and performance have been brought up several times, and the Sia devs have several ideas on how to support a large blockchain.  You can read some of the discussion on GitHub in issue [#2897](https://github.com/NebulousLabs/Sia/issues/2897).

## Raw data

* [Consensus log](https://gist.github.com/tbenz9/6130ca40b94c6550b62b2ba65a7d77c8)

## Conclusion

By reducing timeouts, disabling modules, and syncing to a RAMDisk I was able to reduce initial sync time by 76%.

While this may not be practical for the casual Sia user, it demonstrates the viability of various sync optimizations and sheds light on future opportunities to improve performance.

## About the author

**Thomas Bennett** is a Linux System Engineer with an interest in distributed systems, high-performance computing, and massive parallel storage systems. He has been involved in the Sia community for the last 9 months and is excited to see what Sia has to offer in the coming year.

If you enjoyed this article and would like to see more from Thomas, feel free to send a little Siacoin to his donation address below.

* Siacoin donations (Thomas Bennett)
  * `f63f6c5663efd3dcee50eb28ba520661b1cd68c3fe3e09bb16355d0c11523eebef454689d8cf`
