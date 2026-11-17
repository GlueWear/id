::  id -- ID: an identity card held on your own ship.
::
::  You fill in whatever lines you like, each public or private, and one
::  photo.  Your ID stays on your ship.  Another ship running ID fetches it
::  when its owner opens it: it watches /card/~itself/<mode>/<photo it
::  has>, is sent what it may see, and is kicked.  That is an answer, not a
::  subscription; it is shown and not kept.  The other ship keeps only its
::  list of the ships it has looked up and its own pending requests.
::
::  To see private lines a ship asks.  You accept, deny or block.  A ship
::  you accept sees your whole ID until you revoke.  Whenever what a ship
::  may see changes, it is sent a %nudge, so it can fetch again.
::
::  Nothing here can stop someone writing down what they were shown.
::
::  Ships still running the first version watch /view/~itself and are sent
::  their whole view on every change, as they expect.
::
/-  *id
/+  default-agent, dbug, server
|%
+$  state-2
  $:  %2
      lines=(list line)                  ::  our ID
      allowed=(set @p)                   ::  ships that see all of it
      inbox=(map @p [note=@t when=@da])  ::  requests waiting on us
      declined=(set @p)                  ::  requests we turned down
      blocked=(set @p)
      book=(map @p entry)                ::  ships we have looked up
  ==
::  earlier states.  They kept a copy of every ID looked up; the upgrade
::  throws the copies away.
::
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
+$  versioned  $%(state-0 state-1 state-2)
+$  card  card:agent:gall
::
++  max-lines  40
++  max-key  16
++  max-label  40
++  max-value  1.000
++  max-photo  400.000
++  max-thumb  40.000
++  max-note  280
++  max-inbox  200
++  max-book  2.000
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
++  sees
  |=  [st=state-2 who=@p]
  ^-  ?
  &((~(has in allowed.st) who) !(~(has in blocked.st) who))
::
++  ask-for
  |=  [st=state-2 who=@p]
  ^-  ask
  ?:  (~(has by inbox.st) who)  %wait
  ?:  (~(has in declined.st) who)  %no
  %none
::
::  what ship who may see of our ID (the thumbnail aside)
::
++  view-for
  |=  [st=state-2 who=@p]
  ^-  view
  =/  all=?  (sees st who)
  =/  ls=(list line)  (skip lines.st |=(l=line =('thumb' key.l)))
  =/  vis=(list line)  (skim ls |=(l=line |(all pub.l)))
  [vis (sub (lent ls) (lent vis)) (ask-for st who)]
::
::  the photo, if who may see it
::
++  pic-for
  |=  [st=state-2 who=@p]
  ^-  (unit [hash=@uv pub=?])
  =/  p  (find-line lines.st 'photo')
  ?~  p  ~
  ?.  |(pub.u.p (sees st who))  ~
  `[(sham value.u.p) pub.u.p]
::
::  our answer when who fetches our ID (then it is kicked)
::
++  answer
  |=  [st=state-2 who=@p =mode have=@uv]
  ^-  (list card)
  =/  v  (view-for st who)
  =/  ls=(list line)
    %+  skip  lines.v
    |=  l=line
    ?|  =('photo' key.l)
        &(?=(%row mode) !(~(has in names) key.l))
    ==
  =/  pf  (pic-for st who)
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
  |=  [st=state-2 who=@p]
  ^-  card
  [%give %fact ~[/view/(scot %p who)] %id-view !>((view-for st who))]
::
::  after a change to our ID: our page, and first-version watchers
::
++  publish
  |=  [=bowl:gall st=state-2]
  ^-  (list card)
  :-  (ui-mine st)
  %+  turn  ~(tap in (viewers bowl))
  |=(who=@p (give-view st who))
::
::  after a change to what who alone may see: our page, a first-version
::  watcher's view, and a nudge to fetch again
::
++  tell
  |=  [st=state-2 who=@p]
  ^-  (list card)
  :~  (ui-mine st)
      (give-view st who)
      (send who [%nudge ~])
  ==
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
  |=  st=state-2
  ^-  json
  %-  pairs:enjs:format
  :~  ['lines' a+(turn lines.st line-json)]
      ['allowed' a+(turn ~(tap in allowed.st) |=(p=@p `json`s+(scot %p p)))]
      :-  'inbox'
      :-  %a
      %+  turn  ~(tap by inbox.st)
      |=  [p=@p note=@t when=@da]
      ^-  json
      %-  pairs:enjs:format
      :~  ['who' s+(scot %p p)]
          ['note' s+note]
          ['when' (ms `when)]
      ==
      ['blocked' a+(turn ~(tap in blocked.st) |=(p=@p `json`s+(scot %p p)))]
  ==
::
::  a fetched ID, passed straight to our page and not kept
::
++  ui-news
  |=  [who=@p =mode n=news]
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
  ==
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
  |=  st=state-2
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
    [?.(?=([%ui ~] path) cards (weld cards (tell inner bowl ~))) this]
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
=|  state-2
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
  =.  state
    ?-  -.o
      %2  o
      %1  [%2 lines.o allowed.o inbox.o declined.o blocked.o (up book.o)]
      %0  [%2 lines.o ~(key by grants.o) inbox.o declined.o blocked.o (up book.o)]
    ==
  :_  this
  :-  claim
  ?:  ?=(%2 -.o)  ~
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
      ::  withdraw any request: we don't keep whether one still waits there
      :_  this
      ;:  weld
        ~[(send who.act [%cancel ~])]
        (drop-fetches bowl who.act ~)
        ~[(ui (frond:enjs:format 'gone' s+(scot %p who.act)))]
      ==
    ::
        %ask
      ?:  =(who.act our.bowl)  `this
      ?:  (gth (met 3 note.act) max-note)
        [~[(note 'That note is too long.')] this]
      =/  had  (~(get by book) who.act)
      ?:  &(?=(~ had) (gte ~(wyt by book) max-book))
        [~[(note 'Your list of IDs is full: forget some first.')] this]
      =/  e=entry  ?~(had [now.bowl `now.bowl | now.bowl] u.had(asked `now.bowl, fresh |))
      =.  book  (~(put by book) who.act e)
      [~[(ui-entry who.act e) (send who.act [%ask note.act])] this]
    ::
        %cancel
      =/  had  (~(get by book) who.act)
      ?~  had  [~[(send who.act [%cancel ~])] this]
      =/  e=entry  u.had(asked ~)
      =.  book  (~(put by book) who.act e)
      [~[(send who.act [%cancel ~]) (ui-entry who.act e)] this]
    ::
        %allow
      ?:  =(who.act our.bowl)  `this
      =.  allowed  (~(put in allowed) who.act)
      =.  inbox  (~(del by inbox) who.act)
      =.  declined  (~(del in declined) who.act)
      =.  blocked  (~(del in blocked) who.act)
      [(tell state who.act) this]
    ::
        %revoke
      =.  allowed  (~(del in allowed) who.act)
      [(tell state who.act) this]
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
      =/  told=?
        |((~(has by inbox) who.act) (~(has in allowed) who.act))
      =?  declined  (~(has by inbox) who.act)  (~(put in declined) who.act)
      =.  inbox  (~(del by inbox) who.act)
      =.  allowed  (~(del in allowed) who.act)
      =.  blocked  (~(put in blocked) who.act)
      ?:  told  [(tell state who.act) this]
      [~[(ui-mine state) (give-view state who.act)] this]
    ::
        %unblock
      ::  a fresh start: they may ask again, and they see that at once
      =/  told=?  (~(has in declined) who.act)
      =.  blocked  (~(del in blocked) who.act)
      =.  declined  (~(del in declined) who.act)
      ?:  told  [(tell state who.act) this]
      [~[(ui-mine state) (give-view state who.act)] this]
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
      =.  inbox  (~(put by inbox) who [note.msg now.bowl])
      =.  declined  (~(del in declined) who)
      [~[(ui-mine state) (give-view state who)] this]
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
      [%ui ~]
    ?>  =(src.bowl our.bowl)
    :_  this
    :~  %-  ui
        %+  frond:enjs:format  'init'
        %-  pairs:enjs:format
        :~  ['our' s+(scot %p our.bowl)]
            ['mine' (mine-json state)]
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
    ``json+!>(`json`s+(scot %uv (sham [lines allowed inbox declined blocked book])))
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
      ?.  ?=(?(%ask %cancel) i.t.wire)  `this
      [~[(ui (frond:enjs:format 'acked' s+(scot %p who)))] this]
    ?.  ?=(%ask i.t.wire)  `this
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
          %pic
        ?.  (good-pic pic.u.n)  `this
        [~[(ui-news who mode u.n)] this]
      ::
          %lines
        ?.  (good-lines 2 lines.u.n)  `this
        ::  our request is theirs once they say it waits or was declined
        =/  had  (~(get by book) who)
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
