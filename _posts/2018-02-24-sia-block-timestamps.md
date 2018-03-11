---
title: The Surprising Difficulty of Finding a Sia Block Timestamp
layout: post
date: '2018-02-24'
summary: How hard can a simple timestamp be?
tags:
- sia
- timestamps
permalink: "/sia-block-timestamps/"
comments: true
---

As I was gathering my cryptocurrency records for what promises to be an exciting tax season, I stumbled upon a Sia task that I never expected to be hard: finding a Sia block's timestamp.

## Does the IRS accept block heights?

My journey began as I used the Sia command-line client to print transactions from my main wallet. Its output looks like this:

```
$ ./siac wallet transactions
    [height]                                                   [transaction id]    [net siacoins]   [net siafunds]
      140607   9a23f03a15e88b2f260bb260c910218049a163235dbea25c9266c85dc320d579        5000.00 SC             0 SF
      141744   8a1130005393975f9f4b9706c534eaacaf260e38677064ac677e5a10120b7520           0.00 SC             0 SF
      141744   bd17de4cd49cb64402a12e4debbc3c48b3d667014a8cf0f0e375ab8f78016fcc         -33.33 SC             0 SF
      141744   dbca011a4a4d0d1d9c6e041f5ef4b025d6a42fe89aa8700647b221c4498a8e90           0.00 SC             0 SF
      141744   f3b9542c1b49ff446289277962a733b68e7889161aa9f32ce614a2f987f91378         -33.33 SC             0 SF
```

No timestamps, just block heights.

The block height is the number of blocks in the blockchain before a particular transaction occurred.  I was pretty sure that the IRS would have questions for me if I reported my cryptocurrency transactions to them in terms of Sia block heights, so I'd need to convert these heights to real-world timestamps.

The blockchain is a public ledger, so if I knew the block in which my transaction occurred, I should be able to just look up the timestamp for that block. That's how it works for Bitcoin:

{% include image.html file="blockchain-info.png" alt="Screenshot of Blockchain.info" max_width="601px" img_link="true" %}

So I checked the official Sia blockchain explorer. What did the latest block look like? At the time, that was block [143,159](https://explore.sia.tech/block/143159):

{% include image.html file="sia-explorer.png" alt="Screenshot of Sia Explorer" img_link="true" %}

Hmm, no timestamp field.

There was a field called "*Maturity* Timestamp." Maybe that was what I wanted.

`1519406327` looked like a UNIX timestamp, so I converted it to a human date:

{% include image.html file="epoch-converted.png" alt="UNIX timestamp converted to human timestamp" max_width="680px" img_link="true" %}

Okay, so it converted to 12:18pm on Feb. 23rd. I was checking at 2:49pm on Feb. 24th. That meant it couldn't be the block timestamp because it would mean Sia had gone 27 hours since finding a new block.

To confirm, I checked [SiaStats](https://siastats.info):

{% include image.html file="siastats-143159.png" alt="SiaStats display for block 143,159" max_width="571px" img_link="true" %}

SiaStats said that the last block occurred at 2:23pm, which was a much more believable time.

Whatever the maturity timestamp is, it's not the time the block occurred. Maybe the [source code](https://github.com/NebulousLabs/Sia/blob/a32e1828ef002533d3124d3e447f02aae8e0cd5c/modules/explorer.go#L21) could explain it:

```golang
// BlockFacts returns a bunch of statistics about the consensus set as
// they were at a specific block.
BlockFacts struct {
  BlockID           types.BlockID     `json:"blockid"`
  Difficulty        types.Currency    `json:"difficulty"`
  EstimatedHashrate types.Currency    `json:"estimatedhashrate"`
  Height            types.BlockHeight `json:"height"`
  MaturityTimestamp types.Timestamp   `json:"maturitytimestamp"`
	...
```

That wasn't helpful. It was just an undocumented field.

It was pretty clear that the maturity timestamp field was a dead end.

## Does SiaStats know?

Wait, SiaStats knew the most recent block time. Maybe SiaStats knew *all* the block times.

SiaStats offers a nice collection of [free data APIs](https://siastats.info/api), so I checked those out.

{% include image.html file="siastats-apis.png" alt="SiaStats available APIs" max_width="811px" img_link="true" %}

No luck! They have a database of blocks and timestamps, but it only goes back 72 hours.

## Does anyone know?

Uh oh. Does Sia not track the timestamp in the block? It had to, right? If not, it was going to be a big pain to do my taxes.

I went back to the Sia source code. [`types/block.go`](https://github.com/NebulousLabs/Sia/blob/1dd4e67a7b046d42a53c9d05bdf89cd447aef179/types/block.go#L30) seemed like a good place to look:

```golang
Block struct {
  ParentID     BlockID         `json:"parentid"`
  Nonce        BlockNonce      `json:"nonce"`
  Timestamp    Timestamp       `json:"timestamp"`
  MinerPayouts []SiacoinOutput `json:"minerpayouts"`
  Transactions []Transaction   `json:"transactions"`
}
```

Bingo!

## Will siac tell me?

Okay, that told me Sia tracked block timestamps, but I still needed a way to access them.

I checked what was available from the Sia command-line client:

```
$ ./siac help
...
Available Commands:
  bash-completion Creates bash completion file.
  consensus       Print the current state of consensus
  gateway         Perform gateway actions
  help            Help about any command
  host            Perform host actions
  hostdb          Interact with the renter's host database.
  man-generation  Creates unix style manpages.
  miner           Perform miner actions
  renter          Perform renter actions
  stop            Stop the Sia daemon
  update          Update Sia
  version         Print version information
  wallet          Perform wallet actions
```

The only command that was promising was `consensus`, but that just gave me the latest block:

```
$ ./siac consensus
Synced: Yes
Block:      00000000000000000b09a3000e97017e005c4e0646f1eeee508b2527ad292605
Height:     143160
Target:     [0 0 0 0 0 0 0 2 219 56 149 122 107 93 113 129 240 11 60 240 98 53 223 137 128 59 47 220 82 214 125 79]
Difficulty: 6458192917864068561
```

## Making raw API calls

The Sia command-line client didn't seem to want to tell me about block timestamps. Maybe I'd have to drop down directly into the [Sia REST API](https://github.com/NebulousLabs/Sia/blob/80cb4bdf63ba45227e62613694d553d09e95bc9f/doc/API.md). What did it have to say about block metadata?

{% include image.html file="sia-api.png" alt="Sia API documentation" max_width="500px" img_link=true %}

No dice! There were only two `/consensus` APIs and they didn't provide historical block timestamps.

## What about the explorer module?

From previous tinkering with the Sia source code, I remembered I had seen a top-level module called `explorer`. I took a look and it was [still there](https://github.com/NebulousLabs/Sia/tree/53266a23d035ff96e4d18e088dbff791f3bce245/modules/explorer).

If the code is live, but the API documentation doesn't cover it, that means it's either inaccessible/dead code or it's accessible through the Sia REST API, but it's not documented. Maybe it's a secret feature only meant for those special enough to find it.

If there was a REST API for this, I expected it to start with `/explorer` because all of the other REST endpoints begin with their associated module name. I checked the source code for that particular string:

```
$ grep "/explorer" ./ -R
Binary file ./.git/index matches
./node/api/explorer.go: // /explorer.
./node/api/explorer.go: // /explorer/block.
./node/api/explorer.go: // /explorer/hash. The HashType will indicate whether the hash corresponds
./node/api/explorer.go:// explorerHandler handles API calls to /explorer/blocks/:height.
./node/api/explorer.go:         WriteError(w, Error{"no block found at input height in call to /explorer/block"}, http.StatusBadRequest)
./node/api/explorer.go:// explorerHashHandler handles GET requests to /explorer/hash/:hash.
./node/api/explorer.go: WriteError(w, Error{"unrecognized hash used as input to /explorer/hash"}, http.StatusBadRequest)
./node/api/explorer.go:// explorerHandler handles API calls to /explorer
./node/api/explorer_test.go:// TestIntegrationExplorerGET probes the GET call to /explorer.
./node/api/explorer_test.go:    err = st.getAPI("/explorer", &eg)
./node/api/explorer_test.go:// TestIntegrationExplorerBlockGET probes the GET call to /explorer/block.
./node/api/explorer_test.go:    err = st.getAPI("/explorer/blocks/0", &ebg)
./node/api/explorer_test.go:            t.Error("wrong block returned by /explorer/block?height=0")
./node/api/explorer_test.go:// TestIntegrationExplorerHashGet probes the GET call to /explorer/hash/:hash.
./node/api/explorer_test.go:    err = st.getAPI("/explorer/hashes/"+gb.ID().String(), &ehg)
./node/api/server_test.go:      err = st.stdGetAPIUA("/explorer", "")
./node/api/routes.go:           router.GET("/explorer", api.explorerHandler)
./node/api/routes.go:           router.GET("/explorer/blocks/:height", api.explorerBlocksHandler)
./node/api/routes.go:           router.GET("/explorer/hashes/:hash", api.explorerHashHandler)
./node/api/server_helpers_test.go:      "github.com/NebulousLabs/Sia/modules/explorer"
./cmd/siad/server.go:   "github.com/NebulousLabs/Sia/modules/explorer"
./Makefile:pkgs = ./build ./cmd/siac ./cmd/siad ./compatibility ./crypto ./encoding ./modules ./modules/consensus ./modules/explorer \
./Makefile:lintpkgs = ./build ./cmd/siac ./cmd/siad ./compatibility ./crypto ./encoding ./modules ./modules/consensus ./modules/explorer \
```

That looked promising! In particular, `node/api/explorer_test.go` seemed like a test of the API, so it should have examples of how to call the API and what the response would look like.

I read a few lines of the file and was confronted with this:

```golang
// TestIntegrationExplorerGET probes the GET call to /explorer.
func TestIntegrationExplorerGET(t *testing.T) {
  t.Skip("Explorer has deadlock issues")
```

Uh oh. Deadlock issues? Issues apparently so bad that the developers aren't even testing this API anymore? That didn't bode well.

Maybe it was a recent change so tests are temporarily disabled while they fix it. I checked the [git blame history](https://github.com/NebulousLabs/Sia/blob/c40312c5fc9927c8701c6d12441fd7c97279ccee/node/api/explorer_test.go) to see when the tests were disabled:

{% include image.html file="github-blame.png" alt="Github blame layer" img_link="true" %}

Two years ago?!?! This code has been sitting in the codebase untested and/or dead for **two years**?

My chances of running this module successfully were looking pretty grim. It was also surprising of the Sia devs to commit such a loud development faux-pas.

But anyway, further down in the code, I could see what looked like a REST call to retrieve a particular Sia block:

```golang
err = st.getAPI("/explorer/blocks/0", &ebg)
```

That REST call probably retrieved block `0`, so I should be able to swap the zero out for any block I want and get my long-sought-after timestamp.

## Loading the explorer module

Sia doesn't load the `explorer` module by default, so I checked the help string to figure out how to load it:

```
$ ./siad modules
Use the -M or --modules flag to only run specific modules. Modules are
independent components of Sia. This flag should only be used by developers or
people who want to reduce overhead from unused modules. Modules are specified by
their first letter. If the -M or --modules flag is not specified the default
modules are run. The default modules are:
        gateway, consensus set, host, miner, renter, transaction pool, wallet
This is equivalent to:
        siad -M cghmrtw
Below is a list of all the modules available.

...

Explorer (e):
        The explorer provides statistics about the blockchain and can be
        queried for information about specific transactions or other objects on
        the blockchain.
        The explorer requires the consenus set.
        Example:
                siad -M gce
```

That seemed easy enough. I ran the command it gave me:

```
$ ./siad -M gce
Sia Daemon v1.3.1
Loading...
(0/3) Loading siad...
(1/3) Loading gateway...
(2/3) Loading consensus...
(3/3) Loading explorer...
Finished loading in 0.037083713 seconds
```

Alright, now the test. Sia was still syncing the blockchain, so I checked to see if I could get information about an early block:

```
$ curl http://localhost:9980/explorer/blocks/10
{"message":"Browser access disabled due to security vulnerability. Use Sia-UI or siac."}
```

Oh right. Sia won't accept HTTP requests unless the caller sets `Sia-Agent` as the HTTP:

```
$ curl -A "Sia-Agent" http://localhost:9980/explorer/blocks/10
{"block":{"minerpayoutids":["da68362fc0addb2c86e6ea249684f87c25bc191029796843edc1203930bb40a5"],"transactions":[{"id":"66f1e1eda06d0f1c4ba876e693093543301ea95113cade9ab8766f28f82c7216","height":10,"parent":"000000001f39e768ce4ec3b32db9b664503a8bc9f2dd1c67bc90a0ae1871ce7a","rawtransaction":{"siacoininputs":[],"siacoinoutputs":[],"filecontracts":[],"filecontractrevisions":[],"storageproofs":[],"siafundinputs":[],"siafundoutputs":[],"minerfees":[],"arbitrarydata":["Tm9uU2lhUZcUfUTm6JuaL8JVR8ct3A=="],"transactionsignatures":[]},"siacoininputoutputs":null,"siacoinoutputids":null,"filecontractids":null,"filecontractvalidproofoutputids":null,"filecontractmissedproofoutputids":null,"filecontractrevisionvalidproofoutputids":null,"filecontractrevisionmissedproofoutputids":null,"storageproofoutputids":null,"storageproofoutputs":null,"siafundinputoutputs":null,"siafundoutputids":null,"siafundclaimoutputids":null}],"rawblock":{"parentid":"00000000014aca60206632a39de3b54e2110cc25a07b712704a911aafd02952e","nonce":[22,36,0,0,0,0,11,22],"timestamp":1433630907,"minerpayouts":[{"value":"299990000000000000000000000000","unlockhash":"138400c5710172b1de804321cb0827245a7f441602df19ba2ad6b628d5237a26f40008f9d392"}],"transactions":[{"siacoininputs":[],"siacoinoutputs":[],"filecontracts":[],"filecontractrevisions":[],"storageproofs":[],"siafundinputs":[],"siafundoutputs":[],"minerfees":[],"arbitrarydata":["Tm9uU2lhUZcUfUTm6JuaL8JVR8ct3A=="],"transactionsignatures":[]}]},"blockid":"000000001f39e768ce4ec3b32db9b664503a8bc9f2dd1c67bc90a0ae1871ce7a","difficulty":"34359738367","estimatedhashrate":"0","height":10,"maturitytimestamp":0,"target":[0,0,0,0,32,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"totalcoins":"3299945000000000000000000000000","minerpayoutcount":10,"transactioncount":11,"siacoininputcount":0,"siacoinoutputcount":0,"filecontractcount":0,"filecontractrevisioncount":0,"storageproofcount":0,"siafundinputcount":0,"siafundoutputcount":47,"minerfeecount":0,"arbitrarydatacount":10,"transactionsignaturecount":0,"activecontractcost":"0","activecontractcount":0,"activecontractsize":"0","totalcontractcost":"0","totalcontractsize":"0","totalrevisionvolume":"0"}}
```

Victory!

It's a big, messy JSON dump, but buried in there is `"timestamp":1433630907`. Translated to human time, it's June 6th, 2015, which seems like the right timestamp for Sia's 11th block.

## Dump all the timestamps

I didn't want to keep dealing with `curl` calls and giant JSON dumps. I just wanted a dump of all the blocks and timestamps so that I could translate the block heights I was seeing in my wallet transactions.

I wrote a quick tool called [Sia Timestamp Dumper](https://github.com/mtlynch/sia_timestamp_dumper) to do exactly that. If you have a Sia node running with the `explorer` module enabled, you can use the tool to dump out all the block timestamps as tab-separated values:

```
$ python dump.py
block_height    unix_timestamp  iso_timestamp
     0  1433600000      2015-06-06T14:13:20Z
     1  1433626546      2015-06-06T21:35:46Z
     2  1433627288      2015-06-06T21:48:08Z
     3  1433628922      2015-06-06T22:15:22Z
     4  1433628961      2015-06-06T22:16:01Z
     5  1433629456      2015-06-06T22:24:16Z
     6  1433629725      2015-06-06T22:28:45Z
```

I also published a [gist](https://gist.github.com/mtlynch/8394e0be8d2de7097ab31cbea51559cd) with the full dump up to block 143,001 (2018-02-23T15:59:57Z).

## SiaHub's API

As I was writing this post, I remembered that [SiaHub](https://siahub.info/) runs their own really nice Sia blockchain explorer. They even display the block timestamp:

{% include image.html file="siahub.png" alt="SiaHub screenshot" img_link="true" %}

It gets even better than that. SiaHub also offers a [free, hosted API](https://siahub.readme.io/v1.0/reference#block) so that users don't have to go through the hassle of spinning up their own Sia node with the `explorer` module loaded.

It's a different API syntax, but you can get the timestamp nonetheless:

```
$ HEIGHT=143159
$ curl -s "https://explorer.siahub.info/api/block/${HEIGHT}" 2>&1 | python -c "import datetime, json, sys; print datetime.datetime.fromtimestamp(json.load(sys.stdin)['blockheader']['timestamp'])"
2018-02-24 14:23:44
```

## Wait, what was I doing again?

I went so far down the rabbit hole with these block timestamps that I forgot what I originally set out to do: figure out when my Sia transactions occurred.

Then a thought occurred to me: doesn't Sia's GUI interface show transaction timestamps in human-readable format?

{% include image.html file="sia-ui.png" alt="Sia-UI screenshot" img_link="true" %}

It does!

So how was Sia-UI getting the timestamps? I knew Sia-UI wasn't jumping through all the hoops of getting Sia to load the `explorer` module.

I checked out [Sia-UI's source](https://github.com/NebulousLabs/Sia-UI/blob/a09d4e27a9d9db2b5ff428163b8d70a0cbc34cbc/plugins/Wallet/js/components/transactionlist.js#L74):

```javascript
{txn.confirmed
    ? prettyTimestamp(txn.confirmationtimestamp)
    : 'Not Confirmed'}
```

Wait a second. Do the transactions themselves store the timestamp?

Back to the Sia source!

Under the covers, Sia-UI was calling `/wallet/transactions`. The response to that REST call is [this struct](https://github.com/NebulousLabs/Sia/blob/b856184ab2cfc7838058ecf731960b6e8c09fe3c/node/api/wallet.go#L88-L91):

```golang
// WalletTransactionsGET contains the specified set of confirmed and
// unconfirmed transactions.
WalletTransactionsGET struct {
  ConfirmedTransactions   []modules.ProcessedTransaction `json:"confirmedtransactions"`
  UnconfirmedTransactions []modules.ProcessedTransaction `json:"unconfirmedtransactions"`
}
```

So what's in a [`ProcessedTransaction`](https://github.com/NebulousLabs/Sia/blob/b856184ab2cfc7838058ecf731960b6e8c09fe3c/modules/wallet.go#L93-L101)?

```golang
ProcessedTransaction struct {
  Transaction           types.Transaction   `json:"transaction"`
  TransactionID         types.TransactionID `json:"transactionid"`
  ConfirmationHeight    types.BlockHeight   `json:"confirmationheight"`
  ConfirmationTimestamp types.Timestamp     `json:"confirmationtimestamp"`
	...
```

Well look at that! The timestamps for my transactions were there all along. The Sia command-line client just wasn't showing it to me.

## Why couldn't the command-line client tell me that?

It seemed like information the user *should* know. Further, there shouldn't be any information available in the Sia GUI that isn't available through the command-line client.

I submitted a [pull request](https://github.com/NebulousLabs/Sia/pull/2791) to add this functionality, and Luke Champine, Sia's CTO, quickly accepted it. In Sia 1.3.2 and onward, when you query the Sia command-line client for transactions, you'll see the timestamp right there alongside the block height:

```
$ ./siac wallet transactions
             [timestamp]    [height]                                                   [transaction id]    [net siacoins]   [net siafunds]
2018-02-06 14:00:20-0500      140607   9a23f03a15e88b2f260bb260c910218049a163235dbea25c9266c85dc320d579        5000.00 SC             0 SF
2018-02-14 15:43:03-0500      141744   8a1130005393975f9f4b9706c534eaacaf260e38677064ac677e5a10120b7520           0.00 SC             0 SF
2018-02-14 15:43:03-0500      141744   bd17de4cd49cb64402a12e4debbc3c48b3d667014a8cf0f0e375ab8f78016fcc         -33.33 SC             0 SF
```
