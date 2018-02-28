---
title: Why You Shouldn't Take the Sia Roadmap Seriously
layout: post
date: '2018-02-27'
summary: If you're expecting any of the 2018 Q1 features to happen, I have bad news
  for you.
tags:
- sia
- timestamps
permalink: "/dont-trust-the-roadmap/"
comments: true
---

For the past few weeks, I've seen cryptocurrency bloggers breathlessly tell their readers about all the exciting things Sia will do in the first quarter of 2018.

Here's an excerpt from an article published two days ago:

[![Screenshot of article about Sia 2018Q1 features](/images/dont-trust-the-roadmap/article1.png)](/images/dont-trust-the-roadmap/article1.png)

And here's another that was published just yesterday:

[![Screenshot of article about Sia 2018Q1 features](/images/dont-trust-the-roadmap/article2.png)](/images/dont-trust-the-roadmap/article2.png)

Is this real? Will Sia challenge BitTorrent and MEGA with a revolutionary new peer-to-peer filesharing solution sometime in the next month?

Of course not. Anyone who's been paying attention to Sia could have told you that.

## Why do people think this will happen?

This information is coming from the [Sia public roadmap](https://trello.com/b/Io1dDyuI/sia-public-roadmap), a Trello board that ostensibly tracks what the Sia team is working on for each release.

Here's what it looks like today:

[![Sia's public roadmap](/images/dont-trust-the-roadmap/sia-roadmap-2018-02-27.png)](/images/dont-trust-the-roadmap/sia-roadmap-2018-02-27.png)

Okay, so the roadmap supports everything the bloggers claim. But as you might have guessed from the title of this post, the roadmap is the problem.

## Why won't these feature ship in Q1?

Sia is already testing a release candidate for their next version, 1.3.2. Sia generally goes several months between releases, so 1.3.2 is likely to be the only release of 2018 Q1.

The new features in 1.3.2 are:

* Improved performance for renter downloads
* Reduced contract fees

In case you missed it, here's a Venn diagram of the overlap between those features and the features that were announced on the roadmap for Q1:

[![Sia's public roadmap](/images/dont-trust-the-roadmap/venn-diagram-sm.png)](/images/dont-trust-the-roadmap/venn-diagram.png)

In other words, the features actually in the 1.3.2 release are completely distinct from the features the roadmap promised (and continues to promise) for Q1.

From the [source history](https://github.com/NebulousLabs/Sia/commits/master), I don't see progress on any of the roadmap features. "Overhauled UI" is still listed as a Q1 feature despite the fact that Sia-UI has only had [five trivial commits](https://github.com/NebulousLabs/Sia-UI/compare/v1.3.1...f455716bfd1ad071ca73bf5dad33dce6fb63a2f1) since the December release.

The only roadmap feature where I see any progress at all is support for seed-based file recovery, and that's only because an external developer [sent them a design proposal](https://github.com/NebulousLabs/Sia/pull/2794) two days ago.

## This is not new

The exact same thing happened in Sia's previous release. Sia worked on it for five months. For four and a half of those months, the roadmap advertised many of the same features we see advertised for the 2018 Q1 release: file sharing, fast contract formation, a UI overhaul.

The Sia team didn't implement any of them.

The only feature from the roadmap that actually made it into the December release was automatic wallet unlocking. That only happened because, again, an external developer [contributed the code](https://github.com/NebulousLabs/Sia/pull/2351).

## Sia doesn't take the roadmap seriously

The problem isn't just that Sia estimates tasks poorly (though that's also a problem). It's that they're ignoring the roadmap entirely. The last time the dev team implemented a feature that was actually on the roadmap was July 2017.

The Sia team *is* still implementing features. And they're good, useful features like improvements to fee calculation and download speed. But they're nowhere near as gamechanging as the features we see repeatedly promised and punted, such as file-sharing or seed-based file recovery.

## Why does this matter?

Recall that in Sia's January [blog post](https://blog.sia.tech/sia-triannual-update-september-december-2017-8afdf9c10325), they boldy declared 2018 to be the year of Sia enterprise adoption:

>By the end of 2018, expect to see several **meaningful** partnerships with enterprises who are storing data on Sia.
>
>-Zach Herbert, VP of Operations

It will take a lot of trust to convince businesses to begin using Sia's storage network in a meaningful way. To someone eyeing  Sia as a storage solution for their business, these unannounced feature digressions and missed deadlines degrade confidence in the product.

If they hope to win enterprise trust, Sia will need to do what they say and say what they'll do.

## What can Sia do?

**Respect the roadmap**

A roadmap that consistently contradicts reality is worse than no roadmap at all.

Sia should be checking the roadmap at least monthly to make sure it reflects their true direction. This is not hard to do. All it takes is discipline.

**Estimate conservatively**

The roadmap change history reveals a pattern of drastically over-optimistic time estimates. Sia should pare down the set of features they promise in each release.

It's better to announce a narrow feature set and expand it later than to routinely overpromise and underdeliver.

## What can you do?

**Speak up**

It's easy for the Sia team to ignore the roadmap if people blindly accept it as fact and forget about its track record. If you value an accurate roadmap, let the Sia team know. Give feedback about the product's planned direction, and ask questions when they diverge from it.

## Updates

* **2018-02-27, 6pm ET**: Sia's lead developer has posted a [lengthy response](https://www.reddit.com/r/siacoin/comments/80qcbf/why_you_shouldnt_take_the_sia_roadmap_seriously/duxiuj3/?st=je6lxryn&sh=6149ac36) to this article on reddit.
* **2018-02-27, 7:30pm ET**: In response to this post, external Sia contributor Thomas Bennett has updated the [public roadmap](https://trello.com/b/Io1dDyuI/sia-public-roadmap) to remove specific dates and trim down the set of features listed under "Short Term."

