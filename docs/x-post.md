# X launch thread — draft

Post as a thread only after the 90-second recording exists and the links below return 200. Attach the recording to post 1 or 2.

The demo is local, the classifier signal is synthetic, and the ledger is not externally anchored yet. Say that plainly.

**1/**
A single automated decision can erase a 2M-subscriber channel.

The appeal? A bot says a human reviewed it.

We're building the open alternative — starting with the part that matters: due process for creators.

Demo + RFC below. 🧵

**2/**
We shipped a working local appeal demo:

• an original video plays
• a synthetic automated signal flags it
• the creator files an appeal
• an independent reviewer reverses it
• every step lands in a hash-chained, append-only ledger that can be verified and exported

Run it locally:
github.com/keel-foundation/keel-dev

**3/**
This is not a YouTube clone.

The protocol is designed around:

• PeerTube-compatible ActivityPub
• creator-owned identity and export
• moderation-first data model
• content protection: piracy, spam, scams, impersonation
• transparent payouts

**4/**
The rule is simple:

AI can flag.
AI can triage.
AI cannot be the final judge on a creator's livelihood.

Channel-level actions need a specific reason, evidence, a human reviewer, an appeal path, and a published reversal rate.

**5/**
Still to build:

• real upload + FFmpeg/HLS pipeline
• policy engine + review queue
• PeerTube federation
• payout ledger
• creator studio + moderation console
• CSAM, copyright, and safety operations

**6/**
We need founding maintainers:

• Go + FFmpeg / media pipeline
• trust and safety / policy / appeals
• payments + double-entry ledger
• Next.js creator studio
• infra / CDN / storage
• technical writing

**7/**
RFC-0001 is open for 14 days:
github.com/keel-foundation/keel-spec/discussions/1

Good first issues:
github.com/search?q=org%3Akeel-foundation+label%3Agood-first-issue+state%3Aopen&type=issues

**8/**
If you've lost a channel to a false positive, or you want to build the lifeboat, comment or DM.

Not a YouTube killer. A creator-owned alternative with a covenant.

#BuildInPublic #PeerTube #OpenSource
