---
title: Sia Load Test Wrap-up
comments: true
hide_description: true
layout: post
date: '2018-04-19'
description: A high-level review of the Sia load test results
tags:
- sia
- load test
permalink: "/load-test-wrapup/"
---

## Result summary

| Metric | [Worst-case](/load-test-1) | [Real data](/load-test-2) | [Best-case](/load-test-3) |
|---------|---------|------------|
| Total uploaded ([file bytes](/load-test-1/#file-bytes-vs-absolute-bytes)) | 47.2 KiB |  4.3 TiB | 1.5 TiB |
| Total uploaded ([absolute bytes](/load-test-1/#file-bytes-vs-absolute-bytes)) | 9.8 TiB | 15.4 TiB | 7.2 TiB |
| Storage efficiency | 0.0000004470% | 28.3% | 21.5% |
| Total files uploaded | 48,358 |  2,626 | 40,552 |
| Total file contracts created | 60 | 62 | 68 |
| Total spent | 3625 SC<br />$50.75\* USD | 4377.1 SC<br />$61.07\* USD | 1,840 SC<br />$25.21\* USD |
| $ per TB/month\*\* | $350 million |  $4.51 | $5.13 |
| Total test time | 596.8 hours<br />(24.9 days) | 231.7 hours<br />(9.7 days) | 336.0 hours<br />(14.0 days)|
| Average upload bandwidth ([file data](/load-test-1/#file-data-bandwidth-vs-absolute-bandwidth)) | 0.00000018 Mbps |  45.8 Mbps | 11.2 Mbps |
| Average upload bandwidth ([absolute](/load-test-1/#file-data-bandwidth-vs-absolute-bandwidth)) | 40.3 Mbps |  162.1 Mbps | 52.2 Mbps |
| Sia crashes | 0 | 0 | 0 |

\* Based on Siacoin value at test start. Assumes that unused renter funds will successfully return to the test wallet at the conclusion of the renter contracts.

\*\*Assumes that a standard renter contract lasts 2.77 months. Excludes bandwidth costs. Includes all fees.

## Test environment

* Sia version: 1.3.1
* OS: Windows 10 x64
* CPU: Intel i7-5820K @ 3.3 GHz
* RAM: 32 GB
* Local disk (for Sia metadata): 512 GB SSD
* Network storage (for input files): Synology DS412+ (4 TB free)
* Internet connection: Verizon FiOS home (940 Mbps download / 880 Mbps upload)

## What I learned about Sia

### Sia is robust

Having used Sia for almost two years and seeing my fair share of Sia crashes in earlier versions, I was impressed that Sia never crashed. Anecdotally, many of the errors I see people report are due to Sia exhausting memory. My tests were less at risk of exhausting memory due to the fact that I was running on a PC with 32 GB of RAM and the test automation kept Sia limited to a maximum of five simultaneous uploads.

### Storage isn't that cheap

Sia has always listed low storage costs as one of their main advantage over competitors like Amazon S3. Once you take into account fees, 

### Upload bandwidth is inexpensive

Traditional cloud storage providers typically give away upload bandwidth for free as a way of encouraging customers to pay for services once it's uploaded. Sia charges

The more interesting test is download bandwidth. I'm assuming that contract fees stay fixed even with additional downloads. If download causes jumps in fees the same way that uploading does, then it won't be so cheap.

### Cost estimates are wildly inaccurate

Sia offers a [`/renter/prices` API](https://github.com/NebulousLabs/Sia/blob/master/doc/api/Renter.md#json-response-4) that the Sia GUI and command-line client rely on to provide cost estimates before you store your data on Sia.

Because of Sia's errors in accounting, I treated the wallet's remaining balance as the ground-truth measure of how much Sia spent in contracts and scaled by a constant factor.

#### Real data scenario

| Cost    | Advertised | Actual (corrected accounting)\* | % error in advertised cost |
|--|----------------|--------------------------------------------------|---------------------------------|----|
| Upload (SC/TB) | 27.7 | 35.2 | +27.4% |
| Storage (SC/TB/month) | 96.5 | 203.5 | +110.8% |
| Contract fees (SC) | 56.2 | 1,117.3 | +1,888.1% |

\* Scaling Sia's reported costs by 1.74x to correct for accounting bugs.

#### Best-case scenario

| Cost    | Advertised | Actual (corrected accounting)\* | % error in advertised cost |
|--|----------------|--------------------------------------------------|---------------------------------|----|
| Upload (SC/TB) | 37.1 | 53.1 | +43.2% |
| Storage (SC/TB/month) | 99.1 | 188.2 | +90.0% |
| Contract fees (SC) | 70.0 | 710.0 | +914.9% |

\* Scaling Sia's reported costs by 1.13x to correct for accounting bugs.

I've omitted the worst-case scenario from this comparison because the numbers are so high that they're meaningless.

### Costs are unpredictable

```text
total_cost = (file_size * upload_cost) +
             (file_size * storage_cost) +
             (file_size * download_cost)
```

In reality, there are some additional cost per API call, but these are negligible. I believe for a load test similar to the ones I ran on Sia, the additional costs of API calls on S3 would be a few cents. talking costs of a few cents for usage similar to my load tests.

https://therub.org/2015/11/18/glacier-costlier-than-s3-for-small-files/

```text
contract_size = file_size * (1 / storage_efficiency)
total_cost = (contract_size * upload_cost) +
             (contract_size * storage_cost) +
             (file_size * download_cost) +
             ((contract_count + contract_renewals) * contract_fee)
```

Storage efficiency depends on the degree of replication (by default, 3x), the distribution of file sizes in your data, and how stable your hosts are.

### Cost accounting is unreliable

I filed two bugs related to accounting two months ago, but neither has received a response from the dev team:

* [Sia loses funds during contract formation](https://github.com/NebulousLabs/Sia/issues/2772)
* [StorageSpending in /renter/contracts is not strictly increasing](https://github.com/NebulousLabs/Sia/issues/2768)

### Fees represent a high proportion of cost

I never looked too deeply into contract fees, but I assumed they were a small percentage of 

| Test case | Fee spending (incorrect accounting) | Total spending (incorrect accounting) | Fee % |
|-------------|-----------------|----------------|--------|
| [Worst-case](/load-test-1) | 697.6 SC | 1,593.1 SC | 43.8% |
| [Real data](/load-test-2) | 640.6 SC | 2,243.8 SC | 28.5% |
| [Best-case](/load-test-3) | 628.6 SC | 1,473.3 | 42.7% |

### Fees are variable, not fixed

Increase with the amount of data uploaded, increase with the size of the allowance.

### Contract spending is unintuitive

Uploads with too high a redundancy.

### We need a precise language for metrics



## Improving tests

### Run load tests on a cloud server

I originally designed the tests to run on my home desktop because I wanted to simulate as little as possible. The obvious alternative is a virtual cloud server, but I was concerned that virtualization might introduce unexpected side effects to the test. 

I also wanted to test Sia with actual data instead of synthetic files. That presents challenges in a cloud environment. For example, in the test case where I used XX TiB of video files, Sia uploaded XX TiB just 

Having run the tests on my personal infrastructure, I realize that my personal infrastructure has its own signicant drawbacks. I only have a single desktop, which meant that I had to run the tests serially rather than in parallel, which substantially increased the total duration of these tests. It also meant that my computer usage unrelated to Sia affected the tests. Notably, in test #3, my desktop crashed and affected test results. In other tests

In retrospect, I think that the costs outweigh the benefits. I recommend that researchers interested in measuring my 

I've adjusted sia_load_tester to make this easy. Now you can specify a `--copy_count` flag to sia_load_tester. Using this flag, you can tell Sia to cycle through the input files N times. So if you have 50 GiB of files, you can specify `--copy_count=205` so that sia_load_tester reuploads that set of files 205x to simulate 10 TiB of input data.

### Bandwidth is a first-class citizen

The biggest metric I failed to account for was bandwidth. I knew I'd be running on my home infrastructure where my ISP does not guarantee me a particular bandwidth and I'm also doing other stuff at the same time like watching streaming 4K video, which would affect Sia's available bandwidth.

Having run the tests, I see that bandwidth matters a great deal.

### Set more realistic bandwidth minimums

I set the minimum bandwidth to 3 Mbps, which is far too low. I also based the minimum on absolute file bandwidth instead of file data bandwidth. In other words, the test considers Sia to be making useful progress even if it does nothing but upload the same file over and over again until it's at 11x redundancy.

I propose that a more realistic minimum is 50 Mbps of file data bandwidth averaged over the last 24 hours (equivalent to uploading ~500 GiB per day).

### Increase  file sizes for best-case scenario

One of the surprising outcomes of the load test was that the real data scenario outperformed the worst-case scenario.

Due to the previous point about bandwidth, Sia performs much better with a small set of very large files as opposed to a large set of ~40 MiB files. A better best-case scenario would probably use files that are ~20 GiB each (512x Sia's chunk size).

### Increase file sizes for worst-case scenario

I want to take a moment to emphasize the importance of this test.

You could build a file-repacking layer on top of it.

## Why I'm not continuing to test Sia

I never intended to run these on a regular basis. I wanted to demonstrate that these metrics are valuable. I'd go so far as to say that tracking these metrics is *necessary*.

There is a group of volunteers discussing a plan for running these tests on an ongoing basis. If you're interested in helping these efforts, email me at michael@spaceduck.io and I'll put you in touch with them.

## Test plan

I performed this test according to the "Sia Load Test Plan" document that I [originally opened for feedback](https://blog.spaceduck.io/sia-load-test-preview/) on Feb. 7th, 2018 and [finalized](https://blog.spaceduck.io/files/sia-load-test-preview/load-test-plan-2018-02-14.pdf) on Feb. 14th, 2018.

I ran all tests according to the defined plan with the one exception that I added a maximum time limit of 14 days per test case. I added this condition after the first test case ran for almost 25 days without making significant upload progress.

## Test tools

All tools used during this test are open source, fully documented, and available on Github under the permissive MIT license:

* [sia_load_tester](https://github.com/mtlynch/sia_load_tester/)
* [sia_metrics_collector](https://github.com/mtlynch/sia_metrics_collector)
* [dummy_file_generator](https://github.com/mtlynch/dummy_file_generator)

## Acknowledgments

Thanks to:

* Sia bounty fund for providing the Siacoins used in these tests
* Luke Champine, James Muller, Salvador Herrera for their contributions to the test plan.
* David Vorick for providing feedback about test results.