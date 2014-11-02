
class DummyHighlight
    ###
        Dummy Highlights - implements the Highlight interface but doesn't do anything :)
    ###
    start: ->
    refreshScore: ->
    isComplete: -> true
    tick: ->
    isGoal: -> Math.random() < 0.4

class Highlight
    ###
        Class reponsible for producing, animating, evaluating highlights
    ###
    constructor: (@homeTeam,@awayTeam,@homeScore,@awayScore,@homeAttacking) ->
        @goals = @plays = 0
        @goalWidth = 140
        @pitch = new Pitch(@homeTeam,@awayTeam,@homeScore,@awayScore,@goalWidth,not @homeAttacking)  # Create the pitch
        @start()

    start: ->
        @pitch.redraw()                                                                 # reset the pitch
        @ball = new Ball(0,900,3100,@,@goalWidth)                                       # create a ball object
        @goalie = new Goalkeeper(0,20,3101,@,@goalWidth)                                # create a goalkeeper
        @attackers = []                                                                 # attackers
        @defenders = []                                                                 # defenders
        @objectList = [@ball,@goalie]                                                   # List of player objects
        for i in [1..3]                                                                 # create 3 attackers.
            x = (i-2)*370-120+Math.random()*240                                         # position.
            y = 650+Math.random()*350
            col = @homeTeam.colour()                                                    # shirt colour.
            unless @homeAttacking
                col = @awayTeam.colour()
                col = "orange" if @homeTeam.colour() == @awayTeam.colour()              # colour clash, play in orange.
            if i == 2                                                                   # create strikesrs
                player = new CentreForward(x,y,3110+i,@,col,@goalWidth)
            else
                player = new Attacker(x,y,3110+i,@,col,@goalWidth)
            @attackers.push(player)
            @objectList.push(player)
        for i in [1..3]                                                                 # create 3 defenders
            x = (i-2)*370-120+Math.random()*240                                         # position.
            y = 150+Math.random()*350
            col = @homeTeam.colour()                                                    # shirt colour.
            if @homeAttacking
                col = @awayTeam.colour()
                col = "orange" if @homeTeam.colour() == @awayTeam.colour()              # colour clash, play in orange.
            player = new Defender(x,y,3120+i,@,col)
            @defenders.push(player)
            @objectList.push(player)
        @lastPlayerWithBall = null                                                      # stops stickin
        @playerWithBall = @attackers[Math.floor(Math.random()*@attackers.length)]       # give one attacker the ball.
        @ball.move(@playerWithBall.x,@playerWithBall.y)                                 # put it somewhere near them.
        return @

    refreshScore: (h,a) -> @pitch.refreshScore(h,a)

    pass: ->                                                                            # pass to another team member.
        while true
            target = @attackers[Math.floor(Math.random()*@attackers.length)]            # pick random target
            target = @playerWithBall if target.y > @playerWithBall.y and Math.random() < 0.1              # abandon if too far back.
            break if target != @playerWithBall
        @lastPlayerWithBall = @playerWithBall                                           # Remember who had it.
        @playerWithBall = null                                                          # No longer have the ball.
        @ball.moveTo(target.x,target.y)                                                 # pass it.
        ob.toTravel = 0 for ob in @attackers                                            # stop attackers while passing.
        $G("play","kick")

    tick: (elapsed) ->
        for ob in @objectList                                                           # tick and redraw all objects
            if @playerWithBall == null and ob instanceof Player                         # check collision with player
                if ob != @lastPlayerWithBall
                    if Math.abs(ob.x-@ball.x) < 30 and Math.abs(ob.y-@ball.y) < 30      # made a collision.
                        @playerWithBall = ob                                            # give that player the ball
                        @ball.toTravel = 0                                              # ball no longer moving.
                        @playerWithBall.rethink()                                       # and decide what next.

        if @playerWithBall != null                                                      # Does a player have the ball.
            @ball.propel(0,0)                                                           # if so, it isn't moving.
            radians = @playerWithBall.orientation()/360*2*3.14                          # angle player is facing
            x = @playerWithBall.x+54*Math.cos(radians)                                  # put it at the players feet.
            y = @playerWithBall.y-54*Math.sin(radians)
            @ball.move(x,y)
        for ob in @objectList                                                           # tick and redraw all objects
            ob.tick(elapsed)
            @pitch.draw(ob)

    isComplete: -> @ball.dead or @playerWithBall == @goalie
    isGoal: -> @ball.goal

class BaseGameObject
    ###
        Base Class for objects on the screen
    ###
    constructor: (@x,@y,@ID) ->
    image: -> "ball"                                                                    # image name
    orientation: -> 90                                                                  # angle facing
    move: (@x,@y) ->                                                                    # set position.

class MoveableGameObject extends BaseGameObject
    ###
        Moving base objects functionality
    ###
    constructor: (@x,@y,@ID) ->
        super(@x,@y,@ID)                                                                # call superclass.
        @dir = 90                                                                       # direction facing
        @toTravel = 0                                                                   # distance to travel.
    orientation: -> @dir                                                                # return current direction
    speed: -> 0.4                                                                       # object speed
    needRethink: -> false                                                               # check new decision required.
    propel: (@toTravel,@dir) ->                                                         # Set object distance and direction.
    rethink: ->                                                                         # what to do next.
    tick: (elapsed) ->
        if @toTravel <= 0 or @needRethink()                                             # time for reconsideration ?
            @rethink()
            @toTravel = 0 if @needRethink()
        return if @toTravel <= 0                                                        # not moving.
        dist = Math.min(elapsed*@speed(),@toTravel)                                     # how far to go ?
        @toTravel = @toTravel - dist                                                    # remove from distance to travel.
        radians = @dir / 360.0 * 2 * 3.14                                               # convert direction to radians
        @move(@x+Math.cos(radians)*dist,@y-Math.sin(radians)*dist)                      # Move it
    moveTo: (x,y) ->                                                                    # Move to a specific position.
        return if @x == x and @y == y                                                   # already there
        dir = Math.atan2(@y-y,x-@x)                                                     # work out the direction.
        dir = Math.round(dir / (2*3.14) * 360 + 360) % 360                              # convert to angle.
        dist = Math.sqrt((@x-x)*(@x-x)+(@y-y)*(@y-y))                                   # work out the distance
        @propel(dist,dir)                                                               # and set it moving.

class Player extends MoveableGameObject
    ###
        Base object for Players
    ###
    constructor: (@x,@y,@ID,@state,@shirt) ->
        super(@x,@y,@ID)
    speed: -> 0.15
    image: -> @shirt
    isAttacker: -> false

class Goalkeeper extends Player
    constructor: (@x,@y,@ID,@state,@goalWidth) ->
        super(@x,@y,@ID,@state,"green")
        @dir = 270
    orientation: -> 270
    rethink: ->
        x = @state.ball.x
        if Math.abs(x) > @goalWidth*3/4
            x = if x < 0 then -@goalWidth*3/4 else @goalWidth*3/4
        @moveTo(x,@y)
        if @ == @state.playerWithBall and Math.random() < 0.5 and @state.ball.y >= 0
            @state.lastPlayerWithBall = @
            @state.playerWithBall = null
            @state.ball.propel(20480,Math.random()*60+240)
            $G("play","kick")

class Attacker extends Player
    ###
        Attacker object
    ###
    constructor: (@x,@y,@ID,@state,@shirt,@goalWidth) ->
        super(@x,@y,@ID,@state,@shirt)
        @dir = 90
    isAttacker: -> true

    rethink: ->
        if @state.playerWithBall == @                                                   # if player has the ball.
            chance = (Math.abs(@x)+@y)/80-2.5                                           # worst chance about 1 in 15
            chance = 20 if Math.abs(@x) > 400                                           # unlikely if out on the wing.
            chance = 1.3 if Math.abs(@x) < @goalWidth*1.1 and @y < 300                  # really likely if shooting position.
            chance = Math.max(1,chance)                                                 # tops out at 1 in 1
            if Math.random() < 1/chance                                                 # shooting ?
                @state.lastPlayerWithBall = @
                @state.playerWithBall = null
                w = @goalWidth*1.3                                                      # aiming zone.
                @state.ball.moveTo(Math.random()*w*2-w,-100)                            # shoot
                $G("play","kick")
            else                                                                        # keeping the ball
                if Math.random() < 0.25 or @y < 140                                     # chance of passing
                    @state.pass()
                else
                    @propel(120,Math.random()*90+45)                                    # dribbling.

        if @state.playerWithBall != null and @state.playerWithBall != @                 # ball is held by someone else.
            @advance()

    needRethink: -> Math.abs(@x) > 490 or @y < 100

    advance: -> @propel(120,Math.random()*90+45)                                        # move forward

class CentreForward extends Attacker
    advance: ->
        x = Math.random()*100
        x = -x if @state.ball.x > 0
        @moveTo(x,100+Math.random()*200)
    speed: -> 0.2                                                                       # centre forward is fast.

class Defender extends Player
    ###
        Defender object
    ###
    constructor: (@x,@y,@ID,@state,@shirt) ->
        super(@x,@y,@ID,@state,@shirt)
        @dir = 270

    speed: -> 0.10                                                                      # defenders are slower

    tick: (elapsed) ->
        super(elapsed)
        if @state.playerWithBall == @                                                   # if got the ball then kick it clear
            @state.lastPlayerWithBall = @
            @state.playerWithBall = null
            clearance = if @x < 0 then 180 else 270                                     # kick it clear.
            clearance = Math.random()*90+clearance
            clearance = Math.random()*180+180 if Math.random()<0.1
            @state.ball.propel(20480,clearance)
            $G("play","kick")

    rethink: ->
        pick = @state.attackers[Math.floor(Math.random()*@state.attackers.length)]      # pick an attacker.
        return if Math.abs(pick.x - @x) > 200                                           # not chaseable
        @moveTo(pick.x,pick.y-120)                                                      # set to chase them.
        @toTravel = Math.max(@toTravel,30)                                              # but only so far.

class Ball extends MoveableGameObject
    ###
        Ball object
    ###
    constructor: (@x,@y,@ID,@state,@goalWidth) ->
        super(@x,@y,@ID)
        @dead = false                                                                   # Ball is dead flag
        @goal = false                                                                   # Ball in goal flag
        @firstCheck = false                                                             # Check first time crossed line.
                                                                                        # 0.54 changed ball propel so limited.
    speed: -> 0.9                                                                       # Ball speed
    image: -> "ball"                                                                    # Ball graphic
    orientation: -> Math.round((@x+@y)*3) % 360                                         # Ball is animated while moving not on distance
    needRethink: ->                                                                     # Ball has no brains, it just stops out of play.
        return false if @dead                                                           # ball already dead
        @dead = false                                                                   # Set Ball is dead flag.
        @dead = true if Math.abs(@x) > 550                                              # off left or right
        @dead = true if @y < -200 or @y > 1024 or (@goal and @y < -120)                 # off top/bottom, or in goal.
        @dead = true if @state.playerWithBall == null and @toTravel <= 0                # ball come to a stop.
        if (not @firstCheck) and @y <= 0                                                # Ball crossed the goal line ?
            @firstCheck = true                                                          # mark so don't check it again.
            @goal = true if Math.abs(@x) < @goalWidth                                   # in the goal, if so scored ?
            $G("play","goal") if @goal

        if @goal and Math.abs(@x) >= @goalWidth                                         # goal scored, stop it coming out of the net.
            @x = if @x < 0 then -@goalWidth else @goalWidth
        @toTravel = 0 if @dead                                                          # stop ball if dead.
        return false                                                                    # don't rethink.

class Pitch
    ###
        Encapsulate pitch rendering
    ###
    constructor: (@homeTeam,@awayTeam,@homeGoal,@awayGoal,@goalWidth,@flip) ->

    draw: (gameobject) ->
        orn = gameobject.orientation()                                                  # orientation
        if @flip                                                                        # vertically flipped
            orn = 360-orn
            orn = (orn+360)%360
        $G(gameobject.ID).move(@xc(gameobject.x),@yc(gameobject.y)).anchor(0,0).image(gameobject.image(),orn)

    redraw: ->
        $G("reset")
        $G("background","2C6700")
        @vline(1000,-512,0,1024)
        @vline(1001,512,0,1024)
        @vline(1004,-290,0,512)
        @vline(1005,290,0,512)
        $G(1002).borderWidth(0).width(@xc(512)-@xc(-512)).height(32).anchor(0,0).move(2048,@yc(0)).fillColour("white")
        $G(1006).borderWidth(0).width(@xc(290)-@xc(-290)).height(32).anchor(0,0).move(2048,@yc(512)).fillColour("white")
        $G(1007).borderWidth(0).width(64).height(64).move(@xc(0),@yc(320)).fillColour("white").rounded(64)
        $G(3000).anchor(0,-1).image("semicircle","v").move(2048,@yc(512))
        $G(3001).anchor(0,if @flip then -1 else 1).image("goal",if @flip then "v" else "n").move(2048,@yc(0)).depth(99)
        if @homeTeam != null
            $G(1003).borderWidth(16).anchor(0,0).move(768,250).fillColour("black").width(1224).height(300).borderColour("white")
            @refreshScore(@homeGoal,@awayGoal)
        $G(3002).anchor(1,1).image("flag","n").move(@xc(-512),@yc(0))
        $G(3003).anchor(-1,1).image("flag","h").move(@xc(512),@yc(0))
        #console.log @xc(@goalWidth/2)-@xc(-@goalWidth/2)

    refreshScore: (h,a) ->
        $G(2000).anchor(0,0).move(768,250).text(@homeTeam.shortName()+" "+h+"-"+a+" "+@awayTeam.shortName()).fontSize(80).colour("white").depth(3)

    xc: (x) ->
        x*3.7+2048
    yc: (y) ->
        y = y*2.5+512
        unless @flip then y else 3071-y
    vline: (id,x,y1,y2) ->
        x = @xc(x)
        y1 = @yc(y1)
        y2 = @yc(y2)
        if y1 > y2
            a = y1
            y1 = y2
            y2 = a
        $G(id).borderWidth(0).width(32).anchor(0,-1).height(y2-y1).move(x,y1).fillColour("white")

class TeamData
    ###
        Class encapsulating team data.
    ###
    teams: ->
        return ["Manchester Utd0MANU","Manchester City1MANC","Arsenal0ARNL","Tottenham2TOTT",
                "Chelsea1CHEL","Newcastle Utd3NEWC","Everton4EVTN","Liverpool0LIVP",
                "Sunderland0SUND","W.B.A.3WBA ","Aston Villa5VILL","Q.P.R.2QPR ",
                "Fulham2FULM","Swansea City2SWAN","Norwich City6NORW","Stoke City0STOC",
                "Bolton Wanderers2BOLT","Blackburn Rovers4BBRN","Wigan Athletic4WIGN","Wolves7WOLV"]
    colours: ->
        return ["red","cyan","white","black","blue","magenta","yellow","orange"]

    leagueName: -> "Premier League"

