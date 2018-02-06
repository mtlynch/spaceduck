---
title: How Much Data Can You Store with Sia? (Preview)
layout: post
date: '2018-02-08'
summary: A formal load test of Sia's upload capacity.
tags:
- sia
permalink: "/sia-load-test-preview/"
comments: true
---

Every time there's a new Sia release, I try to upload my collection of Blu-Ray and DVD backups. They take up ~5 TB of storage. Even on a low cost option like Google Cloud Storage coldline, that would cost me $35 per month. Sia claims to be about $2/TB per month, so I'd pay $10 per month.

Every time I've tried, I hit some bug. Sia's native app isn't very friendly to bulk uploads, so I'm always trying to upload data through some complicated interface, like Docker + NextCloud + Sia or Docker + Sia + Minio + S3 client. When failures occur, I don't know for sure if it's Sia.
