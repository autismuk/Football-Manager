/************************************************************************/
/*																		*/
/*		Name:		MATCHDAY.C 											*/
/*		Project:	Football Manager Remake								*/
/*		Purpose:	Matchday routines									*/
/*		Author:		Paul Robson											*/
/*		Created:	12th December 2001									*/
/*		Updated:	18th December 2001									*/
/*																		*/
/************************************************************************/

#include "fm.h"                                   /* Standard header */

static TEAMINFO *OurTeam;
static TEAMINFO *Opposition;
static int DivCup,i,AtHome,Fixture,IsCup,IsReplay;
static DIVISION *Division;
static DIVISION *ODivision;
static int OurStat[5],OppStat[5];

static void _MDIdentifyGround(GAME *g);
static void _MDCalculateIncome(GAME *g);
static void _MDWorkOutStatus(GAME *g);
static void _MDSelectOpposition(GAME *g);
static int _MDSelectTeam(GAME *g);
static void _MDDisplayTeam(GAME *g);
static void _MDDisplayInfo(int x,DIVISION *Div,TEAMINFO *Team,int *Stats);
static int _MDDisplayStats(GAME *g);
static void _MDCalcStatus(GAME *g);
static void _MDInjuryEnergy(GAME *g);
static void _MDAdjustStatistics(TEAMINFO *t1,TEAMINFO *t2);
static void _MDCalculateResults(GAME *g,TEAMINFO *t1,TEAMINFO *t2);
static void _MDPlayMatch(GAME *g);

/************************************************************************/
/*																		*/
/*							One complete matchday						*/
/*																		*/
/************************************************************************/

void MDRun(GAME *g)
{
    char _Temp[33],*Msg;
    int Col;
    MASSERT(g != NULL);
    Division = &(g->Division[g->Div]);            /* Our division */
/* This is our team */
    OurTeam = &(Division->Teams[Division->Team]);
/* Get the fixture */
    Fixture = Division->FixtureList[Division->Played];

    IsCup = (Fixture < 0);                        /* Set "Is Cup" flag */
    if (IsCup && g->OutOfCup)                     /* Check knocked out of cup */
    {
        IOClear(COL_BLACK);
        IOText(-1,10*8-4,COL_CYAN,COL_BLACK,"F.A. Cup Matches this week");
        IOText(-1,10*8+12,COL_CYAN,COL_BLACK,"You were knocked out.");
#ifndef HISPEED
        INITPressEnter();
#endif
        Division->Played++;
        return;
    }
    if (IsCup)                                    /* Record last round played */
        g->LastCupRound = -Fixture;
    INITGenerateSortArray(g);                     /* Calculate league posns */
    _MDIdentifyGround(g);                         /* Where is it played */
    _MDSelectOpposition(g);                       /* Who are we playing */
    IsReplay = 0;
    do
    {
        if (Division->Played != 0)                /* Energy and Injury adjust */
            _MDInjuryEnergy(g);
        _MDWorkOutStatus(g);                      /* Work out oppositions status */
        _MDCalculateIncome(g);                    /* Calculate gate receipts */
        OurTeam->Score = 0;                       /* Reset the score to 0-0 */
        Opposition->Score = 0;
        while (_MDDisplayStats(g))                /* Keep going till continue */
            while (_MDSelectTeam(g))              /* Keep selecting team */
        {
        };

        _MDPlayMatch(g);                          /* Play the match */

        IOClear(COL_BLACK);                       /* Display final score & receipts */
        IOText(-1,1*8,COL_YELLOW,COL_RED," **** FINAL SCORE ****");
        if (AtHome)
            sprintf(_Temp,"%s %d   %s %d",
                OurTeam->Name,OurTeam->Score,
                Opposition->Name,Opposition->Score);
        else
            sprintf(_Temp,"%s %d   %s %d",
                Opposition->Name,Opposition->Score,
                OurTeam->Name,OurTeam->Score);
        IOText(-1,6*8,COL_GREEN,COL_BLACK,_Temp);
        IOText(-1,14*8,COL_WHITE,COL_BLACK,"Gate Receipts");
        sprintf(_Temp,"%c%ld",96,g->Receipts);
        IOText(-1,16*8,COL_YELLOW,COL_BLACK,_Temp);
        g->Cash += g-> Receipts;                  /* Add receipts to cash */
#ifndef HISPEED
        INITPressEnter();
#endif

        if (IsCup &&                              /* Cup replay */
            OurTeam->Score == Opposition->Score)
        {
            IsReplay = 1;
            AtHome = (AtHome == 0);
        }
        else                                      /* Otherwise, the loop ends */
            IsReplay = 0;
    } while (IsReplay);
    if (IsCup == 0)                               /* League match, other results */
    {
        _MDAdjustStatistics(OurTeam,Opposition);
        if (AtHome)
            _MDCalculateResults(g,OurTeam,Opposition);
        else
            _MDCalculateResults(g,Opposition,OurTeam);
        if (OurTeam->Score < Opposition->Score)
        {
            g->CurrentCrowd = g->CurrentCrowd * 9 / 10;
            if (g->CurrentCrowd < 1000) g->CurrentCrowd = 1000;
        }
        if (OurTeam->Score > Opposition->Score)
            g->CurrentCrowd += (10000*g->FinancialScaler-g->CurrentCrowd)/10;
#ifndef HISPEED
        INITDisplayDivision(g);
#endif
    }
    else                                          /* Analyse etc. cup results */
    {
        if (Opposition->Score >                   /* Set out of cup flag */
            OurTeam->Score)
        {
            g->OutOfCup = 1;
            Col = COL_MAGENTA;
            Msg = "You're out of the F.A. Cup";
        }
        else
        {
            Col = COL_CYAN;Msg = "You're through to the next round";
            if (Fixture == -8)
                Col = COL_YELLOW,Msg = "You've won the F.A. Cup !";
        }
        IOClear(COL_BLACK);
        IOText(-1,12,COL_YELLOW,COL_RED," F.A. Cup ");
        IOText(-1,84,Col,COL_BLACK,Msg);
#ifndef HISPEED
        INITPressEnter();
#endif
    }
/* Adjust morale of team */
    if (Opposition->Score > OurTeam->Score)
        g->Morale = g->Morale / 2;
    if (OurTeam->Score > Opposition->Score)
        g->Morale = g->Morale + (20-g->Morale)/2;
    if (g->Morale < 1) g->Morale = 1;             /* Morale forced into range */
    if (g->Morale > 20) g->Morale = 20;
    Division->Played++;                           /* Played one more match */
}


/************************************************************************/
/*																		*/
/*						Identify Home or Away							*/
/*																		*/
/************************************************************************/

static void _MDIdentifyGround(GAME *g)
{
    MASSERT(g != NULL);
    AtHome = rand()%2;                            /* At home random in cup */
    if (IsCup == 0)                               /* Identify home or away if league */
    {
        AtHome = Division->FirstMatchHome;
        for (i = 0;i < Division->Played;i++)
            if (Division->FixtureList[i] >= 0) AtHome = (AtHome == 0);
        Opposition = &(Division->Teams[Fixture]);
        ODivision = Division;
    }
    g++;                                          /* Kill warning */
}


/************************************************************************/
/*																		*/
/*			Get information about opposition in the cup 				*/
/*																		*/
/************************************************************************/

static void _MDSelectOpposition(GAME *g)
{
    int i;
    MASSERT(g != NULL);
    if (IsCup != 0)                               /* If a cup match.... */
    {
        do                                        /* Select a division */
        {
            i = rand()%(g->DivCount);
            if (-Fixture <= 2) i++;
            if (-Fixture == 3) i++;
            if (-Fixture >= 7) i--;
            if (-Fixture == 8) i = 0;
        } while (i < 0 || i >= g->DivCount);

        ODivision = &(g->Division[i]);            /* Select a team in the division */
        DivCup = i;
        do
        {
            i = rand()%(ODivision->NoTeams);
        } while (ODivision == Division            /* Not us */
            && i == Division->Team);
        Opposition = &(ODivision->Teams[i]);
    }
}


/************************************************************************/
/*																		*/
/*					Work out oppositions status levels					*/
/*																		*/
/************************************************************************/

static void _MDWorkOutStatus(GAME *g)
{
    int i;
    MASSERT(g != NULL);
    for (i = 0;i < 5;i++)                         /* Work out statuses */
    {
        if (IsCup != 0)                           /* Cup team statuses */
        {
            OppStat[i] = rand() % 16 + g->Skill;
            OppStat[i] = OppStat[i] - (DivCup - g->Div);
        }
        else                                      /* League team statuses */
        {
            OppStat[i] = rand() % 14 + g->Skill;
            OppStat[i] += Opposition->Points / (Division->Played+1);
        }
        if (OppStat[i] < 1)                       /* Force into range */
            OppStat[i] = 1;
        if (OppStat[i] > 20)
            OppStat[i] = 20;
    }
}


/************************************************************************/
/*																		*/
/*						Calculate Game Receipts							*/
/*																		*/
/************************************************************************/

static void _MDCalculateIncome(GAME *g)
{
    MASSERT(g != NULL);
    if (IsCup)                                    /* Cup receipts */
    {
        if (AtHome)                               /* Home game */
            g->Receipts = g->CurrentCrowd;
        else                                      /* Away game */
            g->Receipts = (g->DivCount - g->Div)*1000;
/* End games */
        if (Fixture == -7) g->Receipts = 50000L;
        if (Fixture == -8) g->Receipts = 100000L;
    }
    else                                          /* League Receipts */
    {
        if (AtHome)
            g->Receipts = g->CurrentCrowd;
        else
            g->Receipts = (Division->NoTeams-Opposition->LeaguePos) *
                g->FinancialScaler * 500;
    }
}


/************************************************************************/
/*																		*/
/*						Display league game/cup game					*/
/*																		*/
/************************************************************************/

static char *Label[5] = { "Energy","Morale","Defence","Midfield","Attack" };

static void _MDDisplayTeam(GAME *g)
{
    char _Msg[32];
    MASSERT(g != NULL);
    IOClear(COL_BLACK);
    if (IsCup)                                    /* Work out cup round name */
    {
        sprintf(_Msg," F.A. Cup Round %d",-Fixture);
        if (Fixture == -7) strcpy(_Msg,"F.A. Cup Semi-Final");
        if (Fixture == -8) strcpy(_Msg,"F.A. Cup Final");
        if (IsReplay) strcat(_Msg," Replay");
        strcat(_Msg," ");
    }
    else                                          /* League match */
    {
        sprintf(_Msg," League Match - %s ",Division->DivName);
    }
    IOText(-1,8,COL_YELLOW,COL_RED,_Msg);
    IOText(-1,32,COL_GREEN,COL_BLACK,"V");
/* Display team info */
    _MDDisplayInfo((AtHome ? 1:17),Division,OurTeam,OurStat);
    _MDDisplayInfo((AtHome ? 17:1),ODivision,Opposition,OppStat);
    for (i = 0;i < 5;i++)                         /* Status labels */
    {
        IOText(-1,56+i*14,COL_WHITE,COL_BLACK,Label[i]);
    }
    g++;                                          /* Kill warning */
}


/************************************************************************/
/*																		*/
/*					  Display one teams information						*/
/*																		*/
/************************************************************************/

static void _MDDisplayInfo(int x,DIVISION *Div,TEAMINFO *Team,int *Stat)
{
    char _Msg[32];
    int i;
    MASSERT(Div != NULL);
    MASSERT(Team != NULL);
    MASSERT(Stat != NULL);
    x = x * 8;                                    /* Name, and maybe division */
    sprintf(_Msg,"%s",Team->Name);
    IOText(x+60-strlen(_Msg)*4,32,COL_CYAN,COL_BLACK,_Msg);
    sprintf(_Msg,"Pos. %d",Team->LeaguePos);
    if (IsCup)
        sprintf(_Msg,"%s",Div->DivName);
    IOText(x+60-strlen(_Msg)*4,40,COL_GREEN,COL_BLACK,_Msg);
    for (i = 0;i < 5;i++)                         /* Statuses */
    {
        sprintf(_Msg,"%d",Stat[i]);
        IOText(x+60-strlen(_Msg)*4,56+i*14,COL_MAGENTA,COL_BLACK,_Msg);
    }
}


/************************************************************************/
/*																		*/
/*					Calculate our status and no of players				*/
/*																		*/
/************************************************************************/

static void _MDCalcStatus(GAME *g)
{
    int i;
    MASSERT(g != NULL);
    for (i = 0;i < 5;i++) OurStat[i]=0;           /* Erase our status */
    g->Picked = g->Injured = g->Available = 0;
    OurStat[1] = g->Morale;                       /* Copy morale */
    for (i = 0;i < g->PlayerCount;i++)            /* Calculate statuses */
        if (g->Player[i].InOurTeam)               /* Count the team up */
    {
        g->Available++;
        switch(g->Player[i].Status)
        {
            case AVAILABLE:                       /* Available for selection */
                break;
            case INJURED:                         /* Injured */
                g->Injured++;break;
            case PICKED:                          /* In the team */
                g->Picked++;
                OurStat[0] +=                     /* Calculating mean energy */
                    g->Player[i].Energy;
                switch(g->Player[i].Pos)          /* And area strengths */
                {
                    case DEFENCE:   OurStat[2] += g->Player[i].Skill;break;
                    case MIDFIELD:  OurStat[3] += g->Player[i].Skill;break;
                    case ATTACK:    OurStat[4] += g->Player[i].Skill;break;
                }
                break;
        }
    }
    OurStat[0] /= g->Picked;                      /* Average energy */
}


/************************************************************************/
/*																		*/
/*				Display Status Info, select Change or Play				*/
/*																		*/
/************************************************************************/

static int _MDDisplayStats(GAME *g)
{
    MASSERT(g != NULL);
    _MDCalcStatus(g);                             /* Calc statuses and show them */
    _MDDisplayTeam(g);
    if (g->Picked > 11)                           /* Too many players, must change */
    {
        INITPressEnter(); return 1;
    }
    IOText(-1,160,COL_CYAN,COL_BLACK,             /* Offer option if <= 11 players */
        "C to change team, P to play game");
    do                                            /* Get Change or Play */
    {
        i = IOInkey();i = toupper(i);
    } while (i != 'C' && i != 'P');
    return (i == 'C');                            /* Change, return with 1 */
}


/************************************************************************/
/*																		*/
/*								Team Selection							*/
/*																		*/
/************************************************************************/

static int _MDSelectTeam(GAME *g)
{
    char *Msg = NULL;
    int i,y;
    MASSERT(g != NULL);
    IOClear(COL_BLACK);                           /* Editing options */
    y = 0;MENUPlayer(g,-1,&y);
    for (i = 0; i < g->PlayerCount;i++)
        if (g->Player[i].InOurTeam) MENUPlayer(g,i,&y);
    MENUPlayer(g,-2,&y);
/* Display prompt */
    IOText(-1,154,COL_CYAN,COL_BLACK,g->Picked > 11 ?
        "Enter the player to drop":"Enter the player to pick");
    i = (int)MENUGetInt(120,164,2);               /* Get number */
    if (i <= 0) return 0;                         /* Nothing selected */
    if (i > g->PlayerCount) return 0;             /* Too high */
    i--;                                          /* Convert to index */
    if (g->Picked <= 11)                          /* Adding a player */
    {
        if (g->Player[i].Status == INJURED)
            Msg = "The player is injured";
        if (g->Player[i].Status == PICKED)
            Msg = "Player is selected already";
        if (g->Player[i].InOurTeam == 0)
            Msg = "Player is not in our team";
        if (Msg == NULL)
            g->Player[i].Status = PICKED;
    }
    else                                          /* Chopping a player */
    {
        if (g->Player[i].InOurTeam == 0 ||
            g->Player[i].Status != PICKED)
            Msg = "You cannot drop that player";
        else
            g->Player[i].Status = AVAILABLE;
    }

    if (Msg != NULL)                              /* Message ? */
    {
        IOText(-1,174,COL_YELLOW,COL_BLACK,Msg);
        INITPressEnter();
    }
    i = (g->Picked > 11);                         /* if was 12+ or is now 12 then */
    _MDCalcStatus(g);                             /* We must edit again */
    return i || (g->Picked > 11) ;
}


/************************************************************************/
/*																		*/
/*						Energy/Injury Calculations						*/
/*																		*/
/************************************************************************/

static void _MDInjuryEnergy(GAME *g)
{
    int i;
    PLAYER *p;
    MASSERT(g != NULL);
    for (i = 0;i < g->PlayerCount;i++)            /* Work through all players */
    {
        p = &(g->Player[i]);                      /* Temporary pointer */
        switch(p->Status)                         /* Adjust energy */
        {
            case PICKED:    p->Energy--;break;
            case INJURED:   p->Energy++;break;
            case AVAILABLE: p->Energy += 10;break;
        }
        if (p->Energy < 1)p->Energy = 1;          /* Force into limits */
        if (p->Energy > 20) p->Energy = 20;
        if (p->Status==INJURED)                   /* Recover from injuries */
            p->Status = AVAILABLE;
        if (p->InOurTeam &&                       /* 1 in 20 chance of injury */
            rand()%20 == 0)
            p->Status = INJURED;
    }
}


/************************************************************************/
/*																		*/
/*						Update information for team						*/
/*																		*/
/************************************************************************/

static void _MDAdjustStatistics(TEAMINFO *t1,TEAMINFO *t2)
{
    MASSERT(t1 != NULL);
    MASSERT(t2 != NULL);
    t1->GoalsFor += t1->Score;                    /* Update score */
    t2->GoalsFor += t2->Score;
    t1->GoalsAgainst += t2->Score;
    t2->GoalsAgainst += t1->Score;
    if (t1->Score == t2->Score)                   /* Adjust points */
        t1->Drawn++,t2->Drawn++;
    if (t1->Score > t2->Score)
        t1->Won++,t2->Lost++;
    if (t2->Score > t1->Score)
        t2->Won++,t1->Lost++;
}


/************************************************************************/
/*																		*/
/*				Calculate other results, display all results			*/
/*																		*/
/************************************************************************/

static void _MDCalculateResults(GAME *g,TEAMINFO *t1,TEAMINFO *t2)
{
    int i,j;
    char _Temp[32];
    TEAMINFO *f,*Fix[MAXTEAMS];
    DIVISION *d = &(g->Division[g->Div]);
    MASSERT(g != NULL);
    for (i = 0;i < d->NoTeams;i++)                /* Blank all entries */
        Fix[i] = NULL;
    Fix[0] = t1;Fix[1] = t2;
    for (i = 0;i < d->NoTeams;i++)                /* Fill with the rest */
        if (t1 != &(d->Teams[i]) && t2 != &(d->Teams[i]))
    {
        do
        j = rand()%(d->NoTeams);
        while (Fix[j] != NULL);
        Fix[j] = &(d->Teams[i]);
    }

    for (i = 2;i < d->NoTeams;i+=2)               /* Play the games */
    {
        Fix[i]->Score =
            Fix[i]->Points/(d->Played+1)+rand()%4;
        Fix[i+1]->Score =
            Fix[i+1]->Points/(d->Played+1)+rand()%4;
        _MDAdjustStatistics(Fix[i],               /* Award points */
            Fix[i+1]);
    }

    do                                            /* Sort results alphabetically */
    {
        j = 0;
        for (i = 0;i < d->NoTeams-2;i+=2)
            if (strcmp(Fix[i]->Name,Fix[i+2]->Name) > 0)
        {
            j = 1;
            f = Fix[i];Fix[i] = Fix[i+2];Fix[i+2] = f;
            f = Fix[i+1];Fix[i+1] = Fix[i+3];Fix[i+3] = f;
        }
    }
    while (j != 0);

    sprintf(_Temp," %s Results ",                 /* Display the results */
        d->DivName);
    IOClear(COL_BLACK);
    IOText(-1,8,COL_YELLOW,COL_RED,_Temp);
    for (i = 0;i < d->NoTeams;i+=2)
    {
        sprintf(_Temp,"%-10s %-2d     %-10s %-2d",
            Fix[i]->Name,Fix[i]->Score,Fix[i+1]->Name,Fix[i+1]->Score);
        IOText(-1,24+i*6,COL_GREEN,COL_BLACK,_Temp);
    }
#ifndef HISPEED
    INITPressEnter();                             /* Wait for a key */
#endif
}


/************************************************************************/
/*																		*/
/*						Play match with highlights						*/
/*																		*/
/************************************************************************/

static void _MDPlayMatch(GAME *g)
{
    int n,Offer,c1,c2,s;
    MASSERT(g != NULL);
    s = 150;                                      /* Speed */
#ifdef HISPEED
    s = 1;
#endif
    c1 = OurTeam->Colour;                         /* Deal with shirt clash */
    c2 = Opposition->Colour;
    while (OurTeam->Colour == Opposition->Colour)
    {
        n = rand()%7;
        if (AtHome)
            Opposition->Colour = n;
        else
            OurTeam->Colour = n;
    }
    OurTeam->HomeTeam = AtHome;                   /* Set the home team flags */
    Opposition->HomeTeam = (AtHome == 0);
    for (Offer = 0;Offer < 5;Offer++)
    {
        n = (rand()%100) + (OurStat[Offer]-OppStat[Offer])*5;
        if (n >= 75)
            MAOneAttack(OurTeam,Opposition,AtHome,g->Sound,s);
        n = (rand()%100) + (OppStat[Offer]-OurStat[Offer])*5;
        if (n >= 75)
            MAOneAttack(Opposition,OurTeam,AtHome == 0,g->Sound,s);
    }
    if (OurTeam->Score+Opposition->Score == 0)
    {
        MAOneAttack(OurTeam,Opposition,AtHome,g->Sound,s);
        MAOneAttack(Opposition,OurTeam,AtHome == 0,g->Sound,s);
    }
    OurTeam->Colour = c1;                         /* Restore Colours */
    Opposition->Colour = c2;
}
