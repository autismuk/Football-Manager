/************************************************************************/
/*																		*/
/*		Name:		MATCH.C												*/
/*		Project:	Football Manager Remake								*/
/*		Purpose:	Match Highlights									*/
/*		Author:		Paul Robson											*/
/*		Created:	7th December 2001									*/
/*		Updated:	17th December 2001									*/
/*																		*/
/************************************************************************/

#include "fm.h"                                   /* Standard header */

/************************************************************************/
/*																		*/
/*				Emulate Spectrum PLOT and DRAW commands					*/
/*																		*/
/************************************************************************/

static int xc,yc,xFlipped;

static void _MAPlot(int x,int y)
{
    xc = xFlipped ? (255-x):x;
    yc = 175-y;
}


static void _MADraw(int x,int y)
{
    int x1,y1;
    x1 = xc + ((xFlipped)?-x:x);
    y1 = yc-y;
    IOLine(xc,yc,x1,y1,COL_WHITE);
    xc = x1;yc = y1;
}


/************************************************************************/
/*																		*/
/*							Draw the goalmouth							*/
/*																		*/
/************************************************************************/

static void _MAPitch(void)
{
    double d;
    IOClear(COL_DKGREEN);                         /* Draw the pitch */
    _MAPlot(71,88);_MADraw(-16,-8);_MADraw(-8,-16);_MADraw(24,0);
    _MAPlot(8,0);_MADraw(175,175);_MADraw(255-183,0);
    _MAPlot(8,0);_MADraw(127,0);_MADraw(120,0);
    _MAPlot(72,64);_MADraw(0,24);_MADraw(48,48);_MADraw(0,-24);
    _MAPlot(64,56);_MADraw(24,0);_MADraw(64,64);_MADraw(-24,0);
    _MAPlot(32,24);_MADraw(96,0);_MADraw(115,115);_MADraw(-96,0);
    _MAPlot(119,135);_MADraw(-16,-8);_MADraw(-8,-16);_MADraw(24,0);
    _MAPlot(102,126);_MADraw(-48,-48);
    _MAPlot(158,84);_MADraw(2,0);
    _MAPlot(158,85);_MADraw(2,0);
    _MAPlot(170,100);             

    d = -7.0;
    while (d <= 95)
    {
        IOPut(xc + (xFlipped?-1:1)*40*cos(2*3.14*d/360),
            yc+40*sin(2*3.14*d/360),COL_WHITE);
        d = d + 1.0;
    }
}


/************************************************************************/
/*																		*/
/*								Draw a player							*/
/*																		*/
/************************************************************************/

static void _MADrawPlayer(COORD *Pos,int Colour,int FaceLeft)
{
    int c = (Pos->x+Pos->y)/2%4;
    int x = xFlipped ? 255-Pos->x:Pos->x;
    if (x < 0 || Pos->y < 0) return;
    if (x >= 248 || Pos->y >= 184) return;
    if (FaceLeft) c = c+6;
    IOChar(x,Pos->y,Colour,-1,c);
}


/************************************************************************/
/*																		*/
/*								Draw the ball							*/
/*																		*/
/************************************************************************/

static void _MADrawBall(COORD *Pos)
{
    int x = xFlipped ? 255-Pos->x:Pos->x;
    if (x < 0 || Pos->y < 0) return;
    if (x >= 248 || Pos->y >= 184) return;
    IOChar(x,Pos->y,COL_BLACK,-1,xFlipped ? 10 : 5);
}


/************************************************************************/
/*																		*/
/*						Find player nearest the ball					*/
/*																		*/
/************************************************************************/

static int _MAFindNearestToBall(COORD *Ball,COORD *Players,
int PCount,int *Dist)
{
    int x,y,d,Nearest = -1,NearDist = 999,Curr = 0;
    *Dist = 999;                                  /* Initialise distance */
    while (PCount-- > 0)                          /* For all players */
    {
        x = abs(Ball->x-Players->x);              /* Calc distance */
        y = abs(Ball->y-Players->y);
        if (x < 16 && y < 16)                     /* Worth continuing ? */
        {
            d = sqrt(x*x+y*y);                    /* Actual distance */
            if (d < NearDist)                     /* Best so far */
            {
                *Dist = NearDist = d;
                Nearest = Curr;
            }
        }
        Curr++;Players++;
    }
    return Nearest;
}


/************************************************************************/
/*																		*/
/*					Play one highlighted match							*/
/*																		*/
/************************************************************************/

void MAOneAttack(TEAMINFO *Attack,TEAMINFO *Defend,int FlipX,int SoundOn,int Speed)
{
    COORD Att[3],Def[4];
    COORD Ball,BallDir;
    char _Temp[32],_Temp2[32];
    int d1,d2,Moves,OutOfPlay,GoalScored,i,x,y,j,c;
    int NoTouch;
    long t;
    TEAMINFO *tm;
    xFlipped = FlipX;                             /* Save flip flag */
    _MAPitch();                                   /* Draw the pitch */
    IOCopy(COPYTOBB);                             /* Copy into the back buffer */
    Att[0].y = 3+rand()%18;                       /* Initialise player with ball */
    Att[0].x = 25+rand()%6;
    Ball = Att[0];Att[0].x++;                     /* Initialise ball */
    BallDir.x = -1;BallDir.y = 0;
    Def[3].x = 11 + rand()%2;                     /* Goalie position */
    if (Att[0].y < 10) Def[3].x += 2;
    if (Att[0].y > 13) Def[3].x -= 2;
    Def[3].y = 23-Def[3].x;

    for (i = 1;i < 3;i++)                         /* Other attackers */
    {
        do
        {
            Att[i].x = 10+rand()%20;
            Att[i].y = rand()%21;
            c = (Att[i].x+Att[i].y < 25);
            if (Att[i].x > Att[0].x-4) c = 1;
            for (j = 0;j < i;j++)
                if (Att[i].y == Att[j].y) c = 1;
        } while (c != 0);
    }
    for (i = 0;i < 3;i++)                         /* Defenders */
    {
        do
        {
            Def[i].x = 10+rand()%10;
            Def[i].y = rand()%18;
            c = (Def[i].x+Def[i].y < 24 || Def[i].x > Att[0].x-4);
            for (j = 0;j < 3;j++)
            {
                if (Def[i].y == Att[j].y) c = 1;
                if (i < j && Def[i].y == Def[j].y) c = 1;
            }
        } while (c != 0);
    }
    for (i = 0;i < 3;i++)                         /* Convert to pixel positions */
    {
        Att[i].x *= 8;Att[i].y *= 8;
        Def[i].x *= 8;Def[i].y *= 8;
    }
    Ball.x *= 8;Ball.y *= 8;_MADrawBall(&Ball);
    Def[3].x *= 8;Def[3].y *= 8;
    Moves = (rand()%3+1)*2-1;                     /* Number of character moves */
    Moves *= 8;                                   /* Pixel moves */
    t = IOClock();
    while (Moves-- > 0)                           /* Move players forward */
    {
        t = t+(32*Speed/100);                     /* Sync */
        Ball.x--;
        for (i = 0;i < 3;i++)                     /* Move players */
        {
            x = Att[i].x-1;
            y = Att[i].y;
            if (i != 0)                           /* Non-ball players head to middle */
            {
                if (y < 80) y++;
                if (y > 72) y--;
            }
            if (x+y > 25*8 || i == 0)             /* If legal, update positions */
            {
                Att[i].x = x;Att[i].y = y;
            }
            x = Def[i].x-1;
            y = Def[i].y;
            if (i != 0)                           /* Non-ball players head to middle */
            {
                if (y < 80) y++;
                if (y > 72) y--;
            }
            if (x+y > 25*8)                       /* If legal, update positions */
            {
                Def[i].x = x;Def[i].y = y;
            }

        }
        IOCopy(COPYFROMBB);                       /* Update Display */
        _MADrawBall(&Ball);
        for (i = 0;i < 4;i++)
        {
            if (i < 4) _MADrawPlayer(&Att[i],Attack->Colour,xFlipped);
            _MADrawPlayer(&Def[i],(i == 3) ? COL_GREEN:Defend->Colour,(xFlipped == 0));
        }
        HWUpdate();
        while (IOClock() < t)                     /* Wait for time out */
        {
        };
    }
    BallDir.y = 0;
    BallDir.x = -2;
    if (Ball.y < 9*8) BallDir.y++;
    if (Ball.y > 13*8) BallDir.y--;
    if (Ball.y >= 9*8 && Ball.y < 12*8)
        BallDir.y = (rand()%3) -1;
    GoalScored = OutOfPlay = 0;
    if (SoundOn) IOSound(0,0);
    NoTouch = 3;
    while (OutOfPlay == 0)
    {
        t = t + (14*Speed/100);                   /* Sync */
        Ball.x += BallDir.x;
        Ball.y += BallDir.y;
        if (Ball.x < 0 || Ball.y < 0              /* If out of bounds mark as such */
            || Ball.x >= 31*8 || Ball.y >= 23*8)
        {
            Ball.x -= BallDir.x;
            Ball.y -= BallDir.y;
            OutOfPlay = 1;
        }
        x = (Ball.x+Ball.y)/8;                    /* Check if goalie move */
        if (BallDir.x < 0 && Ball.y != Def[3].y && Ball.y > 56 && x >= 24 && x < 28)
        {
            y = Def[3].y;
            if (Ball.y < Def[3].y) Def[3].y--;else Def[3].y++;
            if (Def[3].y < 64 || Def[3].y > 112) Def[3].y = y;
            Def[3].x = 23*8-Def[3].y;
        }
/* Find nearest player */
        _MAFindNearestToBall(&Ball,Att,3,&d1);
        _MAFindNearestToBall(&Ball,Def,4,&d2);
        d1 = d1 / 2;                              /* Scaling this affects effectiveness */
        d2 = d2 * 9 / 4;
        NoTouch--;
        if ((d1 < 5 || d2 < 5) &&                 /* Player in range */
            NoTouch < 0)
        {
            BallDir.y = rand()%3-1;               /* Reset ball dir */
            NoTouch = 3;
            BallDir.x = (d1 <= d2) ? -2:2;
            if (SoundOn) IOSound(0,0);
            if (d1 <= d2)                         /* If hit an attacker, aim */
            {
                BallDir.y = 0;
                if (Ball.y < 9*8) BallDir.y++;
                if (Ball.y > 13*8) BallDir.y--;
                if ((Ball.y >= 9*8 && Ball.y < 12*8) || rand()%6 == 0)
                    BallDir.y = (rand()%3) -1;
            }
        }
        if (Ball.x+Ball.y < 170)                  /* Past goal line */
        {
            OutOfPlay = 1;                        /* Out of play, goal scored ? */
            GoalScored = (Ball.y > 58 && Ball.y < 108);
        }
        IOCopy(COPYFROMBB);                       /* Update Display */
        _MADrawBall(&Ball);
        for (i = 0;i < 4;i++)
        {
            if (i < 4) _MADrawPlayer(&Att[i],Attack->Colour,xFlipped);
            _MADrawPlayer(&Def[i],(i == 3) ? COL_GREEN:Defend->Colour,(xFlipped == 0));
        }
        HWUpdate();
        while (IOClock() < t)                     /* Wait for time out */
        {
        };
    }

    if (GoalScored)                               /* Goal scored */
    {
        Attack->Score++;
        HWDisplayGoal();
        tm = (Attack->HomeTeam) ? Attack:Defend;
        y = tm->Colour;
        sprintf(_Temp," %s %d ",tm->Name,tm->Score);
        tm = (Attack->HomeTeam) ? Defend:Attack;
        sprintf(_Temp2,"%s %d ",tm->Name,tm->Score);
        x = 128-(strlen(_Temp)+strlen(_Temp2))*4;
        IOText(x,32,y,COL_GREY,_Temp);
        x = x+strlen(_Temp)*8;
        IOText(x,32,tm->Colour,COL_GREY,_Temp2);
    }
    else
    {
        strcpy(_Temp," No Goal! ");
        IOText(-1,8,COL_BLUE,COL_GREY,_Temp);
    }
    t = t + 1500L * Speed / 100;                  /* Short delay */
    if (GoalScored && SoundOn) IOSound(10*Speed,1);
    HWUpdate();
    while (IOClock() < t);
}


/************************************************************************/
/*																		*/
/*					Routine for testing Match Graphics					*/
/*																		*/
/************************************************************************/

void MAMatchTest(void)
{
    int y = 0;
    TEAMINFO t1,t2;
    IOInitialise();

    strcpy(t1.Name,"Chelsea");t1.Colour = COL_BLUE;t1.Score = 0;t1.HomeTeam = 1;
    strcpy(t2.Name,"Man Utd");t2.Colour = COL_RED;t2.Score = 0;t2.HomeTeam = 0;
    while (IOInkey() == 0)
    {
        y = (y == 0) ? 1 : 0;
        MAOneAttack(&t1,&t2,y,1,100);
    }
    IOTerminate();
}
