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

## What I learned about Sia

### Sia is robust

Having used Sia for almost two years and seeing my fair share of Sia crashes in earlier versions, I was impressed that Sia 

### Storage is not that cheap

### Bandwidth is very price-competitive

### Prices are unpredictable

### Cost accounting is unreliable

### Fees represent a high proportion of cost

### Sia's contract spending is unintuitive

Uploads with too high a redundancy.

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

I set the minimum bandwidth to XX Mbps, which is far too low. I also based the minimum on absolute file bandwidth instead of file data bandwidth. In other words, the test considers Sia to be making useful progress even if it does nothing but upload the same file over and over again until it's at 11x redundancy.

I propose that a more realistic minimum is 50 Mbps of file data bandwidth averaged over the last 24 hours (equivalent to uploading ~500 GiB per day).

### Increase  file sizes for best-case scenario

One of the surprising outcomes of the load test was that the real data scenario outperformed the 

Due to the previous point about bandwidth, Sia performs much better with a small set of very large files as opposed to a large set of ~40 MiB files. A better best-case scenario would probably use files that are ~10 GiB each (256x Sia's chunk size).

### Keep testing the worst-case

I want to take a moment to emphasize the importance of this test.

You could build a file-repacking layer on top of it.

## Why I'm not continuing to test Sia

I never intended to run these on a regular basis. I wanted to demonstrate that these metrics are valuable. I'd go so far as to say that tracking these metrics is *necessary*.

## Acknowledgments

Thanks to:

* Sia bounty fund for providing the Siacoins used in these tests
* Luke Champine, James Muller, Salvador Herrera for their contributions to the test plan.
* David Vorick for providing feedback about test results.