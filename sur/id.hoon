::  sur/id -- ID: an identity card held on your own ship.
::
|%
::  one line of an ID.  key: a standard field ('name', 'height', ...),
::  'photo' (value is a data:image/ URL) or a custom line ('x1', 'x2', ...).
::  pub: shown to anyone who looks.  Otherwise only to ships
::  we accept.
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
::  an ID we have looked up
::
+$  entry
  $:  view=(unit view)                    ::  as last sent (~ = no answer yet)
      got=(unit @da)                      ::  when that came
      asked=(unit @da)                    ::  our request, until they have it
      gone=?                              ::  their ship refused: no ID there
      fresh=?                             ::  they shared with us, not opened
  ==
::
::  pokes from our own page
::
+$  action
  $%  [%save lines=(list line)]           ::  our ID, all of it
      [%look who=@p]                      ::  look a ship up (and keep watching)
      [%forget who=@p]
      [%ask who=@p note=@t]               ::  ask to see its private lines
      [%cancel who=@p]
      [%allow who=@p]                     ::  let it see every line
      [%revoke who=@p]
      [%decline who=@p]
      [%block who=@p]
      [%unblock who=@p]
  ==
::
::  ship to ship
::
+$  msg
  $%  [%ask note=@t]
      [%cancel ~]
      [%nudge ~]                          ::  "you may see my whole ID"
  ==
--
