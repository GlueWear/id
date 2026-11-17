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
        [%forget (ot ~[who+(se %p)])]
        [%ask (ot ~[who+(se %p) note+so])]
        [%cancel (ot ~[who+(se %p)])]
        [%allow (ot ~[who+(se %p)])]
        [%revoke (ot ~[who+(se %p)])]
        [%decline (ot ~[who+(se %p)])]
        [%block (ot ~[who+(se %p)])]
        [%unblock (ot ~[who+(se %p)])]
    ==
  --
++  grow
  |%
  ++  noun  act
  --
++  grad  %noun
--
