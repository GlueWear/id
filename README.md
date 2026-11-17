# ID

An identity card held on your own Urbit ship.

Fill in as much or as little as you like: name, date of birth, height, address,
phone, a photo, and lines of your own. Each line is **public** or **private**.
Anyone with ID can look you up by @p or by scanning your card. They see your
public lines straight away and can request the rest. You accept, deny or block.

To prove it's you, press **SHOW ID**. It shows a live pass: a QR code that
works once, for two minutes, and that only your ship can answer for.

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
  **PRIVATE** shows your whole ID. The small QR square on the card flips it
  over to the back, which holds your card code (see below).
- **EDIT ID** opens the editor on its own screen, so your private lines are
  never just a scroll away. On a wide screen the card's preview sits beside it.
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
- Private lines carry an orange dot.

**Show ID**
- **SHOW ID** opens on a **public** pass, a QR code of your public lines.
  Choose **PRIVATE** for a pass of your whole ID.
- Your ship makes a new random code for each pass. It works once, for two
  minutes. When it is scanned your screen says who scanned it.
- Closing the screen, switching between public and private, or leaving the
  app ends the code at once.
- The other person scans it in ID (**LOOK UP → SCAN CODE**). Their ship asks
  yours whether the code is real. Only your ship can answer for your @p, so a
  made-up code fails. They see what the pass shows, once, marked
  **LIVE · VERIFIED** with the time, and they don't keep it. It doesn't give
  them lasting access.

**Look up**
- Type an @p, scan an ID card or a live pass with your camera, or choose a
  photo of one.
- Opening an ID asks that ship for it. If the ship doesn't answer it is shown as
  **offline or unavailable**, with **Try again**. An open ID checks for changes
  every 30 seconds.
- If part of an ID is private, it is marked **PARTIAL** and the withheld lines
  are blacked out. Press **REQUEST ID** to ask for the rest.
- Once they accept, you see their whole ID, including later changes, until they
  revoke. Lines shared with you carry a green dot.
- Your list keeps only the ships you have looked up. Their names and thumbnails
  are fetched as you scroll, not stored. Lists and IDs wait on a loading screen
  until their pictures have come (two seconds at most for a list), so they
  appear whole.

**Requests**
- **Accept** shows the asker your whole ID. **Deny** keeps them to your public
  lines. **Block** denies every request they send from now on; they aren't told
  they are blocked.
- Everyone you have accepted is listed with **Revoke**. Blocked ships are listed
  with **Unblock**.

## The card

The back of your card on **MY ID** holds a QR code to print on a card, as SVG
(vector) or PNG. It holds only your @p, with your sigil in the middle. Whoever
scans it sees what you allow, live from your ship, so a lost card gives nothing
away. A card only says who to look up. To prove it's you, use **SHOW ID**.

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
- A verified live pass proves that whoever showed it controls that ship and
  chose to show it, just now. It doesn't prove who is holding the phone, so
  compare their face with the photo.

## How it works

- `app/id.hoon`, the agent: holds your ID, the requests and who you have
  accepted. A ship opening your ID watches
  `/card/~that-ship/<full|row>/<hash of the photo it has>`. It is sent what it
  may see (the photo only if it doesn't have it) and then kicked, so the
  answer is used once. When what a ship may see changes, it gets a `%nudge` to
  fetch again. Ships running version 0.1 are still answered on `/view/~ship`.
- A live pass is a QR code of `IDPASS:SHIP:CODE`, where the code is 128 random
  bits from the owner's ship. The scanning ship watches
  `/pass/~itself/<code>/<hash of the photo it has>` on the owner.
  - If the code is the owner's live pass, unexpired and unused, the owner sends
    `%live`, then the public lines or the whole ID, then kicks. The code is then
    used up, though the same ship may ask again.
  - Otherwise it gets `%nope` with `%gone`, `%used` or `%expired`.
  - A blocked ship is told `%gone`, and the pass stays unused.
  - There is one pass at a time.
- Your photo is saved with a 96×120 thumbnail, so lists stay small.
- `app/id-sigil.hoon` draws sigils as SVG at `/apps/id/sigil/~ship`, so the page
  needs no network for them.
- `lib/id/index.html` is the whole page. The QR, scanning and phone-number
  libraries are inlined at the end of it (see the licences below).

Built for `[%zuse 408]`.

## Licence

MIT for this project's code; see [LICENSE](LICENSE). Third-party parts keep
their own licences; see [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).
