---
title: Streaming Video with Sia (Live Demo)
comments: true
hide_description: true
layout: post
description: A preview of some neat things you can do with the streaming feature of
  Sia 1.3.3
tags:
- sia
- docker
---

File streaming is the headline feature of Sia's next release. Users will be able to stream files over HTTP, whereas previously they had to fully download their files to disk in order to access them.

The key limitation is that streaming only works within the local system. Sia can't, for instance, serve videos to a web page.

Or rather, Sia can't do this *natively*. Using Docker and the Sia 1.3.3 release candidate, I created a server that streams my files from Sia to any place I want.

Below, you'll find embedded videos that I'm serving directly from my Sia node.

# Setting up remote streaming

## Requirements

The only software you'll need to follow my examples is Docker.

[Docker Community Edition](https://store.docker.com/search?offering=community&type=edition) is available for free on all major OSes.

## Files

You'll need to download just two files, which I'll explain in turn:

### docker-compose.yml

```yaml
services:
  sia:
    image: mtlynch/sia:1.3.3-rc1
    container_name: sia
    environment:
      - SIA_MODULES=gctrw
    restart: on-failure
    ports:
      - 9981:9981
    volumes:
      - ./sia-data:/sia-data
      - ./uploads:/sia-uploads
  nginx:
    image: nginx
    container_name: nginx
    restart: always
    ports:
      - 80:80
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    links:
      - sia
  # sia-metrics-collector is optional. It will collect Sia metrics for you
  # in your metrics/ folder. You can delete this section if you don't want it.
  sia-metrics-collector:
    image: mtlynch/sia_metrics_collector:2018-05-08
    container_name: sia-metrics-collector
    environment:
      - SIA_HOSTNAME=http://sia
      - OUTPUT_FILE=/metrics/metrics.csv
    restart: on-failure
    volumes:
      - ./metrics:/metrics
    depends_on:
      - sia
    links:
      - sia
```

This file tells Docker to set up a network of three containers to support my streaming solution.

Obviously, there's a container for Sia, which runs the 1.3.3 release candidate.

The next container is for [nginx](https://nginx.org/en/), which I use as a reverse proxy to connect external HTTP requests to Sia.

Finally, there's the Sia metrics collector. That one is optional and just captures metrics about Sia that you can visualize by following [these instructions](https://github.com/mtlynch/sia_metrics_collector).

### nginx.conf

```text
events {}

http {
    upstream sia-backend {
      server sia:9980;
    }

    server {
        listen 80;
        proxy_read_timeout 600s;

        rewrite ^/(.+)$ /renter/stream/$1 last;
        location /renter/stream/ { proxy_pass http://sia:9980; }
    }
}
```

This is the coniguration file for nginx. It listens on port 80, the default port for HTTP traffic. When it receives an HTTP request for a path like `/foo/bar.mp4`, it forwards the request to the Sia node and rewrites the path to `http://sia:9980/renter/stream/foo/bar.mp4`, which is Sia's [streaming download endpoint](https://github.com/NebulousLabs/Sia/blob/master/doc/API.md#renterstreamsiapath-get).

It's worth noting that Sia runs many endpoints on port 9980, many of which are sensitive APIs that you shouldn't expose publicly. The APIs for sending funds or displaying your wallet seed run on the same port, for example. The configuration above protects the Sia node by only exposing the `/renter/stream` API and keeping every other sensitive endpoint inaccessible externally.

## Starting your node

Starting your streaming Sia node requires just five shell commands:

```bash
# Create directories for Sia.
mkdir sia-streaming && cd sia-streaming
mkdir sia-data uploads metrics

# Download the necessary files.
wget https://gist.githubusercontent.com/mtlynch/ff0b7789bf7d8797cae09646163bee49/raw/8de1b5ee0919dbc5fda8428d6c3713ff60469c1a/docker-compose.yml
wget https://gist.githubusercontent.com/mtlynch/ff0b7789bf7d8797cae09646163bee49/raw/8de1b5ee0919dbc5fda8428d6c3713ff60469c1a/nginx.conf

# Start the Docker containers
docker-compose up --detach
```

## Interacting with Sia

You can interact with Sia through the `siac` command-line client within the container to perform any standard actions:

```bash
$ docker exec -it sia ./siac version
Sia Client
        Version 1.3.2
        Git Revision 6cf56381
        Build Time   Thu May  3 15:49:46 UTC 2018
Sia Daemon
        Version 1.3.2
        Git Revision 6cf56381
        Build Time   Thu May  3 15:49:46 UTC 2018
```

To start streaming, you need to create a Sia wallet and fund it with at least 500 SC (this is left as an exercise to the reader).

You then need to create renter contracts. I created contracts through the command below. It's a bit unusual because I'm choosing very short contracts to match my VPS's one-month lifetime.

```bash
$ docker exec -it sia ./siac renter setallowance 5KS 30d 50 288b
```

Next, you'll need to upload files. Any file you place in the `./uploads` directory on your host will appear within your Sia container under the `/sia-uploads` path. Here are the commands I used to upload a few video files:

```bash
$ docker exec -it sia ./siac renter upload \
  /sia-uploads/big_buck_bunny_480p_surround-fix.mp4 \
  /big_buck_bunny_480p_surround-fix.mp4

$ docker exec -it sia ./siac renter upload \
  /sia-uploads/bbb_sunflower_1080p_60fps_normal.mp4 \
  /bbb_sunflower_1080p_60fps_normal.mp4

$ docker exec -it sia ./siac renter upload \
  /sia-uploads/bbb_sunflower_2160p_60fps_normal.mp4 \
  /bbb_sunflower_2160p_60fps_normal.mp4
```

I'm keeping the files on the Sia network, so it wouldn't be very exciting if I had to keep all the files locally as well. Once `siac renter -v` showed that my files were 100% uploaded to Sia, I deleted the local copies from my host:

```bash
$ rm uploads/*
```

# Live demo

I set up a demo below where you can stream the short film *Big Buck Bunny*  **directly from my Sia node**.

Click one of the "Play" buttons and a video player will pop up below:

| Filename | Resolution | File size | Watch |
|------------|------------|---------------|---|
| [big_buck_bunny_480p_surround-fix.mp4](http://streamingdemo.spaceduck.io/big_buck_bunny_480p_surround-fix.mp4) | 480p | 151 MB | <input type="submit" value="Play" id="load480p"> |
| [bbb_sunflower_1080p_60fps_normal.mp4](http://streamingdemo.spaceduck.io/bbb_sunflower_1080p_60fps_normal.mp4) | 1080p | 356 MB | <input type="submit" value="Play" id="load1080p"> |
| [bbb_sunflower_2160p_60fps_normal.mp4](http://streamingdemo.spaceduck.io/bbb_sunflower_2160p_60fps_normal.mp4) | 2160p | 673 MB | <input type="submit" value="Play" id="load2160p"> |

<div id="vidHolder" style="width: 700px; height: 500px;">
<p style="color: red;">Click one of the "Play" buttons above to watch.</p>
</div>

<script>
var loadVideo = function(source) {
  var vidHolder = document.getElementById("vidHolder");
	vidHolder.innerHTML = "";
  var videlem = document.createElement("video");
	videlem.controls = "controls";
	videlem.autoplay = "autoplay";
	videlem.width = 640;
	videlem.height = 480;
	videlem.autoplay = true;
  var sourceMP4 = document.createElement("source"); 
  sourceMP4.type = "video/mp4";
  sourceMP4.src = source;
  videlem.appendChild(sourceMP4);
  vidHolder.appendChild(videlem);
};

document.getElementById("load480p").onclick = function() {
  loadVideo("http://streamingdemo.spaceduck.io/big_buck_bunny_480p_surround-fix.mp4");
};
document.getElementById("load1080p").onclick = function() {
  loadVideo("http://streamingdemo.spaceduck.io/bbb_sunflower_1080p_60fps_normal.mp4");
};
document.getElementById("load2160p").onclick = function() {
  loadVideo("http://streamingdemo.spaceduck.io/bbb_sunflower_2160p_60fps_normal.mp4");
};
</script>

***Note**: The streaming feature is not meant to support streaming to multiple clients at once. Expect to see very long load times and timeouts.*

The server is an [Afterburst Mini KVM](https://afterburst.com/unmetered-kvm-vps) with 2 CPU cores, 2 GB of RAM, and 1 Gbps network. I rented the server for one month and loaded my Sia wallet with 5000 SC, so I’ll let it run until people download enough to exhaust my renter contracts or until my VPS month ends. I'm [collecting metrics](https://github.com/mtlynch/sia_metrics_collector) on Sia's spending, so I'll update if anything neat emerges from that.

# Stream whatever you want

Video and audio are the most useful types of files to stream because they allow you to skip around the file, but Sia can stream files of any type.

I copied the PDF of my [Sia Load Test](/load-test-wrapup/) plan to my Sia node as well, so you can download that via the URL below:

* [http://streamingdemo.spaceduck.io/load-test-plan-2018-02-14.pdf](http://streamingdemo.spaceduck.io/load-test-plan-2018-02-14.pdf)

# Don't get too excited yet

When people hear that Sia will offer video streaming, they think that it's going to be some sort of decentralized, censorship-free YouTube. That's not what this is.

The server is still the single-point of failure. When I shut off the VPS at the end of the month, the video demos above will stop playing. If I streamed something illegal, authorities could track down the server and seize it just like any other site.

Sia does indeed stream videos, but if all you wanted to do was stream a few videos from a web server, there are far easier ways to do it.

What's interesting about Sia's streaming feature is how it allows you to trade resource constraints. There are four main resources that a video streaming provider typically cares about (in descending order of importance):

1. Network bandwidth
1. Compute power
1. Memory
1. Storage

Sia's streaming feature increases network bandwidth because it has to download data from hosts, then send data to the user's browser. It increases compute and memory consumption because it also needs to rejoin and decrypt each data shard.

The advantage Sia offers is its low storage footprint. You could theoretically set up Sia to serve ~5 TB of files on a server that has only 50 GB of local storage. An example use-case might be a site that has a very large catalog of videos which users don't access very frequently (e.g., [The Internet Archive](https://archive.org/)).

# Okay, you can get a little excited

Sia is advertising the video streaming aspect of this feature because that's the most tangible use-case. If you're thinking ahead, the *really* exciting part is how it facilitates software integrations with Sia.

Prior to 1.3.3, applications could only download files from Sia if they ran on the same system. That's a crippling limitation, as most apps expect to integrate with storage backends over the network, not through the filesystem.

Download streaming brings Sia closer to the point where applications can communicate with Sia entirely over the network. It's not quite there yet because Sia doesn't yet support upload streaming, but downloads get it halfway there.

# Acknowledgments

Thanks to Christoph Schaefer, who created [the first tutorial](https://medium.com/@chrsch79/stream-video-from-sia-network-bc9e2d5d9daa) for Sia's video streaming feature. His post showed me how to use the feature and inspired me to extend it in this post.