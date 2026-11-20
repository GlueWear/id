# ID

An identity card held on your own Urbit ship.

Fill in as much or as little as you like: your name, a photo, your signature,
date of birth, height, address, phone, wallets, accounts and lines of your own.
Each line is **public** or **private**. Anyone can look you up by @p or by
scanning your card and see your public lines. Private details are never just
taken: they are **exchanged**. You see someone's private details only when they
can see yours.

To prove it's you, press **SHOW ID**. It shows a live pass: a QR code that
works once, for two minutes, and that only your ship can answer for. People
without Urbit can scan it with a phone camera too: it opens on
[offlineazimuth.com](https://offlineazimuth.com).

Your ID stays on your ship. Other ships fetch it when someone opens it, show
it, and don't keep it.

The app and desk are named `%id`.

## Install

```
|install ~nolset %id
```

Then open **ID** from your home screen, or go to `/apps/id` on your ship.

## Use

**My ID**
- Opens on your card's **public** side: what anyone who looks you up sees.
- The card shows your photo; your first, middle and last name; what you go by;
  your ship's class and number (worked out from your @p); your signature; and
  in the corner a second photo, or a faded copy of the first. Tap a photo to see
  it full size.
- The strip across the top holds your sigil and @p, **PUBLIC | PRIVATE**, and a
  small QR square. **PRIVATE** shows your whole ID, in orange so you can tell at
  a glance. The QR square flips the card to its back (see **The card**).
- **EDIT ID** opens the editor on its own screen, so your private lines are
  never just a scroll away. Every line starts **private**; switch any line to
  **public** to show it to everyone.
- Standard lines use one fixed form, so every ID reads the same way:
  - date of birth `YYYY-MM-DD`, height `5 FT 11 IN`, weight `170 LB`, sex M or F
  - eyes, hair, blood type, organ donor and country from lists
  - the address in parts: street, street 2, city, state / region, postal code,
    country
  - phone numbers checked against the country's numbering plan and saved in
    international form, e.g. `+44 20 7946 0000`
  - wallets checked with each chain's own checksum (Ethereum, Bitcoin, Solana),
    and accounts for X, Bluesky, Farcaster, GitHub, Instagram, Nostr, Telegram
    and Discord, as many as you like
  - a website, linked only if it is a plain http(s) address
- Your signature is drawn on screen and saved as a small vector drawing.
- Private lines carry an orange dot.

**How ID works**
- Tap the ID icon at the top left for a short guide, with your @p and the
  version you are running.

**Exchanging private details**
- On someone's ID, **EXCHANGE PRIVATE DETAILS** sends them an offer.
- They **accept** (and you both see each other's whole ID, including later
  changes), **deny**, or **block** (their offers are turned down from now on;
  they aren't told).
- Either of you can **END EXCHANGE** at any time, and then neither sees the
  other's private details. It can't erase what was already seen.
- The **EXCHANGES** tab lists offers waiting on you, who you exchange with, your
  own offers, and blocked ships. **ACCEPT & EXCHANGE** takes you to their ID.
- A ship still running an ID from before exchanges can only ask one way, and is
  marked so. Accepting it shows it your ID without showing you theirs.

**Show ID**
- **SHOW ID** opens on a **public** pass: your public lines (or your whole ID,
  for a ship you already exchange with).
- **PRIVATE** makes a pass that also offers an exchange to whoever scans it in
  ID. They see **EXCHANGE & VIEW**.
- Your ship makes a new random code for each pass. It works once, for two
  minutes. When it is scanned, your screen shows **✓ VERIFIED** with the ship
  that scanned it and its card, or **WEB VIEWER** if it was opened on the web.
- Closing the screen, switching between public and private, or leaving the app
  ends the code at once.
- Someone with ID scans it in **LOOK UP**. Their ship asks yours whether the
  code is real; only your ship can answer for your @p, so a made-up code fails.
- Someone without ID scans it with a phone camera. It opens on
  offlineazimuth.com, checked with your ship the same way. **On the web, either
  pass shows only your public lines.** Private details are only ever exchanged
  in ID.

**Look up**
- Type an @p, scan an ID card or a live pass with your camera, or choose a
  photo of one.
- Opening an ID asks that ship for it. If the ship doesn't answer it is shown as
  **offline or unavailable**, with **Try again**. An open ID checks for changes
  every 30 seconds.
- If part of an ID is private, it is marked **PARTIAL** and the withheld lines
  are blacked out. Lines shared with you carry a green dot.
- Your list keeps only the ships you have looked up. Their names and thumbnails
  are fetched as you scroll, not stored.

## The card

The back of your card on **MY ID** holds a QR code to print on a card, as SVG
(vector) or PNG, with your sigil in the middle. It is a link to your public ID:
`https://offlineazimuth.com/id/~your-ship`.

- A phone camera opens it on the web, for anyone.
- ID's own scanner reads it as your @p, so it opens your ID in the app. Older
  versions of ID read it the same way.
- Whoever scans it sees only what you allow, live from your ship, so a lost card
  gives nothing away. A card only says who to look up; anyone can copy one. To
  prove it's you, use **SHOW ID**.

Scanning with the camera inside ID needs the page to be open over https (or on
localhost). Otherwise use **Photo of card**.

## Offline Azimuth

[offlineazimuth.com](https://offlineazimuth.com) shows public IDs to people who
don't run Urbit. Its server has its own Urbit identity and asks your ship over
Urbit's network, like any other ship would. It only ever gets your **public**
lines: from `/public/v1` when someone opens your card's link, and from a live
pass when someone scans one. It keeps nothing, sets no cookies and never logs in
to your ship.

## What ID does and doesn't promise

- Your ID lives only on your ship. Other ships get only what you allow, over
  Urbit's own network, when they open it. The app doesn't keep a copy on their
  ship.
- The page keeps one note in your browser: which ships didn't answer last time,
  and when, so it can show them as offline at once. Nothing from anyone's ID is
  kept there.
- After an exchange ends, each side sees only the other's public lines the next
  time it opens the ID. Anything already shown could have been written down, and
  like every Urbit message it passes through the other ship's event log.
- The details on an ID are what its owner typed in. ID proves which ship you are
  dealing with, not that the details are true.
- A verified live pass proves that whoever showed it controls that ship and
  chose to show it, just now. It doesn't prove who is holding the phone, so
  compare their face with the photo.

## How it works

- `app/id.hoon`, the agent, holds your ID, the offers, exchanges and blocks.
- A ship opening your ID watches
  `/card/~that-ship/<full|row>/<hash of the photo it has>`. It is sent what it
  may see (the photo only if it doesn't have it) and then kicked, so the answer
  is used once. When what a ship may see changes, it gets a `%nudge` to fetch
  again.
- The second photo and the signature travel apart from the lines, on
  `/more/~that-ship/<hashes it has>`, so IDs from before them never see them.
- Exchanges are ship-to-ship pokes: `%offer`, `%accept` and `%end`. A ship whose
  ID predates exchanges refuses `%offer` and is asked the old one-way way
  (`%ask`).
- A live pass is a link, `https://offlineazimuth.com/p/~ship/<code>`, where the
  code is 128 random bits from the owner's ship.
  - A ship with ID watches `/pass/~itself/<code>/<hash of the photo it has>` on
    the owner. If the code is the owner's live pass, unexpired and unused, the
    owner sends `%live`, then everything that ship may see, then kicks. A
    private pass also offers that ship an exchange. Otherwise it gets `%nope`
    with `%gone`, `%used` or `%expired`.
  - The website watches `/web/v1/<code>` and gets the public lines (as JSON), or
    `gone`, `expired` or `used`.
  - The code is then used up, though the same ship may ask again. A blocked ship
    is told it's gone, and the pass stays unused. There is one pass at a time.
  - Passes from earlier versions, `IDPASS:SHIP:CODE`, are still read.
- `/public/v1` gives the public lines once, as JSON, for the website and other
  clients.
- Saved data from every earlier version upgrades in place: 0.4's waiting
  requests become one-way requests, and ships it had accepted stay one-way.
- Your photo is saved with a 96×120 thumbnail, so lists stay small.
- `app/id-sigil.hoon` draws sigils as SVG at `/apps/id/sigil/~ship`, so the page
  needs no network for them.
- `lib/id/index.html` is the whole page. The QR, scanning and phone-number
  libraries are inlined at the end of it (see the licences below).

Built for `[%zuse 408]`.

## Licence

MIT for this project's code; see [LICENSE](LICENSE). Third-party parts keep
their own licences; see [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).
