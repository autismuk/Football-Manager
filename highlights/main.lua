--- ************************************************************************************************************************************************************************
---
---				Name : 		main.lua
---				Purpose :	Test bed for highlights.
---				Created:	26 Sep 2014
---				Updated:	26 Sep 2014
---				Author:		Paul Robson (paul@robsons.org.uk)
---				License:	Copyright Paul Robson (c) 2014+
---
--- ************************************************************************************************************************************************************************

display.setStatusBar(display.HiddenStatusBar)

require("highlights")

local highlightTest = {}

--- ************************************************************************************************************************************************************************
--													Code is translated from original in match.c
--- ************************************************************************************************************************************************************************

highlightTest.drawBackground = function(leftPostY,rightPostY)

	if highlightTest.isDrawn then return end 
	highlightTest.isDrawn = true

	local pitch = display.newRect(0,0,256,224)
	pitch.anchorX,pitch.anchorY = 0,0
	pitch:setFillColor(0,0.4,0)
	highlightTest.plot(71,88) highlightTest.draw(-16,-8) highlightTest.draw(-8,-16) highlightTest.draw(24,0) 

    highlightTest.plot(8,0) highlightTest.draw(175,175) highlightTest.draw(255-183,0) 
    highlightTest.plot(8,0) highlightTest.draw(127,0) highlightTest.draw(120,0) 
    highlightTest.plot(72,64) highlightTest.draw(0,24) highlightTest.draw(48,48) highlightTest.draw(0,-24) 
    highlightTest.plot(64,56) highlightTest.draw(24,0) highlightTest.draw(64,64) highlightTest.draw(-24,0) 
    highlightTest.plot(32,24) highlightTest.draw(96,0) highlightTest.draw(115,115) highlightTest.draw(-96,0) 
    highlightTest.plot(119,135) highlightTest.draw(-16,-8) highlightTest.draw(-8,-16) highlightTest.draw(24,0) 
    highlightTest.plot(102,126) highlightTest.draw(-48,-48) 
    highlightTest.plot(158,84) highlightTest.draw(2,0) 
    highlightTest.plot(158,85) highlightTest.draw(2,0) 
    highlightTest.plot(170,100)              

    print("TODO: Amend posts for final coordinate system")
    highlightTest.plot(0,leftPostY) highlightTest.draw(40,0)
    highlightTest.plot(0,rightPostY) highlightTest.draw(40,0)

    local d = -7.0
    local isFirst = true 
    local xc,yc = 170,100
    local xLast,yLast
    while d <= 98 do
    	local d2 = d - 90
    	local x = xc + 40*math.cos(2*3.14*d2/360)
        local y = yc + 40*math.sin(2*3.14*d2/360)
        if isFirst then 
        	highlightTest.plot(x,y)
        else 
        	highlightTest.draw(x-xLast,y-yLast)
        end 
        xLast,yLast = x,y
        isFirst = false
        d = d + 1.0
    end
end 

highlightTest.plot = function(x,y)
	highlightTest.currentX = x 
	highlightTest.currentY = 192-y
end 

highlightTest.draw = function(x,y)
	local newX = highlightTest.currentX + x
	local newY = highlightTest.currentY - y
	local line = display.newLine(highlightTest.currentX,highlightTest.currentY,newX,newY)
	highlightTest.currentX,highlightTest.currentY = newX,newY
end

--- ************************************************************************************************************************************************************************
--												Dummy rendering function which we don't actually need
--- ************************************************************************************************************************************************************************

highlightTest.render = function() end 

highlightTest.translate = function(x,y) 
	x = x * 8 + 16
	y = y * 8
	return x,y 
end 

--- ************************************************************************************************************************************************************************
--											Draw player with given reference code at a given position.
--- ************************************************************************************************************************************************************************

highlightTest.objects = {}

highlightTest.drawPlayer = function(code,x,y) 
	x,y = highlightTest.translate(x,y)
	if highlightTest.objects[code] == nil then
		local circle = display.newCircle(0,0,3)
		circle:setFillColor(0,1,1) circle:setStrokeColor(0,0,0) circle.strokeWidth = 1
		if code:sub(1,1) == "G" then circle:setFillColor(1,1,0) end
		if code:sub(1,1) == "A" then circle:setFillColor(1,0,0) end
		highlightTest.objects[code] = circle
	end 
	highlightTest.objects[code].x,highlightTest.objects[code].y = x,y
end 


highlightTest.drawBackground(64,111)

for i = 1,15 do 
	local x = math.random(1,22)
	local y = 23 - x
	print(x,y)
	highlightTest.drawPlayer("D"..i,x,y)
end

--- ************************************************************************************************************************************************************************
--[[

		Date 		Version 	Notes
		---- 		------- 	-----
		26-Sep-14	0.1 		Initial version of file

--]]
--- ************************************************************************************************************************************************************************
