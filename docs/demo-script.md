# 90-second demo script

Record at 1440×900, browser zoom 100%, no personal tabs or notifications. Voiceover is optional; the on-screen story should stand alone.

## 0–8s — Start

Show the terminal:

```sh
make demo
```

Show the expected output:

```
→ starting moderation
→ starting web
  moderation ready
  web ready

Demo:  http://localhost:3000/demo
Logs:  .demo/*.log
Press Ctrl-C to stop.
```

## 8–20s — The setup

Open `http://localhost:3000/demo`. Play the clip for two seconds.

Say or caption:

> Mara Vale published an original eight-second documentary. An automated classifier thinks it is mass-produced spam.

Point at the status badge: `published`, no enforcement action.

## 20–35s — The false positive

Click **1. Issue false positive**.

Show:

- status changes to `active`;
- policy `spam.mass_production`;
- evidence lines (`model: spam-v0.1`, `confidence: 0.91`);
- the audit hash.

Caption: “A decision with a specific reason, evidence, and a reviewer — not a generic ban.”

## 35–50s — The appeal

Click **2. File appeal**.

Show the grounds, the appeal status `pending`, and a new ledger record: `appeal.filed`.

Caption: “The creator gets a real appeal, with their own evidence.”

## 50–65s — Human review

Click **3. Reverse on human review**.

Show:

- appeal `decided` / `reverse`;
- action `reversed`;
- reasoning text;
- ledger records `appeal.decided` and `enforcement_action.reversed`.

Caption: “A human can reverse the machine. The reversal is recorded forever.”

## 65–78s — The ledger

Scroll the audit ledger. Point at the chained hashes and sequence numbers.

Caption: “Every step is tamper-evident and exportable. This is the part YouTube does not show you.”

## 78–90s — Call to action

Cut to the repository or a title card:

> TubeKeel is building creator-owned video with real due process.
>
> We need maintainers for the media pipeline, trust and safety, payments, and the creator studio.
>
> RFC-0001 is open for comment.

End on `github.com/keel-foundation`.

## Recording

macOS: QuickTime Player → File → New Screen Recording. Record the browser and terminal only. Export as `docs/demo-90s.mp4` and attach it to the launch post.

If `make demo` skips `core` and `pipeline` because Go is not installed, the UI still works with the bundled sample clip; the appeal and ledger flow are unchanged.
