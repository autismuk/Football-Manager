/***************************************************************************
                          main.c  -  main program
                             -------------------
    begin                : Wed Dec 18 15:52:46 GMT 2002
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

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include "fm.h"

GLOBAL Glo;

static int _GLOParameter(int argc,char **argv,char *Name,int Default,int IsHelp);

#define PARAM(name,default) _GLOParameter(argc,argv,name,default,Help)

int main(int argc, char *argv[])
{
    int i,Help;
    MASSERT(argc > 0);
    MASSERT(argv != NULL);

    Help = 0;
    for (i = 0;i < argc;i++)
        if (strcmp(argv[i],"-h") == 0 || strcmp(argv[i],"--help") == 0) Help = 1;

    if (Help) printf("Parameters");
    Glo.xSize = PARAM("xscreen",1024);      // Screen Size and Depth
    Glo.ySize = PARAM("yscreen",768);
    Glo.Depth = PARAM("depth",16);

    if (Help)                               // Help display, do nothing else.
    {                                       // Parameters are printed via PARAM Macro.
        printf("\n\n");
        exit(0);
    }
    RunFootballManager(argc,argv);      /* It had to have main.c & I couldn't be bothered to figure it out */
    return EXIT_SUCCESS;
}

static int _GLOParameter(int argc,char **argv,char *Name,int Default,int IsHelp)
{
    int i;
    char *p;
    if (IsHelp)                                 // Help mode - print out information
    {
        printf(" --%s [%d]",Name,Default);
        return Default;
    }
    for (i = 0;i < argc;i++)                    // else look  for the parameter and evaluate it.
    {
        p = argv[i];
        if (p[0] == '-' && p[1] == '-')
            if (strcmp(p+2,Name) == 0) return atoi(argv[i+1]);
    }
    return Default;
}
