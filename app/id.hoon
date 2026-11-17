::  id -- ID: an identity card held on your own ship.
::
::  You fill in whatever lines you like, each public or private, and one
::  photo.  Any ship running ID can look you up: it watches /view/~itself
::  here and is sent only what it may see -- the public lines.  To see the
::  rest it asks.  You accept, deny or block.  A ship you accept sees all
::  your lines, with your later edits, until you revoke.
::
::  Revoking takes the lines out of the copy on the other ship if that ship
::  runs this code.  Anything already shown could have been written down:
::  revoking stops updates, it can't make anyone unsee.
::
/-  *id
/+  default-agent, dbug, server
|%
+$  state-1
  $:  %1
      lines=(list line)                  ::  our ID
      allowed=(set @p)                   ::  ships that see all of it
      inbox=(map @p [note=@t when=@da])  ::  requests waiting on us
      declined=(set @p)                  ::  requests we turned down
      blocked=(set @p)
      book=(map @p entry)                ::  IDs we have looked up
  ==
::  the first build shared chosen lines with each ship; a ship that was
::  shown any lines is now allowed to see them all
::
+$  state-0
  $:  %0
      lines=(list line)
      grants=(map @p (set @ta))
      inbox=(map @p [note=@t when=@da])
      declined=(set @p)
      blocked=(set @p)
      book=(map @p entry)
  ==
+$  versioned  $%(state-0 state-1)
+$  card  card:agent:gall
::
++  max-lines  40
++  max-key  16
++  max-label  40
++  max-value  1.000
++  max-photo  400.000
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
      ?.  =('photo' key.l)
        (lte (met 3 value.l) (mul k max-value))
      ?&  (lte (met 3 value.l) (mul k max-photo))
          =('data:image/' (end [3 11] value.l))
      ==
  ==
::
++  good-lines
  |=  [k=@ud ls=(list line)]
  ^-  ?
  ?&  (lte (lent ls) (mul k max-lines))
      (levy ls |=(l=line (good-line k l)))
      =((lent ls) ~(wyt in (silt (turn ls |=(l=line key.l)))))
  ==
::
::  what ship who may see of our ID
::
++  view-for
  |=  [st=state-1 who=@p]
  ^-  view
  =/  all=?
    &((~(has in allowed.st) who) !(~(has in blocked.st) who))
  =/  vis=(list line)
    (skim lines.st |=(l=line |(all pub.l)))
  :+  vis
    (sub (lent lines.st) (lent vis))
  ?:  (~(has by inbox.st) who)  %wait
  ?:  (~(has in declined.st) who)  %no
  %none
::
::  ships watching our ID, each on its own path
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
  |=  [st=state-1 who=@p]
  ^-  card
  [%give %fact ~[/view/(scot %p who)] %id-view !>((view-for st who))]
::
++  publish
  |=  [=bowl:gall st=state-1]
  ^-  (list card)
  :-  (ui-mine st)
  %+  turn  ~(tap in (viewers bowl))
  |=(who=@p (give-view st who))
::
++  look-wire
  |=  who=@p
  ^-  wire
  /look/(scot %p who)
::
++  watch
  |=  [=bowl:gall who=@p]
  ^-  (list card)
  ?:  =(who our.bowl)  ~
  ?:  (~(has by wex.bowl) [(look-wire who) who %id])  ~
  ~[[%pass (look-wire who) %agent [who %id] %watch /view/(scot %p our.bowl)]]
::
++  send
  |=  [who=@p =msg]
  ^-  card
  [%pass ~[%msg -.msg (scot %p who)] %agent [who %id] %poke %id-msg !>(msg)]
::
++  blank  `entry`[~ ~ ~ | |]
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
++  view-json
  |=  v=view
  ^-  json
  %-  pairs:enjs:format
  :~  ['lines' a+(turn lines.v line-json)]
      ['hidden' (numb:enjs:format hidden.v)]
      ['ask' s+ask.v]
  ==
::
++  entry-json
  |=  [who=@p e=entry]
  ^-  json
  %-  pairs:enjs:format
  :~  ['who' s+(scot %p who)]
      ['view' ?~(view.e ~ (view-json u.view.e))]
      ['got' (ms got.e)]
      ['asked' (ms asked.e)]
      ['gone' b+gone.e]
      ['fresh' b+fresh.e]
  ==
::
++  mine-json
  |=  st=state-1
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
++  ui
  |=  jon=json
  ^-  card
  [%give %fact ~[/ui] %json !>(jon)]
::
++  ui-mine
  |=  st=state-1
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
=|  state-1
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
  =.  state
    ?-  -.o
      %1  o
      %0  [%1 lines.o ~(key by grants.o) inbox.o declined.o blocked.o book.o]
    ==
  :_  this
  :-  claim
  ::  watch again any ID a lost subscription dropped
  %-  zing
  (turn ~(tap in ~(key by book)) |=(w=@p (watch bowl w)))
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
      ?.  (good-lines 1 lines.act)
        :_  this
        ~[(note 'Not saved: a line is too long, there are too many lines, or a line is repeated.')]
      =.  lines  lines.act
      [(publish bowl state) this]
    ::
        %look
      ?:  =(who.act our.bowl)  `this
      =/  had  (~(get by book) who.act)
      ?:  &(?=(~ had) (gte ~(wyt by book) max-book))
        [~[(note 'Your list of IDs is full: forget some first.')] this]
      =/  e=entry  ?~(had blank u.had(fresh |, gone |))
      =.  book  (~(put by book) who.act e)
      :_  this
      :-  (ui-entry who.act e)
      (watch bowl who.act)
    ::
        %forget
      =/  had  (~(get by book) who.act)
      ?~  had  `this
      =.  book  (~(del by book) who.act)
      =/  waiting=?
        ?|  ?=(^ asked.u.had)
            ?&(?=(^ view.u.had) ?=(%wait ask.u.view.u.had))
        ==
      :_  this
      ;:  weld
        ?.(waiting ~ ~[(send who.act [%cancel ~])])
        ?.  (~(has by wex.bowl) [(look-wire who.act) who.act %id])  ~
        ~[[%pass (look-wire who.act) %agent [who.act %id] %leave ~]]
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
      =/  e=entry  ?~(had blank u.had(fresh |, gone |))
      =.  e  e(asked `now.bowl)
      =.  book  (~(put by book) who.act e)
      :_  this
      :*  (ui-entry who.act e)
          (send who.act [%ask note.act])
          (watch bowl who.act)
      ==
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
      =/  cards=(list card)  ~[(ui-mine state) (give-view state who.act)]
      ::  a ship that isn't watching is told to come and look
      ?:  (~(has in (viewers bowl)) who.act)  [cards this]
      [(snoc cards (send who.act [%nudge ~])) this]
    ::
        %revoke
      =.  allowed  (~(del in allowed) who.act)
      [~[(ui-mine state) (give-view state who.act)] this]
    ::
        %decline
      =.  inbox  (~(del by inbox) who.act)
      =.  declined  (~(put in declined) who.act)
      [~[(ui-mine state) (give-view state who.act)] this]
    ::
        %block
      ?:  =(who.act our.bowl)  `this
      ::  a waiting request is declined; a ship that never asked is told
      ::  nothing, so blocking looks like nothing at all
      =?  declined  (~(has by inbox) who.act)  (~(put in declined) who.act)
      =.  inbox  (~(del by inbox) who.act)
      =.  allowed  (~(del in allowed) who.act)
      =.  blocked  (~(put in blocked) who.act)
      [~[(ui-mine state) (give-view state who.act)] this]
    ::
        %unblock
      ::  a fresh start: they may ask again, and they see that at once
      =.  blocked  (~(del in blocked) who.act)
      =.  declined  (~(del in declined) who.act)
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
      ?:  (~(has in blocked) who)  `this
      =/  had  (~(get by book) who)
      ?:  &(?=(~ had) (gte ~(wyt by book) max-book))  `this
      =/  e=entry  ?~(had blank u.had(gone |))
      =.  e  e(fresh &)
      =.  book  (~(put by book) who e)
      :_  this
      :+  (ui-entry who e)
        (note (rap 3 ~[(scot %p who) ' let you see their whole ID.']))
      (watch bowl who)
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
    =/  marks  (~(run by book) |=(e=entry [got.e asked.e gone.e fresh.e]))
    ``json+!>(`json`s+(scot %uv (sham [lines allowed inbox declined blocked marks])))
  ==
::
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)
  ?+    wire  (on-agent:def wire sign)
      [%msg @ @ ~]
    ?.  ?=(%poke-ack -.sign)  `this
    ?~  p.sign  `this
    =/  who=@p  (slav %p i.t.t.wire)
    =/  what=@t  (rap 3 ~['The ship ' (scot %p who) ' did not take that. Is ID installed there?'])
    ?.  =(%ask i.t.wire)  [~[(note what)] this]
    =/  had  (~(get by book) who)
    ?~  had  [~[(note what)] this]
    =/  e=entry  u.had(asked ~)
    =.  book  (~(put by book) who e)
    [~[(ui-entry who e) (note what)] this]
  ::
      [%look @ ~]
    =/  who=@p  (slav %p i.t.wire)
    =/  had  (~(get by book) who)
    ?-    -.sign
        %poke-ack  `this
    ::
        %watch-ack
      ?~  p.sign  `this
      ?~  had  `this
      =/  e=entry  u.had(gone &)
      =.  book  (~(put by book) who e)
      [~[(ui-entry who e)] this]
    ::
        %kick
      ?~  had  `this
      [(watch bowl who) this]
    ::
        %fact
      ?~  had  `this
      ?.  =(%id-view p.cage.sign)  `this
      =/  v  (mole |.(!<(view q.cage.sign)))
      ?~  v  `this
      ?.  (good-lines 2 lines.u.v)  `this
      ::  our request is theirs once they say it waits or was declined
      =/  e=entry
        %=  u.had
          view   v
          got    `now.bowl
          gone   |
          asked  ?:(?=(%none ask.u.v) asked.u.had ~)
        ==
      =.  book  (~(put by book) who e)
      [~[(ui-entry who e)] this]
    ==
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
