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
 change_state(state_title)
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

  if not subtextx or 
         subtextx<-320 then
   subtextx=180
  end
  if textx<=16 then 
   subtextx-=40*dt
   textx=16
  end

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
  
  fx.drawtop()
  swimmer.draw()
  draw_actors()
  draw_buttons()
  shark.draw()
  clock.draw()
 elseif state==state_title then
  map()
  --lifguard chair
  spr(200,24,57,2,4)
  --pool chairs
  spr(245,53,80,3,1)
  spr(229,53,72)
  spr(245,92,80,3,1)
  spr(229,92,72)
  cursor(textx,9)
  color(10)
  print('  \^#no lifeguard on duty')

  if not locktitle then
   color(2)
   cursor(textx,18)
   print('      by mike purdy      ')
   cursor(textx+2,26)
   print('  for 2023 summer jam   ')
   color(7)
   cursor(subtextx,100)
   print('\^#try to save the drowning swimmer by clicking the buttons on the top of the screen')
  end
  if not locktitle and sin(t())+.5<1 then
   pprint('-click mouse to start-',
    20,119,9,0)
   end
 elseif state==state_over then
  gameover.draw()
 end
 mouse.draw()
end
change_state=function(new_state)
 log('from '..state..' to '..new_state)
 --timed_function.clear()
 local old_state=state
 state=new_state
 if new_state==state_game then
  swimmer.init()
  water.init()
  init_actors()
  clock.init()
  fx.init()
  shark.init()
  make_buttons()
  --reset_buttons()
  clock.reset()
  publish('buttons.pause')
  timed_function.new(function()
   publish('buttons.pause')
   clock.start()
  end,1)
  return
 end
 if new_state==state_title then
  timed_function.clear()
  locktitle=true
  local t=4
  if old_state==state_over then
   t=1
  end
  timed_function.new(function()
   locktitle=false
  end,t)
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
 actors={}
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
  if buoy.landed and not buoy.lifted then
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
   swimmer.addmsg('careful with that!')
   
   local buoy=get_actor('buoy')
   spear.target={
    x=buoy.x+5,
    y=buoy.y,
    w=4,h=4
   }
  else
   swimmer.addmsg('what are you doing\nwith that spear?')
   spear.target=swimmer
  end
  spear.latched=true
  timed_function.new(function()
   spear.latched=false
  end,2)
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
    swimmer.addmsg('phew, close one')
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

 local toaster={
  t='toaster',
  dx=200,
  dy=-7,---10,
  gravity=25,--50,
  landingzone={
   x=100,
   y=140,
   w=40,
   h=40,
  },
  x=-30,y=80,w=10,h=10,
  target='shark',
 }
 toaster.init=function()
  if shark.state then
   toaster.safe=true
  elseif shark.dead then
   swimmer.addmsg('woohoo!')
  else
   swimmer.addmsg("is that a toaster?!\nare you crazy?!")
  end
 end
 toaster.update=function(dt)
  if toaster.done then 
   return
  end
  toaster.x+=toaster.dx*dt
  toaster.dy+=toaster.gravity*dt
  toaster.y+=toaster.dy
  if not collide(toaster,toaster.landingzone) then
   return
  end
  if toaster.safe then
   timed_function.new(function()
    log('shark is dead')
    shark.dead=true
    publish('water.shock')
    toaster.done=true
   end,.5)
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
 toaster.draw=function()
  log('toaster draw')
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
 subscribe('actors.lift',function()
  timed_function.new(function()
   buoy.lifted=true
   swimmer.x+=10
   swimmer.y+=10
   swimmer.showfullbody=true
  end,1)
 end)
end
function lift_actors(dy)
 actors.lifting=true
 actors.liftingdy=dy
end
 
function update_actors(dt)
 if actors.lifting then
  local dy=actors.liftingdy
  get_actor('drone').y+=dy
  get_actor('buoy').y+=dy
  get_actor('spear').y+=dy
  local toaster=get_actor('toaster')
  if not toaster.idle then
   toaster.update(dt)
  end
 end
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
 lifting=false,
 showfullbody=false,
 showhalfbody=false,
 msg='',
 msgtimer=3,
 dead=false,
 deadface=false,
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
  timed_function.new(function()
   publish('gameover','win')
  end,3)
 end)
 subscribe('swimmer.dead',function(cause)
  swimmer.deadsprindex=1
  swimmer.dead=true
  if cause=='buoy' then
   swimmer.dead=true
   swimmer.deadsprs={127}
  elseif cause=='toaster' then
   swimmer.dead=true
   swimmer.deadsprs={32,32,32}
  elseif cause=='drone' then
   swimmer.deadsprs={223}
  elseif cause=='shark' or 
         cause=='spear' then
   swimmer.dead=true
   swimmer.deadsprs={32,32,32}
  else
   swimmer.deadsprs={124,125,126,223}
  end
  timed_function.new(function()
   init_actors()
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
  if swimmer.deadsprindex>#swimmer.deadsprs then
   swimmer.deadsprindex=#swimmer.deadsprs
  end
  return
 end
 if swimmer.lifting then
  local dy=-15*dt
  swimmer.y+=dy
  lift_actors(dy)
  if actor.showhalfbody then
  end
  return
 end
 if get_actor('drone').latched then
  swimmer.lifting=true
  publish('actors.lift')
 end
 swimmer.drawlefthand=sin(t())>.5
 swimmer.drawrighthand=sin(t())<.5
 local should_add_splashes = 
  not swimmer.deadface and
  not get_actor('buoy').landed
 if should_add_splashes then
  fx.addsplash(
   {x=swimmer.x-rnd(10),y=swimmer.y+8})
  if swimmer.drawlefthand then
   fx.addsplash(
    {x=swimmer.x-rnd(2)-12,y=swimmer.y+8})
  end
  if swimmer.drawrighthand then
   fx.addsplash(
    {x=swimmer.x-rnd(2),y=swimmer.y+6})
  end
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
 
 if swimmer.showfullbody then
  spr(13,x-6,y-6,2,5)
  rectfill(70,110,128,128,12)
 elseif swimmer.showhalfbody then
  spr(13,x-6,y-6,2,4)
  rectfill(70,110,128,128,12)
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
end
swimmer.draw_hands=function(x,y)
 -- hands
 -- don't show hands if speared
 if swimmer.deadface or
    swimmer.showfullbody or
    swimmer.showhalfbody then
  return
 end
 
 -- if buoy is landed, then
 -- swimmer should hold onto it
 if get_actor('buoy').landed then
  spr(90,x+6,y,2,1)
  -- if drone chopped off hands
  -- then draw stubs
  if get_actor('drone').cutoffhands then
   spr(121,x+6,y)
   return
  end
  spr(105,x+6,y-8,1,2)
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
 if swimmer.drawrighthand then
  spr(105,x+6,y-8,1,2)
 end
 if swimmer.drawlefthand then
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
 water.shock=false
 water.shocks={}
 water.bloodspots={}
 water.blood=false
 water.bloodradius=0
 water.bloodxoffset=0
 water.bloodyoffset=0
 subscribe('water.shock',function()
  water.shock=true
  water.shocks={}
 end)
 subscribe('water.blood',function(cause)
  water.blood=true
  water.bloodcause=cause
  if cause=='drone' then
   water.bloodxoffset=-10
   water.bloodyoffset=5
  elseif cause=='spear' then
   water.bloodxoffset=-5
   water.bloodyoffset=3
  elseif cause=='shark' then
   water.blood=false
   timed_function.new(function()
    for i=0,100 do
     add(water.bloodspots,
      {x=rnd(128),y=rnd(32)+96})
    end
   end,1)
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
  spr(35+sp,s.x,s.y)
 end)
 foreach(water.bloodspots,function(spot)
  pset(spot.x,spot.y,8)
 end)
 if water.blood then
  local x=swimmer.x
  local y=110
  if water.bloodcause!='shark' then
   x=swimmer.x+water.bloodxoffset
   y=swimmer.y+water.bloodyoffset
  end
  circfill(x,y,water.bloodradius,8)
 end
end
-->8
--fx
fx={}
fx.init=function()
 fx.ents={}
 fx.topents={}
 fx.splashes=true
 fx.droneblood=false
 fx.sharkblood=false
 subscribe('fx.blood',function(cause)
  if cause=='shark' then
   fx.sharkblood=true
  else fx.droneblood=true end
  publish('water.blood',cause)
 end)
end
fx.stopsplashes=function()
 fx.topents={}
 fx.splashes=false
end
fx.addsplash=function(pos)
 if rnd()>.1 then return end
 add(fx.topents,{
  t='splash',
  x=pos.x,
  y=pos.y,
  dx=sin(rnd()),
  dy=-50-rnd(5),
  r=2,
  limit=1,
 })
end
fx.update=function(dt)
 if swimmer.deadface then
  fx.topents={}
 end
 if fx.sharkblood then
  for i=0,80 do
   add(fx.ents,{
    t='blood',
    x=swimmer.x-5,
    y=swimmer.y,
    dx=rnd(5)-2.5,
    dy=rnd(100)-5,
    r=sin(t())+2,
    gravity=true,
   })
   fx.sharkblood=false
  end
 end
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
 foreach(fx.topents,function(ent)
  if ent.t=='splash' then
   ent.r+=8*dt
   if ent.r>9 then
    del(fx.topents,ent)
   end
  end
 end)
end
fx.draw=function()
 foreach(fx.ents,function(ent)
  if ent.t=='blood' then
   circfill(ent.x,ent.y,ent.r,8)
  end
 end)
 if fx.splashes then
  foreach(fx.topents,function(ent)
   if ent.t=='splash' then
    circ(ent.x,ent.y,ent.r,7)
   end
  end)
 end
end
fx.drawtop=function()

end
-->8
--shark
shark={}
shark.init=function()
 shark.x=-20
 shark.y=100
 shark.dx=20
 shark.dy=0
 shark.gravity=0
 shark.state=nil
 shark.dead=false
 subscribe('shark.start',function()
  shark.state='moving'
  swimmer.addmsg('what\'s that?!\nhurry!!!')
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
    shark.x>60 then
  fx.addsplash({
   x=shark.x,y=shark.y+16
  })
  shark.state='jump'
  shark.dy=-8
  shark.gravity=20
  shark.dx=40
 end
 if shark.state=='jump' and
    shark.dy>0 then
  shark.state='bite'
  publish('button.pause')
  publish('fx.blood','shark')
  swimmer.showfullbody=false
  swimmer.showhalfbody=true
  swimmer.deadface=true
  publish('swimmer.dead','shark')
  return
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
  spr(115,x-8,y+24)
  spr(70,x-8,y+32,4,2)
  rectfill(60,100,128,128,12)
 end
 if shark.state=='bite' then
  spr(68,x,y,2,2)
  spr(80,x,y+8)
  spr(96,x,y+16,3,2)
  spr(83,x+8,y+16)
  spr(115,x-8,y+24)
  spr(70,x-8,y+32,4,2)
  if not swimmer.dead then
   rectfill(60,100,128,128,12)
  end
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
  rectfill(60,100,128,128,12)
  return
 end
 if shark.state=='moving' then
  spr(33,x,y,2,2) 
 end
end
__gfx__
d1dddddd000000050000000000008888888000000000000000000000000000000000000000000000000000000006660000000000000000000000000000000000
161ddddd0000005100005500000888888888800000000000000000000000000000000000000000000000000000661166600000000fff0000000fff0000000000
1661dddd0000051000051151007788888888770000000000000000000000000000000000000000000000000006666611166600000fff0000000fff0000000000
16661ddd5000510000051051087770000007778000000000000000000000000000000000000000000000000066116666611660000fff0000000fff0000000000
166661dd5555100000055510088700000000788000aaaaaa9999990000999999aaaaaa000778888888888770d6661116666660000ff000000000ff0000000000
16661ddd555100000051110088800000000008880000aaaa9999000000009999aaaa00008778888888888778d7766661166660000ff000000000ff0000000000
d1161ddd55550000051000008880000000000888000000055000000000000005500000008778888888888778d777777666661000ff00000000000ff000000000
dddddddd11111000010000008880000000000888000000055000000000000005500000000778888888888770d777777776616000ff00000000000ff000000000
d0dddddd00000006000000008880000000000888550000000000005550000000000000050000000000000000d777777776156000ff0000000000fff000000000
050ddddd00000065000000008880000000000888855555555555555b855555555555555b0000044444000000d7777777766560000ff000000000ff0000000000
0550dddd0000065000000000888000000000088888555555555555bb88555556655555bb00004fffff0000000dd77777766500000ff000000000ff0000000000
05550ddd60006500000000000887000000007880000000066000000000000006600000000004fffffff00000000dddd7766000000ff000000000ff0000000000
055550dd66665000000000000877700000077780000006666660000000000066660000000004fffff71f00000000000dd60000000fff0000000fff0000000000
05550ddd66650000000000000077888888887700000060000006000000000600006000000004f71ff77f000000000000000000000fff0000000fff0000000000
d0050ddd66660000000000000008888888888000000060000006000000000600006000000044f77ffffff000000000000000000000fff000000fff0000000000
dddddddd55555000000000000000088888800000000000000000000000000060060000000044fffffffff000000000000000000000ffffffffffff0000000000
0000000000000000000000000000000000000000000000000000000000000000000000000044fffffffff0000000fffffffffff0000fffffffffff0000000000
0000000000000000000000000a0000000000a0000000000000000000000000000000000000444ffffffff000000ffffffffffff0000fffffffffff0000000000
00000000000000000000000009a00a000a0a90000000000000000000000000000000000000044ffff811f000000fffffffffff00000fffffffffff0010101010
000000000555550000000000009aa90009a9000000000000000000000000000000000000000444fff11ff000000fffffffffff00000fffffffffff0001010101
0000000005666655500000000009a000009a0000000000000000000000000000000000000004444ffffff000000fffffffffff00000fffffffffff0011111111
00000000005d666665500000000a9a000a99a000000000000000000000000000000000000000444fffff0000000fffffffffff00000fffffffffff0011011101
000000000056d6666665000000a9090009009a0000000000000000000000000000000000000004fffff000000000ffffffffff000000ffffffffff0011111111
0000000000056d6666665000009000000000090000000000000000000000000000000000000000fffffff0000000ffffffffff000000ffffffffff0010111011
0000000000056d66666650000000000000000000000000000000000000000000000000000000fffffffffff000000000000000000000b1b11111110011111111
00000000000566d666666500000000000000000000000000000000000000000000000000000ffffffffffff0000000000000000000001b111111b10011111111
00000000000056d666666500000000000000000000000000000000000000000000000000000fffffffffff00000000000000000000001111011b1b0011111111
000000000000566d66666650000000000000000000000000000000000000000000000000000fffffffffff000000000000000000000011110111b10011111111
000000000005666666666650000000000000000000000000000000000000000000000000000fffffffffff000000000000000000000011110b11110011111111
000000000005666000000000000000000000000000000000000000000000000000000000000fffffffffff0000000000000000000000b11100b1110011111111
0000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffff00000000000000000000001b110001110011111111
0000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffff00000000000000000000000ff0000ff00011111111
0000000000000000000000000000000000000000000000000565566666666666666666666666000000000005055616170000000000000ff0000ff00011111111
0000000000056000000000000000000000000000000000005656666666666666666666666666000000000055055666670000000000000ff0000ff00011111111
0000000000566000000000000000000000000000000000005555555666666666666666666666000000000556555666660000000000000ff0000ff00021212121
0000000005667600000000000000000000000000000000000000000566666666666666666666000000055566555666660000000000000ff0000ff00012121212
0000000056677600000000000000000000000000000005550000000566666666666666666660000000056666556666660000000000000ff0000ff00022222222
000000056677770000000000000000000000000000055660000000056666666666666666666000000055666655666666000000000000fff000fff00022122212
000000566677770000000000000000000000000000566770000000056666666666666666666000000055161755665666000000000000fff000fff00022222222
00000056677eee000000000000000000000000005566677000000005666666666666666666600000005661675566656600000000000000000000000021222122
0000055667eee70000000000ee77777e000000055666770000000000566666666666666666600000000000000000000000000000000000000000000022222222
0000056677ee770000000000ee7777ee0000005566677e0000000000566666666666666666600000000000000000000000000000000000000000000022222222
000005667ee70000000000007eeeeee7000005566677ee0000000000566666666666666666000000000000000000000000000000000000000000000022222222
000555667ee70000000000007eee777700055566677eee7000000000566666666666666666000000000000000000000000000000000000000000000022222222
000566667ee7000700000000777777770005666677eee777000000005666666666666666600000000000ffffff00000010101010000011100000000022222222
00556667ee700007e0000000777777770055666677ee77770000000056666666666666666000000000ffffffffff000001010101111100011110000022222222
00551167ee700077e700000067777766005511677ee7777700000000566666666666666600000000fffff0000000000010101010000000000001111022222222
00561167ee700777e700000066666666005611677ee7777700000000566666666666666600000000fff000000000000000000000000000000000000022222222
05566667ee00077ee770000000000000000000000000000000001111110000000000000000000000000000000000000000000000000000000000000022222222
05566667ee0077ee7770000000000000000004444400000000011111111000000000000000000000000004444400000000000000000000000000000022222222
555666667eeeeee7777000000000000000004fffff0000000011111111100000000000000000f00000004fffff000000000000000000000000000000c2c2c2c2
555666667eee777777760000000000000004fffffff0000001111111111000000f000000000fff000004fffffff000000000000000000000000000002c2c2c2c
556666667777777777660000000000000004ffff1f1f000001111000000000000ff0000000fffff00004fffff71f0000000000000000000000000000cccccccc
5566666677777777766600000000000000041f1ff1ff00000111000000000000fffff00000ffff000004f71ff77f0000000000000000000000000000cc2ccc2c
556656666777776666660000000000000044f1ff1f1ff00011110000000000000fff0000000fff000044f77ffffff000000000000000000000000000cccccccc
5566656666666666666600000000000000441f1ffffff00011110000000000000fff0000000ff0000044fffffffff000000000000000000000000000c2ccc2cc
556656556666666666666000000000000044fffffffff000111110000000000000ff0000000ff0000044fffffffff000000000000000000000000000cccccccc
5566656655666666666660000000000000444ffffffff000111110000000000000ff0000000ff00000444ffffffff0000000f0000000000000000000cccccccc
5566565566666666666660000000000500044ffffffff000111111000000000000ff0000000ff00000044ffff811f0000f00f0f00000000000000000cccccccc
55666566556666666666600000000556000444ff111ff000111111000000000000fff000000ff000000444fff11ff00000ff0f000000ff0000000000cccccccc
556666556666666666666000000056660004444f1ffff000011110000000000000fff000000ff0000004444ffffff00000fff0000f00ff0000000000cccccccc
556666666666666666666000000566660000444fffff00000011000000000000000ff000000ff0000000444fffff000000ff110000ffff0000000000cccccccc
55666666666666666666000000566666000004fffff000000000000000000000000fff0000fff000000004fffff000000111111000f11000000ff000cccccccc
55666666666666666666000005666556000000000000000000000000000000000000ff00000000000000000000000000000000000111110000111100cccccccc
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
__label__
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccc000000000ccc000000000ccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccc0bbb0b0b0ccc0bbb0bbb0ccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccc0b000b0b0ccc000b0b000ccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccc0bbb0bbb0ccccc0b0bbb0ccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccc000b000b0000cc0b000b0ccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccc0bbb0c0b00b0cc0b0bbb0ccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccc00000c000000cc0000000ccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccc11111111111111111cccccccc11111111111111111cccccccc11111111111111111cccccccc11111111111111111cccccccc11111111111111111cccccc
ccccc1eeeeeeeeeeeeeee1cccccccc1bbbbbbbbbbbbbbb1cccccccc12222222222222221cccccccc1aaaaaaaaaaaaaaa1cccccccc1ddddddddddddddd1cccccc
ccccc1eeeeeeeeeeeeeee1cccccccc1bbbbbbbbbbbbbbb1cccccccc12222222222222221cccccccc1aaaaaaaaaaaaaaa1cccccccc1ddddddddddddddd1cccccc
ccccc1eeeeeeeeeeeeeee1cccccccc1bbbbbbbbbbbbbbb1cccccccc12222222222222221cccccccc1aaaaaaaaaaaaaaa1cccccccc1ddddddddddddddd1cccccc
ccccc1eeeeeeeeeeeeeee1cccccccc1bbbbbbbbbbbbbbb1cccccccc12222222222222221cccccccc1aaaaaaaaaaaaaaa1cccccccc1ddddddddddddddd1cccccc
ccccc1eeeeeeeeeeeeeee1cccccccc1bbbbbbbbbbbbbbb1cccccccc12222222222222221cccccccc1aaaaaaaaaaaaaaa1cccccccc1ddddddddddddddd1cccccc
ccccc1eeeeeeeeeeeeeee1cccccccc1bbbbbbbbbbbbbbb1cccccccc12222222222222221cccccccc1aaaaaaaaaaaaaaa1cccccccc1ddddddddddddddd1cccccc
ccccc1eeeeeeeeeeeeeee1cccccccc1bbbbbbbbbbbbbbb1cccccccc12222222222222221cccccccc1aaaaaaaaaaaaaaa1cccccccc1ddddddddddddddd1cccccc
ccccc1eeeeeeeeeeeeeee1cccccccc1bbbbbbbbbbbbbbb1cccccccc12222222222222221cccccccc1aaaaaaaaaaaaaaa1cccccccc1ddddddddddddddd1cccccc
ccccc1eeeeeeeeeeeeeee1cccccccc1bbbbbbbbbbbbbbb1cccccccc12222222222222221cccccccc1aaaaaaaaaaaaaaa1cccccccc1ddddddddddddddd1cccccc
ccccc1eeeeeeeeeeeeeee1cccccccc1bbbbbbbbbbbbbbb1cccccccc12222222222222221cccccccc1aaaaaaaaaaaaaaa1cccccccc1ddddddddddddddd1cccccc
ccccc1eeeeeeeeeeeeeee1cccccccc1bbbbbbbbbbbbbbb1cccccccc12222222222222221cccccccc1aaaaaaaaaaaaaaa1cccccccc1ddddddddddddddd1cccccc
ccccc11111111111111111cccccccc11111111111111111cccccccc11111111111111111cccccccc11111111111111111cccccccc11111111111111111cccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
cc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cc
ccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65ccc
ccc56cccccc56cccccc56cccccc56cccccc56cccccc56cccccc56cccccc56cccccc56cccccc56cccccc56cccccc56cccccc56cccccc56cccccc56cccccc56ccc
cc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cc
c5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6c
5cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc6
5cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc6
c5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6c
cc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cc
ccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65ccc
ccc56cccccc56cccccc56cccccc56cccccc56cccccc56cccccc56cccccc56cccccc56cccccc56cccccc56cccccc56cccccc56cccccc56cccccc56cccccc56ccc
cc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cc
c5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6c
5cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc6
5cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc67777777777777777777777775cccccc65cccccc65cccccc6
c5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6c766777777777777777777667c5cccc6cc5cccc6cc5cccc6c
cc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cc777777777777777777777777cc5cc6cccc5cc6cccc5cc6cc
ccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65ccc779979797979997799979997ccc65cccccc65cccccc65ccc
ccc56cccccc56cccccc56cccccc56cccccc56cccccc56cccccc56cccccc56cccccc56cccccc56ccc797779797979997797977977ccc56cccccc56cccccc56ccc
cc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cc799979797979797799977977cc5cc6cccc5cc6cccc5cc6cc
c5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6c777979997979797797977977c5cccc6cc5cccc6cc5cccc6c
5cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc67997799979797977979779775cccccc65cccccc65cccccc6
5cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc67777777777777777777777775cccccc65cccccc65cccccc6
c5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6c797979997799979779979797c5cccc6cc5cccc6cc5cccc6c
cc5cc6cccc5cc6cccc5cc6cccc111111111111cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cc797979797797979797779797cc5cc6cccc5cc6cccc5cc6cc
ccc65cccccc65cccccc65cccc11111111111111cccc65cccccc65cccccc65cccccc65cccccc65ccc797979977799779799979977ccc65cccccc65cccccc65ccc
ccc56cccccc56cccccc56cccc77711111111777cccc56cccccc56cccccc56cccccc56cccccc56ccc797979797797979777979797ccc56cccccc56cccccc56ccc
cc5cc6cccc5cc6cccc5cc6ccc77711cccc11777ccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cc799979797797979799779797cc5cc6cccc5cc6cccc5cc6cc
c5cccc6cc5cccc6cc5cccc6cc711cc6cc5cc117cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6c766777777777777777777667c5cccc6cc5cccc6cc5cccc6c
5cccccc65cccccc65cccccc65711cc6666ccc1765cccccc65cccccc65cccccc65cccccc65cccccc67777777777777777777777775cccccc65cccccc65cccccc6
5cccccc65cccccc65cccccc65c711111111117c65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc6
c5cccc6cc5cccc6cc5cccc6cc571116cc511176cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6c
cc5cc6cccc5cc6cccc5cc6cccc71c6cccc5c17cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cc
ccc65cccccc65cccccc65cccc77777777777777cccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65ccc
ccc56cccccc56cccccc56cccc77777777777777cccc56cccccc56cccccc56cccccc56cccccc56cccccc56cccccc56cccccc56cccccc56cccccc56cccccc56ccc
cc5cc6cccc5cc6cccc5cc6ccc77777777777777ccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cc
c5cccc6cc5cccc6cc5cccc6cc77111111111177cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6c
5cccccc65cccccc65cccccc6577cccc65cccc7765cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc6
5cccccc65cccccc65cccccc6577cccc65cccc7765cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc6
c5cccc6cc5cccc6cc5cccc6cc77ccc6cc5ccc77cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6cc5cccc6c
cc5cc6cccc5cc6cccc5cc6ccc77cc6cccc5cc77ccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5cc6cc
ccc65cccccc65cccccc65cccc7765cccccc6577cccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65cccccc65ccc
ccc56cccccc56cccccc56cccc7756cccccc5676cccc56cccccc56cccccc56cccccc56cccccc56cccccc56cccccc56cccccc56cccccc56cccccc56cccccc56ccc
cc5cc6cccc5cc6cccc5cc6ccc77cc6cccc5cc76ccc5cc6cccc5cc77ccc5cc6cccc5cc6cccc5cc6cccc5cc6cccc5c77cccc5cc6cccc5cc6cccc5cc6cccc5cc6cc
c5cccc6cc5cccc6cc5cccc6cc77ccc6cc5ccc76cc5cccc6cc5cccc77c5cccc6cc5cccc6cc5cccc6cc5cccc6cc5ccc77cc5cccc6cc5cccc6cc5cccc6cc5cccc6c
5cccccc65cccccc65cccccc677777778877777775cccccc65cccccc77cccccc65cccccc65cccccc65cccccc65ccccc775cccccc65cccccc65cccccc65cccccc6
5cccccc65cccccc65cccccc677777788887777775cccccc65cccccc777ccccc65cccccc65cccccc65cccccc65ccccc777cccccc65cccccc65cccccc65cccccc6
c5cccc6cc5cccc6cc5cccc6c7777778888777777c5cccc6cc5cccc7c777ccc67777ccc6cc5cccc6cc5cccc6cc5ccc76777cccc7777cccc6cc5cccc6cc5cccc6c
cc5cc6cccc5cc6cccc5cc6cc7777777887777777cc5cc6cccc5cc7ccc777c67ccc57c6cccc5cc6cccc5cc6cccc5c76cc777cc7cccc7cc6cccc5cc6cccc5cc6cc
ccc65cccccc65cccccc65ccc7771111111111777ccc65cccccc65777777777777777777777777cccccc65cccccc67777777777777777777777775cccccc65ccc
ccc56cccccc56cccccc56ccc77756cccccc56777ccc56cccccc56777777777777777777777777cccccc56cccccc57777777777777777777777776cccccc56ccc
cc5cc6cccc5cc6cccc5cc6cc777cc6cccc5cc777cc5cc6cccc5cc7cccc5cc7cccc5c76cccc5776cccc5cc6cccc5c76cccc5c76cccc57c6cccc77c6cccc5cc6cc
c5cccc6cc5cccc6cc5cccc6c777ccc6cc5ccc776c5cccc6cc5cccc7cc5cc7c6cc5ccc76cc5c7cc6cc5cccc6cc5ccc76cc5c7cc6cc5cc7c6cc57ccc6cc5cccc6c
5cccccc65cccccc65cccccc6777cccc65cccc7765cccccc65cccccc77777ccc65ccccc77777cccc65cccccc65ccccc77777cccc65cccc77777ccccc65cccccc6
bbbbbbbbbbbbbbbbbbbbbbbb777bbbbbbbbbb766bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000bbbb00000000000b00000000bbbb0000000000000000000bbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666666666666666666666666666666660aaa066600aa0aaa0aa000a00aaa066600aa0a0a0aaa0aaa00a066666666666666666666666
6666666666666666666666666666666666666666666666666666600a006660a000a0a0a0a0a0000a006660a000a0a00a00aaa00a066666666666666666666666
777777777777777777777777777f777777777777777777777777770a077f70a070aaa0a0a000770a077770aaa0a0a00a00a0a00a077777777777777777777777
777777777777777777777777777f777777777777777777777777700a007f70a000a0a0a0a077770a07777000a0aaa00a00a0a000077777777777777777777777
777777777777777777777777777f77777777777777777777777770aaa07f700aa0a0a0a0a077770a077770aa00aaa0aaa0a0a00a077777777777777777777777
777777777777777777777777777f7777777777777777777777777000007f77000000000000777700077770000000000000000000077777777777777777777777
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccfccccc44444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccffccc4fffffcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccfffff4fffffffccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccfffc4fffff71fcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccfffc4f71ff77fcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccff44f77ffffffc77777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccff44fffffffff7ccccc7cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccc7ff44fffffffffccccccc7ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccc7cfff44ffffffffcccccccc7cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccc7ccfff44ffff811fccccccccc7ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccc7cccff444fff11ff77ccccccc7ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccc7ccccfff444ffffffc7ccccccc7ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccc7cccccff444fffff7cc7cccccc7ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccc7cccccccc4fffffc7cc7cccccc7ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccc7ccccccccc77cc777cc7ccccc7cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccc7cccccccccc777cc7c7ccccc7ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccc7cccccccccc77c7c77cccc7cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccc7cccccccccccc777c77777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccc7ccccccccccc7ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccc7ccccccccc7cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccc77ccccc77ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccc77777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

__map__
2020202020202020202020202020202000000000000040414200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000050515200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000060616200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000070717273000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dadadadadadadadadadadadadadadada00000000000046474849000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dbdbdbdbdbdbdbdbdbdbdbdbdbdbdbdb00000000000056575859000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
