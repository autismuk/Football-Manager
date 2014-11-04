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

require("highlights.manager")
local demo = Framework:new("highlights.manager")

demo:start({})
--demo:delete() Framework:dump()


--- ************************************************************************************************************************************************************************
--[[

		Date 		Version 	Notes
		---- 		------- 	-----
		1-Nov-14	0.1 		Initial version of file

--]]
--- ************************************************************************************************************************************************************************



--[[

	TODO: player picks up the ball.
	TODO: fix up shirt/short/hair/skin colour properly.

--]]

