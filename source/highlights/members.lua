--- ************************************************************************************************************************************************************************
---
---				Name : 		members.lua
---				Purpose :	Classes representing team members and the ball, all the moveable game objects.
---				Updated:	2 November 2014
---				Author:		Paul Robson (paul@robsons.org.uk)
---				License:	Copyright Paul Robson (c) 2014+
---
--- ************************************************************************************************************************************************************************

--- ************************************************************************************************************************************************************************
--//												Abstract Superclass for all displayable objects
--- ************************************************************************************************************************************************************************

local MoveableGameObject = Framework:createClass("highlights.objects.base")

function MoveableGameObject:constructor(info)
	self.m_distanceToTravel = 0 																-- number of logical units to travel.
	self.m_direction = 90 																		-- current direction.
	self.m_displayObject = self:createGameObject(info)											-- create a game object which implements move(),rotate()
																								-- ** NOT A CORONA DISPLAY OBJECT **
	self:move(info.x,info.y) 																	-- move game object to specified place.
	self:rotate(info.direction) 																-- rotate to direction.
	-- TODO: tick handler (see manager.coffee)
	-- TODO: move to Method (see manager.coffee)
end 		

function MoveableGameObject:destructor()
	self.m_displayObject = nil 																	-- remove reference to display object
end 

function MoveableGameObject:createGameObject(info)												-- this *must* be sub classed.
	error("MoveableGameObject is an abstract class")
end 

function MoveableGameObject:getSpeed()
	return 0.4 
end 

function MoveableGameObject:isRethinkRequired()
	return false 
end 

function MoveableGameObject:rethink() 
end 

function MoveableGameObject:move(x,y)
	-- TODO: Map logical to physical.
	self.m_displayObject:move(x or 100,y or 100)
end 

function MoveableGameObject:rotate(angle)
	self.m_direction = angle or self.m_direction 												-- default is original value
	self.m_displayObject:rotate(self.m_direction)												-- update direction.
end 

--- ************************************************************************************************************************************************************************
--- ************************************************************************************************************************************************************************

local Player,SuperClass = Framework:createClass("highlights.objects.player","highlights.objects.base")

local Goalkeeper,SuperClass = Framework:createClass("highlights.objects.goalkeeper","highlights.objects.player")

local Attacker,SuperClass = Framework:createClass("highlights.objects.attacker","highlights.objects.player")

local CentreForward,SuperClass = Framework:createClass("highlights.objects.centreforward","highlights.objects.attacker")

local Defender,SuperClass = Framework:createClass("highlights.objects.defender","highlights.objects.player")

local Ball,SuperClass = Framework:createClass("highlights.objects.ball","highlights.objects.base")

--[[

	Create some logical players (Player has default colours) by implementing createGameObject() method.
	Map logical to physical
	tickHandler, moveTo handler code.
	shirt/shorts/skin code on initialisation.

--]]

--- ************************************************************************************************************************************************************************
--[[

		Date 		Version 	Notes
		---- 		------- 	-----
		2-Nov-14	0.1 		Initial version of file

--]]
--- ************************************************************************************************************************************************************************
