---
title: How Much Data Can You Store on Sia?
layout: post
date: '2018-02-07'
summary: A rigorous test of Sia's upload capacity.
tags:
- sia
permalink: "/sia-load-test-preview/"
comments: true
---

Sia's [first blog post of 2018](https://blog.sia.tech/sia-triannual-update-september-december-2017-8afdf9c10325) made it clear that this is the year they hope to achieve enterprise adoption:

>We want companies like Dropbox and Netflix to use Sia to store and distribute their content.
>
>-Zach Herbert, VP of Operations

Before the Dropboxes and Netflixes of the world start moving their data to Sia, the network must work at enterprise-level scale.

So how does Sia scale today? If you install Sia, how much data can you upload to the Sia network? How much does that cost?

We don't really know.

# Why don't we know Sia's capacity?

The simple answer is that nobody has tried to find out.

For the first few years of its existence, Sia has struggled with the challenge of building a decentralized storage network that functions at all. It hasn't left them much time to capture performance metrics.

In addition, testing on the production Sia network is expensive. To test, you have to make real payments to storage sellers.

Performing a single load test might cost hundreds to thousands of dollars. We don't know exactly how much it will cost, which leads to my next question...

# Why don't we know how much Sia costs?

Sia is decentralized. When clients purchase data on Sia, they're not purchasing it from a single entity, but rather from a variety of storage sellers, each with their own prices for upload, download, and storage.

The software currently doesn't offer buyers much control or visibility into costs. It allows them to specify a maximum budget, but that's about it. As a buyer, you don't know how much it will cost you to upload a file until you've uploaded it.

[SiaStats](https://siastats.info/storage_pricing.html), the excellent Sia metrics monitoring site, generates estimates of storage costs based on available host information:

[![Table of SiaStats storage cost estimates](/images/sia-load-test-preview/siastats-estimates-sm.png)](/images/sia-load-test-preview/siastats-estimates.png)

Because these are only estimates, we don't know how accurately they reflect real-world usage.

# Pushing Sia to the limit

I'm interested in Sia's limits.

I'm looking for new software projects, and I may build something on top of Sia. But to do that, it's pretty important for me to know whether its maximum storage is 300 GB or 300 TB. And I'd like to know ahead of time if the cost for storing that data is $3 or $3,000.

To find out the answers, I'm going to perform a rigorous test of Sia's limits. I will determine the maximum amount of data I can upload from a single Sia node and measure how much it costs.

I will perform the test using three independent test cases:

## Optimal case

In the first test case, I will upload a set of files where each file's size is exactly 41942760 bytes (~40 MiB).

When Sia processes files for upload, it breaks them into "chunks" of 41942760 bytes. Uploading files that match this size exactly should yield optimal storage capacity.

This test will provide an upper bound on Sia's performance.

## Worst case

In the second test case, I will upload a set of files where each file's size is exactly 1 byte.

Because Sia uses ~40 MiB data chunks, a file of 1 byte is Sia's worst case. It causes Sia to generate a ~40 MiB chunk where all but 1 byte is unused space.

This test will provide a lower bound on Sia's performance.

## Real-world data

Unlike the first two tests, which use simulated data to exercise Sia's limits, the final test will use real-world data.

Whenever I buy a DVD or Blu-ray, I rip the disc image to my local storage server, then encode the video data to MP4 for streaming. I buy a lot of Blu-rays, so I have 4.33 TB of disc data.

I will upload these files to Sia to determine performance on real-world data.

# Full test plan

The full test plan is available as a PDF below:

[![Sia load test doc cover](/images/sia-load-test-preview/sia-load-test-cover-sm.png)](/files/sia-load-test-preview/load-test-plan-2018-02-08.pdf)

The test plan is open to community feedback until Saturday, Feb. 10th at 12pm ET. If you have suggestions or see gaps in the design, feel free to comment below or send me an email at [michael@spaceduck.io](mailto:michael@spaceduck.io).

When the feedback window closes, I will update this post with the final test plan, then perform the test as defined.

# Test Outputs

I aim to publish results by Feb. 16th, 2018.

To avoid [publication bias](https://en.wikipedia.org/wiki/Publication_bias), I will publish regardless of the outcome, even if results are inconclusive due to measurement error.

The test outputs will include:

* A report detailing the measurements obtained in the load test
* Source code for all testing tools, published on Github under the MIT license

I will provide everything any interested party needs to perform the same tests. These tools will also be reusable in future versions of Sia, allowing the community to benchmark improvements in Sia's metrics over time.

# Funding

The [Sia bounty contributors group](https://blog.sia.tech/announcing-sia-bounties-800daf90398b) has generously funded Sia wallets for use in this test. The group will collect any unused funds at the test's conclusion.

# Acknowledgements

Thanks to Luke Champine, David Vorick, James Muller, Salvador Herrera for their contributions to the test plan.
