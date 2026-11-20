::  mar/id-action -- pokes from our own page, parsed from JSON.
::
/-  id
|_  act=action:id
++  grab
  |%
  ++  noun  action:id
  ++  json
    |=  jon=^json
    ^-  action:id
    ::  a pass: {show: {show, seal}}, where the seal is a private pass's
    ::  whole ID locked for the web.  A page from before seals sends only
    ::  {show: "public"}.
    =/  old=?
      ?.  ?=([%o *] jon)  |
      =/  v  (~(get by p.jon) 'show')
      ?=([~ %s *] v)
    =?  jon  old
      ?>  ?=([%o *] jon)
      =/  kind=^json  (~(got by p.jon) 'show')
      [%o (~(put by p.jon) 'show' (pairs:enjs:format ~[['show' kind] ['seal' s+'']]))]
    =,  dejs:format
    =/  ln
      %-  ot
      :~  key+(su sym)
          label+so
          value+so
          pub+bo
      ==
    %.  jon
    %-  of
    :~  [%save (ot ~[lines+(ar ln)])]
        [%look (ot ~[who+(se %p)])]
        [%fetch (ot ~[who+(se %p) mode+(cu |=(t=@t ;;(mode:id t)) so) have+(se %uv)])]
        [%forget (ot ~[who+(se %p)])]
        [%ask (ot ~[who+(se %p) note+so])]
        [%cancel (ot ~[who+(se %p)])]
        [%allow (ot ~[who+(se %p)])]
        [%revoke (ot ~[who+(se %p)])]
        [%decline (ot ~[who+(se %p)])]
        [%block (ot ~[who+(se %p)])]
        [%unblock (ot ~[who+(se %p)])]
        [%show (ot ~[show+(cu |=(t=@t ;;(show:id t)) so) seal+so])]
        [%hide ul]
        [%redeem (ot ~[who+(se %p) code+(se %uv) have+(se %uv)])]
        [%more (ot ~[who+(se %p) have+(ar (se %uv))])]
    ==
  --
++  grow
  |%
  ++  noun  act
  --
++  grad  %noun
--
