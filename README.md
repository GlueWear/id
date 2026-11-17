# ID

An identity card held on your own Urbit ship.

Fill in as much or as little as you like: name, date of birth, height, address,
phone, a photo, and lines of your own. Each line is **public** or **private**.
Anyone with ID can look you up by @p or by scanning your card. They see your
public lines straight away and can request the rest. You accept, deny or block.

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
- Every line starts **private**. Switch any line to **public** to show it to
  everyone who looks you up.
- Your name is a first name, a last name, and what you go by.
- Standard lines use one fixed form so every ID reads the same way:
  - date of birth: `YYYY-MM-DD`
  - height: `5 FT 11 IN`
  - weight: `170 LB`
  - sex: M or F
  - eye and hair colour, and country, from lists
  - phone numbers are checked against the country's numbering plan and saved in
    international form, e.g. `+44 20 7946 0000`
- The preview shows your ID two ways: **public** (what anyone sees) and
  **private** (your whole ID, as the ships you accept see it). Private lines
  carry an orange dot.

**Look up**
- Type an @p, scan an ID card with your camera, or choose a photo of a card.
- Opening an ID asks that ship for it. If the ship doesn't answer it is shown as
  **offline or unavailable**, with **Try again**. An open ID checks for changes
  every 30 seconds.
- If part of an ID is private, it is marked **PARTIAL** and the withheld lines
  are blacked out. Press **REQUEST ID** to ask for the rest.
- Once they accept, you see their whole ID, including later changes, until they
  revoke. Lines shared with you carry a green dot.
- Your list keeps only the ships you have looked up. Their names and thumbnails
  are fetched as you scroll, not stored.

**Requests**
- **Accept** shows the asker your whole ID. **Deny** keeps them to your public
  lines. **Block** denies every request they send from now on; they aren't told
  they are blocked.
- Everyone you have accepted is listed with **Revoke**. Blocked ships are listed
  with **Unblock**.

## The card

**MY ID → CARD CODE** gives you a QR code to print on a card, as SVG (vector)
or PNG. It holds only your @p, with your sigil in the middle. Whoever scans it
sees what you allow, live from your ship, so a lost card gives nothing away.

Scanning with the camera needs the page to be open over https (or on
localhost). Otherwise use **Photo of card**.

## What ID does and doesn't promise

- Your ID lives only on your ship. Other ships get only what you allow, over
  Urbit's own network, when they open it. The app doesn't keep a copy on their
  ship.
- After you revoke, the next time they open your ID they see only your public
  lines. Anything already shown could have been written down, and like every
  Urbit message it passes through their ship's event log.
- The details on an ID are what its owner typed in. ID proves which ship you are
  dealing with, not that the details are true.

## How it works

- `app/id.hoon`, the agent: holds your ID, the requests and who you have
  accepted. A ship opening your ID watches
  `/card/~that-ship/<full|row>/<hash of the photo it has>`. It is sent what it
  may see (the photo only if it doesn't have it) and then kicked, so the
  answer is used once. When what a ship may see changes, it gets a `%nudge` to
  fetch again. Ships running version 0.1 are still answered on `/view/~ship`.
- Your photo is saved with a 96×120 thumbnail, so lists stay small.
- `app/id-sigil.hoon` draws sigils as SVG at `/apps/id/sigil/~ship`, so the page
  needs no network for them.
- `lib/id/index.html` is the whole page. The QR, scanning and phone-number
  libraries are inlined at the end of it (see the licences below).

Built for `[%zuse 408]`.

## Licence

MIT for this project's code; see [LICENSE](LICENSE). Third-party parts keep
their own licences; see [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).
