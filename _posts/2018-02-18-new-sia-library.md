---
title: Sia Finally Published an Official Library but Forgot to Tell Anyone
layout: post
date: '2018-02-18 00:00:00'
summary: A first look at a long-awaited library.
tags:
- sia
- api
permalink: "/new-sia-library/"
comments: true
---

In my last post, I described the [testing tools](/sia-metrics-collector/) I developed to load test Sia. I shared that article on [reddit](https://redd.it/7y2q3k) and lamented the fact that I had to write my tools in Python using a third-party library because Sia doesn't offer any official client libraries.

Imagine my surprise when David Vorick, Sia's lead developer, [responded](https://www.reddit.com/r/siacoin/comments/7y2q3k/capturing_sias_history_with_sia_metrics_collector/dudr5vb/?st=jdt2mhnn&sh=965510a3) to say there *is* an official library, and it was quietly published two weeks ago:

https://godoc.org/github.com/NebulousLabs/Sia/node/api/client

I've been looking forward to an official library for a long time. It's a big step forward for the Sia ecosystem, as it makes it easier for third-party developers to use Sia.

## Doesn't Sia already have an API?

Indeed it does. Sia has always had a [REST API](https://github.com/NebulousLabs/Sia/blob/master/doc/API.md), which clients can access programmatically. Several developers have built third-party applications using this API.

## So why do we need a library too?

The REST API makes it possible for applications to communicate with Sia, but each application's developer is responsible for writing all the code to handle that communication.

Writing API wrappers is tedious and time-consuming. There are lots of edge cases to cover and many opportunities for subtle errors. Without a shared library, everyone who develops on top of Sia redundantly implements this same tedious logic.

This was most apparent during Sia's integration with the Minio file server a few months ago. The project was supposed to take a few weeks but stretched into five months due to various challenges that third-party developers encountered when developing on top of Sia.

One of the top findings from the [postmortem](https://mtlynch.io/sia-minio-postmortem/) was that 30-40% of the integration code was just to wrap Sia's REST API.

[![Screenshot from Sia-Minio postmortem](/images/new-sia-library/sia-postmortem-no-library.png)](https://docs.google.com/document/d/1Bupw6vQQCfiv6r28BARsa4kjDWOhowWvDzAQmwLWrY8/edit)

For Sia to grow, it needs a powerful, intuitive library on which clients can build applications. In fact, it needs *many* libraries so that it can support a broad range of technologies. But a Go library is a good start.

## Testing the new library

I decided to take the new library for a spin. I wrote this simple app to query a few metrics from Sia:

```golang
package main

import (
  "flag"
  "fmt"

  "github.com/NebulousLabs/Sia/node/api/client"
)

func printHeight(c *client.Client) {
  cg, err := c.ConsensusGet()
  if err != nil {
    fmt.Printf("Error retrieving consensus: %s\n", err)
    return
  }
  fmt.Printf("Height: %d\n", cg.Height)
}

func printSiacoinBalance(c *client.Client) {
  wg, err := c.WalletGet()
  if err != nil {
    fmt.Printf("Error retrieving wallet: %s\n", err)
    return
  }
  fmt.Printf("Siacoin balance: %s\n",
	     wg.ConfirmedSiacoinBalance.HumanString())
}

func main() {
  a := flag.String("address", "localhost:9980",
	           "Address and port of Sia node (e.g., sia-server:9980)")
  flag.Parse()
  c := client.New(*a)
  printHeight(c)
  printSiacoinBalance(c)
}
```

Here's what happens when I run it:

```bash
$ go run main.go
Height: 142286
Siacoin balance: 21.71 KS
```

Pretty neat. It was easy to get started, and I didn't have to write much boilerplate code.

## A very thin abstraction layer

The library was straightforward for me to use, but I've been experimenting with Sia and contributing to its codebase for two years. What is this library like for a developer who's discovering Sia for the first time?

One of the most important parts a good library is naming. A developer should have a reasonably good idea about a function's purpose just by reading its name.

The following are real functions from Sia's library. Imagine reading them as if you were a developer new to Sia:

* `Client.WalletSiacoinsMultiPost`
* `Client.HostAcceptingContractsPost`
* `Client.MinerHeaderPost`

What can you deduce about these functions from their names? Not much. They're a nonsensical mishmash of terms from HTTP and Sia, strung together in apparently random order.

The bizarre naming is because these functions provide a very thin abstraction layer over [Sia's REST API](https://github.com/NebulousLabs/Sia/blob/31f21234a371122970dd84f2545e667a47aee557/doc/API.md). For example, `WalletSiacoinsMultiPost` is so named because it wraps an HTTP `POST` request to the `/wallet/siacoin` API endpoint.

## What's wrong with a thin abstraction layer?

In addition to steepening the learning curve, the thin abstraction layer limits Sia's ability to improve over time.

Look at the library function [HostStorageFoldersAddPost](https://github.com/NebulousLabs/Sia/blob/43e31a1603177b558638ded59fb5a51a633e6f53/node/api/client/host.go#L25). It tells Sia to offer a file folder as storage space on the Sia network:

```golang
// HostStorageFoldersAddPost uses the /host/storage/folders/add api
// endpoint to add a storage folder to a host
func (c *Client) HostStorageFoldersAddPost(
    path string, size uint64) (err error) { ... }
```

It works today because a host folder only has two properties: a file path and a maximum capacity.

But what happens when Sia allows hosts to specify another folder property, such as a bandwidth cap?

The parameters to `HostStorageFoldersAddPost` can't change because that will break callers that used the original function signature. The library will need a whole new function to support this one additional parameter.

One new function may not sound like a big deal, but over time the library will accumulate dozens of new functions, all of them slight variants on functions that already exist. Sifting through these functions will create an enormous learning curve for new API consumers.

How can Sia avoid this fate?

## A good model of abstraction

The [Google Cloud Storage (GCS) Library for Go](https://godoc.org/cloud.google.com/go/storage) is a great example of a well-designed API.

Like Sia's, the GCS library is just a wrapper over a REST API. But the GCS Go library abstracts away all the REST-related details of the API. The functions are named not in terms of HTTP verbs such as `Get` or `Post` but rather as actions such as `Create` or `Update` that apply to GCS entities.

This naming is much more intuitive to a new developer. Take [`BucketHandle.Create`](https://godoc.org/cloud.google.com/go/storage#BucketHandle.Create) for example. Most readers would guess that it creates a bucket handle. Spoiler alert: it does.

Notice also that all options for `Create` are encapsulated in the [`BucketAttrs`](https://godoc.org/cloud.google.com/go/storage#BucketAttrs) type. This solves the flexibility problem I demonstrated above with `HostStorageFoldersAddPost`. If the GCS developers ever add a new option for creating a bucket, they'll simply add a field to the `BucketAttrs` type. They won't need to create a new function, and they won't break legacy clients.

## Is Sia's library final?

Sia hasn't made any official announcement about their library yet. I don't know whether the published version is an unsupported alpha release or the official Sia library that they'll commit to supporting for years into the future. Obviously, I hope it's the former.

I'd love to see the Sia team iterate on this library based on feedback from third-party developers. No matter how good you are at designing an API, you can't do it well without talking to the people who are actually using it.

## How about an app contest?

If I were the Sia team, I'd hold an app contest.

This could fit well into the Sia [bounty program](https://blog.sia.tech/announcing-sia-bounties-800daf90398b). Give developers a few weeks to build beta apps on top of this new library, then award Siacoins as a prize to the best app.

To make sure the contest achieves good coverage of the different library functions, they could offer sub-prizes like "best use of host APIs" or "best use of renter APIs."

As a condition of entering, contestants would have to give feedback about the Sia Go library. What was hard to understand? Which APIs did something unexpected? What functionality was missing?

This could be a great way to foster development of new Sia applications and to improve the library for all third-party developers in the future.