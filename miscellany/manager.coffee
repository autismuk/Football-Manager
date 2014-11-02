# *************************************************************************************************************
#
#       File:       manager.coffee
#
#       Purpose:    Football Manager Application Class
#
#       Author:     Paul Robson (paul@robsons.org.uk)
#
# *************************************************************************************************************

class ManagerApplicationFactory extends ApplicationFactory                              # Factory method.
    create: -> return new ManagerApplication()

$(document).ready -> new ManagerApplicationFactory()                                    # start up.

class ManagerApplication extends Application

    createGameObject: (parent) ->  new ManagerQuestionAppGameWrapper(parent)            # Use a subclassed wrapper
    createQuestionGameObject: (parent) -> new ManagerGameObject(parent)                 # create the object.

    appName: -> "Football Manager"
    appVersion: -> "1.0"

class ManagerQuestionAppGameWrapper extends QuestionApplicationGameWrapper
    ###
        Subclassed wrapper. Required because we need however many questions a round for training x max number of teams -1.
    ###
    getQuestions: -> new QuestionSet(undefined,undefined,4*12*2)                        # Max questions available 4/round,11 teams, home&away
    darken: -> true

class MQASystem extends QASystem
    ###
        Decorator for questions
    ###
    decorate: -> (id) -> $G(id).fontSize(128)

class ManagerGameObject extends BaseQAGameObject
    ###
        Encapsulation of game state
    ###
    constructor: (@parent) ->
        @fsm = new FSM(@)                                                               # create FSM.
        @fsm.add(new State("Start","Continue->Fixture"))
        @fsm.add(new FixtureState())
        @fsm.add(new HighlightState())
        @fsm.add(new DelayState("Pause",3000,"Highlight"))
        @fsm.add(new DelayState("Endgame",3000,"Results"))
        @fsm.add(new ResultsState())
        @fsm.add(new LeagueState())
        @fsm.add(new YieldState("Continue->Fixture"))
        @completed = false                                                              # not over yet
        @config = new ConfigureState()                                                  # create configuration state
        @testHighlights = false
        console.log "Testing Highlights ...." if @testHighlights

    configureState: -> @config

    isAlive: -> not @completed

    build: ->
        @fsm.Continue()

    tick: (@elapsed,@elapsedScaled,@clock)->
        @fsm.Tick()

    roundSize: -> 
        size = 4                                                                        # Games per round
        size = 0 if $G("get","testing") != 0                                            # Skip if testing.

        return size

    createQASystem: (question,type,notifier,position) ->
        new MQASystem(question,type,notifier,position,true)

    drawQuestionBackground: (status) ->
        ###
            Called to construct display, initialise for this turn etc.
        ###
        new Pitch(null,null,0,0,320,true).redraw()
        $G(2001).anchor(0,-1).text(Translate.instance().translate(31)).colour("yellow").move(2048,64).fontSize(192).depth(101)
        return [0,0,4096,512]

class ConfigureState extends ConfigState
    ###
        Set up the game state
    ###
    constructor: ->
        super("Round",false)                                                            # Going to round required by AppQuest.coffee
        tf = Translate.instance()
        @tSource = new TeamData()                                                       # create list of team names
        @tlist = (s[..-6] for s in @tSource.teams().sort())
        clist = []                                                                      # create list of season lengths
        clist.push((i*4)+" "+tf.translate(33)) for i in [1..3]
        @add(new RotatorButton(@tlist),"team",0,0)                                      # construct the configuration dialog.
        @add(new RotatorButton(clist),"matches",0,1)
        @add(new RotatorButton(["1 "+tf.translate(32),"2 "+tf.translate(32)]),"fix",0,2)
        @add(new RotatorButton([tf.translate(27)+" : "+tf.translate(23),
            tf.translate(27)+" : "+tf.translate(24),tf.translate(27)+" : "+tf.translate(25)]),"skill",0,3)
        @add(new ActionButton(),"ok",0,4)
    onExit: ->
        super()
        cfg = @get()                                                                    # get config info and create league
        @parent.league = new League(@tSource,@tlist[cfg.team],cfg.matches*4+4,cfg.fix+1)

class FixtureState extends DelayState
    ###
        State where the next game is displayed
    ###
    constructor: ->
        super("Fixture",3000,"Highlight")                                               # Delay for 2s then goto highlights.

    onEntry: ->
        super()
        l = @parent.league
        gameStatus = [l.team(0),l.team(Math.abs(l.nextFixture())),0,0,0,0]              # Get next fixture data. Work as if home game.

        stat = @parent.parent.quizStatus                                                # Get the quiz status
        if stat.roundQuestions > 0                                                      # if some questions.
            gameStatus[2] = 4*stat.roundCorrect/stat.roundQuestions                     # range from 1..4
        else                                                                            # testing 4
            gameStatus[2] = 4
        gameStatus[2] += 1-@parent.config.get().skill                                   # adjust for skill level (0=easy->2=hard)
        gameStatus[2] += 0.4 if l.nextFixture() > 0                                     # extra for playing at home.
        gameStatus[2]-- if Math.random() < 0.33                                         # poor game randomly
        gameStatus[3] = if Math.random() < 0.33 then 3 else 2                           # 2 or 3 shots from the opposition.
        gameStatus[2] = Math.max(1,Math.round(gameStatus[2]))                           # convert to integer - at least one shot.

        gameStatus = [gameStatus[1],gameStatus[0],                                      # swap names, tries round if an away game.
                                    gameStatus[3],gameStatus[2],0,0] if l.nextFixture() < 0
        $G("reset")                                                                     # display the next fixture
        $G("background","black")

        t1 = gameStatus[0].name()
        t2 = gameStatus[1].name()
        $G(2000).fontSize(176).anchor(0,0).move(2048,1536).text("vs").colour("yellow")
        $G(2001).fontSize(176).anchor(0,0).text(t1).move(2048,1036).colour("cyan")
        $G(2002).fontSize(176).anchor(0,0).text(t2).move(2048,2036).colour("cyan")
        $G(2003).fontSize(176).anchor(0,0).move(2048,236).text(Translate.instance().translate(34)+" "+l.weekNumber()).colour("white")
        @parent.currentGame = gameStatus                                                # store game status in parent object

class HighlightState extends State
    constructor: ->
        super("Highlight","Tick-> Continue->Endgame Again->Pause")
        @countHighlights = 0                                                            # testing.
        @countGoals = 0
    onEntry: ->
        gameInfo = @parent.currentGame                                                  # retrieve current game information
        @homeAttack = Math.floor(Math.random()*(gameInfo[2]+gameInfo[3])) < gameInfo[2] # is it a home attack ?
        @highlight = new Highlight(gameInfo[0],gameInfo[1],                             # create the highlight (DummyHighlight to fake it)
                                            gameInfo[4],gameInfo[5],@homeAttack)
        reduce = if @homeAttack then 2 else 3                                           # decrement the appropriate attack count
        gameInfo[reduce]-- unless @parent.testHighlights

    onTick: ->
        return if @highlight == undefined
        @highlight.tick(@parent.elapsed)                                                # tick the highlights.
        if @highlight.isComplete()                                                      # highlights finished ?
            @parent.currentGame[(if @homeAttack then 4 else 5)]++ if @highlight.isGoal()# bump goal count if scored.
            @highlight.refreshScore(@parent.currentGame[4],@parent.currentGame[5])      # refresh scoreboard.
            if @parent.currentGame[2]+@parent.currentGame[3] > 0                        # more play
                @fsm.Again()                                                            # another set of highlights
            else
                @fsm.Continue()                                                         # go onto results.
            if @parent.testHighlights
                @countHighlights++
                @countGoals++ if @highlight.isGoal()
                console.log @countGoals,@countHighlights,Math.round(100*@countGoals/@countHighlights)+"%" if @countHighlights % 10==0

class ClickExitState extends State
    constructor: (name,events) ->
        super(name,"Tick-> "+events)
    onEntry: ->
        $G("reset")
        $G("background","#000")
        $G(2000).move(2048,32).anchor(0,-1).colour("yellow").text(@parent.league.leagueName())
        $G(1000).move(0,0).width(4096).height(3072).clickable().opacity(0).depth(100)
    onTick: ->
        end = false
        while (q = $G("dequeue")) != null
            end = true if q[0] == "C" and q[1] = 1000
        @exit() if end

class LeagueState extends ClickExitState
    ###
        Display the league table screen
    ###
    constructor: ->
        super("League","Continue->Yield")

    exit: ->
        @parent.league.incFixture()                                                     # go to next fixture
        @parent.completed = true if @parent.league.nextFixture() == null                # done if no more games to play.
        @fsm.Continue()                                                                 # and yield.

    onEntry: ->
        super()
        id = 2100
        for i in [0...@parent.league.teamCount()]                                       # work through the teams
            team = @parent.league.team(i)                                               # get team.
            y = 1536-@parent.league.teamCount()*96+192*(team.position())
            $G(id++).text(team.name()).anchor(-1,0).move(256,y).fontSize(96).colour("white")
            @writeList(id,y,team.getResults(),"cyan")
            id += 10
        @writeList(id,1536-@parent.league.teamCount()*96,["P","W","D","L","F","A","Pts"],"green")

    writeList: (id,y,res,colour) ->
        for i in [0...res.length]
            $G(id++).text(res[i]).anchor(0,0).move(2048+i*300,y).fontSize(96).colour(colour)


class ResultsState extends ClickExitState
    ###
        Display the results screen
    ###
    constructor: ->
        super("Results","Continue->League")

    exit: -> @fsm.Continue()

    onEntry: ->
        super()
        game = @parent.currentGame
        results = [ [game[0],game[1],game[4],game[5] ]]                                 # this result.
        teamsToDo = []                                                                  # create list of all the unused teams.
        for i in [0...@parent.league.teamCount()]
            teamsToDo.push(i) if @parent.league.team(i) != game[0] and @parent.league.team(i) != game[1]
        for i in [0...teamsToDo.length]                                                 # mix them up.
            n = Math.floor(Math.random()*teamsToDo.length)
            c = teamsToDo[i]
            teamsToDo[i] = teamsToDo[n]
            teamsToDo[n] = c
        for i in [0...teamsToDo.length/2]                                               # Now create the results
            res = [ @parent.league.team(teamsToDo[i*2]),@parent.league.team(teamsToDo[i*2+1]),3,2 ]
            pdiff = @parent.league.team(teamsToDo[i*2]).points()-@parent.league.team(teamsToDo[i*2]).points()
            pdiff = 2 * pdiff / @parent.league.weekNumber()                             # Points difference per week x 2
            if pdiff > 0                                                                # If +ve add to home team
                res[2] = res[2] + pdiff
            else                                                                        # If -ve add negative to away team.
                res[3] = res[3] - pdiff
            res[2] = Math.round(res[2]*Math.random())                                   # Work out score
            res[3] = Math.round(res[3]*Math.random())
            results.push(res)                                                           # push onto results list

        results.sort((a,b) => (if a[0].name() < b[0].name() then -1 else 1))            # Sort by home team name.
        id = 2100                                                                       # Now display them.
        for i in [0...results.length]                                                   # Work through all the results.
            res = results[i]                                                            # Result information.
            y = 1536-results.length * 128+i*256                                         # vertical position
            $G(id++).move(256,y).text(res[0].name()).anchor(-1,0).fontSize(96).colour("cyan")
            $G(id++).text(res[1].name()).anchor(1,0).move(4096-256,y).fontSize(96).colour("cyan")
            $G(id++).move(1848,y).text(res[2]).anchor(0,0).fontSize(96).colour("white")
            $G(id++).move(2248,y).text(res[3]).anchor(0,0).fontSize(96).colour("white")
            $G(id++).move(2048,y).text("-").anchor(0,0).fontSize(96).colour("white")
        for r in results                                                                # now update the team stuff.
            r[0].addScore(r[2],r[3])
            r[1].addScore(r[3],r[2])
        @parent.league.calculateStandings()                                             # and calculate the team positions.

class League
    ###
        Encapsulates the league
    ###
    constructor: (teamData,teamName,teamCount,fixturesAgainstEach) ->
        @teamList = []                                                                  # List of teams #0 is player.
        teamCheck = {}                                                                  # Hash checking for duplicate teams.
        for i in teamData.teams()                                                       # Find the team by name and put them in slot#0
            if i[0...teamName.length] == teamName                                       # found it ?
                @teamList.push(new Team(i,teamData))                                    # add to list
                teamCheck[i] = true                                                     # mark as used.
        while @teamList.length < teamCount                                              # Fill up with randomly picked teams.
            t = teamData.teams()[Math.floor(Math.random()*teamData.teams().length)]     # Pick a random team
            @teamList.push(new Team(t,teamData)) unless t of teamCheck                  # add if not already present
            teamCheck[t] = true                                                         # mark as used, if above fails already present.
        @fixtures = []                                                                  # create fixture list.
        for i in [1..teamCount-1]                                                       # Go through teams.
            if fixturesAgainstEach == 1                                                 # 1 set of fixtures
                @fixtures.push(if i % 2 == 0 then i else -i)                            # alternate home and away matches.
            else                                                                        # 2 games against each team.
                @fixtures.push(i)                                                       # add home and awat
                @fixtures.push(-i)
        for i in [0...@fixtures.length]                                                 # mix up the fixtures
            n = Math.floor(Math.random()*@fixtures.length)                              # pick team to swap with
            c = @fixtures[i]                                                            # swap the fixtures round
            @fixtures[i] = @fixtures[n]                                                 # effectively randomises results.
            @fixtures[n] = c
        @calculateStandings()                                                           # Work out standings (position in table)
        @fixtureNumber = 0                                                              # Current fixture number.
        @teamData = teamData                                                            # Save team data source.

    calculateStandings: ->
        ###
            Recalculate the league positions
        ###
        teamSort = (x for x in @teamList)                                               # Copy the teamlist to another array
        teamSort.sort((a,b) => b.standing()-a.standing())                               # Sort it using the standing values
        teamSort[i].setPosition(i+1) for i in [0...@teamList.length]                    # Copy those values back.

    team: (n) -> @teamList[n]                                                           # accessor for team data.
    teamCount: -> @teamList.length
    weekNumber: -> return @fixtureNumber+1                                              # get week number
    leagueName: -> @teamData.leagueName()
    incFixture: -> @fixtureNumber++

    nextFixture: ->
        ###
            get next fixture or null if there isn't one, the season is over.
        ###
        return if @fixtureNumber < @fixtures.length then @fixtures[@fixtureNumber] else null

class Team
    ###
        Encapsulates a single teams information
    ###
    constructor: (compTeam,teamData) ->
        @_name = compTeam[..-6]                                                         # Extract the team name.
        @_short = compTeam[-4..]                                                        # Extract the short name.
        col = compTeam.charAt(compTeam.length-5)*1                                      # Get colour, convert to number
        @_colour = teamData.colours()[col]                                              # Save colour name.
        @won = @draw = @lost = @for = @against = 0                                      # Reset league table data.
        @updateStandingScore()                                                          # Recalculate value used to update league tables.
    name: -> @_name                                                                     # Accessors
    colour: -> @_colour
    shortName: -> @_short
    standing: -> @_standingScore
    position: -> @_position
    points: -> @won*3 + @draw                                                           # Points gained.
    setPosition: (pos) -> @_position = pos                                              # Update league position.
    updateStandingScore: -> @_standingScore = @points() * 100000 + 5000 + (@for - @against) * 1000 + @for
    addScore: (sfor,against) ->
        @for += sfor                                                                    # adjust WDLFA values accordingly.
        @against += against
        @won++ if sfor > against
        @draw++ if sfor == against
        @lost++ if sfor < against
        @updateStandingScore()                                                          # update the positioning value
    getResults: -> return [@won+@draw+@lost,@won,@draw,@lost,@for,@against,@points()]   # return statistics.

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

# *************************************************************************************************************
#
#                                     Version Information
#
# *************************************************************************************************************

#   Date        Version     Notes
#   ====        =======     =====
#   1/4/12      0.1         In Development
#   7/4/12      0.2         First complete and working version.
#   7/4/12      0.5         Code Read #1
#   9/4/12      0.51        Fixed goalkeeper with ball position (side rather than in front)
#   16/4/12     0.52        Alternate colour now Orange - won't work for (say) Wolves v Holland :)
#   20/4/12     0.53        Fixed issues with low frame rate.
#   2/5/12      1.0         Code Read #2 to 1.0
