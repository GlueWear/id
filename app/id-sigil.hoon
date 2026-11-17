::  %id-sigil: a ship's sigil as an SVG image, at /apps/id/sigil/~ship
::
::    ?fg=rrggbb&bg=rrggbb pick the colours (default: white on black).
::    Drawn on the ship, so the page needs no sigil library and no network.
::    Stateless and separate from %id, so the symbol data stays out of its
::    build and a fault here can't take ID down.  Copied from Noltbook's
::    %noltbook-sigil.  A given address always returns the same drawing,
::    so responses are cacheable for good.
::
/+  default-agent, server, sigil
|%
+$  card  card:agent:gall
::
++  connect
  ^-  card
  [%pass /eyre/connect %arvo %e %connect [~ /apps/id/sigil] %id-sigil]
::
::  a colour from the query string: six hex digits, or the default
::
++  colour
  |=  [v=(unit @t) def=tape]
  ^-  tape
  ?~  v  def
  =/  t=tape  (trip u.v)
  ?.  =(6 (lent t))  def
  ?.  (levy t |=(c=@tD ?=(^ (find ~[c] "0123456789abcdefABCDEF"))))  def
  (weld "#" t)
::
::  serve: /apps/id/sigil/~ship -> the sigil; anything else -> 404, never a crash
::
++  serve
  |=  =request:http
  ^-  simple-payload:http
  =/  rl  (parse-request-line:server url.request)
  ?.  ?=([%apps %id %sigil @ ~] site.rl)  not-found:gen:server
  =/  who=(unit ship)  (slaw %p `@ta`i.t.t.t.site.rl)
  ?~  who  not-found:gen:server
  =/  args  (malt args.rl)
  =/  fg=tape  (colour (~(get by args) 'fg') "#ffffff")
  =/  bg=tape  (colour (~(get by args) 'bg') "#000000")
  =/  pic=(each manx tang)
    %-  mule  |.
    %.  u.who
    %_  sigil
      fg      fg
      bg      bg
      size    128
      margin  |
      icon    |
    ==
  ?:  ?=(%| -.pic)  not-found:gen:server
  :_  `(manx-to-octs:server p.pic)
  :-  200
  :~  ['content-type' 'image/svg+xml']
      ['cache-control' 'public, max-age=31536000, immutable']
  ==
--
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %|) bowl)
++  on-init
  ^-  (quip card _this)
  [~[connect] this]
++  on-save  !>(~)
++  on-load
  |=  old=vase
  ^-  (quip card _this)
  [~[connect] this]
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?.  ?=(%handle-http-request mark)  (on-poke:def mark vase)
  =+  !<([eyre-id=@ta =inbound-request:eyre] vase)
  :_  this
  %+  give-simple-payload:app:server  eyre-id
  ?.  ?=(%'GET' method.request.inbound-request)  not-found:gen:server
  (serve request.inbound-request)
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ?:  ?=([%http-response @ ~] path)  `this
  (on-watch:def path)
++  on-leave  on-leave:def
++  on-peek   on-peek:def
++  on-agent  on-agent:def
++  on-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip card _this)
  ?:  ?=([%eyre %bound *] sign-arvo)  `this
  (on-arvo:def wire sign-arvo)
++  on-fail   on-fail:def
--
