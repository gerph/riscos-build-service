# Makefile to build the front end

DESTDIR = ../dest
PRJFILE = ../hsc.project
PREFS = ../hsc.prefs
STDINC  = ../macros.hsc
# ignore warnings about missing files
# ignore=21
# smartent (used to convert to entities automatically)
# getsize
HSCFLAGS = ignore=49 msgbrowser=throwback \
		   prefsfile=$(PREFS) \
		   xhtml \
		   prjfile=$(PRJFILE) to=$(DESTDIR)/ $(STDINC) serverdir=$(DESTDIR)
# ena=notes

ICON_SIZE = 128
FILETYPE_SIZE = ${ICON_SIZE}
COG_SIZE = 128

#.PHONY: all static all_hsc

all: dirs static all_hsc
dirs:
	mkdir -p ${DESTDIR}
	mkdir -p ${DESTDIR}/icons

static: ${DESTDIR}/ansi_up.js \
 	 	${DESTDIR}/icons/file_ff8.png \
 	 	${DESTDIR}/icons/file_ffa.png \
 	 	${DESTDIR}/icons/file_ffc.png \
 	 	${DESTDIR}/icons/cog.png \
 	 	${DESTDIR}/icons/patched.png \

${DESTDIR}/icons/file_%.png: icons/file_%.svg
	./make-icon.sh --inset 1 $? $@ ${FILETYPE_SIZE}

${DESTDIR}/icons/%.png: icons/%.svg
	./make-icon.sh --trim --inset 1 $? $@ ${ICON_SIZE}

${DESTDIR}/icons/patched.png: ${DESTDIR}/icons/cog.png ${DESTDIR}/icons/plaster.png
	convert -size ${COG_SIZE}x${COG_SIZE} ${DESTDIR}/icons/cog.png -gravity center \( ${DESTDIR}/icons/plaster.png -resize 85% \) -composite $@


../dest/%: %
	cp $? $@

.SUFFIXES:
.SUFFIXES: .html .hsc

../dest/%.html: %.hsc
	hsc $(HSCFLAGS) $<

# --- DO NOT MODIFY THIS LINE -- hsc-dependencies follow ---

# dependencies updated: Saturday 14-Mar-2020 12:34:02

all_hsc : ../dest/index.html

../dest/index.html : index.hsc ../macros.hsc

# --- DO NOT MODIFY THIS LINE -- hsc-dependencies precede ---

depend :
	hscdepp file=../Makefile prjfile=$(PRJFILE) verbose

add :
	hsc $(HSCFLAGS) $(INCLUDE) from=$(FILE)
	hscdepp file=../Makefile prjfile=$(PRJFILE) verbose

delete :
	hscpitt delete $(FILE) PRJFILE=$(PRJFILE)
	hscdepp file=../Makefile prjfile=$(PRJFILE) verbose

clean :
	-rm -rf "${DESTDIR}"
