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
require("highlights.members")

local r = display.newRect(0,0,960,640) r.anchorX,r.anchorY = 0,0 r:setFillColor(0,0.4,0)
display.newLine(0,40,960,40).strokeWidth = 4

p1 = Framework:new("highlights.objects.player",{ x = 0,y = 0,camera = "bottom" })
p2 = Framework:new("highlights.objects.player",{ x = -512,y = 512,camera = "bottom" })
p3 = Framework:new("highlights.objects.player",{ x = 512,y = 1024,direction = -90,camera = "bottom" })

--- ************************************************************************************************************************************************************************
--[[

		Date 		Version 	Notes
		---- 		------- 	-----
		1-Nov-14	0.1 		Initial version of file

--]]
--- ************************************************************************************************************************************************************************



