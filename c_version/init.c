/************************************************************************/
/*																		*/
/*		Name:		INIT.C												*/
/*		Project:	Football Manager Remake								*/
/*		Purpose:	Initialise new game/new season						*/
/*		Author:		Paul Robson											*/
/*		Created:	12th December 2001									*/
/*		Updated:	21st December 2001									*/
/*																		*/
/*		Fixed: 21/12/01. The fixture calculation routine in				*/
/*			INITNewSeason() assumed the team was the last in the list	*/
/*																		*/
/************************************************************************/

#include "fm.h"                                   /* Standard header */

static void _INITShuffle(DIVISION *d);

/************************************************************************/
/*																		*/
/*						 Initialise a new game							*/
/*																		*/
/************************************************************************/

void INITNewGame(GAME *g)
{
    int i,n,Mode = -1;
    FILE *f;
    char Line[128];
    memset(g,0,sizeof(GAME));                     /* Zap all of the structure */
    g->DivCount = g->PlayerCount = 0;             /* These will count the div/players */
    g->Cash = 100000L;g->Loans = 0L;              /* Cash, Loans erased */
    g->Skill = 3;                                 /* A default skill level */
    f = fopen("game.dat","r");                    /* Open the data file */
    if (f == NULL)                                /* In Linux, it goes here */
            f = fopen("/usr/share/fm/game.dat","r");
    MASSERT(f != NULL);                           /* File not present ? */
    while (fgets(Line,                            /* Read and strip line */
        sizeof(Line),f) != NULL)
    {
        while (Line[0] != '\0' && Line[strlen(Line)-1] <= ' ')
            Line[strlen(Line)-1] = '\0';
        if (Line[0] == ';') Line[0] = '\0';
        if (Line[0] != '\0')
        {
            if (*Line == ':')                     /* Mode switch, check players ? */
            {
                if (strcmp(Line,":Players") == 0)
                {
                    Mode = -2;
                }
                else                              /* Check new division */
                {
                    Mode =  (g->DivCount++);
                    MASSERT(Mode < DIVISIONS);
                    strcpy(g->Division[Mode].DivName,Line+1);
                    g->Division[Mode].NoTeams = 0;
                }
            }
            else                                  /* Data, copy it in */
            {
                if (Mode == -2)                   /* A player */
                {
                    MASSERT(g->PlayerCount < MAXPLAYERS);
                    n = g->PlayerCount++;
                    strcpy(g->Player[n].Name,Line);
                    g->Player[n].InOurTeam = 0;
                }
                else                              /* A team */
                {
                    MASSERT(g->Division[Mode].NoTeams < MAXTEAMS);
                    n = g->Division[Mode].NoTeams++;
                    strcpy(g->Division[Mode].Teams[n].Name,Line+1);
                    g->Division[Mode].Teams[n].Colour = Line[0] - '0';
                }
            }
        }
    }
    fclose(f);
    g->Div = g->DivCount - 1;                     /* Move no divisions to our div */

    for (n = 0;n < g->DivCount;n++)
        MASSERT(g->Division[n].NoTeams % 2 == 0);

    g->Division[g->Div].Team =  0;                /* Give us the first team */

    for (i = 0;i < g->PlayerCount;i++)            /* Select positions */
    {
        g->Player[i].Pos = DEFENCE;
        if (i >= g->PlayerCount/3)
            g->Player[i].Pos = (i >= 2*g->PlayerCount/3) ? ATTACK:MIDFIELD;
    }
    for (i = 0;i < 12;i++)                        /* Pick 12 players for us */
    {
        do                                        /* Look for nonselected player */
        n = rand()%(g->PlayerCount);
        while (g->Player[n].InOurTeam);
        g->Player[n].InOurTeam = 1;               /* part of our team now */
        g->Player[n].Status =                     /* 11 selected, 1 reserve */
            (i == 11) ? AVAILABLE:PICKED;
    }
    g->Score = g->Seasons = 0;                    /* No score or seasons */
    g->Sound = 1;g->Sacked = 0;
}


/************************************************************************/
/*																		*/
/*						Initialise a new season							*/
/*																		*/
/************************************************************************/

void INITNewSeason(GAME *g)
{
    int n,i,j;
    DIVISION *d = &(g->Division[g->Div]);
    TEAMINFO *t;
    for (i = 0;i < g->DivCount;i++)
    {
        if (g->Div != i)                          /* Set team id to -1 in other divs */
            g->Division[i].Team = -1;
        _INITShuffle(&(g->Division[i]));
    }
    d->FirstMatchHome = rand()%2;                 /* Next home ? */
    d->Fixtures = d->NoTeams - 1;                 /* Number of league matches */
    n = 0;
    for (i = 0;i < d->Fixtures;i++)               /* Create the fixture list */
    {
        if (n == d->Team) n++;
        d->FixtureList[i] = n++;
    }
    d->Played = 0;                                /* Played no fixtures */
    for (i = 0;i < d->NoTeams;i++)                /* Erase each team */
    {
        t = &(d->Teams[i]);
        t->Won = t->Drawn = t->Lost =0;
        t->GoalsFor = t->GoalsAgainst = 0;
        t->Points = 0;
    }

    n = 9;                                        /* Insert cup matches */
    while (--n >= 1)
    {
        j = (d->NoTeams-1)*n/8;                   /* Post to insert FA Cup Rounds */
        i = d->Fixtures-1;                        /* Make space for it */
        while (i >= j)
        {
            d->FixtureList[i+1] = d->FixtureList[i];
            i--;
        }
        d->FixtureList[j] = -n;                   /* Insert the new fixture */
        d->Fixtures++;
    }
    g->OutOfCup = 0;                              /* Not out of the cup */
    g->FinancialScaler =                          /* Financial multiplier */
        g->DivCount-g->Div;
    g->Morale = 10;                               /* Initial morale */
    g->CurrentCrowd =                             /* Financial bases */
        5000*g->FinancialScaler;
    g->GroundRent = 500*g->FinancialScaler;

    for (i = 0;i < g->PlayerCount;i++)            /* Reset players detail */
    {
        g->Player[i].Value = 5000L*g->FinancialScaler*(rand()%5+1);
        g->Player[i].Skill = (int)(g->Player[i].Value/(5000*g->FinancialScaler));
        g->Player[i].Energy = rand()%20+1;
    }
    g->MoveCount = 2;                             /* Promoted/Relegated */
    if (d->NoTeams > 19) g->MoveCount = 3;
    if (d->NoTeams > 24) g->MoveCount = 4;
}


/************************************************************************/
/*																		*/
/*			Shuffle all the teams in the division, except ours			*/
/*																		*/
/************************************************************************/

static void _INITShuffle(DIVISION *d)
{
    int i,n1,n2;
    TEAMINFO t;
    for (i = 0;i < 100;i++)                       /* Lotsa shuffles */
    {                                             /* Pick 2 teams, not ours */
        do n1 = rand()%(d->NoTeams); while (n1 == d->Team);
        do n2 = rand()%(d->NoTeams); while (n2 == d->Team);
        t = d->Teams[n1];                         /* Swap them */
        d->Teams[n1] = d->Teams[n2];
        d->Teams[n2] = t;
    }
    i++;
}


/************************************************************************/
/*																		*/
/*						Display the fixture list						*/
/*																		*/
/************************************************************************/

void INITFixtureList(GAME *g)
{
    int i,c,x,y,h;
    char _Temp[16];
    DIVISION *d = &(g->Division[g->Div]);
    IOClear(COL_BLACK);
    IOText(-1,12,COL_YELLOW,COL_RED," Fixture List ");
    h = d->FirstMatchHome;
    for (i = 0;i < d->Fixtures;i++)
    {
        x = (i < (d->Fixtures+1)/2) ? 1:17;
        y = (i % ((d->Fixtures+1)/2)) + 4;
        x = x* 8-4;y *= 8;
        sprintf(_Temp,"%d",i+1);
        IOText(x,y,COL_YELLOW,COL_BLACK,_Temp);
        if (d->FixtureList[i] >= 0)
        {
            sprintf(_Temp,"%s %c",
                d->Teams[d->FixtureList[i]].Name,h ? 'H':'A');
            h = (h == 0);
        }
        else
        {
            switch(-d->FixtureList[i])
            {
                case 7: strcpy(_Temp,"FA Cup Semis");break;
                case 8: strcpy(_Temp,"FA Cup Final");break;
                default: sprintf(_Temp,"FA Cup R%d",-d->FixtureList[i]);break;
            }
            if (g->OutOfCup) strcpy(_Temp,"No match");
        }
        c = (d->Played == i) ? COL_CYAN:COL_GREEN;
        if (i < d->Played) c = COL_BLUE;
        IOText(x+24,y,c,COL_BLACK,_Temp);
    }
    INITPressEnter();
}


/************************************************************************/
/*																		*/
/*						Press enter to continue message					*/
/*																		*/
/************************************************************************/

void INITPressEnter(void)
{
    IOText(-1,184,COL_CYAN,COL_BLUE," Press Enter to Continue ");
    while (IOInkey() != 13) {}
}


/************************************************************************/
/*																		*/
/*						Generate the sort array							*/
/*																		*/
/************************************************************************/

void INITGenerateSortArray(GAME *g)
{
    int n1,n2,Redo,i,Swap;
    DIVISION *d = &(g->Division[g->Div]);
    for (i = 0;i < d->NoTeams;i++)                /* Set sort index, calc points */
    {
        d->SortIndex[i] = i;
        d->Teams[i].Points =                      /* Points first, then gd, then goals */
            d->Teams[i].Won * 3 + d->Teams[i].Drawn;
        d->Teams[i].SortSc = (long)(d->Teams[i].Points) * 1000 + 500;
        d->Teams[i].SortSc += d->Teams[i].GoalsFor - d->Teams[i].GoalsAgainst;
        d->Teams[i].SortSc = (d->Teams[i].SortSc*1000)+d->Teams[i].GoalsFor;
    }
    do                                            /* Bubble sort the SortIndex array */
    {
        Redo = 0;
        for (i = 0;i < d->NoTeams-1;i++)
        {
            n1 = d->SortIndex[i];n2 = d->SortIndex[i+1];
            Swap = (d->Teams[n1].SortSc < d->Teams[n2].SortSc);
            if (d->Teams[n1].SortSc == d->Teams[n2].SortSc)
                Swap = strcmp(d->Teams[n1].Name,d->Teams[n2].Name) > 0;
            if (Swap)
            {
                Redo = d->SortIndex[i];
                d->SortIndex[i] = d->SortIndex[i+1];
                d->SortIndex[i+1] = Redo;
                Redo = 1;
            }
        }
    } while (Redo != 0);
    for (i = 0;i < d->NoTeams;i++)
    {
        d->Teams[d->SortIndex[i]].LeaguePos = i+1;
    }
}


/************************************************************************/
/*																		*/
/*						Display the league table						*/
/*																		*/
/************************************************************************/

void INITDisplayDivision(GAME *g)
{
    int i,n,y = 0,TwoPage;
    char _Temp[32];
    DIVISION *d = &(g->Division[g->Div]);
    TEAMINFO *t;
    TwoPage = (d->NoTeams > 17);
    INITGenerateSortArray(g);
    for (i = 0;i < d->NoTeams;i++)
    {
        if (i == 0 || (TwoPage && i == d->NoTeams/2))
        {
            y = 192/2-4*(TwoPage ? d->NoTeams/2:d->NoTeams)-8;
            if (i != 0) INITPressEnter();
            IOClear(COL_BLACK);
            sprintf(_Temp," %s ",g->Division[g->Div].DivName);
            IOText(-1,4,COL_YELLOW,COL_RED,_Temp);
            IOText(84,y,COL_WHITE,COL_BLACK,"P  W  D  L  F  A");
            IOText(232,y,COL_WHITE,COL_BLACK,"Pts");
            y+=8;
        }
        n = d->SortIndex[i];
        t = &(d->Teams[n]);
        IOText(0,y,(n == d->Team) ? COL_YELLOW:COL_RED,COL_BLACK,d->Teams[n].Name);
        sprintf(_Temp,"%-2d %-2d %-2d %-2d %-3d%-3d",
            t->Won+t->Drawn+t->Lost,t->Won,t->Drawn,t->Lost,t->GoalsFor,t->GoalsAgainst);
        IOText(84,y,COL_BLUE,COL_BLACK,_Temp);
        sprintf(_Temp,"%3d",t->Points);
        IOText(232,y,(n == d->Team) ? COL_YELLOW:COL_RED,COL_BLACK,_Temp);
        y+=8;
        if ((i == g->MoveCount-1 && g->Div > 0) ||
            (i == d->NoTeams-g->MoveCount-1 && g->Div < g->DivCount-1))
        {
            IOLine(0,y+1,127,y+1,COL_CYAN);
            IOLine(128,y+1,255,y+1,COL_CYAN);y += 2;
        }
    }
    INITPressEnter();
}
