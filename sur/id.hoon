::  sur/id -- ID: an identity card held on your own ship.
::
|%
::  one line of an ID.  key: a standard field ('first', 'height', ...),
::  'photo' (value is a data:image/ URL), 'thumb' (the same photo, tiny,
::  for lists; it goes wherever the photo goes), one of the extra
::  pictures, 'photo2' (a second photo) and 'sig' (a signature), a wallet
::  or social account ('wallet-1', 'social-1', ...) or a custom line
::  ('x1', 'x2', ...).  pub: shown to anyone who looks.  Otherwise only
::  to ships we accept.
::
+$  line  [key=@ta label=@t value=@t pub=?]
::
::  where a ship's request to see our private lines stands, as we tell it
::
+$  ask  ?(%none %wait %no)
::
::  what one ship may see of an ID: the public lines, or every line once
::  it is allowed (the private ones have pub=|), and how many it can't see
::
+$  view  [lines=(list line) hidden=@ud =ask]
::
::  fetching an ID: %full when it is opened, %row for a line in a list
::  (only the names and the thumbnail)
::
+$  mode  ?(%full %row)
::
::  a photo: its hash, the photo ('' in a %row answer) and the thumbnail
::
+$  pic  [hash=@uv full=@t thumb=@t]
::
::  the answer to a ship that watches /card/~itself/<mode>/<hash of the
::  photo it already has, or 0v0>: the lines it may see (never the photo),
::  whether it may see a photo and which one, then the photo itself unless
::  it has it.  Then it is kicked: an answer, not a subscription.
::
+$  news
  $%  [%lines lines=(list line) hidden=@ud =ask pic=(unit [hash=@uv pub=?])]
      [%pic =pic]
      [%live =show]                       ::  a live pass: what follows it shows
      [%nope why=?(%gone %used %expired)] ::  a live pass that doesn't work
      [%more pics=(list [key=@ta hash=@uv pub=?])]
      [%img key=@ta hash=@uv data=@t]
  ==
::
::  the extra pictures ('photo2', 'sig') never go out in %lines, so ID
::  apps from before them never see them.  A ship that knows them watches
::  /more/~itself/<hashes of those it has>: it is told which it may see
::  (%more), then sent each it lacks (%img), and kicked.
::
::  a live pass: the QR code SHOW ID puts on the screen.  It holds our @p
::  and code, a random number our ship just made.  A ship that scans it
::  watches /pass/~itself/<code>/<photo it has>; we answer once, and the
::  code is used up.  A public pass shows our public lines; a private one
::  shows the whole ID and offers that ship an exchange.  Either shows a
::  ship already accepted the whole ID.  Anyone can make up a code; only
::  ours works, and only we can answer for our @p.  One pass at a time,
::  for two minutes.
::
::  The same code opens on the web (Offline Azimuth): a ship with no ID,
::  the website's, watches /web/v1/<code>.  Either pass gives it only our
::  public lines.  The web never gets private lines: those are only ever
::  exchanged, ship to ship.
::
+$  show  ?(%public %private)
+$  pass
  $:  code=@uv
      =show
      until=@da                           ::  dead after this
      used=(unit @p)                      ::  scanned by
      web=?                               ::  that was the website
      seal=@t                             ::  unused, always ''
  ==
::
::  a ship we have looked up.  Its ID is never kept, only fetched.
::
+$  entry
  $:  added=@da                           ::  when we first looked it up
      asked=(unit @da)                    ::  our request, until they have it
      fresh=?                             ::  it changed what we may see
      told=@da                            ::  when it last said so
  ==
::
::  pokes from our own page
::
+$  action
  $%  [%save lines=(list line)]           ::  our ID, all of it
      [%look who=@p]                      ::  put a ship on our list
      [%fetch who=@p =mode have=@uv]      ::  ask a ship for its ID
      [%forget who=@p]
      [%ask who=@p note=@t]               ::  offer to exchange private details
      [%cancel who=@p]
      [%allow who=@p]                     ::  accept: let it see every line
      [%revoke who=@p]                    ::  end it (an exchange, both ways)
      [%decline who=@p]
      [%block who=@p]
      [%unblock who=@p]
      [%show =show seal=@t]               ::  make a live pass (seal unused)
      [%hide ~]                           ::  end it
      [%redeem who=@p code=@uv have=@uv]  ::  check a pass we scanned
      [%more who=@p have=(list @uv)]      ::  fetch its extra pictures
  ==
::
::  ship to ship
::
+$  msg
  $%  [%ask note=@t]                      ::  one way, from IDs before exchanges
      [%cancel ~]
      [%nudge ~]                          ::  "what you may see of my ID changed"
      [%offer ~]                          ::  exchange private details?
      [%accept ~]                         ::  yes: we show you ours, show us yours
      [%end ~]                            ::  our exchange is over, both ways
  ==
--
