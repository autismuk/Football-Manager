####### kdevelop will overwrite this part!!! (begin)##########
bin_PROGRAMS = fm

## INCLUDES were found outside kdevelop specific part

fm_SOURCES = font.c misc.c menu.c matchday.c match.c main.c io.c init.c fm.c eos.c drv_linux.c 
fm_LDADD   = 


EXTRA_DIST = drv_linux.c eos.c fm.c fm.h game.dat init.c io.c main.c match.c matchday.c menu.c misc.c font.c 

install-data-local:
	$(mkinstalldirs) /usr/share/fm/
	$(INSTALL_DATA) $(srcdir)/game.dat /usr/share/fm/game.dat

uninstall-local:
	-rm -f /usr/share/fm/game.dat

####### kdevelop will overwrite this part!!! (end)############
# set the include path found by configure
INCLUDES= $(all_includes)

# the library search path.
fm_LDFLAGS = $(all_libraries) 
                                                                                
