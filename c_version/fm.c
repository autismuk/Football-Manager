/************************************************************************/
/*																		*/
/*		Name:		FM.C  												*/
/*		Project:	Football Manager Remake								*/
/*		Purpose:	Main Program       									*/
/*		Author:		Paul Robson											*/
/*		Created:	12th December 2001									*/
/*		Updated:	21st December 2001									*/
/*																		*/
/************************************************************************/

#include "fm.h"                                   /* Standard header */

GAME g;                                           /* The entire game is here ! */

// static void FixFixtureList(GAME *g);

/************************************************************************/
/*																		*/
/*								Main Program							*/
/*																		*/
/************************************************************************/

int RunFootballManager(int argc,char *argv[])
{
    FILE *f;
    char *FileName;
    IOInitialise();                               /* Initialise driver */
    INITNewGame(&g);                              /* Load game.dat etc. */
    MISCTitle();                                  /* Display title page */
    FileName = MISCGetFileName('L');              /* Load file ? */
    if (FileName != NULL)                         /* If so, load the file in */
    {
        f = fopen(FileName,"rb");
        MASSERT(f != NULL);
        fread(&g,sizeof(GAME),1,f);
        fclose(f);
    /* FixFixtureList(&g); */
    }
    else
    {
        MISCSelectTeam(&g);                       /* Select a team to play with */
        MENUSkillLevel(&g);                       /* Select the skill level */
        INITNewSeason(&g);                        /* Start a new season */
    }
    while (g.Sacked == 0 &&                       /* While keeping on playing */
        MENUMain(&g) == 0)
    {
        MDRun(&g);                                /* Play one game */
        MISCBills(&g);                            /* Pay bills and so on */
        if (g.Sacked == 0)                        /* Sacked on financial grounds */
        {
            MISCTransfers(&g);                    /* Buy players ? */
            EOSEndSeason(&g);                     /* End of Season Code */
        }
    }
    if (g.Sacked == 0)                            /* Not sacked ! */
    {
        FileName = MISCGetFileName('S');          /* Get save slot */
        if (FileName != NULL)                     /* If save selected, save */
        {
            f = fopen(FileName,"wb");
            MASSERT(f != NULL);
            fwrite(&g,sizeof(GAME),1,f);
            fclose(f);
        }
    }
    IOTerminate();                                /* Terminate Driver */
    return 0;
}

