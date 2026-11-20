::  id -- ID: an identity card held on your own ship.
::
::  You fill in whatever lines you like, each public or private, and one
::  photo.  Your ID stays on your ship.  Another ship running ID fetches it
::  when its owner opens it: it watches /card/~itself/<mode>/<photo it
::  has>, is sent what it may see, and is kicked.  That is an answer, not a
::  subscription; it is shown and not kept.  The other ship keeps only its
::  list of the ships it has looked up and its own pending requests.
::
::  Private lines are exchanged, never just taken: a ship offers to
::  exchange (%offer), and if you accept (%accept) each sees the other's
::  whole ID, until either ends it (%end), which ends it both ways.  You
::  accept, deny or block.  A ship running an ID from before exchanges
::  still asks the old, one-way way (%ask), and is asked that way.
::  Whenever what a ship may see changes, it is sent a %nudge, so it can
::  fetch again.
::
::  Nothing here can stop someone writing down what they were shown.
::
::  SHOW ID makes a live pass (see sur/id): a QR code holding our @p and a
::  random code, good once, for two minutes.  The ship that scans it asks
::  us; only we can answer for our @p, so the answer proves that whoever
::  showed the code controls this ship and chose to show it, just now.
::  A private pass also offers that ship an exchange.  The website, a ship
::  with no ID, opens the same pass at /web/v1/<code> (see sur/id) and
::  gets only our public lines, whichever pass it is.
::
::  Ships still running the first version watch /view/~itself and are sent
::  their whole view on every change, as they expect.
::
::  The extra pictures, a second photo and a signature, travel apart from
::  the lines (see sur/id): a ship that knows them also watches
::  /more/~itself/<those it has>.  Earlier versions never ask, and are
::  never sent them.
::
/-  *id
/+  default-agent, dbug, server
|%
+$  state-5
  $:  %5
      lines=(list line)                  ::  our ID
      allowed=(set @p)                   ::  ships that see all of it
      inbox=(map @p held)                ::  offers and requests waiting on us
      declined=(set @p)                  ::  ones we turned down
      blocked=(set @p)
      book=(map @p entry)                ::  ships we have looked up
      live=(unit pass)                   ::  our live pass, if any
      mutual=(set @p)                    ::  of the allowed, those we exchange with
      offers=(map @p @da)                ::  our offers to exchange, standing
      elder=(set @p)                     ::  ships whose ID is from before exchanges
  ==
::  waiting on us: an offer to exchange (two), or a one-way request from an
::  ID from before exchanges
::
+$  held  [note=@t when=@da two=?]
::
::  earlier states.  Up to %4, a pass had no web use or seal.
::
+$  pass-4  [code=@uv =show until=@da used=(unit @p)]
+$  state-4
  $:  %4
      lines=(list line)
      allowed=(set @p)
      inbox=(map @p held)
      declined=(set @p)
      blocked=(set @p)
      book=(map @p entry)
      live=(unit pass-4)
      mutual=(set @p)
      offers=(map @p @da)
      elder=(set @p)
  ==
+$  state-3
  $:  %3
      lines=(list line)                  ::  our ID
      allowed=(set @p)                   ::  ships that see all of it
      inbox=(map @p [note=@t when=@da])  ::  requests waiting on us
      declined=(set @p)                  ::  requests we turned down
      blocked=(set @p)
      book=(map @p entry)                ::  ships we have looked up
      live=(unit pass-4)                 ::  our live pass, if any
  ==
::  earlier states.  The first two kept a copy of every ID looked up; the
::  upgrade throws the copies away.
::
+$  state-2
  $:  %2
      lines=(list line)
      allowed=(set @p)
      inbox=(map @p [note=@t when=@da])
      declined=(set @p)
      blocked=(set @p)
      book=(map @p entry)
  ==
+$  entry-0  [view=(unit view) got=(unit @da) asked=(unit @da) gone=? fresh=?]
+$  state-1
  $:  %1
      lines=(list line)
      allowed=(set @p)
      inbox=(map @p [note=@t when=@da])
      declined=(set @p)
      blocked=(set @p)
      book=(map @p entry-0)
  ==
+$  state-0
  $:  %0
      lines=(list line)
      grants=(map @p (set @ta))
      inbox=(map @p [note=@t when=@da])
      declined=(set @p)
      blocked=(set @p)
      book=(map @p entry-0)
  ==
+$  versioned  $%(state-0 state-1 state-2 state-3 state-4 state-5)
+$  card  card:agent:gall
::
++  max-lines  60
++  max-key  16
++  max-label  40
++  max-value  1.000
++  max-photo  400.000
++  max-thumb  40.000
++  max-sig  60.000
++  max-note  280
++  max-inbox  200
++  max-offers  500
++  max-book  2.000
++  pass-life  ~m2
::
++  claim
  ^-  card
  [%pass /eyre-bind %arvo %e %connect [~ /apps/id] %id]
::
::  a line we would keep.  k loosens the limits for IDs sent by other
::  ships, which may run a later version.
::
++  good-line
  |=  [k=@ud l=line]
  ^-  ?
  ?&  ((sane %ta) key.l)
      !=(0 (met 3 key.l))
      (lte (met 3 key.l) (mul k max-key))
      (lte (met 3 label.l) (mul k max-label))
      !=(0 (met 3 value.l))
      ?:  =('photo' key.l)  (good-image value.l (mul k max-photo))
      ?:  =('photo2' key.l)  (good-image value.l (mul k max-photo))
      ?:  =('sig' key.l)  (good-image value.l (mul k max-sig))
      ?:  =('thumb' key.l)  (good-image value.l (mul k max-thumb))
      (lte (met 3 value.l) (mul k max-value))
  ==
::
++  good-image
  |=  [v=@t max=@ud]
  ^-  ?
  &((lte (met 3 v) max) =('data:image/' (end [3 11] v)))
::
++  good-lines
  |=  [k=@ud ls=(list line)]
  ^-  ?
  ?&  (lte (lent ls) (add 1 (mul k max-lines)))
      (levy ls |=(l=line (good-line k l)))
      =((lent ls) ~(wyt in (silt (turn ls |=(l=line key.l)))))
  ==
::
::  another ship's extra pictures: which there are, then each one, whose
::  hash must be its own.  Any sane key, for later versions' pictures.
::
++  good-more
  |=  ps=(list [key=@ta hash=@uv pub=?])
  ^-  ?
  ?&  (lte (lent ps) 8)
      (levy ps |=([key=@ta hash=@uv pub=?] &(((sane %ta) key) (lte (met 3 key) (mul 2 max-key)))))
  ==
::
++  good-img
  |=  [key=@ta hash=@uv data=@t]
  ^-  ?
  ?&  ((sane %ta) key)
      (lte (met 3 key) (mul 2 max-key))
      (good-image data (mul 2 max-photo))
      =(hash (sham data))
  ==
::
::  a photo from another ship: the hash must be the photo's ('' in a %row
::  answer, which carries only the thumbnail)
::
++  good-pic
  |=  p=pic
  ^-  ?
  ?&  |(=('' full.p) (good-image full.p (mul 2 max-photo)))
      |(=('' thumb.p) (good-image thumb.p (mul 2 max-thumb)))
      |(=('' full.p) =(hash.p (sham full.p)))
  ==
::
++  find-line
  |=  [ls=(list line) k=@ta]
  ^-  (unit line)
  |-
  ?~  ls  ~
  ?:  =(k key.i.ls)  `i.ls
  $(ls t.ls)
::
::  the thumbnail goes with the photo: dropped without one, private with it
::
++  norm
  |=  ls=(list line)
  ^-  (list line)
  =/  p  (find-line ls 'photo')
  ?~  p  (skip ls |=(l=line =('thumb' key.l)))
  (turn ls |=(l=line ?.(=('thumb' key.l) l l(pub pub.u.p))))
::
++  names  (silt `(list @ta)`~['first' 'last' 'preferred' 'name'])
::
::  the extra pictures: never in %lines, only on /more
::
++  extras  (silt `(list @ta)`~['photo2' 'sig'])
::
++  sees
  |=  [st=state-5 who=@p]
  ^-  ?
  &((~(has in allowed.st) who) !(~(has in blocked.st) who))
::
++  ask-for
  |=  [st=state-5 who=@p]
  ^-  ask
  ?:  (~(has by inbox.st) who)  %wait
  ?:  (~(has in declined.st) who)  %no
  %none
::
::  what ship who may see of our ID (the thumbnail aside): all of it, or
::  the public lines
::
++  view-for
  |=  [st=state-5 who=@p]
  ^-  view
  (view-as st who (sees st who))
::
++  view-as
  |=  [st=state-5 who=@p all=?]
  ^-  view
  =/  ls=(list line)  (skip lines.st |=(l=line =('thumb' key.l)))
  =/  vis=(list line)  (skim ls |=(l=line |(all pub.l)))
  ::  the extra pictures count as withheld when they are, but are sent
  ::  only on /more
  :+  (skip vis |=(l=line (~(has in extras) key.l)))
    (sub (lent ls) (lent vis))
  (ask-for st who)
::
::  the photo, if it is public or all may be seen
::
++  pic-as
  |=  [st=state-5 all=?]
  ^-  (unit [hash=@uv pub=?])
  =/  p  (find-line lines.st 'photo')
  ?~  p  ~
  ?.  |(pub.u.p all)  ~
  `[(sham value.u.p) pub.u.p]
::
::  our answer when who fetches our ID (then it is kicked)
::
++  answer
  |=  [st=state-5 who=@p =mode have=@uv]
  ^-  (list card)
  (answer-as st who mode have (sees st who))
::
::  the same, showing all of it or the public lines (a fetch, or a live
::  pass, shows what who may see)
::
++  answer-as
  |=  [st=state-5 who=@p =mode have=@uv all=?]
  ^-  (list card)
  =/  v  (view-as st who all)
  =/  ls=(list line)
    %+  skip  lines.v
    |=  l=line
    ?|  =('photo' key.l)
        &(?=(%row mode) !(~(has in names) key.l))
    ==
  =/  pf  (pic-as st all)
  =/  give  |=(n=news `card`[%give %fact ~ %id-news !>(n)])
  :-  (give [%lines ls hidden.v ask.v pf])
  =/  p  (find-line lines.st 'photo')
  ?~  pf  ~
  ?~  p  ~
  =/  t  (find-line lines.st 'thumb')
  =/  thumb=@t  ?~(t '' value.u.t)
  ?:  ?=(%row mode)
    ?:  =('' thumb)  ~
    ~[(give [%pic hash.u.pf '' thumb])]
  ?:  =(have hash.u.pf)  ~
  ~[(give [%pic hash.u.pf value.u.p thumb])]
::
::  our answer on /more: the extra pictures who may see, then each one
::  it doesn't have yet
::
++  more-as
  |=  [st=state-5 all=? have=(list @uv)]
  ^-  (list card)
  =/  ls=(list line)
    (skim lines.st |=(l=line &((~(has in extras) key.l) |(all pub.l))))
  =/  give  |=(n=news `card`[%give %fact ~ %id-news !>(n)])
  :-  (give [%more (turn ls |=(l=line [key.l (sham value.l) pub.l]))])
  %+  murn  ls
  |=  l=line
  ^-  (unit card)
  =/  h=@uv  (sham value.l)
  ?^  (find ~[h] have)  ~
  `(give [%img key.l h value.l])
::
::  ships running the first version, each on its own /view path
::
++  viewers
  |=  =bowl:gall
  ^-  (set @p)
  %-  silt
  %+  murn  ~(val by sup.bowl)
  |=  [who=@p =path]
  ^-  (unit @p)
  ?.  ?=([%view @ ~] path)  ~
  (slaw %p i.t.path)
::
++  give-view
  |=  [st=state-5 who=@p]
  ^-  card
  [%give %fact ~[/view/(scot %p who)] %id-view !>((view-for st who))]
::
::  after a change to our ID: our page, and first-version watchers
::
++  publish
  |=  [=bowl:gall st=state-5]
  ^-  (list card)
  :-  (ui-mine st)
  %+  turn  ~(tap in (viewers bowl))
  |=(who=@p (give-view st who))
::
::  after a change to what who alone may see: our page, a first-version
::  watcher's view, and a nudge to fetch again
::
++  tell
  |=  [st=state-5 who=@p]
  ^-  (list card)
  :~  (ui-mine st)
      (give-view st who)
      (send who [%nudge ~])
  ==
::
::  accept who's offer or request: they see our whole ID.  An offer makes
::  an exchange: we tell them, and they show us theirs.
::
++  accept
  |=  [st=state-5 who=@p]
  ^-  (quip card state-5)
  =/  q  (~(get by inbox.st) who)
  =/  two=?  ?~(q | two.u.q)
  =.  allowed.st  (~(put in allowed.st) who)
  =.  inbox.st  (~(del by inbox.st) who)
  =.  declined.st  (~(del in declined.st) who)
  =.  blocked.st  (~(del in blocked.st) who)
  =?  mutual.st  two  (~(put in mutual.st) who)
  =?  offers.st  two  (~(del by offers.st) who)
  :_  st
  %+  weld  (tell st who)
  ?.(two ~ ~[(send who [%accept ~])])
::
::  who stops seeing our private lines.  An exchange ends both ways, so
::  they are told, and stop showing us theirs.
::
++  unshare
  |=  [st=state-5 who=@p]
  ^-  (quip card state-5)
  =/  was=?  (~(has in mutual.st) who)
  =.  allowed.st  (~(del in allowed.st) who)
  =.  mutual.st  (~(del in mutual.st) who)
  :_  st
  %+  weld  (tell st who)
  ?.(was ~ ~[(send who [%end ~])])
::
::  fetching: one answer, on a wire of its own.  A fetch of the same kind
::  still waiting (a ship that is offline) is dropped first.
::
++  fetch
  |=  [=bowl:gall who=@p =mode have=@uv]
  ^-  (list card)
  ?:  =(who our.bowl)  ~
  %+  snoc  (drop-fetches bowl who `mode)
  :*  %pass  ~[%get (scot %p who) mode (scot %da now.bowl)]
      %agent  [who %id]
      %watch  ~[%card (scot %p our.bowl) mode (scot %uv have)]
  ==
::
::  a ship running the first version answers only on /view, and keeps
::  sending; we take one answer and leave
::
++  fetch-old
  |=  [=bowl:gall who=@p =mode]
  ^-  card
  :*  %pass  ~[%old (scot %p who) mode (scot %da now.bowl)]
      %agent  [who %id]
      %watch  /view/(scot %p our.bowl)
  ==
::
++  drop-fetches
  |=  [=bowl:gall who=@p which=(unit mode)]
  ^-  (list card)
  %+  murn  ~(tap by wex.bowl)
  |=  [[w=wire s=@p d=term] *]
  ^-  (unit card)
  ?.  &(=(s who) =(d %id))  ~
  ?.  ?=([?(%get %old) @ @ @ ~] w)  ~
  ?:  &(?=(^ which) !=(u.which i.t.t.w))  ~
  `[%pass w %agent [who %id] %leave ~]
::
::  a fetch of extra pictures still waiting
::
++  drop-more
  |=  [=bowl:gall who=@p]
  ^-  (list card)
  %+  murn  ~(tap by wex.bowl)
  |=  [[w=wire s=@p d=term] *]
  ^-  (unit card)
  ?.  &(=(s who) =(d %id) ?=([%more @ @ ~] w))  ~
  `[%pass w %agent [who %id] %leave ~]
::
++  send
  |=  [who=@p =msg]
  ^-  card
  [%pass ~[%msg -.msg (scot %p who)] %agent [who %id] %poke %id-msg !>(msg)]
::
::  JSON for our own page
::
++  ms
  |=  d=(unit @da)
  ^-  json
  ?~(d ~ (time:enjs:format u.d))
::
++  line-json
  |=  l=line
  ^-  json
  %-  pairs:enjs:format
  :~  ['key' s+key.l]
      ['label' s+label.l]
      ['value' s+value.l]
      ['pub' b+pub.l]
  ==
::
++  entry-json
  |=  [who=@p e=entry]
  ^-  json
  %-  pairs:enjs:format
  :~  ['who' s+(scot %p who)]
      ['added' (ms `added.e)]
      ['asked' (ms asked.e)]
      ['fresh' b+fresh.e]
      ['told' (ms `told.e)]
  ==
::
++  mine-json
  |=  st=state-5
  ^-  json
  %-  pairs:enjs:format
  :~  ['lines' a+(turn lines.st line-json)]
      ['allowed' a+(turn ~(tap in allowed.st) |=(p=@p `json`s+(scot %p p)))]
      :-  'inbox'
      :-  %a
      %+  turn  ~(tap by inbox.st)
      |=  [p=@p note=@t when=@da two=?]
      ^-  json
      %-  pairs:enjs:format
      :~  ['who' s+(scot %p p)]
          ['note' s+note]
          ['when' (ms `when)]
          ['two' b+two]
      ==
      ['blocked' a+(turn ~(tap in blocked.st) |=(p=@p `json`s+(scot %p p)))]
      ['mutual' a+(turn ~(tap in mutual.st) |=(p=@p `json`s+(scot %p p)))]
      :-  'offers'
      :-  %a
      %+  turn  ~(tap by offers.st)
      |=  [p=@p when=@da]
      ^-  json
      (pairs:enjs:format ~[['who' s+(scot %p p)] ['when' (ms `when)]])
      ['elder' a+(turn ~(tap in elder.st) |=(p=@p `json`s+(scot %p p)))]
  ==
::
::  The web gateway always gets public lines, even if its ship is allowed.
++  public-json
  |=  [who=@p st=state-5]
  ^-  json
  %-  pairs:enjs:format
  :~  ['version' (numb:enjs:format 1)]
      ['ship' s+(scot %p who)]
      ['lines' a+(turn (skim lines.st |=(l=line pub.l)) line-json)]
  ==
::
::  a fetched ID, passed straight to our page and not kept
::
++  ui-news
  |=  [who=@p mode=@tas n=news]
  ^-  card
  %-  ui
  ?-    -.n
      %lines
    %+  frond:enjs:format  'got'
    %-  pairs:enjs:format
    :~  ['who' s+(scot %p who)]
        ['mode' s+mode]
        ['lines' a+(turn lines.n line-json)]
        ['hidden' (numb:enjs:format hidden.n)]
        ['ask' s+ask.n]
        :-  'pic'
        ?~  pic.n  ~
        (pairs:enjs:format ~[['hash' s+(scot %uv hash.u.pic.n)] ['pub' b+pub.u.pic.n]])
    ==
  ::
      %pic
    %+  frond:enjs:format  'pic'
    %-  pairs:enjs:format
    :~  ['who' s+(scot %p who)]
        ['hash' s+(scot %uv hash.pic.n)]
        ['full' s+full.pic.n]
        ['thumb' s+thumb.pic.n]
    ==
  ::
      %live
    %+  frond:enjs:format  'live'
    (pairs:enjs:format ~[['who' s+(scot %p who)] ['show' s+show.n]])
  ::
      %nope
    %+  frond:enjs:format  'passfail'
    (pairs:enjs:format ~[['who' s+(scot %p who)] ['why' s+why.n]])
  ::
      %more
    %+  frond:enjs:format  'more'
    %-  pairs:enjs:format
    :~  ['who' s+(scot %p who)]
        :-  'pics'
        :-  %a
        %+  turn  pics.n
        |=  [key=@ta hash=@uv pub=?]
        ^-  json
        (pairs:enjs:format ~[['key' s+key] ['hash' s+(scot %uv hash)] ['pub' b+pub]])
    ==
  ::
      %img
    %+  frond:enjs:format  'img'
    %-  pairs:enjs:format
    :~  ['who' s+(scot %p who)]
        ['key' s+key.n]
        ['hash' s+(scot %uv hash.n)]
        ['data' s+data.n]
    ==
  ==
::
::  our live pass, for our page: the code, what it shows, how long it has
::  left and who scanned it.  A dead one is null.
::
++  pass-json
  |=  [now=@da p=(unit pass)]
  ^-  json
  ?~  p  ~
  ?:  (gte now until.u.p)  ~
  %-  pairs:enjs:format
  :~  ['code' s+(scot %uv code.u.p)]
      ['show' s+show.u.p]
      ['left' (numb:enjs:format (div (sub until.u.p now) (div ~s1 1.000)))]
      ['used' ?~(used.u.p ~ s+(scot %p u.used.u.p))]
      ['web' b+web.u.p]
  ==
::
++  ui-pass
  |=  [now=@da p=(unit pass)]
  ^-  card
  (ui (frond:enjs:format 'pass' (pass-json now p)))
::
++  ui-who
  |=  [key=@t who=@p =mode]
  ^-  card
  (ui (frond:enjs:format key (pairs:enjs:format ~[['who' s+(scot %p who)] ['mode' s+mode]])))
::
++  ui
  |=  jon=json
  ^-  card
  [%give %fact ~[/ui] %json !>(jon)]
::
++  ui-mine
  |=  st=state-5
  ^-  card
  (ui (frond:enjs:format 'mine' (mine-json st)))
::
++  ui-entry
  |=  [who=@p e=entry]
  ^-  card
  (ui (frond:enjs:format 'entry' (entry-json who e)))
::
++  note
  |=  text=@t
  ^-  card
  (ui (frond:enjs:format 'note' s+text))
::
::  +stamped: wraps the agent so every event ends by telling our page the
::  stamp of the new state (see /x/stamp).  The page polls the stamp too;
::  if the ship's differs from the last one it was told, it missed events
::  and reconnects.
::
++  stamped
  |=  inner=agent:gall
  =/  tell
    |=  [a=agent:gall =bowl:gall paths=(list path)]
    ^-  (list card)
    =/  p  (mole |.((~(on-peek a bowl) /x/stamp)))
    ?.  ?=([~ ~ ~ *] p)  ~
    ~[[%give %fact paths %json !>((frond:enjs:format 'stamp' !<(json q.u.u.u.p)))]]
  ^-  agent:gall
  |_  =bowl:gall
  +*  this  .
      ag    ~(. inner bowl)
  ++  on-init
    ^-  (quip card agent:gall)
    =^  cards  inner  on-init:ag
    [cards this]
  ++  on-save  on-save:ag
  ++  on-load
    |=  old=vase
    ^-  (quip card agent:gall)
    =^  cards  inner  (on-load:ag old)
    [cards this]
  ++  on-poke
    |=  [=mark =vase]
    ^-  (quip card agent:gall)
    =^  cards  inner  (on-poke:ag mark vase)
    [(weld cards (tell inner bowl ~[/ui])) this]
  ++  on-watch
    |=  =path
    ^-  (quip card agent:gall)
    =^  cards  inner  (on-watch:ag path)
    :_  this
    ?+  path  cards
      [%ui ~]     (weld cards (tell inner bowl ~))
      [%pass *]   (weld cards (tell inner bowl ~[/ui]))
      [%web *]    (weld cards (tell inner bowl ~[/ui]))
    ==
  ++  on-leave
    |=  =path
    ^-  (quip card agent:gall)
    =^  cards  inner  (on-leave:ag path)
    [cards this]
  ++  on-peek  on-peek:ag
  ++  on-agent
    |=  [=wire =sign:agent:gall]
    ^-  (quip card agent:gall)
    =^  cards  inner  (on-agent:ag wire sign)
    [(weld cards (tell inner bowl ~[/ui])) this]
  ++  on-arvo
    |=  [=wire =sign-arvo]
    ^-  (quip card agent:gall)
    =^  cards  inner  (on-arvo:ag wire sign-arvo)
    [cards this]
  ++  on-fail
    |=  [=term =tang]
    ^-  (quip card agent:gall)
    =^  cards  inner  (on-fail:ag term tang)
    [cards this]
  --
--
::
%-  stamped
%-  agent:dbug
=|  state-5
=*  state  -
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %|) bowl)
::
++  on-init
  ^-  (quip card _this)
  [~[claim] this]
::
++  on-save  !>(state)
::
++  on-load
  |=  old=vase
  ^-  (quip card _this)
  ::  a state we can't read is never thrown away: refuse to load, and Gall
  ::  keeps the previous build running with the ID intact
  =/  prev  (mole |.(!<(versioned old)))
  ?~  prev  ~|(%id-cannot-read-saved-state !!)
  =/  o=versioned  u.prev
  =/  up
    |=  b=(map @p entry-0)
    ^-  (map @p entry)
    (~(run by b) |=(e=entry-0 `entry`[(fall got.e now.bowl) asked.e fresh.e (fall got.e now.bowl)]))
  ::  from %3: what waits on us was asked the one-way way; no exchanges yet
  =/  four
    |=  t=state-3
    ^-  state-4
    =/  in  (~(run by inbox.t) |=([note=@t when=@da] `held`[note when |]))
    [%4 lines.t allowed.t in declined.t blocked.t book.t live.t ~ ~ ~]
  ::  from %4: a pass so far was never opened on the web, and has no seal
  =/  five
    |=  t=state-4
    ^-  state-5
    =/  l=(unit pass)  ?~(live.t ~ `[code show until used | '']:u.live.t)
    [%5 lines.t allowed.t inbox.t declined.t blocked.t book.t l mutual.t offers.t elder.t]
  =.  state
    ?-  -.o
      %5  o
      %4  (five o)
      %3  (five (four o))
      %2  (five (four [%3 lines.o allowed.o inbox.o declined.o blocked.o book.o ~]))
      %1  (five (four [%3 lines.o allowed.o inbox.o declined.o blocked.o (up book.o) ~]))
      %0  (five (four [%3 lines.o ~(key by grants.o) inbox.o declined.o blocked.o (up book.o) ~]))
    ==
  :_  this
  :-  claim
  ?:  ?=(?(%2 %3 %4 %5) -.o)  ~
  ::  the first versions kept a standing subscription to every ID looked
  ::  up: leave them
  %+  murn  ~(tap by wex.bowl)
  |=  [[w=wire s=@p d=term] *]
  ^-  (unit card)
  ?.  &(=(d %id) ?=([%look @ ~] w))  ~
  `[%pass w %agent [s %id] %leave ~]
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?+    mark  (on-poke:def mark vase)
      %id-action
    ?>  =(src.bowl our.bowl)
    =/  act  !<(action vase)
    ?-    -.act
        %save
      =/  ls=(list line)  (norm lines.act)
      ?.  (good-lines 1 ls)
        :_  this
        ~[(note 'Not saved: a line is too long, there are too many lines, or a line is repeated.')]
      =.  lines  ls
      [(publish bowl state) this]
    ::
        %look
      ?:  =(who.act our.bowl)  `this
      =/  had  (~(get by book) who.act)
      ?:  &(?=(~ had) (gte ~(wyt by book) max-book))
        [~[(note 'Your list of IDs is full: forget some first.')] this]
      =/  e=entry  ?~(had [now.bowl ~ | now.bowl] u.had(fresh |))
      =.  book  (~(put by book) who.act e)
      [~[(ui-entry who.act e)] this]
    ::
        %fetch
      [(fetch bowl who.act mode.act have.act) this]
    ::
        %forget
      =/  had  (~(get by book) who.act)
      ?~  had  `this
      =.  book  (~(del by book) who.act)
      =.  offers  (~(del by offers) who.act)
      ::  withdraw any request: we don't keep whether one still waits there
      :_  this
      ;:  weld
        ~[(send who.act [%cancel ~])]
        (drop-fetches bowl who.act ~)
        (drop-more bowl who.act)
        ~[(ui (frond:enjs:format 'gone' s+(scot %p who.act)))]
      ==
    ::
        %ask
      ::  an offer to exchange private details.  It stands until they
      ::  accept or decline it, or we cancel it.  An ID from before
      ::  exchanges is asked the old, one-way way.
      ?:  =(who.act our.bowl)  `this
      ?:  (gth (met 3 note.act) max-note)
        [~[(note 'That note is too long.')] this]
      =/  had  (~(get by book) who.act)
      ?:  &(?=(~ had) (gte ~(wyt by book) max-book))
        [~[(note 'Your list of IDs is full: forget some first.')] this]
      ?:  &(!(~(has by offers) who.act) (gte ~(wyt by offers) max-offers))
        [~[(note 'You have too many offers waiting: cancel some first.')] this]
      =/  e=entry  ?~(had [now.bowl `now.bowl | now.bowl] u.had(asked `now.bowl, fresh |))
      =.  book  (~(put by book) who.act e)
      =.  offers  (~(put by offers) who.act now.bowl)
      ::  they offered first: accepting theirs is the exchange
      =/  q  (~(get by inbox) who.act)
      ?:  &(?=(^ q) two.u.q)
        =^  cards  state  (accept state who.act)
        [[(ui-entry who.act e) cards] this]
      :_  this
      :~  (ui-entry who.act e)
          (ui-mine state)
          (send who.act ?:((~(has in elder) who.act) [%ask note.act] [%offer ~]))
      ==
    ::
        %cancel
      =.  offers  (~(del by offers) who.act)
      =/  had  (~(get by book) who.act)
      ?~  had  [~[(send who.act [%cancel ~]) (ui-mine state)] this]
      =/  e=entry  u.had(asked ~)
      =.  book  (~(put by book) who.act e)
      [~[(send who.act [%cancel ~]) (ui-entry who.act e) (ui-mine state)] this]
    ::
        %allow
      ?:  =(who.act our.bowl)  `this
      =^  cards  state  (accept state who.act)
      [cards this]
    ::
        %revoke
      =^  cards  state  (unshare state who.act)
      [cards this]
    ::
        %decline
      =.  inbox  (~(del by inbox) who.act)
      =.  declined  (~(put in declined) who.act)
      [(tell state who.act) this]
    ::
        %block
      ?:  =(who.act our.bowl)  `this
      ::  a waiting request is declined and an allowed ship loses its view,
      ::  and either is told; a ship that had neither is told nothing, so
      ::  blocking looks like nothing at all
      ::  An exchange ends, both ways, and our offer is withdrawn.
      =/  told=?
        |((~(has by inbox) who.act) (~(has in allowed) who.act))
      =/  end=(list card)  ?.((~(has in mutual) who.act) ~ ~[(send who.act [%end ~])])
      =?  declined  (~(has by inbox) who.act)  (~(put in declined) who.act)
      =.  inbox  (~(del by inbox) who.act)
      =.  allowed  (~(del in allowed) who.act)
      =.  mutual  (~(del in mutual) who.act)
      =.  offers  (~(del by offers) who.act)
      =.  blocked  (~(put in blocked) who.act)
      ?:  told  [(weld (tell state who.act) end) this]
      [(weld ~[(ui-mine state) (give-view state who.act)] end) this]
    ::
        %unblock
      ::  a fresh start: they may ask again, and they see that at once
      =/  told=?  (~(has in declined) who.act)
      =.  blocked  (~(del in blocked) who.act)
      =.  declined  (~(del in declined) who.act)
      ?:  told  [(tell state who.act) this]
      [~[(ui-mine state) (give-view state who.act)] this]
    ::
        %show
      ::  a new pass ends the last one.  The code is 128 random bits.
      =.  live  `[`@uv`(end [3 16] eny.bowl) show.act (add now.bowl pass-life) ~ | '']
      [~[(ui-pass now.bowl live)] this]
    ::
        %hide
      =.  live  ~
      [~[(ui-pass now.bowl live)] this]
    ::
        %redeem
      ?:  =(who.act our.bowl)  `this
      ::  one check at a time with each ship
      =/  old=(list card)
        %+  murn  ~(tap by wex.bowl)
        |=  [[w=wire s=@p d=term] *]
        ^-  (unit card)
        ?.  &(=(s who.act) =(d %id) ?=([%pass @ @ ~] w))  ~
        `[%pass w %agent [s %id] %leave ~]
      :_  this
      %+  snoc  old
      :*  %pass  ~[%pass (scot %p who.act) (scot %da now.bowl)]
          %agent  [who.act %id]
          %watch  ~[%pass (scot %p our.bowl) (scot %uv code.act) (scot %uv have.act)]
      ==
    ::
        %more
      ?:  =(who.act our.bowl)  `this
      ?>  (lte (lent have.act) 8)
      :_  this
      %+  snoc  (drop-more bowl who.act)
      :*  %pass  ~[%more (scot %p who.act) (scot %da now.bowl)]
          %agent  [who.act %id]
          %watch  (weld /more/(scot %p our.bowl) (turn have.act |=(h=@uv (scot %uv h))))
      ==
    ==
  ::
      %id-msg
    =/  =msg  !<(msg vase)
    =/  who=@p  src.bowl
    ?:  =(who our.bowl)  `this
    ?-    -.msg
        %ask
      ?>  (lte (met 3 note.msg) max-note)
      ::  a blocked ship's request is declined at once
      ?:  (~(has in blocked) who)
        =.  declined  (~(put in declined) who)
        [~[(give-view state who)] this]
      ?:  &(!(~(has by inbox) who) (gte ~(wyt by inbox) max-inbox))
        `this
      =.  inbox  (~(put by inbox) who [note.msg now.bowl |])
      =.  declined  (~(del in declined) who)
      [~[(ui-mine state) (give-view state who)] this]
    ::
        %offer
      ::  an offer to exchange.  If ours to them stands too, that is an
      ::  exchange at once.  If we exchange already (they lost track), say so.
      ?:  (~(has in blocked) who)
        =.  declined  (~(put in declined) who)
        [~[(give-view state who)] this]
      ?:  (~(has in mutual) who)
        [~[(send who [%accept ~])] this]
      ?:  &(!(~(has by inbox) who) (gte ~(wyt by inbox) max-inbox))
        `this
      =.  inbox  (~(put by inbox) who ['' now.bowl &])
      =.  declined  (~(del in declined) who)
      ?:  (~(has by offers) who)
        =^  cards  state  (accept state who)
        [cards this]
      [~[(ui-mine state) (give-view state who)] this]
    ::
        %accept
      ::  they accepted our offer and show us their whole ID, so we show
      ::  them ours.  If our offer doesn't stand (we cancelled it, or
      ::  blocked them), there is no exchange, and they are told.
      ?:  |((~(has in blocked) who) !(~(has by offers) who))
        ?:  (~(has in mutual) who)  `this
        [~[(send who [%end ~])] this]
      =.  offers  (~(del by offers) who)
      =.  allowed  (~(put in allowed) who)
      =.  mutual  (~(put in mutual) who)
      =.  inbox  (~(del by inbox) who)
      =.  declined  (~(del in declined) who)
      =/  had  (~(get by book) who)
      =/  e=entry  ?~(had [now.bowl ~ & now.bowl] u.had(asked ~, fresh &, told now.bowl))
      =?  book  |(?=(^ had) (lth ~(wyt by book) max-book))  (~(put by book) who e)
      :_  this
      %+  weld  (tell state who)
      :~  (ui-entry who e)
          (ui (frond:enjs:format 'exchanged' s+(scot %p who)))
      ==
    ::
        %end
      ::  they ended our exchange: neither sees the other's private lines
      ?.  (~(has in mutual) who)  `this
      =.  allowed  (~(del in allowed) who)
      =.  mutual  (~(del in mutual) who)
      [(snoc (tell state who) (ui (frond:enjs:format 'ended' s+(scot %p who)))) this]
    ::
        %cancel
      ?.  (~(has by inbox) who)  `this
      =.  inbox  (~(del by inbox) who)
      [~[(ui-mine state) (give-view state who)] this]
    ::
        %nudge
      ::  what we may see of their ID changed: mark it, and tell our page.
      ::  The time changes our state, so a page that missed this notices.
      ?:  (~(has in blocked) who)  `this
      =/  had  (~(get by book) who)
      ?:  &(?=(~ had) (gte ~(wyt by book) max-book))  `this
      =/  e=entry  ?~(had [now.bowl ~ & now.bowl] u.had(fresh &, told now.bowl))
      =.  book  (~(put by book) who e)
      :_  this
      :~  (ui-entry who e)
          (ui (frond:enjs:format 'nudge' s+(scot %p who)))
      ==
    ==
  ::
      %handle-http-request
    =+  !<([eyre-id=@ta =inbound-request:eyre] vase)
    ?.  authenticated.inbound-request
      :_  this
      %+  give-simple-payload:app:server  eyre-id
      (login-redirect:gen:server request.inbound-request)
    =/  base=path  ~[(scot %p our.bowl) q.byk.bowl (scot %da now.bowl)]
    =/  body=octs
      (as-octs:mimes:html .^(@ %cx (weld base /lib/id/index/html)))
    :_  this
    %+  give-simple-payload:app:server  eyre-id
    :-  [200 ~[['content-type' 'text/html; charset=utf-8'] ['cache-control' 'no-store']]]
    `body
  ==
::
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ?+    path  (on-watch:def path)
      [%http-response *]  `this
  ::
  ::  A one-shot, public-only answer for Offline Azimuth and other clients.
  ::
      [%public %v1 ~]
    :_  this
    :~  [%give %fact ~ %json !>((public-json our.bowl state))]
        [%give %kick ~ ~]
    ==
  ::
      [%ui ~]
    ?>  =(src.bowl our.bowl)
    :_  this
    :~  %-  ui
        %+  frond:enjs:format  'init'
        %-  pairs:enjs:format
        :~  ['our' s+(scot %p our.bowl)]
            ['mine' (mine-json state)]
            ['pass' (pass-json now.bowl live)]
            :-  'book'
            :-  %a
            %+  turn  ~(tap by book)
            |=([w=@p e=entry] (entry-json w e))
        ==
    ==
  ::
  ::  a ship fetching our ID: one answer, then kicked
  ::
      [%card @ @ @ ~]
    =/  who=@p  (slav %p i.t.path)
    ?>  =(src.bowl who)
    =/  =mode  ;;(mode i.t.t.path)
    =/  have=@uv  (slav %uv i.t.t.t.path)
    :_  this
    (snoc (answer state who mode have) [%give %kick ~ ~])
  ::
  ::  a ship that scanned our live pass: once, then kicked.  A code that
  ::  isn't ours, or a blocked ship, gets %gone and the pass stays unused.
  ::  The ship that used it may ask again (its first answer may be lost).
  ::
      [%pass @ @ @ ~]
    =/  who=@p  (slav %p i.t.path)
    ?>  =(src.bowl who)
    =/  code=@uv  (slav %uv i.t.t.path)
    =/  have=@uv  (slav %uv i.t.t.t.path)
    =/  give  |=(n=news `card`[%give %fact ~ %id-news !>(n)])
    =/  kick=card  [%give %kick ~ ~]
    =/  why=(unit ?(%gone %used %expired))
      ?~  live  `%gone
      ?.  =(code code.u.live)  `%gone
      ?:  (~(has in blocked) who)  `%gone
      ?:  (gte now.bowl until.u.live)  `%expired
      ?:  &(?=(^ used.u.live) !=(who u.used.u.live))  `%used
      ~
    ?^  why  [~[(give [%nope u.why]) kick] this]
    ?>  ?=(^ live)
    =/  =show  show.u.live
    =.  live  `u.live(used `who)
    ::  Either pass shows who all it may see.  Whoever scanned it goes on
    ::  our list, so we see their card in return.  A private pass is our
    ::  offer to exchange private details with them: if they accept, each
    ::  sees the other's whole ID.
    =/  had  (~(get by book) who)
    =/  room=?  |(?=(^ had) (lth ~(wyt by book) max-book))
    =/  e=entry  ?~(had [now.bowl ~ | now.bowl] u.had)
    =?  book  room  (~(put by book) who e)
    =/  offer=?
      ?&  ?=(%private show)
          !(~(has in mutual) who)
          |((~(has by offers) who) (lth ~(wyt by offers) max-offers))
      ==
    =?  offers  offer  (~(put by offers) who now.bowl)
    :_  this
    ;:  weld
      ~[(give [%live show])]
      (answer-as state who %full have (sees state who))
      ~[kick (ui-pass now.bowl live)]
      ?.(room ~ ~[(ui-entry who e)])
      ?.  offer  ~
      ~[(ui-mine state) (send who ?:((~(has in elder) who) [%ask ''] [%offer ~]))]
    ==
  ::
  ::  the website opening our live pass for someone with no ID (see
  ::  sur/id): once, then kicked; the ship that used it may ask again.
  ::  Only our public lines, whichever pass it is.  Nothing goes on our
  ::  list and nothing is exchanged.
  ::
      [%web %v1 @ ~]
    =/  code=(unit @uv)  (slaw %uv i.t.t.path)
    =/  head=(list [@t json])
      ~[['version' (numb:enjs:format 1)] ['ship' s+(scot %p our.bowl)]]
    =/  give
      |=  j=(list [@t json])
      ^-  card
      [%give %fact ~ %json !>(`json`(pairs:enjs:format (weld head j)))]
    =/  kick=card  [%give %kick ~ ~]
    =/  why=(unit @t)
      ?~  code  `'gone'
      ?~  live  `'gone'
      ?.  =(u.code code.u.live)  `'gone'
      ?:  (~(has in blocked) src.bowl)  `'gone'
      ?:  (gte now.bowl until.u.live)  `'expired'
      ?:  &(?=(^ used.u.live) !=(src.bowl u.used.u.live))  `'used'
      ~
    ?^  why  [~[(give ~[['error' s+u.why]]) kick] this]
    ?>  ?=(^ live)
    =.  live  `u.live(used `src.bowl, web &)
    :_  this
    :~  %-  give
        :~  ['pass' s+show.u.live]
            ['lines' a+(turn (skim lines |=(l=line pub.l)) line-json)]
        ==
        kick
        (ui-pass now.bowl live)
    ==
  ::
  ::  a ship fetching our extra pictures: which it may see, each it lacks,
  ::  then kicked
  ::
      [%more @ *]
    =/  who=@p  (slav %p i.t.path)
    ?>  =(src.bowl who)
    =/  hs=(list @ta)  t.t.path
    ?>  (lte (lent hs) 8)
    =/  have=(list @uv)  (turn hs |=(t=@ta (slav %uv t)))
    :_  this
    (snoc (more-as state (sees state who) have) [%give %kick ~ ~])
  ::
  ::  a ship running the first version
  ::
      [%view @ ~]
    =/  who=@p  (slav %p i.t.path)
    ?>  =(src.bowl who)
    [~[[%give %fact ~ %id-view !>((view-for state who))]] this]
  ==
::
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?+  path  (on-peek:def path)
    [%x %mine ~]  ``json+!>((mine-json state))
  ::
  ::  a hash of everything the page shows (see +stamped)
  ::
      [%x %stamp ~]
    ``json+!>(`json`s+(scot %uv (sham [lines allowed inbox declined blocked book live mutual offers elder])))
  ==
::
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)
  ?+    wire  (on-agent:def wire sign)
      [%msg @ @ ~]
    ?.  ?=(%poke-ack -.sign)  `this
    =/  who=@p  (slav %p i.t.t.wire)
    ::  a request or cancel arrived: our page fetches again to see it
    ?~  p.sign
      ?.  ?=(?(%ask %cancel %offer) i.t.wire)  `this
      [~[(ui (frond:enjs:format 'acked' s+(scot %p who)))] this]
    ::  an ID from before exchanges refuses an offer: ask it the old way
    ?:  ?=(%offer i.t.wire)
      =.  elder  (~(put in elder) who)
      [~[(send who [%ask '']) (ui-mine state)] this]
    ?.  ?=(%ask i.t.wire)  `this
    =.  offers  (~(del by offers) who)
    =/  what=@t
      (rap 3 ~['The ship ' (scot %p who) ' did not take your request. Is ID installed there?'])
    =/  had  (~(get by book) who)
    ?~  had  [~[(note what)] this]
    =/  e=entry  u.had(asked ~)
    =.  book  (~(put by book) who e)
    [~[(ui-entry who e) (note what)] this]
  ::
      [%get @ @ @ ~]
    =/  who=@p  (slav %p i.t.wire)
    =/  =mode  ;;(mode i.t.t.wire)
    ?+    -.sign  `this
        %watch-ack
      ?~  p.sign  `this
      ::  no answer on /card: an ID app from before fetching, or none
      [~[(fetch-old bowl who mode)] this]
    ::
        %fact
      ?.  =(%id-news p.cage.sign)  `this
      =/  n  (mole |.(!<(news q.cage.sign)))
      ?~  n  `this
      ?-    -.u.n
          ?(%live %nope %more %img)  `this
          %pic
        ?.  (good-pic pic.u.n)  `this
        [~[(ui-news who mode u.n)] this]
      ::
          %lines
        ?.  (good-lines 2 lines.u.n)  `this
        ::  our request is theirs once they say it waits or was declined
        =/  had  (~(get by book) who)
        ::  a decline ends our offer
        ?:  &(?=(%no ask.u.n) (~(has by offers) who))
          =.  offers  (~(del by offers) who)
          =/  e=(unit entry)  ?~(had ~ `u.had(asked ~))
          =?  book  ?=(^ e)  (~(put by book) who (need e))
          :_  this
          :*  (ui-mine state)
              (ui-news who mode u.n)
              ?~(e ~ ~[(ui-entry who u.e)])
          ==
        ?:  |(?=(~ had) ?=(~ asked.u.had) ?=(%none ask.u.n))
          [~[(ui-news who mode u.n)] this]
        =/  e=entry  u.had(asked ~)
        =.  book  (~(put by book) who e)
        [~[(ui-entry who e) (ui-news who mode u.n)] this]
      ==
    ==
  ::
      [%old @ @ @ ~]
    =/  who=@p  (slav %p i.t.wire)
    =/  =mode  ;;(mode i.t.t.wire)
    ?+    -.sign  `this
        %watch-ack
      ?~  p.sign  `this
      [~[(ui-who 'noapp' who mode)] this]
    ::
        %fact
      ::  one answer, as a fetch would give it; then stop listening
      =/  leave=card  [%pass wire %agent [who %id] %leave ~]
      ?.  =(%id-view p.cage.sign)  [~[leave] this]
      =/  v  (mole |.(!<(view q.cage.sign)))
      ?~  v  [~[leave] this]
      ?.  (good-lines 2 lines.u.v)  [~[leave] this]
      =/  p  (find-line lines.u.v 'photo')
      =/  ls  (skip lines.u.v |=(l=line |(=('photo' key.l) =('thumb' key.l))))
      =/  ph=(unit [hash=@uv pub=?])  ?~(p ~ `[(sham value.u.p) pub.u.p])
      :_  this
      ;:  weld
        ~[(ui-news who mode [%lines ls hidden.u.v ask.u.v ph])]
        ?~(p ~ ~[(ui-news who mode [%pic (sham value.u.p) value.u.p ''])])
        ~[leave]
      ==
    ==
  ::
  ::  a live pass we scanned: their ship's answer, passed to our page and
  ::  not kept.  A ship that refuses the watch runs an ID without passes.
  ::
      [%pass @ @ ~]
    =/  who=@p  (slav %p i.t.wire)
    ?+    -.sign  `this
        %watch-ack
      ?~  p.sign  `this
      =/  why=json  (pairs:enjs:format ~[['who' s+(scot %p who)] ['why' s+'old']])
      [~[(ui (frond:enjs:format 'passfail' why))] this]
    ::
        %fact
      ?.  =(%id-news p.cage.sign)  `this
      =/  n  (mole |.(!<(news q.cage.sign)))
      ?~  n  `this
      ?-    -.u.n
          ?(%live %nope)  [~[(ui-news who %pass u.n)] this]
          ?(%more %img)  `this
          %pic
        ?.  (good-pic pic.u.n)  `this
        [~[(ui-news who %pass u.n)] this]
      ::
          %lines
        ?.  (good-lines 2 lines.u.n)  `this
        [~[(ui-news who %pass u.n)] this]
      ==
    ==
  ::
  ::  a ship's extra pictures: passed to our page and not kept.  A ship
  ::  that refuses the watch runs an ID from before them: none.
  ::
      [%more @ @ ~]
    =/  who=@p  (slav %p i.t.wire)
    ?+    -.sign  `this
        %watch-ack
      ?~  p.sign  `this
      [~[(ui-news who %full [%more ~])] this]
    ::
        %fact
      ?.  =(%id-news p.cage.sign)  `this
      =/  n  (mole |.(!<(news q.cage.sign)))
      ?~  n  `this
      ?+    -.u.n  `this
          %more
        ?.  (good-more pics.u.n)  `this
        [~[(ui-news who %full u.n)] this]
      ::
          %img
        ?.  (good-img +.u.n)  `this
        [~[(ui-news who %full u.n)] this]
      ==
    ==
  ::
  ::  standing subscriptions from the first versions, being left
  ::
      [%look @ ~]  `this
  ==
::
++  on-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip card _this)
  ?+  wire  (on-arvo:def wire sign-arvo)
    [%eyre-bind ~]  `this
  ==
::
++  on-leave  on-leave:def
++  on-fail   on-fail:def
--
