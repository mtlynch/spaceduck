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

For the past three months, I performed various load tests on Sia and published a report after each to describe the results. I completed my test plan, but now I'd like to look back on the tests at a high level to share what I learned about Sia and how to test it.

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
* Internet connection: Verizon FiOS home - 940 Mbps download / 880 Mbps upload

## What I learned about Sia

### Sia is robust

I've been using Sia for almost two years now. I like to push Sia's limits and run it under weird scenarios, which means I've seen a lot of Sia crashes over the years.

Sia didn't crash once during these tests. Cumulatively, Sia ran for 48.6 days and processed 91,536 files without a single crash.

I still see users report crashes on versions 1.3.1 and 1.3.2. Anecdotally, the crashes seem to be mostly related to Sia exhausting memory. In this load test, Sia was running on a system with 32 GB of RAM, so RAM was harder to exhaust. In addition, the test automation kept Sia limited to a maximum of five simultaneous uploads, which may have kept memory demands in check.

### Storage isn't that cheap

Sia has always listed low storage costs as one of their competitive advantages.  A 50% reduction is significant, but it's not close to Sia's frequently cited claim of "90% less than incumbent cloud storage providers."

I found that in practice, after taking into account fees and extra costs from replication, Sia remains low-cost, but the savings are not as dramatic as advertised.

The test with the best cost efficiency was the real data test, which achieved $4.51 per TB/month. This is certainly lower than Amazon S3's standard storage class ($23 per TB/month), but the comparison to S3 isn't quite realistic. AWS doesn't have an offering that's similar to Sia in performance. Standard S3 is much more performant than Sia, whereas Amazon Glacier is much less performant. Neither comparison quite works.

Google Cloud Storage's (GCS) nearline storage class is probably the closest comparison in terms of performance. It's $10 per TB/month. Further, there are low-cost centralized providers like Backblaze and [Wasabi](https://wasabi.com/) that offer storage for $5 per TB/month.

|                                                                          | Sia | Amazon S3<br>(Standard) | GCS Nearline | Azure | Backblaze B2 |
|-----------------------------------------|-----|---------------------------|-------------------|--------|------------------|
| Storage cost<br>(per TB per month) | $4-5 | $23 | $10 | $18.40 | $5 |

I'm excluding some costs for this comparison that I consider negligible:

* I exclude the frictional costs involved in acquiring Siacoin. To use Sia, the user must convert fiat currency to a mainstream cryptocurrency such as Bitcoin or Ethereum, then trade that cryptocurrency for Siacoin. Each conversion and coin transfer incurs a small frictional cost.
* For traditional storage providers, I'm neglecting per-request costs, which some providers charge, but generally account for \<1% of costs in normal usage.

### Upload bandwidth is inexpensive

One surprising result was how inexpensive upload bandwidth was. For the real data and best-case tests, upload bandwidth was around $0.40-$0.70 per TB of file data uploaded (I'll explain the inexact numbers [below](#cost-accounting-is-unreliable)).

This isn't exciting in itself because cloud providers typically charge zero for inbound data transfers. It does, however, bode well for download bandwidth costs. I didn't measure downloads in this test, but if they're within even an order of magnitude of upload bandwidth, it would give Sia a huge price advantage over traditional storage providers:

|                                                                          | Amazon S3<br>(Standard) | GCS Nearline | Azure | Backblaze B2 |
|-----------------------------------------|---------------------------|-------------------|--------|------------------|
| Download cost<br>(per TB) | $90 | $130 | $90 | $10 |

### Cost accounting is unreliable

Sia reports its spending through both its [`renter`](https://github.com/NebulousLabs/Sia/blob/master/doc/API.md#renter) and its [`wallet`](https://github.com/NebulousLabs/Sia/blob/master/doc/API.md#wallet) APIs. Unfortunately, they [contradict each other](https://github.com/NebulousLabs/Sia/issues/2772).

| Test case | Spending according to `/renter/contracts` | Spending according to `/wallet` | Discrepancy |
|-------------|-----------------------------------------------------|----------------------------------------|--------|
| [Worst-case](/load-test-1) | 2,966.7 SC | 5,000.0 SC | 2033.3 SC |
| [Real data](/load-test-2) | 2,866.7 SC | 5,000.0  SC | 2,133.3 SC |
| [Best-case](/load-test-3) | 2,833.3 SC | 3,200.0 SC | 366.7 SC |

For the purposes of my reports, I treated the `wallet` API as the ground truth for spending.

Sia also reports spending metrics that are [logically impossible](https://github.com/NebulousLabs/Sia/issues/2768). In each of the tests, Sia's accounting showed increases and *decreases* in total storage spending over time. Decreases in total storage spending shouldn't be possible. When Sia spends money on a storage contract, the expenditure is permanent so total spending can never decrease.

### Cost estimates are wildly inaccurate

Sia offers a [`/renter/prices` API](https://github.com/NebulousLabs/Sia/blob/master/doc/api/Renter.md#json-response-4) that Sia-UI and command-line client rely on to provide cost estimates before you store your data on Sia.

Because of Sia's errors in accounting, I treated the wallet's remaining balance as the ground-truth measure of how much Sia spent in contracts and scaled by a constant factor.

#### Real data scenario

| Cost    | Advertised | Actual (corrected accounting)\* | % difference from advertised cost |
|--|----------------|--------------------------------------------------|---------------------------------|----|
| Upload (SC/TB) | 27.7 | 35.2 | +27.4% |
| Storage (SC/TB/month) | 96.5 | 203.5 | +110.8% |
| Contract fees (SC) | 56.2 | 1,117.3 | +1,888.1% |

\* Scaling Sia's reported costs by 1.74x to correct for accounting bugs.

#### Best-case scenario

| Cost    | Advertised | Actual (corrected accounting)\* | % difference from advertised cost |
|--|----------------|--------------------------------------------------|---------------------------------|----|
| Upload (SC/TB) | 37.1 | 53.1 | +43.2% |
| Storage (SC/TB/month) | 99.1 | 188.2 | +90.0% |
| Contract fees (SC) | 70.0 | 710.0 | +914.9% |

\* Scaling Sia's reported costs by 1.13x to correct for accounting bugs.

I've omitted the worst-case scenario from this comparison because the numbers are so high that they're meaningless.

Sia-UI has a separate price estimation bug that exacerbates the incorrect estimates, but ironically, this additional bug makes Sia's estimates more accurate.  Sia-UI uses the overly optimistic pricesthe incorrect prices from the `/renter/prices` API and performs an incorrect calculation as [Sia-UI uses API prices incorrectly](https://github.com/NebulousLabs/Sia-UI/issues/775).

### Costs are complex and unpredictable

In addition to Sia's inaccurate estimates, Sia's costs are so complex and depend on so many unknown factors that it's impossible to predict Sia's costs in advance.

To explain, I'll compare the costs of a simple scenario on traditional providers, then attempt to calculate the cost of the same scenario on Sia.

Scenario: Upload 1 TB of files at the beginning of a storage period, download at the end.

On storage providers like S3 or GCS, you could predict the costs pretty accurately with the following formula:

```text
total_cost = (file_size * upload_cost) +
             (file_size * storage_cost) +
             (file_size * download_cost)
```

Again, I'm neglecting per-request costs and maybe a few other minor costs, but that formula would probably get you to within 5% of your actual bill. All variables are known a priori.

Now I'll try to create a formula for Sia:

```text
contract_size = file_size * (1 / storage_efficiency)
total_cost = (contract_size * upload_cost) +
             (contract_size * storage_cost) +
             (file_size * download_cost) +
             ((contract_count + contract_renewals) * contract_fee)
```

Already, it's much more complex a formula than with traditional providers. But the worst part is that the user doesn't know any of the values of these variables ahead of time. There are nine different variables in that formula. The only one that the user knows in advance is `file_size`.

Storage efficiency depends on the degree of replication (by default, 3x), the distribution of file sizes in your data, and how stable your hosts are.


### Fees represent a high proportion of cost

Before I ran this test, I assumed Sia's fees were pretty small.

When you use Sia-UI to set a storage allowance, it shows fees as . As explained [above](#cost-estimates-are-wildly-inaccurate), fees are the cost for which Sia makes the poorest predictions. In these tests, fees were 10-20x more than what Sia's price API predicted.

I'm using Sia's 

| Test case | Fee spending (incorrect accounting) | Total spending (incorrect accounting) | Fees as % of total spending |
|-------------|-----------------|----------------|--------|
| [Worst-case](/load-test-1) | 697.6 SC | 1,593.1 SC | 43.8% |
| [Real data](/load-test-2) | 640.6 SC | 2,243.8 SC | 28.5% |
| [Best-case](/load-test-3) | 628.6 SC | 1,473.3 SC | 42.7% |

### Fees are variable, not fixed

I thought that contract fees were independent of the value of the contract. With Bitcoin, a 1 BTC transaction costs the same in fees as a 10 BTC transaction. So I assumed that a 500 SC Sia renter allowance would cost the same in fees as a 5000 SC allowance.  This is what both Sia-UI and the `/renter/prices` API claim: you pay the same flat fee regardless of allowance amount. This is not the case.

Before I began official testing, I did an practice run of my test script [using a 500 SC wallet](https://redd.it/7y3lzg). When I began official testing with a 5000 SC wallet, I was surprised to see Sia spend almost four times the contract fees as my 500 SC test.

As the test progresses, Sia's accounting becomes unreliable (described [above](#cost-accounting-is-unreliable)), but at the very beginning of the renter period when Sia forms its initial set of 50 contracts, its accounting is consistent.

Comparing the 500 SC test to the 5000 SC test, there are clearly big differences, both in absolute fee costs and in fees as percentage of total spending.

| Allowance | Contract fees<br>(contract creation time) | Total contract spending<br>(contract creation time) | Fees as % of contract costs |
|-----------|-----|-------------|----------------------------|
| 500 SC | 122.5 SC | 166.7 SC | 73.5% |
| 5000 SC | 454.4 SC | 1666.7 |  27.3% |

### Contract spending is unintuitive

This test showed me that my mental model of Sia's contract management was incorrect. I thought that Sia purchased 50 contracts for the duration of the contract period (12 weeks, in the load test), and then used these 50 contracts until they funds associated with them were exhausted or the associated hosts went offline.

This is not how Sia manages contracts. I don't fully understand what Sia's contract logic is, and I don't see the behavior documented anywhere, but I can glean a bit from the test results.

Sia seems to optimize for performance instead of costs. When I set an allowance of 5000 SC, it doesn't spend 5000 SC on contracts. Instead, it spends 1/3 of this on contracts and keeps the remaining 2/3 as reserves to reinvest in contracts that perform well.

When Sia finds a host that performs well, it purchases additional contracts from that host [well before its other contracts are exhausted](https://github.com/NebulousLabs/Sia/issues/2769). Sia represents this as reinvestment, so the contract count doesn't increase, but Sia pays the same amount in fees as if it had purchased a new, separate contract.

Sia always buys contracts in increments of 1/150th of the allowance. Even if it has reinvested in a contract five times, it keeps reinvesting tiny amounts rather than increasing the spending amount to reduce the percentage lost to fees.

Uploads with too high a redundancy.

* Misconception 2: Contract fees are paid once at the start of a contract period and not paid again until the contract completes.

I thought that fees 
Increase with the amount of data uploaded, increase with the size of the allowance.

### File replication is bizzare

First, a bit of background on how Sia's replication works. Sia stores files redundantly with a 10 of 30 [Reed-Solomon encoding](https://en.wikipedia.org/wiki/Reed%E2%80%93Solomon_error_correction). More specifically, it divides each file into chunks of ~40 MiB, then splits each of those chunks into 30 fragments of ~4 MiB each. Sia can reconstruct the original data chunk using any 10 of those 30 fragment. Sia uploads each fragment to a different host so that if the host disappears, Sia can still recover the file from the remaining 29 hosts.

Both Sia-UI and Sia's command-line interface display a "Redundancy" value for each file in terms of a multiplier, like 3x or 3.5x. This multiplier is simply the number of total file fragments uploaded divided by the number of fragments needed to reconstruct the file. A healthy file has a multiplier of 30/10=3.0x. If two of the hosts holding fragments go offline, the redundancy will drop to (30-2)/10=2.8x. The redundancy can increase above 3.0x if a host goes offline, then Sia re-uploads its fragment to a new, healthy host, then the original host comes back online. That would result in a redundancy of 31/10=3.1x.

I calculated aggregate statistics on each file's redundancy in each of the test cases and found inexplicable numbers:

| Test case | Min Redundancy | Max Redundancy | Median Redundancy | Mean Redundancy |
|------------ |------|-------|----------|---------|
| [Worst-case](/load-test-1) | 3.0x | 11.3x | 5.3x | 5.2x |
| [Real data](/load-test-2) | 0.0x | 5.2x | 2.5x | 2.5x |
| [Best-case](/load-test-3) | 3.0x | 7.3x | 4.1x | 4.0x |

The craziest number is the 11.3x redundancy in the worst-case test. It means that Sia went through the process I described above where a host goes offline, Sia redistributes its fragment to a new host, then the original host comes back online. Except an 11.3x redundancy means this happened **83 times**. That test only had contracts with 60 hosts, so going through this process 83 times seems illogical.

I [filed a bug](https://github.com/NebulousLabs/Sia/issues/2813), which the dev team resolved with this note:

>Starting from 1.3.2 Sia will only count healthy renewable contracts towards file redundancy. That way we should never see a >3x redundancy for files uploaded with 1.3.2 or higher.

This perhaps prevents users from being confused, but unfortunately doesn't address the root cause: how could replication have reached such absurdly high levels in the first place?

The real data case shows suspiciously *low* redundancy. I would expect a handful of files to drop below 3.0x redundancy from time to time, but in that test, the median redundancy was 2.5x. This means that most files were in an unhealthy state and hadn't yet been repaired despite the fact that there were plenty of unspent funds in existing contracts.

## Improving load tests

This series of tests was the first rigorous, public test of Sia's performance. It yielded many interesting findings, but because it was the first test of its kind, there were many shortcomings I didn't anticipate when I designed it.

Having gone through the testing process end-to-end, I'd like to share some thoughts on how the Sia community can improve future testing.

### Run on a cloud server

I originally designed the tests to run on my home desktop because I wanted to minimize emulation. I was concerned that running the test from a Docker container or VM might introduce unexpected side effects to the test. 

I also wanted to test Sia with actual data instead of synthetic files. That presents challenges in a cloud environment. For example, storing 5 TB of test data on Google Cloud Storage would cost $102.40 per month. And then if I used Google Compute Engine to run the test, I'd pay ~$100 for each TB of data uploaded to Sia.

Having run the tests on my personal infrastructure, I realize that my personal infrastructure has its own signicant drawbacks. I only have a single desktop, which meant that I had to run the tests serially rather than in parallel, which substantially increased the total duration of these tests. It also meant that my computer usage unrelated to Sia potentially affected the tests. Notably, in test #3, my desktop crashed and caused a stark change in Sia's behavior.

In retrospect, I think that the costs outweigh the benefits. I recommend that researchers interested in carrying these tests forward run tests from a cloud VPS provider that offers unmetered network bandwidth.

The problem is that thes providers generally don't provide options for local disks above 1 TB. To work around this, I've added a `--dataset_copies` flag to sia_load_tester. Using this flag, the test oprator can tell Sia to cycle through the input files N times. So if you have 50 GiB of files, you can specify `--dataset_copies=205` so that sia_load_tester reuploads that set of files 205x to simulate 10 TiB of input data.

### Bandwidth is a first-class citizen

The biggest metric I failed to account for was bandwidth. I knew I'd be running on my home infrastructure where my ISP does not guarantee me a particular bandwidth and I'm also doing other stuff at the same time like watching streaming 4K video, which would affect Sia's available bandwidth.

Having run the tests, I see that bandwidth matters a great deal.

### Set more realistic bandwidth minimums

I set the minimum bandwidth to 3 Mbps, which is far too low. I also based the minimum on absolute file bandwidth instead of file data bandwidth. In other words, the test considers Sia to be making useful progress even if it does nothing but upload the same file over and over again until it's at 11x redundancy.

I propose that a more realistic minimum is 50 Mbps of file data bandwidth averaged over the last 24 hours (equivalent to uploading ~500 GiB per day).

### Increase  file sizes for best-case scenario

One of the surprising outcomes of the load test was that the real data scenario outperformed the worst-case scenario.

Due to the previous point about bandwidth, Sia performs much better with a small set of very large files as opposed to a large set of ~40 MiB files. A better representation of Sia's best-case performance would use files that are ~20 GiB each (or, more precisely, 21474693120 bytes so that they're exactly 512x Sia's chunk size).

### Increase file sizes for worst-case scenario

I want to take a moment to emphasize the importance of this test.

I'm stuck either spending months implementing my own file-repacking layer or explaining to my users why I'm charging them $350M per TB/month for text files, but only $4.50 per TB/month for large video files.

You could build a file-repacking layer on top of it.

https://therub.org/2015/11/18/glacier-costlier-than-s3-for-small-files/

### Automate, automate, automate

This test needs to be as automatic as possible. The more that's automated, the less margin there is for human error and the easier it is for different researchers to reproduce results.

I tried to automate as much as possible, but it's hard to know what needs automating until you actually follow a process end-to-end. There are two key parts that require more automation: provisining and analysis.

By provisioning, I mean:

  * Installing Sia
  * Installing test tools
  * Funding the Sia wallet
  * Generating dummy data

I performed these steps manually for each test and documented the commands in the sia_load_tester README, but it would be better to capture this logic in a single script or Ansible playbook (using ansible-role-sia, of course).

The analysis stage needs better automation for:

* Creating data visualizations from sia_metrics_collector's output
* Calculating relevant metrics ($/TB, price estimate accuracy, etc.) from the outputs of sia_load_tester and sia_metrics_collector.

For the load test, I created a [Google Sheets template](https://docs.google.com/spreadsheets/d/1ep-m_2K5hY9nF_D4TgKyGpp9arB6F3xPA7PJwQnskeg/edit?usp=sharing) to calculate these metrics and create visualizations. This was an okay v1 solution, but is not a good long term solution because it requires the test operator to do a lot of ad-hoc calculations and manually manually upload CSVs to Sheets any time they want to check progress.

A better solution would be a web app that runs on the test system so that the test operator can view test progress and results through a browser.

## Why I'm not continuing to test Sia

I originally conceived of these tests because I was considering building a software company on top of Sia. I couldn't decide whether any of my business ideas were feasible without hard data about Sia's capabilities.

I wanted to demonstrate that these metrics are valuable. I'd go so far as to say that this type of measurement is *necessary* if Sia hopes to move from enthusiasts to production usage by real businesses.

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