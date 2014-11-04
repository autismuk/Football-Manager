--- ************************************************************************************************************************************************************************
---
---				Name : 		manager.lua
---				Purpose :	Manages the players during the game, e.g. drives the highlights
---				Updated:	4 November 2014
---				Author:		Paul Robson (paul@robsons.org.uk)
---				License:	Copyright Paul Robson (c) 2014+
---
--- ************************************************************************************************************************************************************************

require("highlights.members")


local MapClass = Framework:createClass("gfx.mapper")

function MapClass:constructor() end function MapClass:destructor() end

function MapClass:map(x,y) 
	x = ((x or 0)*0.93 + 512) / 1024 * display.contentWidth  									-- calculate actual physical position
	y = (y or 0)/1024 * (display.contentHeight-140) + 140 
	return x,y 
end	

function MapClass:mapRotate(r)
	return r 
end 

local HighlightsManager = Framework:createClass("highlights.manager")

function HighlightsManager:constructor(info) 
	self.m_mapper = Framework:new("gfx.mapper") 												-- helper object maps logical -> physical
	self.m_goalWidth = 140 																		-- goal width in logical units.
	self.m_pitchGroup = display.newGroup()
	self:createBackground()

    self.m_attackers = {} self.m_defenders = {} self.m_objects = {} 							-- lists of attackers, defenders and objects

    local descr = { camera = "bottom", mapper = self.m_mapper, x = 0,y = 100, direction = 90 } 	-- set up, initially, for the ball start

    self.m_ball = Framework:new("highlights.objects.ball",descr)								-- create ball and goalkeeper
    descr.y = 20 self.m_goalKeeper = Framework:new("highlights.objects.goalkeeper",descr)

    self.m_objects[#self.m_objects+1] = self.m_goalKeeper 										-- add to object list.
    self.m_objects[#self.m_objects+1] = self.m_ball

    for i = 1,3 do 																				-- create three defenders.
       	descr.x = (i-2)*370-120+math.random()*240                                       		-- position.
        descr.y = 150+math.random()*350
        self.m_defenders[i] = Framework:new("highlights.objects.defender",descr)				-- create defender
        self.m_objects[#self.m_objects+1] = self.m_defenders[i] 								-- add to general objects list.
    end 

    for i = 1,3 do 																				-- create three attackers.
        descr.x = (i-2)*370-120+math.random()*240                                         		-- position.
        descr.y = 650+math.random()*350
        descr.direction = -90
        if i == 2 then  																		-- create either a centre forward or an attacker
        	self.m_attackers[i] = Framework:new("highlights.objects.centreforward",descr)
        else 
        	self.m_attackers[i] = Framework:new("highlights.objects.attacker",descr) 			-- add to general objects list.
        end 
        self.m_objects[#self.m_objects+1] = self.m_attackers[i]
    end 

    self.m_lastPlayerWithBall = nil self.m_playerWithBall = nil									-- ball not held by any player
    self:giveBallToPlayer(self.m_attackers[math.random(1,#self.m_attackers)]) 					-- give it to an attacker.
end

function HighlightsManager:giveBallToPlayer(player)
	if self.m_lastPlayerWithBall ~= nil then self.m_lastPlayerWithBall:setHasBall(false) end 	-- take it away from the last player
	if player ~= nil then player:setHasBall(true) end 											-- give it to the new player.
	self.m_lastPlayerWithBall = self.m_playerWithBall 											-- update current, last.
	self.m_playerWithBall = player  
end 

function HighlightsManager:destructor()
	self.m_mapper:delete() self.m_mapper = nil 													-- delete mapper
	for _,ref in ipairs(self.m_objects) do ref:delete() end 									-- delete all known objects
	self.m_objects = nil self.m_attackers = nil self.m_defenders = nil self.m_goalKeeper = nil 	-- nil out all references.
	self.m_ball = nil
	self.m_pitchGroup:removeSelf() self.m_pitchGroup = nil 										-- remove background
end 

function HighlightsManager:start()
	self:tag("enterFrame")
end 

function HighlightsManager:onEnterFrame(deltaTime)
	for _,ref in ipairs(self.m_objects) do 														-- tick all objects.
		ref:tick(deltaTime) 
	end 	
	if self.m_playerWithBall ~= nil then 														-- move the ball to the player.
		local x,y = self.m_playerWithBall:get() 												-- get position and direction
		local dir = math.rad(self.m_playerWithBall:getDirection())
		local offset = 50
		self.m_ball:move(x+offset*math.cos(dir),y+offset*math.sin(dir))
	end							
end 

function HighlightsManager:createBackground()
	local x1,x2,y x1,y = self.m_mapper:map(-512,0) x2,y = self.m_mapper:map(512,0) 				-- pitch lines
	local r = display.newRect(self.m_pitchGroup,0,0,960,640) r.anchorX,r.anchorY = 0,0 r:setFillColor(0,0.4,0)
	display.newLine(self.m_pitchGroup,x1,y,x2,y).strokeWidth = 4
	display.newLine(self.m_pitchGroup,x1,y,x1,640).strokeWidth = 4
	display.newLine(self.m_pitchGroup,x2,y,x2,640).strokeWidth = 4
	r = display.newImage(self.m_pitchGroup,"images/goal.png",0,0) 								-- get goal
	r.anchorY = 1 r.x,r.y = self.m_mapper:map(0,0)
	x1,y = self.m_mapper:map(-self.m_goalWidth,0)												-- work out how big it is
	x2,y = self.m_mapper:map(self.m_goalWidth,0)
	local scale = (x2-x1) / r.width r.xScale,r.yScale = scale,scale 							-- scale goal graphic accordingly.
	local offset = r.height * scale * display.contentHeight / display.contentWidth 				-- goal shadow
	local shadow = display.newPolygon(120,120,{ offset,0, 0,r.height*scale, r.width*scale,r.height*scale, r.width*scale+offset,0 })
	shadow:setFillColor(0,0,0,0.3)
	shadow.anchorY = 1 shadow.x,shadow.y = r.x + offset/2,r.y  r:toFront()
end

--- ************************************************************************************************************************************************************************
--[[

		Date 		Version 	Notes
		---- 		------- 	-----
		4-Nov-14	0.1 		Initial version of file

--]]
--- ************************************************************************************************************************************************************************



