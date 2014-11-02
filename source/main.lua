--- ************************************************************************************************************************************************************************
---
---				Name : 		main.lua
---				Purpose :	Top level code "Football Manager"
---				Updated:	1 November 2014
---				Author:		Paul Robson (paul@robsons.org.uk)
---				License:	Copyright Paul Robson (c) 2014+
---
--- ************************************************************************************************************************************************************************

ApplicationDescription = { 																		-- application description.
	appName = 		"Football Manager",
	version = 		"0.1",
	developers = 	{ "Paul Robson" },
	email = 		"paul@robsons.org.uk",
	fqdn = 			"uk.org.robsons.footballmanager", 											-- must be unique for each application.
    admobIDs = 		{ 																			-- admob Identifiers.
    					ios = "ca-app-pub-8354094658055499/7057436417", 						-- TODO: Must be interstitial ones !
						android = "ca-app-pub-8354094658055499/1210562410"
					},
	advertType = 	"interstitial",
	showDebug = 	true 																		-- show debug info and adverts.
}

display.setStatusBar(display.HiddenStatusBar)													-- hide status bar.
require("strict")																				-- install strict.lua to track globals etc.
require("framework.framework")																	-- framework.

--require("utils.sound")																			-- sfx singleton
--require("utils.simplescene")																	-- simple scenes.
--local fm = require("utils.fontmanager")															-- bitmap font manager
--require("utils.stubscene")																		-- stub scenes for development.

--- ************************************************************************************************************************************************************************
--																				Start Up
--- ************************************************************************************************************************************************************************

require("gfx.player")
local r = display.newRect(0,0,640,960) r.anchorX,r.anchorY = 0,0 r:setFillColor(0,0.4,0)
local players = {}
for i = 0,10 do
	local p1 = Framework:new("gfx.player",{ x = i % 3 * 130+100,y = math.floor(i/3)*130+100, marker = false , skin = 80, shirt = "#0000FF", shorts = "#FFFFFF", hair = "#FFFF00"})
	p1:setCamera("bottom")
	players[#players+1] = p1
end 

timer.performWithDelay(50,function()
	local t = math.floor(system.getTimer() / 20)
	for _,p1 in ipairs(players) do p1:setRotation(t % 360) end
	end,
-1)
--- ************************************************************************************************************************************************************************
--[[

		Date 		Version 	Notes
		---- 		------- 	-----
		1-Nov-14	0.1 		Initial version of file

--]]
--- ************************************************************************************************************************************************************************



