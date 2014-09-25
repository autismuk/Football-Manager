/************************************************************************/
/*																		*/
/*		Name:		FM.H												*/
/*		Project:	Football Manager Remake								*/
/*		Purpose:	Include file (generic)								*/
/*		Author:		Paul Robson											*/
/*		Created:	7th December 2001									*/
/*		Updated:	7th December 2001									*/
/*																		*/
/************************************************************************/

#include <stdio.h>                                /* Common include files */
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <math.h>
#include <SDL.h>
#include "config.h"

#define MASSERT(x)  if (!(x)) MERROR()            /* Asserts, errors */
#define MERROR()    IOError(__LINE__,__FILE__)

#define MAXTEAMS    (24)                          /* Max teams per division */
#define MAXPLAYERS  (32)                          /* Max players available */
#define DIVISIONS   (6)                           /* Number of divisions */

typedef struct _Global
{
    int xSize,ySize,Depth;
} GLOBAL;

extern GLOBAL Glo;                                /* Global values */

typedef struct _Coord                             /* Coordinate structure */
{
    int x,y;
} COORD;

typedef struct _TeamInfo                          /* Team basic information */
{
    char Name[16];                                /* Teams name */
    int  Won,Drawn,Lost;                          /* Table information */
    int  GoalsFor,GoalsAgainst;                   /* Goals scored etc. */
    int  Points;                                  /* Points total */
    int  Colour;                                  /* Teams shirt colour */
    int  Score;                                   /* Teams score this match */
    long SortSc;                                  /* Sorting score */
    int  HomeTeam;                                /* Home team this match ? */
    int  LeaguePos;                               /* League Position */
} TEAMINFO;

typedef struct _Division                          /* Division, not sorted by pts */
{
    int  Played;                                  /* Matches played in this division */
    int  NoTeams;                                 /* Teams in this division */
    int  Team;                                    /* Index of our team */
    char DivName[16];                             /* Name of Division */
    TEAMINFO Teams[MAXTEAMS];                     /* Teams, up to 24 in division */
    int  SortIndex[MAXTEAMS];                     /* Sorting array */
    int  Fixtures;                                /* Number of fixtures for our team */
    int  FixtureList[MAXTEAMS+12];                /* Fixtures */
    int  FirstMatchHome;                          /* Next match at home ? */
} DIVISION;

enum PStatus { AVAILABLE,PICKED,INJURED };
enum Position { DEFENCE='d',MIDFIELD='m',ATTACK='a' };

typedef struct _Player                            /* Player record */
{
    char Name[16];                                /* Players name */
    enum PStatus Status;                          /* Status */
    enum Position Pos;                            /* Position */
    int  InOurTeam;                               /* Is player in our team ? */
    int  Energy,Skill;                            /* Energy and skill */
    long Value;                                   /* Current value */
} PLAYER;

typedef struct _Game
{
    PLAYER Player[MAXPLAYERS];                    /* Players */
    DIVISION Division[DIVISIONS];                 /* Divisions */
    int    Div;                                   /* Our current division */
    int    PlayerCount;                           /* Number of players */
    int    DivCount;                              /* Number of divisions */
    long   Cash;                                  /* Money we have */
    long   Loans;                                 /* Current loans */
    int    Skill;                                 /* Skill level */
    int    OutOfCup;                              /* Out of cup flag */
    int    FinancialScaler;                       /* Finance multiplier */
    int    Morale;                                /* Morale */
    long   Score,Seasons;                         /* Scoring */
    long   GroundRent;                            /* Ground Rent */
    int    Sound;                                 /* Sound on ? */
    long   Receipts;                              /* Receipts */
    long   CurrentCrowd;                          /* Current Crowd */
    int    Picked,Injured,Available;              /* Counters for team */
    int    MoveCount;                             /* Number of up/down movers */
    int    LastCupRound;                          /* Last cup round played in */
    int    Sacked;                                /* Sacked Flag */
} GAME;

void IOInitialise(void);                          /* IO Functions Layer */
void IOTerminate(void);
void IOPut(int x,int y,int Colour);
long IOClock(void);
int  IOInkey(void);
void IOClear(int Col);
void IOError(int Line,char *File);
void IOChar(int x,int y,int Ink,int Paper,int Char);
void IOLine(int x1,int y1,int x2,int y2,int Colour);
void IOText(int x1,int y1,int Ink,int Paper,char *Text);
void IOSound(int Delay,int WhiteNoise);
void IOCopy(int Dir);

void HWInitialise(void);                          /* Hardware Layer */
void HWTerminate(void);
void HWPut(int x,int y,int Colour);
long HWClock(void);
int  HWInkey(void);
void HWClear(int Col);
void HWSound(int Delay,int WhiteNoise);
void HWCopy(int Dir);
int  HWXChar(int x,int y,int Ink,int Paper,int Char);
int  HWXLine(int x1,int y1,int x2,int y2,int Colour);
void HWUpdate(void);
void HWDisplayGoal(void);

void MAMatchTest(void);
void MAOneAttack(TEAMINFO *Attack,TEAMINFO *Defend,int FlipX,int SoundOn,int Speed);

void INITNewGame(GAME *g);
void INITNewSeason(GAME *g);
void INITFixtureList(GAME *g);
void INITPressEnter(void);
void INITGenerateSortArray(GAME *g);
void INITDisplayDivision(GAME *g);

int  MENUMain(GAME *g);
void MENUPlayer(GAME *g,int n,int *y);
long MENUGetInt(int x,int y,int Size);
int  MENUYesNo(void);
void MENUFinances(GAME *g,int y);
void MENUSkillLevel(GAME *g);

void MDRun(GAME *g);

void MISCSelectTeam(GAME *g);
void MISCTitle(void);
void MISCBills(GAME *g);
void MISCTransfers(GAME *g);
char *MISCGetFileName(char Transfer);

void EOSEndSeason(GAME *g);

void FONTChar(SDL_Surface *s,SDL_Rect *rc,Uint32 Colour,int Char);
void FONTString(SDL_Surface *s,SDL_Rect *rc,Uint32 Colour,char *Msg);

int RunFootballManager(int argc,char *argv[]);

extern unsigned char SpecFont[];

#define KEY_BS      (8)                           /* Control keys */
#define KEY_CR      (13)

#define COL_BLACK   (0)                           /* Colour constants */
#define COL_RED     (1)
#define COL_GREEN   (2)
#define COL_YELLOW  (3)
#define COL_BLUE    (4)
#define COL_MAGENTA (5)
#define COL_CYAN    (6)
#define COL_WHITE   (7)
#define COL_DKGREEN (8)
#define COL_GREY    (9)

#define COPYTOBB    (1)
#define COPYFROMBB  (2)


