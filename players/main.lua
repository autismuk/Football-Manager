--[[

	Player Graphics Demo

--]]

local field = display.newRect(0,0,640,980)
field.anchorX,field.anchorY = 0,0
field:setFillColor(0,0.4,0)

function createFoot(yOffset)
	local foot = display.newGroup()
	local boot = display.newCircle(foot,0,0,18) boot.yScale = 0.45
	boot:setFillColor(0,0,0)
	display.newLine(foot,6,-3,6,3)
	display.newLine(foot,2,-3,2,3)
	display.newLine(foot,4,-3,4,3)
	foot.y = yOffset * 13
	return foot 
end 

function createArm(yOffset)
	local armGroup = display.newGroup()
	local hand = display.newCircle(armGroup,27+yOffset*4,yOffset*0,7)
	local arm = display.newLine(armGroup,0,0,22+yOffset*4,yOffset*0)
	hand:setFillColor(1,0.87,0.77)
	arm:setStrokeColor(1,0,0) arm.strokeWidth = 13
	armGroup.y = yOffset * 39
	return armGroup 
end 

function createPlayer()
	local player = {}
	player.group = display.newGroup()
	
	local vertices = { 0,-110, 27,-35, 105,-35, 43,16, 65,90, 0,45, -65,90, -43,15, -105,-35, -27,-35, }

	local paint = {
    	type = "gradient",
    	color1 = { 0, 1, 1 },
    	color2 = { 0, 0, 1 },
    	direction = "down"
	}

	player.marker = display.newPolygon(player.group,0,0,vertices)
	player.marker.stroke = paint player.marker.strokeWidth = 16
	player.marker:setFillColor(0,0,0,0)
	player.marker.isVisible = false 

	player.foot1 = createFoot(1) player.group:insert(player.foot1)						-- feet
	player.foot2 = createFoot(-1) player.group:insert(player.foot2)

	player.shadow = display.newCircle(player.group,0,0,35)
	player.shadow.anchorX,player.shadow.anchorY = 0.2,0.4
	player.shadow.rotation = -45 player.shadow.xScale = 1.5
	player.shadow:setFillColor(0,0,0,0.3)

	player.shorts = display.newCircle(player.group,0,0,30)								-- shorts
	player.shorts:setFillColor(1,1,1) player.shorts.xScale = 0.5

	player.shirt2 = display.newCircle(player.group,0,0,35)								-- shirt (bottom)
	player.shirt2:setFillColor(1,0,0) player.shirt2.xScale = 0.5

	player.shirt1 = display.newCircle(player.group,0,0,45) 								-- shirt (top)
	player.shirt1:setFillColor(1,0,0) player.shirt1.xScale = 0.5

	player.arm1 = createArm(1) player.group:insert(player.arm1)							-- arms
	player.arm2 = createArm(-1) player.group:insert(player.arm2)

	player.collar = display.newCircle(player.group,0,0,18) 								-- collar 
	player.collar.strokeWidth = 2 player.collar:setStrokeColor(0,0,0)

 	player.hair = display.newCircle(player.group,0,0,30)								-- hair
	player.hair:setFillColor(102/255,51/255,0)

	player.face = display.newCircle(player.group,18,0,20) 								-- face
	player.face.xScale = 0.5 player.face:setFillColor(1,0.87,0.77)

	player.faceCover = display.newRect(player.group,10,0,20,40)							-- face cover.
	player.faceCover:setFillColor(1,0.6,0)
	player.faceCover:setFillColor(102/255,51/255,0)


	return player
end 

function alignPlayer(player,n)

	player.collar.x = -n*1.3
	player.shirt1.x = player.collar.x
	player.shadow.x = player.collar.x
	player.shirt2.x = -n*0.6
	player.shorts.x = 0
	player.arm1.x = player.collar.x
	player.arm2.x = player.collar.x
	player.hair.x = -n*2.3
	player.face.x = 18+player.hair.x

	if n > 0 then 
		player.foot1.x = n * 0.2
		player.foot2.x = n * 1.1
		player.face.isVisible = true
		player.faceCover.isVisible = true
		player.faceCover.x = 18-n*3.3
	else 
		player.foot1.x = -n * 0.1
		player.foot2.x = n * 0.2
		player.face.isVisible = false
		player.faceCover.isVisible = false
	end
	player.footMin = math.min(player.foot1.x,player.foot2.x)
	player.footMax = math.max(player.foot1.x,player.foot2.x)
end 

function walkAnimation(player,percent) 
	local offset = (player.footMax-player.footMin) * percent / 100 
	player.foot1.x = player.footMin + offset
	player.foot2.x = player.footMax - offset
end 

function armAnimation(arm,percent1,percent2)
	arm.rotation = percent1*40/100-20
	arm.xScale = percent2*0.8/100+0.4
end 

local players = {}

function movePlayer(player,x,y)
	player.group.x = x
	player.group.y = y
end 

function setSkinTone(player,b)
	local r = b * 1.5
	local g = b * 1.15
	r = r / 255 g = g / 255 b = b / 255
	player.face:setFillColor(r,g,b)
end
-- R = B * 1.5
-- G = B * 1.15
-- 140 <= B <= 180

for e = -9,9 do 
	local n = e + 9
	local x = (n % 4) * 140 + 100
	local y = math.floor(n/4) * 140 + 100
	display.newLine(x-40,y,x+40,y) display.newLine(x,y-40,x,y+40)
	p1 = createPlayer()
	p1.group.xScale,p1.group.yScale = 1.2,1.2
	alignPlayer(p1,e*2)
	players[#players+1] = p1
	setSkinTone(p1,170)
	movePlayer(p1,x,y)
end

timer.performWithDelay(80,function() 
	local t = system.getTimer()
	for _,ref in ipairs(players) do 
		ref.group.rotation = math.floor(t/40+_*10) % 360
		ref.shadow.rotation = -45-ref.group.rotation
		local f1 = math.sin(math.rad(ref.group.rotation-45)) * 15
		alignPlayer(ref,f1)
		f1 = math.floor(t/3) % 200 f1 = math.abs(100-f1)
		walkAnimation(ref,f1)
		f1 = math.floor(t/5) % 200 f1 = math.abs(100-f1)
		local f2 = math.floor(t/27) % 200 f2 = math.abs(100-f2)
		armAnimation(ref.arm1,f1,f2)
		armAnimation(ref.arm2,f1,f2)
	end
end,-1)