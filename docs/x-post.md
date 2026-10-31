# X launch thread — draft

Post as a thread. Attach the 90-second recording to post 1 or 2 if available.

**1/**
YouTube can erase a 2M-subscriber channel in 5 minutes.

The appeal? A bot says a human reviewed it.

We're building the open alternative — starting with the part that matters: due process for creators.

Demo + RFC below. 🧵

**2/**
We shipped a working walking skeleton:

• an original video plays
• an automated false positive is issued
• the creator files an appeal
• a human reverses it
• every step lands in a hash-chained ledger

Run it locally:
github.com/keel-foundation/keel-dev

**3/**
This is not a YouTube clone.

It's a protocol + reference implementation:

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
github.com/keel-foundation/keel-dev/issues?q=is%3Aissue+label%3Agood-first-issue

**8/**
If you've lost a channel to a false positive, or you want to build the lifeboat, comment or DM.

Not a YouTube killer. A creator-owned alternative with a covenant.

#BuildInPublic #PeerTube #OpenSource
