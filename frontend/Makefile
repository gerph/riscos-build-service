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
COG_SIZE = ${ICON_SIZE}
BUTTON_SIZE = ${ICON_SIZE}

#.PHONY: all static all_hsc

all: dirs static all_hsc
dirs:
	mkdir -p ${DESTDIR}
	mkdir -p ${DESTDIR}/icons

static: \
		${DESTDIR}/.htaccess \
 	 	${DESTDIR}/ansi_up.js \
 	 	${DESTDIR}/site.css \
 	 	${DESTDIR}/favicon.ico \
 	 	${DESTDIR}/icons/file_ff8.png \
 	 	${DESTDIR}/icons/file_ffa.png \
 	 	${DESTDIR}/icons/file_ffc.png \
 	 	${DESTDIR}/icons/file_xxx.png \
 	 	${DESTDIR}/icons/cog.png \
 	 	${DESTDIR}/icons/patched.png \
 	 	${DESTDIR}/icons/upload.png \
 	 	${DESTDIR}/icons/download.png \
 	 	${DESTDIR}/icons/build.png \
 	 	${DESTDIR}/icons/nextstep.png \
 	 	${DESTDIR}/icons/menu.png \

${DESTDIR}/icons/file_%.png: icons/file_%.svg
	./make-icon.sh --inset 1 $? $@ ${FILETYPE_SIZE}

${DESTDIR}/icons/%.png: icons/%.svg
	./make-icon.sh --trim --inset 1 $? $@ ${ICON_SIZE}

${DESTDIR}/icons/upload.png: icons/140279.svg
	./make-icon.sh --trim $? $@ ${BUTTON_SIZE}

${DESTDIR}/icons/download.png: icons/140283.svg
	./make-icon.sh --trim $? $@ ${BUTTON_SIZE}

# 2746034 is another build icon; a crane, but I didn't feel as comfortable with that one.
${DESTDIR}/icons/build.png: icons/2746034.svg
	./make-icon.sh --trim $? $@ ${BUTTON_SIZE}

${DESTDIR}/icons/nextstep.png: icons/1920786.svg
	./make-icon.sh --trim $? $@ ${BUTTON_SIZE}

${DESTDIR}/icons/menu.png: icons/2328436.svg
	./make-icon.sh --trim $? $@ ${BUTTON_SIZE}

${DESTDIR}/favicon.ico: ${DESTDIR}/icons/patched.png
	convert $? -define icon:auto-resize=64,48,32,16 $@

${DESTDIR}/icons/patched.png: ${DESTDIR}/icons/cog.png ${DESTDIR}/icons/plaster.png
	convert -size ${COG_SIZE}x${COG_SIZE} ${DESTDIR}/icons/cog.png -gravity center \( ${DESTDIR}/icons/plaster.png -resize 85% \) -composite $@

../dest/.htaccess: htaccess
	cp $? $@


../dest/%: %
	cp $? $@

.SUFFIXES:
.SUFFIXES: .html .hsc

../dest/%.html: %.hsc
	hsc $(HSCFLAGS) $<

# --- DO NOT MODIFY THIS LINE -- hsc-dependencies follow ---

# dependencies updated: Sunday 15-Mar-2020 20:48:26

all_hsc : ../dest/about.html ../dest/api.html ../dest/notfound.html \
    ../dest/index.html ../dest/fileformat.html

../dest/about.html : about.hsc ../macros.hsc

../dest/api.html : api.hsc ../macros.hsc

../dest/notfound.html : notfound.hsc ../macros.hsc

../dest/index.html : index.hsc ../macros.hsc

../dest/fileformat.html : fileformat.hsc ../macros.hsc

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
