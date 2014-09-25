/************************************************************************/
/*																		*/
/*		Name:		DRV_LINUX.C											*/
/*		Project:	Football Manager Remake								*/
/*		Purpose:	Driver (Linux SDL)                                  */
/*		Author:		Paul Robson											*/
/*		Created:	7th December 2001									*/
/*		Updated:	1st February 2003									*/
/*																		*/
/************************************************************************/

#include "fm.h"                                   /* Standard header */

SDL_Surface *Screen,*ScreenBuffer;
SDL_AudioSpec AudioSpec;

static Uint32 _HWSpecToSDL(int Colour);

int xOffset,yOffset,Scale;
int IsWhiteNoise,AudioFound;

void HWFillAudio(void *Data,Uint8 *Stream,int Size);

/************************************************************************/
/*																		*/
/*			Tables converting to and from the IBM Colours				*/
/*																		*/
/************************************************************************/

static int ToHW[16] = { 0,12,10,14,9,13,11,15,2,7,7,7,7,7,7,7 };
static int FromHW[16];

/************************************************************************/
/*																		*/
/*						Initialise the driver							*/
/*																		*/
/************************************************************************/

void HWInitialise(void)
{
    unsigned int i,xs,ys;
    char Msg[128];
    Screen = ScreenBuffer = NULL;

    for (i = 0;i < 16;i++) FromHW[i]=-1;          /* Create HW->Logical table */
    for (i = 0;i < 16;i++) FromHW[ToHW[i]] = i;

    if (SDL_Init(SDL_INIT_VIDEO|SDL_INIT_AUDIO)   /* Try to start up SDL */
                                        == -1) MERROR(); 
    atexit(SDL_Quit);                             /* What happens on exit */

    Screen = SDL_SetVideoMode(Glo.xSize,Glo.ySize,Glo.Depth,SDL_SWSURFACE);
    if (Screen == NULL) MERROR();

    ScreenBuffer = SDL_CreateRGBSurface(SDL_SWSURFACE,
                                        Screen->w,Screen->h,
                                        Screen->format->BytesPerPixel*8,0,0,0,0);
    if (ScreenBuffer == NULL) MERROR();
    SDL_EnableUNICODE(1);
    sprintf(Msg,"Football Manager %s",VERSION);
    SDL_WM_SetCaption(Msg,NULL);
    xs = Glo.xSize/256;ys = Glo.ySize/192;        /* Calculate working scale */
    Scale = (xs > ys) ? ys : xs;
    xOffset = (Glo.xSize-256*Scale)/2;            /* And frame */
    yOffset = (Glo.ySize-192*Scale)/2;

    AudioSpec.freq = 11025;                       /* Audio frequency */
    AudioSpec.format = AUDIO_U8;
    AudioSpec.channels = 1;
    AudioSpec.samples = 1024;
    AudioSpec.callback = HWFillAudio;
    AudioSpec.userdata = NULL;
    AudioFound = (SDL_OpenAudio(&AudioSpec,NULL) >= 0);
}


/************************************************************************/
/*																		*/
/*							Clear the screen							*/
/*																		*/
/************************************************************************/

void HWClear(int Col)
{
    MASSERT(Screen != NULL);
    SDL_FillRect(Screen,NULL,_HWSpecToSDL(Col));
}


/************************************************************************/
/*																		*/
/*						Terminate the driver							*/
/*																		*/
/************************************************************************/

void HWTerminate(void)
{
    if (AudioFound) SDL_CloseAudio();
}


/************************************************************************/
/*																		*/
/*								Put a pixel								*/
/*																		*/
/************************************************************************/

void HWPut(int x,int y,int Colour)
{
    SDL_Rect rc;
    rc.x = x*Scale+xOffset;rc.y = y*Scale+yOffset;rc.w = rc.h = Scale;
    SDL_FillRect(Screen,&rc,_HWSpecToSDL(Colour));
}

/************************************************************************/
/*                                                                      */
/*              Convert Speccy Colour to SDL Colour format              */
/*                                                                      */
/************************************************************************/

static Uint32 _HWSpecToSDL(int Colour)
{
    int r,g,b,l;
    Colour = ToHW[Colour & 15];                   /* Convert colour to hw colour */
    l = (Colour & 0x8) ? 255:128;
    r = (Colour & 4) ? l:0;
    g = (Colour & 2) ? l:0;
    b = (Colour & 1) ? l:0;
    return SDL_MapRGB(Screen->format,r,g,b);
}

/************************************************************************/
/*                                                                      */
/*                          Update the display                          */
/*                                                                      */
/************************************************************************/

void HWUpdate(void)
{
    SDL_UpdateRect(Screen,0,0,Screen->w,Screen->h);
}

/************************************************************************/
/*																		*/
/*					Read the time in milliseconds						*/
/*																		*/
/************************************************************************/

long HWClock(void)
{
    return SDL_GetTicks();
}


/************************************************************************/
/*																		*/
/*					Get a keystroke	if there is one						*/
/*																		*/
/************************************************************************/

int  HWInkey(void)
{
    SDL_Event Event;
    int ch;
    HWUpdate();
    if (SDL_PollEvent(&Event) == 0) return 0;
    if (Event.type != SDL_KEYDOWN) return 0;
    ch = Event.key.keysym.unicode;
    if (ch & 0xFF80) return 0;
    ch = ch & 0x7F;ch = toupper(ch);
    return ch;
}


/************************************************************************/
/*																		*/
/*							  Kick/Crowd sound							*/
/*																		*/
/************************************************************************/

void HWSound(int Delay,int WhiteNoise)
{
    long t;
    if (AudioFound == 0) return;
    if (Delay == 0) Delay = 80;
    IsWhiteNoise = WhiteNoise;
    SDL_PauseAudio(0);
    t = HWClock()+Delay;
    while (HWClock() < t) {};
    SDL_PauseAudio(1);
}


/************************************************************************/
/*																		*/
/*						Copy to or from the backbuffer					*/
/*																		*/
/************************************************************************/

void HWCopy(int Dir)
{
    SDL_Rect rc,rc2;
    rc.x = rc.y = 0;rc.w = Screen->w;rc.h = Screen->h;rc2 = rc;
    switch(Dir)
    {
        case COPYTOBB:
            SDL_BlitSurface(Screen,&rc,ScreenBuffer,&rc2);
            break;
        case COPYFROMBB:
            SDL_BlitSurface(ScreenBuffer,&rc,Screen,&rc2);
            break;
    }
}


/************************************************************************/
/*																		*/
/*				Character drawing function (optional)					*/
/*																		*/
/************************************************************************/

int HWXChar(int x,int y,int Ink,int Paper,int Char)
{
    SDL_Rect rc;
    if (Scale == 1) return 0;                     /* IO Layer does it if scale is 1 */
    rc.x = x * Scale + xOffset;
    rc.y = y * Scale + yOffset;
    rc.w = rc.h = 8 * Scale;
    if (Paper >= 0) SDL_FillRect(Screen,&rc,_HWSpecToSDL(Paper));
    FONTChar(Screen,&rc,_HWSpecToSDL(Ink),Char);
    return 1;
}


/************************************************************************/
/*																		*/
/*					Line drawing function (optional)					*/
/*																		*/
/************************************************************************/

int HWXLine(int x1,int y1,int x2,int y2,int Colour)
{
    x1++;x2++;y1++;y2++;Colour++;                 /* Warnings */
    return 0;                                     /* IO Layer does it */
}

/************************************************************************/
/*																		*/
/*                       Replaced the GOAL display                      */
/*																		*/
/************************************************************************/


void HWDisplayGoal(void)
{
    SDL_Rect rc;
    rc.x = xOffset;rc.y = yOffset;rc.w = 32*8*Scale;rc.h = 8*4*Scale;
    SDL_FillRect(Screen,&rc,SDL_MapRGB(Screen->format,255,0,0));
    FONTString(Screen,&rc,SDL_MapRGB(Screen->format,255,255,0)," GOAL ");
    HWUpdate();
}


void HWFillAudio(void *Data,Uint8 *Stream,int Size)
{
    int i;
    for (i = 0;i < Size;i++)
        if (IsWhiteNoise)
            Stream[i] = rand();
        else
            Stream[i] = (i & 32) ? 255:0;
}
