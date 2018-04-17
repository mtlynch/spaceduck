---
title: Benchmarking Sia's Blockchain Sync
comments: true
layout: post
date: "2018-04-05"
description: "An investigation into the bottlenecks of Sia's blockchain sync and how to eliminate them."
tags:
- sia
- benchmark
image: "/images/2018-04-05-sia-blockchain-sync/default-configuration-pie.png"
---

*This is a guest post by Sia community contributor [Thomas Bennett](https://github.com/tbenz9).*

Synchronizing the Sia blockchain takes a long time and is required for using the Sia wallet, hosting, or renting space on the Sia network.

I was frustrated with how long the initial sync was taking so I decided to look into what Sia was doing during that time, and what I can do to reduce initial sync time.

## The blockchain is big and getting bigger

Every Siacoin, Siafund, smart contract, and storage proof transaction is stored on the Sia blockchain and in your local `consensus.db` file. Add all these transactions together and you're looking at over 8,000,000 transactions stored as of March 2018.

{% include image.html file="total-transactions.png" alt="total transactions graph" fig_caption="Total historic Sia blockchain transactions &#40;Source&#58; SiaStats.info&#41;" img_link="true" %}

When you perform the initial sync, Sia downloads every block (over 146,000 at the time of this writing) from its peers and adds them to the local `consensus.db` file. Before adding it to your `consensus.db` file Sia performs a variety of actions on every block. The workflow looks something like this:

1. Download block
1. Validate block header and metadata
1. Validate every transaction in block
1. Write every transaction to `consensus.db`
1. Notify Sia subscribers
1. Repeat steps 1-5 another 146,000+ times until the blockchain is fully synced.

Sia downloads blocks in batches of 10, but it needs to process and validate every transaction within the block in sequential order because future transactions depend on previous ones.

I was frustrated with how long the initial sync took, so I started to do some rough benchmarking and made some interesting discoveries.

{% include image.html file="default-configuration-pie.png" alt="time-spent-on-each-task-pie-chart" fig_caption="Percent time spent on each task" img_link="true" %}

## Downloading blocks

My benchmarking revealed that with default Sia settings it took an average of 167 minutes to download the blocks, that’s 54.91% of the average 309 minutes it took to sync from block 0 to block 146,000. Assuming 10GB of blocks are downloaded that’s an average of 7.98Mb/s throughput. I believe the download portion takes so long for a variety of reasons:

* Sia depends on its peers' upload bandwidth.
  * Some peers may have poor upload bandwidth, not much I can do about that.
* Sia has long timeouts.
  * Sia waits for up to five minutes for a peer to send a batch of 10 blocks. If the peer doesn't send these blocks, Sia sits idle for 5 minutes. This appears to have happened several times during the sync.
* Sia downloads in small batches
  * Sia downloads bocks in batches of 10. That means Sia requests blocks at least 14,600 times for a full blockchain sync. I believe Sia could request blocks in batches of 100, or even 1,000 and reduce some of the overhead from making so many requests.

{% include image.html file="blockchain-size.png" alt="Sia blockchain size graph" fig_caption="Sia blockchain growth over time &#40;Source&#58; SiaStats.info&#41;" img_link="true" %}

## Validate every transaction in block

Sia validates every transaction in every block in sequential order because each transaction depends on past transactions.

Validations are typically sanity checks. For example, a transaction might say wallet A sent 10 Siacoins to wallet B. Before Sia marks such a transaction as valid, it checks if wallet A had a balance of 10 or more Siacoins prior to the transaction.

Validating the transactions in my tests took an average of 41 minutes or 14.11% of the total sync time. This process is very I/O intensive, and I believe I was helped significantly by my super-fast NVMe SSD. I expect a user running the sync on a more traditional HDD or thumb-drive (not recommended) might spend significantly more time in the validation step.

## Apply block to consensus.db

Before running my benchmarks I was under the impression that applying the blocks took the most time. I found this to be untrue.

Applying blocks to the `consensus.db` took an average of 4 minutes or 1.35% of the total time for the sync. Writing out the `consensus.db` file is not the slow part of the sync, but this may depend on your storage hardware. The speed of my SSD probably reduced the time Sia spent writing to disk.

## Notifying subscribers

When Sia downloads a new block, the consensus module advertises that change to its "subscribers."  Different Sia modules can subscribe to each other to stay up to date.  For example, the wallet module subscribes to the consensus module to stay current with the latest transactions.

Updating subscribers is not strictly required when doing the initial blockchain sync, and it takes a lot of processing power and time. In my tests updating subscribers took an average of 55 minutes or 19.06% of the total time.

I have not identified exactly why updating subscribers takes so long, but in every case, it took at least 17 seconds per 1,000 blocks.

## Everything else

31 minutes or 10.57% of the time was spent doing other tasks that my tests did not specifically benchmark. This includes tasks such as validating the headers, error checking, moving between functions in the code, logging, etc.

While 10.57% is a significant portion of the time, it accounts for thousands of lines of code. As far as I can tell, most of this cannot be avoided or easily optimized.

## Timing the synchronization

To gather these measurements, I instrumented the code by adding a new function to the consensus module named `timeTrack`. This function measured how long sections of code took to run. `timeTrack` simply accepts a `start` time and calculates the elapsed time between `start` and `time.Now()`. By calling `timeTrack` at different places around the consensus module I was able to calculate an elapsed time for the major pieces of code executed during an initial Sia synchronization.

You can check out my custom Sia code, including the `timeTrack` function [here](https://github.com/NebulousLabs/Sia/compare/4df5b2e019f760d35461bd90104abd7c2715d8a3...tbenz9:sync-benchmark?expand=0).

The numbers I used represent an average of three tests. I ran these tests at different times of the day, throughout the week, with a standard Sia configuration.

| Test | Downloading blocks (s) | Validating transactions (s) | Applying transactions (s) | Notifying subscribers (s) | Everything else (s) | Total Time (s) |
|------|------------------------|-----------------------------|---------------------------|--------------------------|---------------------|----------------|
| Test 1 | 4887 | 2455 | 234 | 3390 | 1708 | 12674 |
| Test 2 | 15188 | 2458 | 237 | 3159 | 1952 | 22994 |
| Test 3 | 12028 | 2457 | 235 | 3339 | 1947 | 20006 |
| **Average (s)** | **10701** | **2457** | **235** | **3296** | **1869** | **18558** |
| **Average (m)** | **178** | **41** | **4** | **55** | **31** | **309** |

For full test results and timestamps, please check out my [Google Spreadsheet](https://docs.google.com/spreadsheets/d/1p2VojXu4NXIwKQ-QbPdZq8JprvL_lOZpRG5hrbFDhKw/edit?usp=sharing).

### My test environment

* OS: Ubuntu 16.04 LXC Container
* CPU: Intel Xeon D-1521 @ 2.4GHz
* RAM: 4 GB
* Network: Comcast residential 250Mbps Down. 10Mbps Up.
* SSD: Samsung 960 NVMe M.2 512GB

## About the author

**Thomas Bennett** is a Linux System Engineer with an interest in distributed systems, high-performance computing, and massive parallel storage systems. He has been involved in the Sia community for the last 9 months and is excited to see what Sia has to offer in the coming year.

If you enjoyed this article and would like to see more from Thomas, feel free to send a little Siacoin to his donation address below.

* Siacoin donations (Thomas Bennett)
  * `f63f6c5663efd3dcee50eb28ba520661b1cd68c3fe3e09bb16355d0c11523eebef454689d8cf`
