/************************************************************************/
/*																		*/
/*		Name:		EOS.C												*/
/*		Project:	Football Manager Remake								*/
/*		Purpose:	End of Season Code									*/
/*		Author:		Paul Robson											*/
/*		Created:	18th December 2001									*/
/*		Updated:	18th December 2001									*/
/*																		*/
/************************************************************************/

#include "fm.h"                                   /* Standard header */

static void _EOSSwapTeam(GAME *g,TEAMINFO *tMove,int NewDiv);

/************************************************************************/
/*																		*/
/*						End of season stuff								*/
/*																		*/
/************************************************************************/

void EOSEndSeason(GAME *g)
{
    DIVISION *d = &(g->Division[g->Div]);
    char _Temp[42],_Name[32];
    int i,j,ODiv,OPos;
    long n;

    if (d->Played<d->Fixtures) return;            /* Not completed the season */

    IOClear(COL_BLACK);                           /* End of season message */
    IOText(-1,8,COL_WHITE,COL_RED," End of Season ");

    ODiv = g->Div;                                /* Remember performance */
    OPos = d->Teams[d->Team].LeaguePos;
    strcpy(_Name,d->Teams[d->Team].Name);

    g->Seasons++;                                 /* One more season */
    n = (d->NoTeams-OPos+1) +                     /* Calculate new score */
        g->LastCupRound + 2 * g->Div;
    g->Score = g->Score + n;                      /* Add to overall score */
    n = n * g->FinancialScaler * 5000;            /* Make it a cash bonus */
    g->Cash += n;                                 /* Add it on */
    sprintf(_Temp,"Cash Bonus %c%ld",96,n);
    IOText(-1,88,COL_YELLOW,COL_BLACK,_Temp);
    INITPressEnter();
    INITDisplayDivision(g);                       /* Display the division */

    for (i = 0;i < g->DivCount;i++)               /* Use the scores as "already sel." */
        for (j = 0;j < g->Division[i].NoTeams;j++)
    {
        g->Division[i].Teams[j].Score = 0;
        g->Division[i].Teams[j].HomeTeam = 0;
    }

    d->Teams[d->Team].HomeTeam = 1;               /* Mark us */
    IOClear(COL_BLACK);                           /* Display promoted/relegated */
    sprintf(_Temp," %s ",d->DivName);
    IOText(-1,8,COL_YELLOW,COL_RED,_Temp);
    for (i = 0;i < d->NoTeams;i++)                /* Work through the teams */
    {
        if ((d->Teams[i].LeaguePos <= g->MoveCount && g->Div != 0) ||
            d->Teams[i].LeaguePos == 1)
        {
            strcpy(_Temp,d->Teams[i].Name);
            if (d->Teams[i].LeaguePos == 1)
                strcat(_Temp," are champions");
            else
                strcat(_Temp," are promoted");
            IOText(-1,32+d->Teams[i].LeaguePos*12,COL_YELLOW,COL_BLACK,_Temp);
            if (g->Div > 0)                       /* Promote one team */
                _EOSSwapTeam(g,&(d->Teams[i]),g->Div-1);
        }
        if (g->Div < g->DivCount-1 &&
            d->Teams[i].LeaguePos > d->NoTeams-g->MoveCount)
        {
            sprintf(_Temp,"%s%s",d->Teams[i].Name," are relegated");
            IOText(-1,102+(d->NoTeams-d->Teams[i].LeaguePos)*12,
                COL_RED,COL_BLACK,_Temp);
            _EOSSwapTeam(g,                       /* Relegate one team */
                &(d->Teams[i]),g->Div+1);
        }
    }
    INITPressEnter();

    if (ODiv == 0 && OPos == 1)                   /* Check for league champs */
    {
        IOClear(COL_BLACK);
        sprintf(_Temp," *** %s are league champions *** ",_Name);
        IOText(-1,88,COL_WHITE,COL_RED,_Temp);
        INITPressEnter();
    }

    for (i = 0;i < g->DivCount;i++)               /* Find us now */
        for (j = 0;j < g->Division[i].NoTeams;j++)
            if (g->Division[i].Teams[j].HomeTeam)
            {
                g->Div = i;
                g->Division[i].Team = j;
            }
    INITNewSeason(g);                             /* Start a new season */
}


/************************************************************************/
/*																		*/
/*			Swap given team with team in other division					*/
/*																		*/
/************************************************************************/

static void _EOSSwapTeam(GAME *g,TEAMINFO *tMove,int NewDiv)
{
    DIVISION *nd = &(g->Division[NewDiv]);
    TEAMINFO *t,ts;
    int n;
    do                                            /* Find one not already done ! */
    n = rand()%(nd->NoTeams);
    while (nd->Teams[n].Score != 0);
    t = &(nd->Teams[n]);                          /* Get pointer to it */
    ts = *t;*t = *tMove;*tMove = ts;              /* Swap them */
    t->Score = tMove->Score = 1;                  /* Stop any more swapping */
}
