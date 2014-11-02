--- ************************************************************************************************************************************************************************
---
---				Name : 		player.lua
---				Purpose :	Class responsible for animating and rendering player graphics
---				Updated:	2 November 2014
---				Author:		Paul Robson (paul@robsons.org.uk)
---				License:	Copyright Paul Robson (c) 2014+
---
--- ************************************************************************************************************************************************************************

--- ************************************************************************************************************************************************************************
--//	This class builds a basic animatable player out of primitives. This is not done using images because of the need to colour the players
--//	according to their club strips.
--- ************************************************************************************************************************************************************************

local PlayerGraphic = Framework:createClass("gfx.player")

PlayerGraphic.isCameraAtBottom = true 														-- the viewing angle up or down the screen
PlayerGraphic.TOP = 1 																		-- constants for quasi-static function.
PlayerGraphic.BOTTOM = 2

--//	Constructor, takes an assortment of parameters, but none are actually required
--//	@info [table]	constructor data.

function PlayerGraphic:constructor(info)
	self.m_footPosition = 0 																-- percent in foot position (e.g. back/forward)
	self:construct() 																		-- build the physical graphics.
	self:move(info.x or 0,info.y or 0)														-- move it.
	self:showMarker(info.marker or false)													-- show the marker.
	if info.shadow == false then self:showShadow(false) end  								-- show shadow, defaults to true e.g. must supply false.
	self:setSkinTone(info.skin or 40)														-- skin colour a light brown.
	self:setStrip(info.shirt or "#FFFF00", info.shorts or "#008000")						-- Norwich City strip (Yellow/Green)
	self:setHair(info.hair or "#663300")													-- Hair colour (brown)
	self:setRotation(info.direction or 0)													-- set the rotation

	-- arm waving and running animation.
	-- rescaling size method.
end 

function PlayerGraphic:destructor()
	self.m_group:removeAll() self.m_group = nil self.m_gfx = nil 							-- remove all references to graphics objects.
end 

--//	Move the player to position x/y on the physical screen.
--//	@x 		[number]	horizontal position
--//	@y 		[number]	vertical position

function PlayerGraphic:move(x,y)
	self.m_group.x,self.m_group.y = x,y 
end 

--//	Set camera position at the top or bottom - affects the player tilt, so , for example, if the camera is at the bottom
--// 	then players facing down the field have their front visible. The camera is at the opposite end of the goal, always.
--//	This function is static, e.g. all players will behave similarly. An interesting corollary of this is that the shadow 
--//	is always at -45 degrees, which means that it is different for each half.... will anyone notice ?
--//	@position [string]	top or bottom accordingly.

function PlayerGraphic:setCamera(position)
	assert(position == "top" or position == "bottom")
	PlayerGraphic.isCameraAtBottom = (position == "bottom")
end 

--//	Set the rotation of the player, and adjust the body alignment accordingly
--//	@angle [number]		rotation angle, defaults to current rotation.

function PlayerGraphic:setRotation(angle)
	angle = angle or self.m_group.rotation 													-- the angle to rotate by.
	self.m_group.rotation = angle 															-- rotate the player
	self.m_gfx.shadow.rotation = -45-angle 													-- the shadow does not rotate
	self.m_gfx.marker.rotation = -angle 													-- the marker does not rotate
	if not PlayerGraphic.isCameraAtBottom then angle = angle + 180 end 						-- if camera at top, reverse it
	local event = math.sin(math.rad(angle)) * 12 											-- work out the lean given the camera angle
	self:alignBody(event) 																	-- and lean the player only
end 

--//	Set the player's skin tone
--//	@percent [number]	0 = very black, 100 = very fair

function PlayerGraphic:setSkinTone(percent)
	local b = ((percent or 80) * 1.5 + 30) / 255 											-- blue is 30-180
	local skin = { b * 1.5, b * 1.15, b }													-- calculate skin tone.
	self:fill(self.m_gfx.face,skin) 														-- colour face and hands
	self:fill(self.m_gfx.arm1.hand,skin)
	self:fill(self.m_gfx.arm2.hand,skin)
end

--//	Colour the shirt and shorts, single colours only.
--//	@shirt 	[rgb]	shirt colour
--//	@shorts [rgb]	shorts colour

function PlayerGraphic:setStrip(shirt,shorts)
	self:fill(self.m_gfx.shirt1,shirt)														-- colour the shirt
	self:fill(self.m_gfx.shirt2,shirt)
	self:fill(self.m_gfx.arm1.arm,shirt,true)
	self:fill(self.m_gfx.arm2.arm,shirt,true)
	self:fill(self.m_gfx.shorts,shorts) 													-- colour the shorts
end 

--//	Colour the hair
--//	@hair 	[rgb]	hair colour

function PlayerGraphic:setHair(rgb)
	self:fill(self.m_gfx.hair,rgb)															-- hair colour
	self:fill(self.m_gfx.faceCover,rgb) 													-- bit that covers the face
end 

--//	Show or hide the player marker
--//	@isShown 	[boolean]	true if show it.

function PlayerGraphic:showMarker(isShown)
	self.m_gfx.marker.isVisible = isShown 
end 

--//	Show or hide the player shadow
--//	@isShown 	[boolean]	true if showing it

function PlayerGraphic:showShadow(isShown)
	self.m_gfx.shadow.isVisible = isShown 
end 

--//	Set a graphic objects colour
--//	@object [display object] 	Corona display object
--//	@rgb 	[rgb]				Colour
--//	@isLine [boolean]			True if object is a line.

function PlayerGraphic:fill(object,rgb,isLine)
	rgb = self:convert(rgb)																	-- convert #xxxxxx to {r,g,b} if required
	if isLine then  																		-- set colour, type dependent
		object:setStrokeColor(rgb[1],rgb[2],rgb[3])
	else
		object:setFillColor(rgb[1],rgb[2],rgb[3])
	end
end 

--//	Convert string RGB
--//	@rgb 	[rgb]	table or #RRGGBB as string.
--//	@return [table]	RGB table.

function PlayerGraphic:convert(rgb)
	if type(rgb) == "string" then 															-- process strings.
		assert(rgb:sub(1,1) == "#" and #rgb == 7)											-- basic checks.
		rgb = { tonumber(rgb:sub(2,3),16)/255,												-- do the conversion.
								tonumber(rgb:sub(4,5),16)/255,tonumber(rgb:sub(6,7),16)/255}
	end 
	return rgb
end 

--//	Reposition the feet after an alignment or update of the foot position.

function PlayerGraphic:repositionFeet()
	local offset = (self.m_gfx.footMax-self.m_gfx.footMin) * self.m_footPosition / 100 		-- work out the position in the foot movement
	self.m_gfx.foot1.group.x = self.m_gfx.footMin + offset 									-- position feet accordingly.
	self.m_gfx.foot2.group.x = self.m_gfx.footMax - offset
end 

--//	This aligns the players body, tilting it forward or back to reveal details
--//	@n 	[number]	tilt, goes from about -15 to +15, positive tilts back so can see shirt etc.

function PlayerGraphic:alignBody(n)

	self.m_gfx.hair.x = -n*2.3 																-- angle body parts so they become visible.
	self.m_gfx.face.x = 20+self.m_gfx.hair.x
	self.m_gfx.collar.x = -n*1.3
	self.m_gfx.shirt1.x = self.m_gfx.collar.x
	self.m_gfx.shirt2.x = -n*0.6
	self.m_gfx.shorts.x = 0
	self.m_gfx.arm1.group.x = self.m_gfx.collar.x
	self.m_gfx.arm2.group.x = self.m_gfx.collar.x
	self.m_gfx.shadow.x = self.m_gfx.collar.x

	if n > 0 then 																			-- if leaning back (e.g. front of boots visible)
		self.m_gfx.foot1.group.x = n * 0.2 													-- set foot positions.
		self.m_gfx.foot2.group.x = n * 1.1
		self.m_gfx.face.isVisible = true 													-- face is visible, so is the cover
		self.m_gfx.faceCover.isVisible = true
		self.m_gfx.faceCover.x = 18-n*3.3 													-- position face cover
	else 
		self.m_gfx.foot1.group.x = -n * 0.1 												-- leaning forward, so face is not visible
		self.m_gfx.foot2.group.x = n * 0.2 													-- show the back of the boots, partially
		self.m_gfx.face.isVisible = false
		self.m_gfx.faceCover.isVisible = false
	end
	self.m_gfx.footMin = math.min(self.m_gfx.foot1.group.x,self.m_gfx.foot2.group.x) 		-- work out the range of the foot position.
	self.m_gfx.footMax = math.max(self.m_gfx.foot1.group.x,self.m_gfx.foot2.group.x)
	self:repositionFeet() 																	-- reposition the feet.
end 


--//	This creates the basic graphic objects, puts them in a group, and keeps references in a table.

function PlayerGraphic:construct()

	self.m_group = display.newGroup()														-- create the group which holds all the player gfx.
	self.m_gfx = {} 																		-- this table holds all the graphic objects
	self.m_group.x,self.m_group.y = display.contentWidth/2,display.contentHeight/2 			-- default position.

	self.m_gfx.marker = display.newPolygon(self.m_group,0,0,self.markerVertices) 			-- star marker 
	self.m_gfx.marker.stroke = self.markerPaint self.m_gfx.marker.strokeWidth = 16
	self.m_gfx.marker:setFillColor(0,0,0,0)
	self.m_gfx.marker.isVisible = true 

	self.m_gfx.foot1 = self:createFoot(1) self.m_group:insert(self.m_gfx.foot1.group)		-- feet
	self.m_gfx.foot2 = self:createFoot(-1) self.m_group:insert(self.m_gfx.foot2.group)

	self.m_gfx.shadow = display.newCircle(self.m_group,0,0,35)
	self.m_gfx.shadow.anchorX,self.m_gfx.shadow.anchorY = 0.2,0.4
	self.m_gfx.shadow.rotation = -45 self.m_gfx.shadow.xScale = 1.5
	self.m_gfx.shadow:setFillColor(0,0,0,0.3)

	if true then 																			-- debugging - used to establish the physical 
		local t = display.newCircle(self.m_group,0,0,53) 									-- diameter of the player.
		t:setFillColor(0,0,0,0) t.strokeWidth = 1 
		display.newLine(self.m_group,0,-80,0,80)
		display.newLine(self.m_group,-80,0,80,0)
	end 

	self.m_gfx.shorts = display.newCircle(self.m_group,0,0,30)								-- shorts
	self.m_gfx.shorts:setFillColor(1,1,1) self.m_gfx.shorts.xScale = 0.5

	self.m_gfx.shirt2 = display.newCircle(self.m_group,0,0,35)								-- shirt (bottom)
	self.m_gfx.shirt2:setFillColor(1,0,0) self.m_gfx.shirt2.xScale = 0.5

	self.m_gfx.shirt1 = display.newCircle(self.m_group,0,0,45) 								-- shirt (top)
	self.m_gfx.shirt1:setFillColor(1,0,0) self.m_gfx.shirt1.xScale = 0.5

	self.m_gfx.arm1 = self:createArm(1) self.m_group:insert(self.m_gfx.arm1.group)			-- arms
	self.m_gfx.arm2 = self:createArm(-1) self.m_group:insert(self.m_gfx.arm2.group)

	self.m_gfx.collar = display.newCircle(self.m_group,0,0,18) 								-- collar 
	self.m_gfx.collar.strokeWidth = 2 self.m_gfx.collar:setStrokeColor(0,0,0)

 	self.m_gfx.hair = display.newCircle(self.m_group,0,0,30)								-- hair
	self.m_gfx.hair:setFillColor(102/255,51/255,0)

	self.m_gfx.face = display.newCircle(self.m_group,0,0,20) 								-- face
	self.m_gfx.face.xScale = 0.5 self.m_gfx.face:setFillColor(1,0.87,0.77)

	self.m_gfx.faceCover = display.newRect(self.m_group,10,0,20,40)							-- face cover.
	self.m_gfx.faceCover:setFillColor(1,0.6,0)
	self.m_gfx.faceCover:setFillColor(102/255,51/255,0)

	self:alignBody(15)
end 

PlayerGraphic.markerVertices = { 0,-110, 27,-35, 105,-35, 43,16, 65,90, 0,45, -65,90, -43,15, -105,-35, -27,-35, }
PlayerGraphic.markerPaint = { type = "gradient",color1 = { 0, 1, 1 },color2 = { 0, 0, 1 },direction = "down" }

--//	Create a foot for the player
--//	@yOffset 	[number]	-1 or 1 , depending on whether upper or lower

function PlayerGraphic:createFoot(yOffset)
	local foot = display.newGroup()															-- create a foot group
	local boot = display.newCircle(foot,0,0,18) boot.yScale = 0.45 							-- add a boot to it
	boot:setFillColor(0,0,0)
	display.newLine(foot,6,-3,6,3)															-- add laces
	display.newLine(foot,2,-3,2,3)
	display.newLine(foot,4,-3,4,3)
	foot.y = yOffset * 13 																	-- position it.
	return { group = foot }
end 

--//	Create an arm for the player
--//	@yOffset 	[number]	-1 or 1 , depending on whether upper or lower

function PlayerGraphic:createArm(yOffset)
	local armGroup = display.newGroup() 													-- create an arm
	local hand = display.newCircle(armGroup,27+yOffset*4,yOffset*0,7) 						-- add a hand to it
	local arm = display.newLine(armGroup,0,0,22+yOffset*4,yOffset*0)						-- and an arm
	hand:setFillColor(1,0.87,0.77)															-- set hand colour
	arm:setStrokeColor(1,0,0) arm.strokeWidth = 13 											-- arm in coloured shirt.
	armGroup.y = yOffset * 39
	return { group = armGroup, hand = hand, arm = arm }
end 

--- ************************************************************************************************************************************************************************
--[[

		Date 		Version 	Notes
		---- 		------- 	-----
		2-Nov-14	0.1 		Initial version of file

--]]
--- ************************************************************************************************************************************************************************



