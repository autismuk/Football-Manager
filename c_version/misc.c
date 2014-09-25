/************************************************************************/
/*																		*/
/*		Name:		MISC.C												*/
/*		Project:	Football Manager Remake								*/
/*		Purpose:	Miscellaneous Routines        						*/
/*		Author:		Paul Robson											*/
/*		Created:	12th December 2001									*/
/*		Updated:	18th December 2001									*/
/*																		*/
/************************************************************************/

#include "fm.h"                                   /* Standard header */

/************************************************************************/
/*																		*/
/*							Team Selection								*/
/*																		*/
/************************************************************************/

void MISCSelectTeam(GAME *g)
{
    int x,y,n,Div = -1,Found = 0;
    TEAMINFO t,*t1,*t2;
    char _Temp[32];
    while (Found == 0)
    {
        Div = Div+1;                              /* Next division */
        if (Div==g->DivCount) Div=0;              /* Loop round if at the end */
        IOClear(COL_BLACK);                       /* Display labels */
        sprintf(_Temp," %s ",g->Division[Div].DivName);
        IOText(-1,8,COL_YELLOW,COL_RED,_Temp);
        IOText(-1,148,COL_GREEN,COL_BLACK," Please Select a Team ");
        IOText(-1,158,COL_GREEN,COL_BLACK,"Press ENTER for more teams");
                                                  /* Display the teams */
        for (n = 0;n < g->Division[Div].NoTeams;n++)
        {
            x = (n % 2)*128+4;y = (n / 2)*10+24;
            sprintf(_Temp,"%d",n+1);IOText(x,y,COL_YELLOW,COL_BLACK,_Temp);
            IOText(x+24,y,COL_GREEN,COL_BLACK,g->Division[Div].Teams[n].Name);
        }

        n=(int)MENUGetInt(120,170,2)-1;           /* Get team */
        if (n >= 0 &&                             /* End loop if legitimate */
            n < g->Division[Div].NoTeams) Found = 1;
    }
/* t1 points to this,t2 to last team*/
    t1 = &(g->Division[Div].Teams[n]);
    t2 = &(g->Division[g->DivCount-1].Teams[0]);
    t = *t1;*t1 = *t2;*t2 = t;                    /* Relegate to bottom of league */
}


/************************************************************************/
/*																		*/
/*								Title Page								*/
/*																		*/
/************************************************************************/

void MISCTitle(void)
{
    IOClear(COL_BLACK);
    IOText(-1,4,COL_YELLOW,COL_RED,"                  ");
    IOText(-1,12,COL_YELLOW,COL_RED," Football Manager ");
    IOText(-1,20,COL_YELLOW,COL_RED,"                  ");
    IOText(-1,50,COL_CYAN,COL_BLACK,"A rewrite of the Sinclair");
    IOText(-1,60,COL_CYAN,COL_BLACK,"Spectrum Classic.");
    IOText(-1,90,COL_GREEN,COL_BLACK,"Written by Paul Robson 2001-2");
    IOText(-1,100,COL_GREEN,COL_BLACK,"Linux/SDL Port 2003");
    IOText(-1,150,COL_GREEN,COL_BLACK,"Original version by Kevin Toms");
    IOText(-1,160,COL_GREEN,COL_BLACK,"Addictive Games, 1982");
    INITPressEnter();
}


/************************************************************************/
/*																		*/
/*									Pay Bills							*/
/*																		*/
/************************************************************************/

void MISCBills(GAME *g)
{
    long Interest,Wages = 0;
    int i,y = 32;
    char _Temp[32];
    IOClear(COL_BLACK);
    IOText(-1,8,COL_YELLOW,COL_RED," Weekly Bills ");
    for (i = 0;i < g->PlayerCount;i++)            /* Calculate the wages */
        if (g->Player[i].InOurTeam)
            Wages = Wages + (long)(g->Player[i].Skill) * 10L * g->FinancialScaler;
    Interest = g->Loans/100;                      /* CAlculate interest */
    sprintf(_Temp,"Wage Bill %c%ld",96,Wages);
    IOText(-1,y,COL_GREEN,COL_BLACK,_Temp);y += 12;
    sprintf(_Temp,"Ground Rent %c%ld",96,g->GroundRent);
    IOText(-1,y,COL_GREEN,COL_BLACK,_Temp);y += 12;
    sprintf(_Temp,"Loan Interest %c%ld",96,Interest);
    IOText(-1,y,COL_GREEN,COL_BLACK,_Temp);y += 24;
    g->Cash = g->Cash - Wages -                   /* Take the money out */
        Interest - g->GroundRent;
    sprintf(_Temp,"Weekly Balance %c%ld",96,g->Cash);
    IOText(-1,y,(g->Cash < 0) ? COL_RED:COL_YELLOW,COL_BLACK,_Temp);y += 24;

    if (g->Cash <= 0)                             /* Borrow to make up the difference */
    {
        g->Loans += (-g->Cash);                   /* Do so */
        g->Cash = 0;
        IOText(-1,y,COL_MAGENTA,COL_BLACK,"Loan increased to pay the Bills");
        y+= 24;
        if (g->Loans > 250000L *                  /* If you borrow too much,game over */
            g->FinancialScaler)
        {
            IOText(-1,y,COL_YELLOW,COL_RED," The team is bankrupt ");
            IOText(-1,y+16,COL_YELLOW,COL_RED," The board have sacked you ");
            g->Sacked = 1;
        }
    }
#ifndef HISPEED
    INITPressEnter();
#endif
}


/************************************************************************/
/*																		*/
/*							Transfer Market								*/
/*																		*/
/************************************************************************/

void MISCTransfers(GAME *g)
{
    int pID,n;
    long Reqd,Bid;
    char _Temp[32];
    PLAYER *p;
    do                                            /* Find one who doesn't play for us */
    {
        pID = rand()%g->PlayerCount;
        p = &(g->Player[pID]);
    }
    while (p->InOurTeam != 0);
    do
    {
        IOClear(COL_BLACK);
        IOText(-1,8,COL_YELLOW,COL_RED," Transfer Market ");
        if (g->Available > 15)                    /* Max of 15 players */
        {
            IOText(-1,82,COL_CYAN,COL_BLACK,"You cannot buy any more players");
            IOText(-1,92,COL_CYAN,COL_BLACK,"16 is the maximum allowed");
            INITPressEnter();
            return;
        }
        MENUFinances(g,32);                       /* Display finances */
        n = 80;MENUPlayer(g,-1,&n);               /* Display player information */
        n = 90;MENUPlayer(g,pID,&n);
        IOText(-1,140,COL_GREEN,COL_BLACK,"Type your bid");
        Bid = MENUGetInt(104,150,6);
        if (Bid > g->Cash)                        /* Not enough cash */
        {
            IOText(-1,170,COL_CYAN,COL_BLACK," You do not have enough money ");
            INITPressEnter();
        }
        else                                      /* Bid feasible */
        if (Bid > 0)
        {                                         /* Calculate value required */
            Reqd = (long)(rand()%10) *
                Bid / (p->Value);
            if (Reqd <= 5)                        /* Not enough */
            {
                IOText(-1,170,COL_CYAN,COL_BLACK," Bid Refused ! ");
                p->Value = p->Value + (p->Value/5);
                INITPressEnter();
            }
            else                                  /* Successful bid */
            {
                p->Value =                        /* Reset the player value */
                    g->FinancialScaler * p->Skill * 5000;
                p->InOurTeam = 1;                 /* In the team and available */
                p->Status = AVAILABLE;
                sprintf(_Temp,"%s has joined your team",p->Name);
                IOText(-1,170,COL_YELLOW,COL_BLACK,_Temp);
                g->Cash -= Bid;                   /* Lose the cash */
                INITPressEnter();
                Bid = 0;                          /* Drops out the loop */
            }
        }
    } while (Bid > 0);                            /* Abandon it */
}


/************************************************************************/
/*																		*/
/*							Get a file name								*/
/*																		*/
/************************************************************************/

char *MISCGetFileName(char Transfer)
{
    int n,IsSave = (Transfer == 'S');
    FILE *f;
    static char _Temp[32];
    IOClear(COL_BLACK);
    sprintf(_Temp,"Do you want to %s your game ?",
        IsSave ? "Save":"Load");
    IOText(-1,88,COL_YELLOW,COL_BLACK,_Temp);
    if (MENUYesNo() == 0) return NULL;            /* Nope */

    IOText(-1,108,COL_CYAN,COL_BLACK,"Select a slot 0..9");
    do                                            /* Get the slot */
    n = IOInkey()-'0';
    while (n < 0 || n > 9);
    sprintf(_Temp,"fm%d.sav",n);                  /* Build file name */
    if (IsSave) return _Temp;                     /* No test if saving */
    f = fopen(_Temp,"rb");                        /* Loading, check okay */
    if (f == NULL)                                /* No file, try again */
        return MISCGetFileName(Transfer);
    fclose(f);
    return _Temp;

}
