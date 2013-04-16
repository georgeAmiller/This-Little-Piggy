--[[  This is my fourth attempt at "This Little Piggy".  The last try ran into problems when trying to use physics and
	display.groups that were moved and rotated.  This time I shall place all the pens on the background according to 
	predefined tables and then to group the pigs into pens and the pens into a farm.  The pens will all be static and
	the pigs shall be dynamic.  
	I took a long time to figure out how to get the pigs from jamming up agains the fence, move in the direction they were 
	pointing, and do so in a seemingly random fashion.
	I've made good progress and am now putting in the gates and getting them to open in a natural fashion.
	This will involve touch listeners on each gate.
--]]
require("physics")
physics.start()
physics.setGravity(0,0)
local pigWidth= 57
local pigHeight=36
local yard = display.newImage("pig snapshot.png",display,contentWidth, display.contentHeight)
display.setStatusBar( display.HiddenStatusBar )  -- Hide status bar
local centerX=display.contentWidth/2
local centerY=display.contentHeight/2
local s = display.contentWidth/5
local t=0.8660254*s -- s is the length of a side of the pen. t is the distance from the center of a pen to a side.
--  print("s,t = "..s..", "..t)
local deltaAngle=15 -- this is the spacing between poles in the pens
-- the collection point is near the center of the display.  When a pig is let out of
-- the pen, it will run to the open gate, then to the collection point, then off the bottom
-- of the display in a "poof"
local collectionX = centerX
local collectionY = centerY + 0.75*t
local bottomX = centerX
local bottomY = display.contentHeight-pigWidth
local thickness=5 -- this is the radius of the pen poles
-- upper case P are the points for the centers of the 5 pens with respect to the center of the display screen
local P={{x=0,y=-2.5*t,p={},gate=1,gates={},pigs={}},{x=-1.5*s,y=-0.5*t,p={},gate=5,gates={},pigs={}},
		{x=-1.5*s,y=2*t,p={},gate=9,gates={},pigs={}},
		{x=1.5*s,y=-0.5*t,p={},gate=21,gates={},pigs={}},{x=1.5*s,y=2*t,p={},gate=17,gates={},pigs={}}} 
local pigSheet = graphics.newImageSheet("pig_sheet_horizontal.png",{width = 57, height = 36, numFrames = 4})
local pigShape = {-28,-18,28,-18,28,18,-28,18,}

local function turnTo(px,py,tx,ty)
	local angle = math.deg(math.atan((ty-py)/(tx-px)))
	--if angle<0 then angle=180+angle end
	print("pig points to gate at an angle of "..angle.."degrees.")
	return angle
end

local function closest(pen)
	local j=0
	local dist=0
	local d=3*s
	local pigs=P[pen].pigs
	local gate=P[pen].gate
	for i=1,#pigs do
		dist=math.sqrt((pigs[i].x-P[pen].gates[gate].x)^2+(pigs[i].y-P[pen].gates[gate].y)^2)
		if dist<d then
			j=i
			d=dist
		end
	end
 	P[pen].closest=j
	local pig=P[pen].pigs[j]
	pig.rotate=turnTo(pig.x,pig.y,P[pen].gates[gate].x,P[pen].gates[gate].y)
	if pen>3 then pig.rotate=pig.rotate+180 end
	if pen==1 and pig.rotate<0 then pig.rotate=pig.rotate+180 end
	pig.rotation=pig.rotate
	pig.cycle="escape"
return pig
end

local function turnPig(pen)
local pig = closest(pen)
print("You just touched pen number "..pen.." Closest pig is number "..P[pen].closest)
end

local function onLocalPreCollision( self, event )
	-- This new event type fires shortly before a collision occurs, so you can use this if you want
	-- to override some collisions in your game logic. For example, you might have a platform game
	-- where the character should jump "through" a platform on the way up, but land on the platform
	-- as they fall down again.
	
	-- Note that this event is very "noisy", since it fires whenever any objects are somewhat close!

	print( "preCollision: " .. self.myName .. " is about to collide with " .. event.other.myName )

end

local function onTouch( event )
	local t = event.target
	local phase = event.phase
	if "began" == phase then
		-- Make target the top-most object
		local parent = t.parent
		parent:insert( t )
		display.getCurrentStage():setFocus( t )
		turnPig(t.name)
		-- Spurious events can be sent to the target, e.g. the user presses 
		-- elsewhere on the screen and then moves the finger over the target.
		-- To prevent this, we add this flag. Only when it's true will "move"
		-- events be sent to the target.
		t.isFocus = true

		-- Store initial position
		t.x0 = event.x - t.x
		t.y0 = event.y - t.y
	elseif t.isFocus then
		if "moved" == phase then
			-- Make object move (we subtract t.x0,t.y0 so that moves are
			-- relative to initial grab point, rather than object "snapping").
			--t.x = event.x - t.x0  -- this is for dragging the gate to a new position
			--t.y = event.y - t.y0
			if t.open==-1 and t.rotation>=t.stop then t:rotate(t.open) end -- this is for opening the gate
			if t.open==1 and t.rotation<=t.stop then t:rotate(t.open) end
		elseif "ended" == phase or "cancelled" == phase then
			display.getCurrentStage():setFocus( nil )
			t.rotation=t.closed --this closes the gate
			t.isFocus = false
		end
	end

	-- Important to return true. This tells the system that the event
	-- should not be propagated to listeners of any objects underneath.
	return true
end

for i,v in ipairs(P) do
	local c=0
	local k=0
	local left,awake,asleep,right
	while c<360 do
		wx=s*math.sin(math.rad(c))+v.x+centerX
		wy=s*math.cos(math.rad(c))+v.y+centerY
		local point = display.newCircle(wx,wy,thickness)
		k=k+1		
		local pointXY={x=wx,y=wy,id=k}
		table.insert(P[i].p,point)
		point:setFillColor(0,255,0,0)
		physics.addBody( point, "static", { friction=0, bounce=0.3 } )
		table.insert(P[i].gates,pointXY)
		c=c+deltaAngle
	end
	j=math.random(1,9)
	for k=1,j do
		left=display.newImageRect( pigSheet,1,pigWidth,pigHeight ) 
		awake=display.newImageRect( pigSheet,2,pigWidth,pigHeight ) 
		asleep=display.newImageRect( pigSheet,3,pigWidth,pigHeight ) 
		right=display.newImageRect( pigSheet,4,pigWidth,pigHeight ) 
		local pig=display.newImageGroup(pigSheet)
		pig:insert(left)
		pig:insert(awake)
		pig:insert(asleep)
		pig:insert(right)
		pig[1].alpha=0
		pig[2].alpha=0
		pig[3].alpha=1 -- display the sleeping image
		pig[4].alpha=0
		pig.x, pig.y=P[i].x+centerX, P[i].y+centerY  -- put a random number of pigs in each pen
		pig:rotate(math.random(-180,180))	
		pig.cycle="dead" -- the pig can be in the following states: awake,turn,move,asleep
		pig.heading=-1
		pig.number=k
		physics.addBody( pig,  { friction=0, bounce=.3, shape=pigShape} )
		table.insert(P[i].pigs,pig)
	end
end
--P[1].p[P[1].gate].isSensor=true  -- this will make the invisible gate open 
local x,y = 0,0
local arguments =
{
	{ orientation="gate.png", direction=1, rotate=0, stop=-90, reference=display.TopRightReferencePoint},
	{ orientation="gate.png", direction=1, rotate=-60, stop=-180, reference=display.TopRightReferencePoint},
	{ orientation="gate.png", direction=1, rotate=-120, stop=-240, reference=display.TopRightReferencePoint},
	{ orientation="gatep.png", direction=-1, rotate=60, stop=180, reference=display.TopLeftReferencePoint},
	{ orientation="gatep.png", direction=-1, rotate=120, stop=240, reference=display.TopLeftReferencePoint},
}
local x,y
local gates={}
for i,item in ipairs( arguments ) do
	local gate=display.newImage(item.orientation,centerX,centerY)
	gate:scale(.5,.5)
	P[i].p[P[i].gate]:setFillColor(0,255,0,0)  -- make this pole invisible
	x=P[i].p[P[i].gate+item.direction].x y=P[i].p[P[i].gate+item.direction].y
	gate:setReferencePoint(item.reference)
	gate.x=x gate.y=y
	gate.rotation=item.rotate
	gate.closed=item.rotate
	gate.stop=item.stop
	gate.name=i
	gate.open=-item.direction
	gate:addEventListener( "touch", onTouch )
	table.insert(gates,gate)
	end

local function awake(pig,pen)
local pa = pig.rotation
local cx = pen.x+centerX
local cy = pen.y+centerY
local px = pig.x
local py = pig.y
local ca=0
local pa=math.mod(pig.rotation,360)
if cx==px then if cy>py then ca=90 else ca=-90 end
else ca=math.deg(math.atan((py-cy)/(px-cx))) end
if pa<0 then pa=pa+360  end
if ca<0 then ca=ca+180  end
if py>cy then ca=math.mod(ca+180,360) end
local da = math.abs(ca-pa)
	pig.frames= math.random(da-da/3,da+da/3)
	pig[2].alpha=0
	if pig.heading==1 then
		pig[4].alpha=1  -- display the right turn image
	else
		pig[1].alpha=1  -- display the left turn image
	end -- if		
	pig.cycle="turn"
end -- function awake

local function asleep(pig,pen)
	if pig.frames>0 then 
		pig.frames=pig.frames-1	
	else 
		pig[3].alpha=0
		pig[2].alpha=1  -- display the awake image
		pig.cycle="awake" 
	end
end

local function turn(pig,pen)
	if pig.frames<=0 then
		pig.frames=math.random(1,1.5*s)
		pig[1].alpha=0
		pig[4].alpha=0
		pig[2].alpha=1  -- display the awake image
		pig.cycle="move"
	else -- turn the pig one degree
		pig.frames=pig.frames-1
		pig.rotation=pig.rotation+pig.heading
	end
end

local function move(pig,pen)
	if pig.frames<=0 then
		pig.frames = math.random(30,90)
		pig[2].alpha=0
		pig[3].alpha=1  -- display the asleep image
		pig.cycle="asleep"
	else -- move the pig one step in the direction it is currently facing
		pig.frames=pig.frames-1
		local y=math.sin(math.rad(pig.rotation))
		local x=math.cos(math.rad(pig.rotation))
		pig.x=pig.x+x
		pig.y=pig.y+y
	end
end

local function escape(pig,pen)
	pig.frames=300000
	move (pig,pen)
end

local myListener = function(event)
--  every frame we examine each pig and advance him one frame through his cycle
for i,pen in ipairs(P) do
pen.number=i
	for j,pig in ipairs (P[i].pigs) do
		if pig.cycle=="awake" then awake(pig,pen) end
		if pig.cycle=="asleep" then asleep(pig,pen) end
		if pig.cycle=="turn" then turn(pig,pen) end
		if pig.cycle=="move" then move(pig,pen) end
		if pig.cycle=="escape" then escape(pig,pen) end
	end -- for j..
end -- for i ..
end -- myListener
		
Runtime:addEventListener("enterFrame",myListener)

local function awakenPigs (event)
-- closest()
-- awaken the dead pigs
for i,pen in ipairs(P) do 
	for j,pig in ipairs (P[i].pigs) 
		do pig.cycle="awake"
		end -- for j
	end -- for i
end -- function awakenPigs

timer.performWithDelay(1000,awakenPigs)

local function printTouch( event )
 	if event.target then 
 		local bounds = event.target.contentBounds
		print( "event(" .. event.phase .. ") ("..event.x..","..event.y..") bounds: "..bounds.xMin..","..bounds.yMin..","..bounds.xMax..","..bounds.yMax )
	end 
end

-- listener used by Runtime object. This gets called if no other display object
-- intercepts the event.
local function printTouch2( event )
	print( "event(" .. event.phase .. ") ("..event.x..","..event.y..")" )
end

Runtime:addEventListener( "touch", printTouch2 )