pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
debug=false

state_title='state_title'
state_game='state_game'
state_over='state_over'

state=state_title
function _init()
 log('\n\n\n***')
 mouse.init()
 change_state(state_game)
 gameover.init()
 subscribe('gameover',function()
  change_state(state_over)
 end)
end

function _update()
 dt=t()-(before or 0)
 mouse.update()
 timed_function.update(dt)
 if state==state_game then
  water.update(dt)
  update_buttons()
  clock.update(dt)
  update_actors(dt)
  swimmer.update(dt)
  fx.update(dt)
  shark.update(dt)
 elseif state==state_title then
  if stat(34)==1 and
     not locktitle then
   change_state(state_game)
  end
  if not textx then textx=120 end
  textx-=30*dt
  if textx<=16 then textx=16 end
 elseif state==state_over then
  gameover.update(dt)
 end
 before=t()
end

function _draw()
 cls(12)
 pal()
 fillp()
 if state==state_game then
  --sky
  rectfill(0,0,128,88,12)
  water.draw() 
  map()
  --blood if needed
  fx.draw() 
  --lifguard chair
  spr(200,24,57,2,4)
  --pool chairs
  spr(245,53,80,3,1)
  spr(229,53,72)
  spr(245,92,80,3,1)
  spr(229,92,72)
  swimmer.draw()
  draw_actors()
  draw_buttons()
  shark.draw()
  clock.draw()
  mouse.draw()
 elseif state==state_title then
  map()
  --lifguard chair
  spr(200,24,57,2,4)
  --pool chairs
  spr(245,53,80,3,1)
  spr(229,53,72)
  spr(245,92,80,3,1)
  spr(229,92,72)
  cursor(textx,10)
  color(1)
  print('\^i  no lifeguard on duty  ')
  print('   for 2023 summer jam   ')
  print('\^i     by mike purdy      ')
  color(4)
  cursor(0,100)
  if not locktitle then
   print('\^#try to save the drowning swimmer')
  end
  if not locktitle and sin(t())<0 then
   pprint('-click mouse to start-',
    20,119,9,0)
   end
 elseif state==state_over then
  gameover.draw()
 end
end
change_state=function(new_state)
 log('from '..state..' to '..new_state)
 --timed_function.clear()
 local old_state=state
 state=new_state
 if old_state==state_title then
  if new_state==state_game then
   swimmer.init()
   water.init()
   init_actors()
   clock.init()
   fx.init()
   shark.init()
   make_buttons()
   clock.reset()
   publish('buttons.pause')
   timed_function.new(function()
    publish('buttons.pause')
    clock.start()
   end,1)
   return
  end
  if new_state==state_title then
   locktitle=true
   timed_function.new(function()
    locktitle=false
   end,4)
  end
 elseif old_state==state_game then
  reset_buttons()
  if new_state==state_title then
  	return
  end
 elseif old_state==state_over then
  if new_state==state_title then
   locktitle=true
   timed_function.new(function()
    locktitle=false
   end,1)
   return
  end
 end
end
-->8
--buttons
local buttons={}
local _data={
 {
  c=14,
  t='spear',
  f=◆,
 },{
  c=11,
  t='buoy',
  f=♥,
 },{
  c=2,
  t='drone',
  f=🐱,
 },{
  c=10,
  t='helmet',
  f=░,
 },{
  c=13,
  t='toaster',
 },{
  c=4,
 },
}
local new_button=function(i)
 local b={
  pushed=false,
  paused=false,
  x=(i+24*(i-1))+4,
  w=16,
  y=16,
  h=12,
  c=9
 }
 for k,v in pairs(_data[i]) do
  b[k]=v
 end
 mouse.add_listener(b,function()
  if b.pushed or b.paused then return end
  b.pushed=true
  publish('clicked',b.t)
  publish('buttons.pause')
 end)
 subscribe('swimmer.dead',function()
  b.paused=true
 end)
 subscribe('buttons.pause',function()
  b.paused=not b.paused
 end)
 return b
end

make_buttons=function()
 buttons={}
 for i=1,5 do
  b=new_button(i)
  add(buttons,b)
 end
end
reset_buttons=function()
 buttons={}
end
update_buttons=function()
end
draw_buttons=function()
 foreach(buttons,function(b)
  color(0)
  rectfill(b.x,b.y,b.x+b.w,b.y+b.h)
  color(b.c)
  if b.pushed or b.paused then
   color(6)
  end
  rectfill(b.x,b.y,b.x+b.w,b.y+b.h)
  color(1)
  if b.pushed or b.paused then
   color(5)
  end
  rect(b.x,b.y,b.x+b.w,b.y+b.h)
 end)
end
-->8
--mouse
mouse={
 init=function()
  poke(0x5f2d, 1)
  mouse.w=1
  mouse.h=1
  mouse.listeners={}
 end,
 -- listeners are objects
 -- that are registered to
 -- listen to mouse events
 add_listener=function(t,fn)
  add(mouse.listeners,{t,fn})
 end,
 update=function()
  mouse.x=stat(32)
  mouse.y=stat(33)
  -- lmb is down and
  -- does not have a target
  if stat(34)==1 and not
     mouse.target then
   foreach(mouse.listeners,function(l)
    if collide(mouse,l[1]) then
     -- assign overlap obj
     -- as target
     mouse.target=l
    end
   end)
  end
  -- lmb is up and 
  -- does have a target
  -- todo: fix bug where click
  -- starts with no target but
  -- ends with a target
  if stat(34)!=1 and mouse.target then
   if collide(mouse,mouse.target[1]) then
    mouse.target[2]()
   end
   mouse.target=nil
  end
 end,
 draw=function()
  palt(13,true)
  palt(0,false)
  -- use different sprite if
  -- lmb is down
  if stat(34)==1 then
   spr(16,mouse.x,mouse.y)
  else
   spr(0,mouse.x,mouse.y)
  end
  palt()
 end
}

-->8
--utils
function collide(a,b)
 return a.x+a.w>b.x and
        a.x<b.x+b.w and
        a.y+a.h>b.y and
        a.y<b.y+b.h
end
function log(msg)
 if type(msg)=='table' then
  for k,v in pairs(msg) do
   printh(k..': '..tostring(v), 'log')
  end
  return
 end
 printh(tostring(msg), 'log')
end
function pprint(msg,x,y,inner,outer)
 color(0)
 if outer then
  color(outer)
 end
 print(msg,x-1,y-1)
 print(msg,x,  y-1)
 print(msg,x+1,y-1)
 print(msg,x-1,y)
 print(msg,x,  y)
 print(msg,x+1,y)
 print(msg,x-1,y+1)
 print(msg,x,  y+1)
 print(msg,x+1,y+1)
 color(9)
 if inner then
  color(inner)
 end
 print(msg,x,y)
end
function lerp(a,b,t)
 return a+(b-a)*t
end
function easeoutelastic(t)
 if(t==1) return 1
 return 1-2^(-10*t)*cos(2*t)
end

-->8
--events
local subscribers={}
subscribe=function(name,fn)
 if not subscribers[name] then
  subscribers[name]={}
 end
 add(subscribers[name], fn)
end
publish=function(name,payload)
 log('published '..name..' payload: '..tostr(payload))
 local subs=subscribers[name]
 if not subs then
  return
 end
 log(tostr(#subs)..' subs found')
 foreach(subs,function(fn)
  fn(payload)
 end)
end
-->8
--timed function
timed_function={
 fns={},
 clear=function()
  timed_function.fns={}
 end,
 update=function(dt)
  foreach(timed_function.fns,function(o)
   -- o[1] is time
   o[1]-=dt
   if o[1]<=0 then
    -- o[2] is fn
    o[2]()
    del(timed_function.fns,o)
   end
  end)
 end,
 new=function(fn,t)
  local o={t,fn}
  add(timed_function.fns,o)
 end
}
-->8
--clock
clock={
 x=55,
 y=5,
 c=11,
 reset=function()
  clock.subsec=1
  clock.sec=60
  clock.pause=true
  clock.over=true
 end,
 init=function()
  subscribe('swimmer.dead',function()
   clock.over=true
  end)
 end,
 start=function()
  clock.over=false
  clock.pause=false
 end,
 update=function(dt)
  if clock.pause then return end
  if clock.over then
   clock.c=8
   if t()%1==0 then
    clock.c=0
   end
   return
  end
  clock.subsec-=dt*100
		if clock.subsec<=0 then
		 clock.subsec=100
		 clock.sec-=1
		end
  if clock.sec<=0 then
   clock.sec=0
   clock.subsec=1
   clock.over=true
   publish('buttons.pause')
   publish('swimmer.dead','drowned')
  end
  if clock.sec==0 then
   clock.c=8
  elseif clock.sec<15 then
   clock.c=8
  elseif clock.sec<30 then
   clock.c=9
  elseif clock.sec<45 then
   clock.c=10
  else
   clock.c=11
  end
 end,
 draw=function()
  local x=clock.x
  local y=clock.y
  local c=clock.c
  if clock.sec >=10 then 
   pprint(flr(clock.sec),x,y,c)
  else
   pprint('0'..flr(clock.sec),x,y,c)
  end
  pprint('.',x+8,y,c)
  if clock.subsec>=10 then
   pprint(flr(clock.subsec-1),x+12,y,c)
  else
   pprint('0'..flr(clock.subsec-1),x+12,y,c)
  end
 end,
}
-->8
--actors
local actors={}
local success_waits={
 drone=10,
 helmet=10,
 buoy=10,
 spear=10,
}

function get_actor(t)
 actor=nil
 foreach(actors,function(a)
  if a.t==t then
   actor=a
  end
 end)
 return actor
end
function is_actor_active(t)
 active=false
 local a=get_actor(t)
 return a!=nil and a.idle==false
end

function init_actors()
 local drone={
  t='drone',
  x=67,y=-20,
  w=8,h=2,
 }
 drone.init=function()
  local spear=get_actor('spear')
  if spear.latched then
   drone.x+=3
   drone.target={
    x=spear.x,
    y=spear.y-3,
    w=20,h=5,
   }
  end
 end
 drone.update=function(dt)
  if drone.latched then return end
  if drone.over then return end
  if drone.cutoffhands then
   drone.y=lerp(drone.y,-20,3*dt)
   if drone.y<-15 then
    drone.active=false
   end
   return
  end
  if is_actor_active('spear') then
   local spear=get_actor('spear')
   drone.y=lerp(drone.y,spear.y-4,2*dt)
   if collide(drone,drone.target) then
    drone.latched=true
    publish('buttons.pause')
    publish('actors.lift')
    publish('shark.start')
   end
  else
   drone.y=lerp(drone.y,swimmer.y,2*dt)
   if collide(drone,swimmer) then
    drone.cutoffhands=true
    publish('fx.blood','drone')
    timed_function.new(function()
     swimmer.deadface=true
    end,2)
    timed_function.new(function()
     publish('swimmer.dead','drone')
     publish('buttons.pause')
    end,4)
   end
  end
 end
 drone.draw=function()
  local x=drone.x
  local y=drone.y
  if cos(t()*4)>0 then
   spr(5,x-7,y-7,2,1)
  else
   spr(7,x-7,y-7,2,1)
  end
  if sin(t()*4)>0 then
   spr(5,x+7,y-7,2,1)
  else
   spr(7,x+7,y-7,2,1)
  end
  if drone.latched then
   spr(23,x,y,2,1)
  else
   spr(21,x,y,2,1)
  end
 end
 --
 local buoy={
  t='buoy',
  dx=140,--200,
  dy=-5,---10,
  gravity=25,--50,
  landingzone={
   x=swimmer.x+5,
   y=swimmer.y,
   w=2,
   h=2,
  },
  x=-30,y=64,w=2,h=2,
 }
 buoy.update=function(dt)
  if buoy.done then
   return
  end
  if is_actor_active('helmet') then
   buoy.x=lerp(buoy.x,buoy.landingzone.x+8,4*dt)
   buoy.y=lerp(buoy.y,buoy.landingzone.y,easeoutelastic(2*dt))
   if collide(buoy,buoy.landingzone) then
    buoy.landed=true
    buoy.done=true
    swimmer.addmsg('a buoy? perfect!\npull me out!')
    timed_function.new(function()
     publish('buttons.pause')
    end,4)
   end
  else
   buoy.x+=buoy.dx*dt
   buoy.dy+=buoy.gravity*dt
   buoy.y+=buoy.dy
  	if collide(buoy,swimmer.buoyrect) then
  	 buoy.dx*=-1
  	 buoy.done=true
  	 publish('swimmer.dead','buoy')
  	end
  end
 end
 buoy.draw=function()
  if buoy.landed then
   spr(9,buoy.x-2,buoy.y+2,2,1)
  else
   spr(3,buoy.x,buoy.y,2,2)
  end 
 end
 --
 local spear={
  t='spear',
  latched=false,
  x=150,w=2,
  y=-30,h=2,
 }
 spear.init=function()
  if is_actor_active('buoy') then
   local buoy=get_actor('buoy')
   spear.target={
    x=buoy.x+5,
    y=buoy.y,
    w=4,h=4
   }
  else
   spear.target=swimmer
  end
 end
 spear.update=function(dt)
  if spear.latched then return end
  local target=spear.target
  local t=10*dt
  spear.x=lerp(spear.x,target.x,t)
  spear.y=lerp(spear.y,target.y+1,t)
  if target==swimmer and
   collide(spear,swimmer) then
   spear.latched=true
   swimmer.deadface=true
   swimmer.addmsg('ugghhh....')
   timed_function.new(function()
    swimmer.addmsg('')
    publish('swimmer.dead','spear')
   end,3)
   publish('water.blood','spear')
  else
   spear.latched=false
   if collide(spear,target) then
    spear.latched=true
    publish('buttons.pause')
   end
  end
 end
 spear.draw=function()
  if spear.hide then return end
  if not spear.latched then
   spr(1,spear.x-7,spear.y+7)
  end
  spr(2,spear.x,spear.y)
  color(9)
  --line(spear.x+5,spear.y+3,130,80)
 end
 --
 local helmet={
  t='helmet',
  x=buoy.x,y=buoy.y,
  w=4,h=4,
  dx=buoy.dx,
  dy=buoy.dy,
  gravity=buoy.gravity,
 }
 helmet.update=function(dt)
  helmet.x+=helmet.dx*dt
  helmet.dy+=helmet.gravity*dt
  helmet.y+=helmet.dy
  if collide(helmet,swimmer.buoyrect) then
   helmet.dx*=-1
   helmet.done=true
   helmet.attached=true
   swimmer.addmsg('a helmet?\nwhat\'s this for?')
   timed_function.new(function()
    publish('buttons.pause')
   end,4)
  end
 end
 helmet.draw=function()
  if not helmet.attached then
   spr(102,helmet.x,helmet.y,2,2)
  end
 end
 --
 subscribe('clicked',function(t)
  local a=get_actor(t)
  if a.init then
   a.init()
  end
  if a then
   a.idle=false
  end
 end)
 local toaster={
  t='toaster',
  dx=200,
  dy=-7,---10,
  gravity=25,--50,
  landingzone={
   x=100,
   y=120,
   w=40,
   h=40,
  },
  x=-30,y=80,w=10,h=10,
  target='shark',
 }
 toaster.init=function()
  if shark.state then
   toaster.safe=true
  else
   swimmer.addmsg("is that a toaster?!\nare you crazy?!")
  end
 end
 toaster.update=function(dt)
  toaster.x+=toaster.dx*dt
  toaster.dy+=toaster.gravity*dt
  toaster.y+=toaster.dy
  if collide(toaster,toaster.landingzone) then
   if toaster.safe then
    timed_function.new(function()
     shark.dead=true
     publish('water.shock')
    end,1)
    return
   end
   timed_function.new(function()
    swimmer.addmsg('zzzhzhzzzhz')
    swimmer.deadface=true
    publish('water.shock')
   end,2)
   timed_function.new(function()
    publish('swimmer.dead','toaster')
   end,5)
  end
 end
 toaster.draw=function()
  spr(11,toaster.x,toaster.y,2,2)
 end
 -- order of added == draw order
 add(actors,helmet)
 add(actors,buoy)
 add(actors,spear)
 add(actors,drone)
 add(actors,toaster)
 foreach(actors,function(a)
  a.idle=true
 end)
 subscribe('actors.lift',function()
  
 end)
end

function update_actors(dt)
 foreach(actors,function(a)
  if a.idle then return end
  a.update(dt)
 end)
end

function draw_actors(dt)
 foreach(actors,function(a)
  if a.idle then return end
  a.draw()
 end)
end

-->8
--swimmer
local initialswimmer={
 t='swimmer',
 idle=false,
 x=65,w=8,
 y=105,h=8,
 msg='',
 msgtimer=3,
 msgs={
  'help!',
  "i can't swim!",
  'someone!',
  '',
 }
}
swimmer={}
swimmer.init=function()
 for k,v in pairs(initialswimmer) do
  swimmer[k]=v
 end
 subscribe('swimmer.saved',function()
  publish('gameover','win')
 end)
 subscribe('swimmer.dead',function(cause)
  swimmer.deadsprindex=1
  swimmer.dead=true

  if cause=='buoy' then
   swimmer.dead=true
   swimmer.deadsprs={127}
  elseif cause=='toaster' then
   swimmer.dead=true
   swimmer.deadsprs={100,100,100}
  elseif cause=='drone' then
   swimmer.deadsprs={223}
  else
   swimmer.deadsprs={124,125,126,223}
  end
  timed_function.new(function()
   publish('gameover',cause)
  end,4)
 end)
 swimmer.buoyrect={
  x=swimmer.x-14,
  y=swimmer.y-5,
  w=8,
  h=8,
 }
end
swimmer.update=function(dt)
 if swimmer.dead then
  swimmer.deadsprindex+=dt
 end
 swimmer.msgtimer-=dt
 if swimmer.msgtimer<0 then
  swimmer.msgtimer=3+rnd(3)
  if swimmer.nextmsg then
   swimmer.msg=swimmer.nextmsg
   swimmer.nextmsg=nil
  else
   swimmer.msg=rnd(swimmer.msgs)
  end
 end
end
swimmer.addmsg=function(msg)
 swimmer.nextmsg=msg
 swimmer.msgtimer=0
end
swimmer.draw=function()
 local x=swimmer.x-10
 local y=swimmer.y
 if swimmer.dead then
  x+=3
  y+=3
  local i=flr(swimmer.deadsprindex)
  local s=swimmer.deadsprs[i]
  spr(s,x,y)
  return
 end
 if not get_actor('buoy').landed and
    not swimmer.deadface then
  y+=sin(t())
  x+=sin(t()+t())
 end
 -- face needs to change for some
 -- sitations
 if swimmer.deadface then
  spr(100,x-6,y-6,2,2)
 else
  spr(106,x-6,y-6,2,2)
 end
 
 spr(108,x-6,y+3,2,1)
 if get_actor('helmet').attached then
  spr(102,x-6,y-7,2,2)
 end
 -- messages
 -- we need to print random
 -- message, but if hand
 -- is chopped off lets just 
 -- yell about that
 if get_actor('drone').cutoffhands then
  pprint('my hand!!',x,y-15,10)
 else
  pprint(swimmer.msg,x,y-15,10)
 end
 swimmer.draw_hands(x,y)
 if debug then
  color(8)
  local br=swimmer.buoyrect
  rect(br.x,br.y,br.x+br.w,br.y+br.h)
 end
end
swimmer.draw_hands=function(x,y)
 -- hands
 -- don't show hands if speared
 if swimmer.deadface then
  return
 end
 -- if buoy is landed, then
 -- swimmer should hold onto it
 if get_actor('buoy').landed then
  spr(90,x+6,y,2,1)
  return
 end
 -- if drone chopped off hands
 -- then draw stubs
 if get_actor('drone').cutoffhands then
  spr(121,x+6,y)
  return
 end
 -- if swimmer is drowning,
 -- flail the hands
 if sin(t())>0 then
  spr(105,x+6,y-8,1,2)
 else
  spr(104,x-8,y-8,1,2)
 end
end
-->8
--gameover
gameover={}
gameover.msgs={
 win=
 '"it was crazy!" said the\n'
..'drowning child.\n'
..'"the rescuer threw a helmet\n'
..'on my head to protect from\n'
..'the buoy that they threw\n'
..'to me. then they threw\n'
..'a spear right into the buoy!\n'
..'then a drone came down and\n'
..'pulled me out of the water!\n'
..'a shark tried to eat me but\n'
..'they electrocuted it with a\n'
..'toaster! it was insane!!'
,
 drone=
 'bizarre rescue attempt gone\n'
..'wrong!\n'
..'rescuer tries using drone,\n'
..'accidentally chopping off\n'
..'a hand!\n'
..'swimmer bleeds out, dies.\n\n'
..'"first all you could hear\n'
..'was that annoying noise\n'
..'drones make. then screaming\n'
..'in agony!"'
, buoy=
 'drowning swimmer knocked in\n'
..'head by rescuer with buoy.\n'
..'proceeds to drown.\n\n'
..'poolgoers around the state\n'
..'wonder why there wasn\'t\n'
..'a ladder.\n'
..'"no ladder? what is this,\n'
..'the sims?!"'
, spear=
 'swimmer brutally speared\n'
..'in bizarre rescue attempt.\n'
..'witnesses unclear what\n'
..'rescuer was thinking as\n'
..'spears are "very dangerous".\n'
..'lawmakers push new\n'
..'controversial bill titled\n'
..'"no deadly spears at pools".\n'
..'spear lobbyists claim\n'
..'unconstitutional.'
,
 drowned=
 'swimmer drowned.\n'
..'sources unsure why no one\n'
..'jumped in and attempted\n'
..'a rescue.\n'
..'"i don\'t understand why no\n'
..'one would help!" cried a\n'
..'witness.\n\n'
..'witness replied "no comment"\n'
..'when asked why they did\n'
..'not attempt to save swimmer.'
,
 toaster=
 'swimmer electrocuted as\n'
..'rescuer blunders.\n\n'
..'no one knows why a toaster\n'
..'was thrown into the pool\n'
..'or what a toaster was even\n'
..'doing at the pool in\n'
..'the first place.'
,
 shark=
 'pool swimmer eaten by shark!\n'
..'\npool officials unsure how\n'
..'a shark even got in the\n'
..'pool.\n'
..'"honestly, i\'m at a lose\n'
..'for words.  how the hell\n'
..'700 pound shark end up\n'
..'in a community pool!'
}
gameover.init=function()
 subscribe('gameover',function(cause)
  gameover.cause=cause
  gameover.headline='death at local swimming pool'
  if cause=='win' then
   gameover.headline='     hero saves swimmer'
  end
  gameover.msg=gameover.msgs[cause]
  timed_function.new(function()
   gameover.ready=true
  end,3)
 end)
end
gameover.update=function(dt)
 if not gameover.ready then
  return
 end
 if stat(34)==1 then
  change_state(state_title)
 end
end
gameover.draw=function()
 cls(7)
 local umargin=27
 local lmargin=7
 spr(128,4,6,16,2)
 rect(4,4,120,120,5)
 pprint(gameover.headline,
  lmargin,umargin,7,0)
 line(4,24,120,24,5)
 line(4,umargin+8,120,umargin+8,5)
 print(gameover.msg,lmargin,umargin+16)
 if gameover.ready and sin(t())<0then
  pprint('-click mouse to try again-',
   lmargin+5,113,7,0)
 end
 --pprint('caused by '..gameover.cause,
 -- lmargin,20,7,0)
end
-->8
--water
water={}
water.init=function()
 water.bloodradius=0
 water.bloodxoffset=0
 water.bloodyoffset=0
 subscribe('water.shock',function()
  water.shock=true
  water.shocks={}
 end)
 subscribe('water.blood',function(cause)
  water.blood=true
  if cause=='drone' then
   water.bloodxoffset=-10
   water.bloodyoffset=5
  elseif cause=='spear' then
   water.bloodxoffset=-5
   water.bloodyoffset=3
  end
 end)
end
water.update=function(dt)
 if water.blood then
  water.bloodradius+=(4*dt)
 end
 if water.bloodradius>20 then
  water.bloodradius=20
 end
 if water.shock and rnd()>.8 then
  add(water.shocks,{
   x=rnd(120),
   y=rnd(44)+88,
   t=rnd(),
  })
  log('added')
 end
 foreach(water.shocks,function(s)
  s.t-=dt
  if s.t<0 then
   del(water.shocks, s)
  end
 end)
end
water.draw=function()
 rectfill(0,96,128,128,12)
 foreach(water.shocks,function(s)
  local sp=flr(rnd()+.5)
  spr(13+sp,s.x,s.y)
 end)
 if water.blood then
  circfill(swimmer.x+water.bloodxoffset,
           swimmer.y+water.bloodyoffset,
           water.bloodradius,8)
 end
end
-->8
--fx
fx={}
fx.init=function()
 fx.ents={}
 subscribe('fx.blood',function(cause)
  fx.droneblood=true
  publish('water.blood',cause)
 end)
end
fx.update=function(dt)
 if fx.droneblood then
  if rnd(100) > 60 then
   add(fx.ents,{
    t='blood',
    x=swimmer.x,
    y=swimmer.y,
    dx=sin(rnd()),
    dy=-50-rnd(5),
    r=sin(t())+2,
    gravity=true,
   })
  end
 end
 foreach(fx.ents,function(ent)
  if ent.gravity then
   ent.dy+=4
   ent.x+=ent.dx
   ent.y+=ent.dy*dt
  end
  if ent.y>128 then
   del(fx.ents,ent)
  end
 end)
end
fx.draw=function()
 foreach(fx.ents,function(ent)
  if ent.t=='blood' then
   circfill(ent.x,ent.y,ent.r,8)
  end
 end)
end
-->8
shark={}
shark.init=function()
 shark.x=130
 shark.y=100
 shark.dx=-20
 shark.dy=0
 shark.gravity=0
 subscribe('shark.start',function()
  shark.state='moving'
 end)
end
shark.update=function(dt)
 if shark.dead then
  shark.state='dead'
 end
 if not shark.state then return end
 shark.x+=shark.dx*dt
 shark.dy+=shark.gravity*dt
 shark.y+=shark.dy
 if shark.state=='moving' and
    shark.x<70 then
  shark.state='jump'
  shark.dy=-8
  shark.gravity=20
  shark.dx=-40
 end
 if shark.state=='jump' and
    shark.dy>0 then
  shark.state='bite'
 end
 if shark.state=='dead' then
  shark.gravity+=1
  if shark.y>128 then
   shark.state=nil
  end
  publish('swimmer.saved')
 end
end
shark.draw=function()
 local x=shark.x
 local y=shark.y
 if shark.state=='jump' then
  spr(64,x,y,3,4)
  spr(115,x+24,y+24)
  spr(70,x+0,y+32,4,2)
 end
 if shark.state=='bite' then
  spr(68,x+8,y,2,2)
  spr(80,x,y+8)
  spr(96,x,y+16,3,2)
  spr(83,x+8,y+16)
  spr(115,x+24,y+24)
  spr(70,x+0,y+32,4,2)
 end
 if shark.state=='dead' then
  spr(68,x+8,y,2,2)
  spr(80,x,y+8)
  spr(96,x,y+16,3,2)
  spr(83,x+8,y+16)
  spr(115,x+24,y+24)
  spr(70,x+0,y+32,4,2)
  spr(74,x+16,y+8)
  spr(75,x+16,y+16)
  return
 end
 if shark.state=='moving' then
  spr(33,x,y,2,2) 
 end
end
__gfx__
d1dddddd000000050000000000007777777000000000000000000000000000000000000000000000000000000006660000000000000000000000000000000000
161ddddd0000005100005500000777777777700000000000000000000000000000000000000000000000000000661166600000000a0000000000a00000000000
1661dddd000005100005115100ff77777777ff00000000000000000000000000000000000000000000000000066666111666000009a00a000a0a900000000000
16661ddd500051000005105107fff000000fff700000000000000000000000000000000000000000000000006611666661166000009aa90009a9000000000000
166661dd5555100000055510077f00000000f77000aaaaaa9999990000999999aaaaaa000ff7777777777ff0d6661116666660000009a000009a000000000000
16661ddd555100000051110077700000000007770000aaaa9999000000009999aaaa00007ff7777777777ff7d776666116666000000a9a000a99a00000000000
d1161ddd55550000051000007770000000000777000000055000000000000005500000007ff7777777777ff7d77777766666100000a9090009009a0000000000
dddddddd11111000010000007770000000000777000000055000000000000005500000000ff7777777777ff0d777777776616000009000000000090000000000
d0dddddd00000006000000007770000000000777550000000000005550000000000000050000000000000000d777777776156000000000000000000000000000
050ddddd00000065000000007770000000000777855555555555555b855555555555555b0000000000000000d777777776656000000000000000000000000000
0550dddd0000065000000000777000000000077788555555555555bb88555556655555bb00000000000000000dd7777776650000000000000000000000000000
05550ddd6000650000000000077f00000000f770000000066000000000000006600000000000000000000000000dddd776600000000000000000000000000000
055550dd666650000000000007fff000000fff700000066666600000000000666600000000000000000000000000000dd6000000000000000000000000000000
05550ddd666500000000000000ff77777777ff000000600000060000000006000060000000000000000000000000000000000000000000000000000000000000
d0050ddd666600000000000000077777777770000000600000060000000006000060000000000000000000000000000000000000000000000000000000000000
dddddddd555550000000000000000777777000000000000000000000000000600600000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000a90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000a900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010101010
000000000000000000555550000a9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010101
00000000000000055566665000a90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
00000000000005566666d500009a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011011101
0000000000005666666d65000009a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
000000000005666666d6500000009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010111011
000000000005666666d6500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
00000000005666666d66500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
00000000005666666d65000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
0000000005666666d665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
00000000056666666666500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
00000000000000000666500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
00000000000000000000000000000000000000000000000000006666666666666666666666655650500000007161655000000000000000000000000011111111
00000000000650000000000000000000000000000000000000000666666666666666666666666565550000007666655000000000000000000000000011111111
00000000000665000000000000000000000000000000000000000666666666666666666665555555655000006666655500000000000000000000000021212121
00000000006766500000000000000000000000000000000000000666666666666666666650000000665550006666655500000000000000000000000012121212
00000000006776650000000000000000555000000000000000000666666666666666666650000000666650006666665500000000000000000000000022222222
00000000007777665000000000000000066550000000000000000666666666666666666650000000666655006666665500000000000000000000000022122212
00000000007777666500000000000000077665000000000000000666666666666666666650000000716155006665665500000000000000000000000022222222
0000000000eee7766500000000000000077666550000000000000666666666666666666650000000761665006656665500000000000000000000000021222122
00000000007eee7665500000e77777ee007766655000000000000666666666666666666500000000000000000000000000000000000000000000000022222222
000000000077ee7766500000ee7777ee00e776665500000000000666666666666666666500000000000000000000000000000000000000000000000022222222
0000000000007ee7665000007eeeeee700ee77666550000000000066666666666666666500000000000000000000000000000000000000000000000022222222
0000000000007ee7665550007777eee707eee77666555000000000666666666666666665000000000000000000000000000000000000ccc00000000022222222
0000000070007ee76666500077777777777eee7766665000000000066666666666666665000000000000ffffff0000000cccccc0cccc111c0000000022222222
0000000e700007ee76665500777777777777ee77666655000000000666666666666666650000000000ffffffffff0000c1111ccc1111ccc11110000022222222
0000007e770007ee761155006677777677777ee77611550000000000666666666666666500000000fffff000000000001ccccc1ccccccccc0001111022222222
0000007e777007ee761165006666666677777ee77611650000000000666666666666666500000000fff0000000000000cccccccccccccccc0000000022222222
0000077ee77000ee7666655000000000000000000000000000001111110000000000000000000000000000000000000000000000000000000000000022222222
00000777ee7700ee7666655000000000000004444400000000011111111000000000000000000000000004444400000000000000000000000000000022222222
000007777eeeeee7666665550000000000004fffff0000000011111111100000000000000000f00000004fffff000000000000000000000000000000c2c2c2c2
000067777777eee766666555000000000004fffffff0000001111111111000000f000000000fff000004fffffff000000000000000000000000000002c2c2c2c
000066777777777766666655000000000004ffff1f1f000001111000000000000ff0000000fffff00004fffff71f0000000000000000000000000000cccccccc
0000666777777777666666550000000000041f1ff1ff00000111000000000000fffff00000ffff000004f71ff77f0000000000000000000000000000cc2ccc2c
000066666677777666656655000000000044f1ff1f1ff00011110000000000000fff0000000fff000044f77ffffff000000000000000000000000000cccccccc
0000666666666666665666550000000000441f1ffffff00011110000000000000fff0000000ff0000044fffffffff000000000000000000000000000c2ccc2cc
000666666666666655656655000000000044fffffffff000111110000000000000ff0000000ff0000044fffffffff000000000000000000000000000cccccccc
0006666666666655665666550000000000444ffffffff000111110000000000000ff0000000ff00000444ffffffff0000000f0000000000000000000cccccccc
0006666666666666556566555000000000044ffffffff000111111000000000000ff0000000ff00000044ffff811f0000f00f0f00000000000000000cccccccc
00066666666666556656665565500000000444ff111ff000111111000000000000fff000000ff000000444fff11ff00000ff0f000000ff0000000000cccccccc
000666666666666655666655666500000004444f1ffff000011110000000000000fff000000ff0000004444ffffff00000fff0000f00ff0000000000cccccccc
000666666666666666666655666650000000444fffff00000011000000000000000ff000000ff0000000444fffff000000ff110000ffff0000000000cccccccc
00006666666666666666665566666500000004fffff000000000000000000000000fff0000fff000000004fffff000000111111000f11000000ff000cccccccc
00006666666666666666665565566650000000000000000000000000000000000000ff00000000000000000000000000000000000111110000111100cccccccc
00055555555500000000000000000000000000000000000000000000005555555555500000000000000000000000000000000000000000000000000000000000
00005555555550000000000000000000000000000000000000000000000555555555550000000000000000000000000000000000000000000000000000000000
00000505055550000005550000055550005555000005550005000000000050555005550000005550000005555000005555555500000555550000000000000000
00000505005555000055555000055550005555000005550005000000000050550000550000055555000055555500005555555500005555555000000000000000
00000505000555000555555500050550005055000005050005000000000050550000550000555555500050500550005050000500005050005500000000000000
00005505000555005550005500050550005055000005050005000000000050550000550005550005500050500550005050000000005050005500000000000000
00005505000555005050005500050550005055000005050005000000000050550000550005050005500050500550005050000000005050005500000000000000
00005505000555005050005500050550005055000005050005000000000050550005550005050005500050500550005050000000005050005500000000000000
00005505000555005050005500050550005055000005055555000000000050550055500005050005500050505500005050000000005050055000000000000000
00005505000555005050005500050550005055000005505555000000000050555555000005050005500050555000005055550000005055550000000000000000
00005505000555005050005500050550005055000000505500000000000050555550000005050005500050550000005055550000005055500000000000000000
00005505000555005055555500050550005055000000505500000000000050550000000005055555500050550000005050000000005055550000000000000000
00005505000555005050005500050550005055000000505500000000000050550000000005050005500050550000005050000000005055050000000000000000
00005505005550005050005500050550005055005000505500000000000050550000000005050005500050550000005050000500005055055000000000000000
00005505055550005050005500050550005055555000505500000000000050550000000005050005500050550000005055555500005055005000000000000000
00055555555500005550005500055550005555555000555500000000000555550000000005550005500055550000005555555500005555005500000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000011111111111100000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000111111111111110000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000777111111117770000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000777110000117770000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000711000000001170000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000711006666000170000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000071111111111700000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000071110000111700666666665000000677777777777777777777777700000000
00000000000000000000000000000000000000000000000000000000000000000071000000001700555555550500006076677777777777777777766700000000
00000000000000000000000000000000000000000000000000000000000000000777777777777770005006000050060077777777777777777777777700000000
00000000000000000000000000000000000000000000000000000000000000000777777777777770000650000006500077997979797999779997999700000000
00000000000000000000000000000000000000000000000000000000000000000777777777777770000560000005600079777979797999779797797700000000
00000000000000000000000000000000000000000000000000000000000000000771111111111770005006000050060079997979797979779997797700000000
00000000000000000000000000000000000000000000000000000000000000000770000000000770050000600500006077797999797979779797797700000000
00000000000000000000000000000000000000000000000000000000000000000770000000000770500000065000000679977999797979779797797700000000
0000000000000000000000000000000000000000000000000000000000000000077000000000077000000000bbbbbbbb777777777777777777777777bbbbbbbb
0000000000000000000000000000000000000000000000000000000000000000077000000000077000000000bbbbbbbb797979997799979779979797bbbbbbbb
00000000000000000000000000000000000000000000000000000000000000000770000000000770000000006666666679797979779797979777979766666666
00000000000000000000000000000000000000000000000000000000000000000770000000000760000000006666666679797997779977979997997766666666
0000000000000000000000000000000000000000000000000000000000000000077000000000076000000000777f777779797979779797977797979777777777
0000000000000000000000000000000000000000770000000000000000000000077000000000076000000000777f777779997979779797979977979777777777
0000000000000000000000000000000000000000077000000000000000000000777777788777777700000000777f777776677777777777777777766777777777
0000000000000000000000000000000000000000007700000000000000000000777777888877777700000000777f777777777777777777777777777777777777
0000000000000000000000000000000000000000007770000000000000000000777777888877777700000000ddddddddddddddddbbbbbbbbbbbbbbbbcccccccc
0000000000000000000000000000000000000000070777000077770000000000777777788777777700000000cccdccccccccccccbbbbbbbbbbbbbbbbcccccccc
0000000000000000000000000000000000000000700077700700007000000000777111111111177700000000cccccccccccccccc6666666666666666cccccccc
0000000000000000000000000000000000000000777777777777777777777777777000000000077700000000cccccccccccccccc6666666666666666cccccccc
0000000000000000000000000000000000000000777777777777777777777777777000000000077700000000cccccccccccccccc777f777777777777cccccccc
0000000000000000000000000000000000000000700000007000000700000077777000000000077600000000cccccccccccccccc777f777777777777cccccccc
0000000000000000000000000000000000000000070000070000000070000070777000000000077600000000cccccccccccccccc777f777777777777cccccccc
0000000000000000000000000000000000000000007777700000000007777700777000000000076600000000cccccccccccccccc777f777777777777cccccccc
__map__
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dadadadadadadadadadadadadadadada00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dbdbdbdbdbdbdbdbdbdbdbdbdbdbdbdb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dbdbdbdbdbdbdbdbdbdbdcdddedbdbdb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dbdbdbdbdbdbdbdbdbdbecedeedbdbdb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dbdbdbdbdbdbdbdbdbdbdbdbdbdbdbdb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dbdbdbdbdbdbdbdbdbdbdbdbdbdbdbdb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dbdbdbdbdbdbdbdbdbdbdbdbdbdbdbdb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fefefefdfefefefdfefefefefdfefefe00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
