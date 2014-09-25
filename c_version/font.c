/***************************************************************************
                     font.c - scalable bitmapped fonts
                             -------------------
    begin                : Sun Aug 25 2002
    copyright            : (C) 2002 by Paul Robson
    email                : autismuk@autismuk.freeserve.co.uk
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#include "fm.h"

static int _FONTPixelSet(char *Data,int x,int y);
static void _FONTAngleDraw(SDL_Surface *s,SDL_Rect *rc,int w,int h,Uint32 Colour);

void FONTChar(SDL_Surface *s,SDL_Rect *rc,Uint32 Colour,int Char)
{
    int x,y,w,h;
    char *GfxData;
    SDL_Rect rc2;
    MASSERT(s != NULL);                     // Checks
    MASSERT(rc != NULL);
    w = rc->w/8;h = rc->h/8;                // work out the box sizes
    MASSERT(w != 0 && h != 0);              // At least one pixel !
    if (Char == ' ') return;                // Don't do anything for spaces

    GfxData = SpecFont + (Char & 0x7F) * 8;

    for (x = 0;x < 8;x++)                   // Work through the 64 pixel array
        for (y = 0;y < 8;y++)
            if (_FONTPixelSet(GfxData,x,y)) // If set.
            {
                rc2.x = rc->x+w * x;        // Calculate the bounding rectangle
                rc2.y = rc->y+h*y;
                rc2.w = w;rc2.h = h;
                SDL_FillRect(s,&rc2,Colour);// Draw an pixel there
                                            // Neaten the diagonals
                if (_FONTPixelSet(GfxData,x,y+1) == 0 &&
                    _FONTPixelSet(GfxData,x-1,y) == 0 &&
                    _FONTPixelSet(GfxData,x-1,y+1) != 0)
                            _FONTAngleDraw(s,&rc2,-w,h,Colour);
                if (_FONTPixelSet(GfxData,x,y+1) == 0 &&
                    _FONTPixelSet(GfxData,x+1,y) == 0 &&
                    _FONTPixelSet(GfxData,x+1,y+1) != 0)
                            _FONTAngleDraw(s,&rc2,w,h,Colour);
            }
 }

//
//                  Check if pixel is set in character
//
static int _FONTPixelSet(char *Data,int x,int y)
{
    if (x < 0 || y < 0 || x > 7 || y > 7) return 0;
    return (Data[y] & (0x80 >> x)) ? 1 : 0;
}

//
//  Draw an angled line - this stops the squared corners on diagonals showing
//
static void _FONTAngleDraw(SDL_Surface *s,SDL_Rect *rc,int w,int h,Uint32 Colour)
{
    int i,m;
    SDL_Rect rc3;
    MASSERT(s != NULL);                     // Checks
    MASSERT(rc != NULL);
    m = abs(w);if (abs(h) > m) m = abs(h);
    for (i = 0;i < m;i++)
    {
        rc3.x = rc->x + w * i / m;
        rc3.y = rc->y + h * i / m;
        rc3.w = rc->w;rc3.h = rc->h;
        SDL_FillRect(s,&rc3,Colour);
    }
}

//
//
//                                  Draw a string in a box
//
//
void FONTString(SDL_Surface *s,SDL_Rect *rc,Uint32 Colour,char *Msg)
{
    SDL_Rect rc2;
    int i;
    MASSERT(*Msg != '\0');
    for (i = 0;i < strlen(Msg);i++)
    {
        rc2.x = rc->x + rc->w * i / strlen(Msg);
        rc2.y = rc->y;
        rc2.w = rc->w / strlen(Msg);
        rc2.h = rc->h;
        FONTChar(s,&rc2,Colour,Msg[i]);
    }
}
