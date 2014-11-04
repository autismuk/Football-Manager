--- ************************************************************************************************************************************************************************
---
---				Name : 		ball.lua
---				Purpose :	Ball Graphic Object
---				Updated:	4 November 2014
---				Author:		Paul Robson (paul@robsons.org.uk)
---				License:	Copyright Paul Robson (c) 2014+
---
--- ************************************************************************************************************************************************************************

local BallGraphic = Framework:createClass("gfx.ball")

function BallGraphic:constructor(info)
	self.m_ballShadow = display.newCircle(0,0,12)
	self.m_ball = display.newImage("images/ball.png")
	self.m_ball.width,self.m_ball.height = self.m_ballShadow.width,self.m_ballShadow.height
	self.m_ballShadow:setFillColor(0,0,0,0.3)
end 

function BallGraphic:destructor()
	salf.m_ball:removeSelf()
end 

function BallGraphic:move(x,y)
	self.m_ballShadow.x,self.m_ballShadow.y = x+5,y-5
	self.m_ball.x,self.m_ball.y = x,y
	self.m_ball.rotation = x*34-y*37
end 

function BallGraphic:setRotation(rot)
end

--- ************************************************************************************************************************************************************************
--[[

		Date 		Version 	Notes
		---- 		------- 	-----
		4-Nov-14	0.1 		Initial version of file

--]]
--- ************************************************************************************************************************************************************************
