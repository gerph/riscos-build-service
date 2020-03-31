# Makefile to build the front end

# Configurables:
ICON_SIZE = 128
FILETYPE_SIZE = ${ICON_SIZE}
COG_SIZE = ${ICON_SIZE}
BUTTON_SIZE = ${ICON_SIZE}

SUPPORT_C = true
SUPPORT_OBJASM = true
SUPPORT_PERL = true
SUPPORT_PASCAL = true
SUPPORT_BASTXT = true


# Main code
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
FLAGS = SUPPORT_C=${SUPPORT_C} \
        SUPPORT_OBJASM=${SUPPORT_OBJASM} \
        SUPPORT_PERL=${SUPPORT_PERL} \
        SUPPORT_PASCAL=${SUPPORT_PASCAL} \
        SUPPORT_BASTXT=${SUPPORT_BASTXT}

HSCFLAGS += $(subst =,:BOOL=,$(subst false,, ${FLAGS:SUPPORT_%=define "SUPPORT_%"}))
CPPFLAGS = ${FLAGS:SUPPORT_%=-DSUPPORT_%}

CODEMIRROR = ${DESTDIR}/codemirror/lib/codemirror.js \
             ${DESTDIR}/codemirror/lib/codemirror.css \
             ${DESTDIR}/codemirror/theme/liquibyte.css \
             ${DESTDIR}/codemirror/addon/mode/simple.js \
             ${DESTDIR}/codemirror/mode/jfpatch.js \
             ${DESTDIR}/colouring.js \

ifeq (${SUPPORT_C}, true)
CODEMIRROR += ${DESTDIR}/codemirror/mode/clike.js
endif
ifeq (${SUPPORT_OBJASM}, true)
CODEMIRROR += ${DESTDIR}/codemirror/mode/objasm.js
endif
ifeq (${SUPPORT_PERL}, true)
CODEMIRROR += ${DESTDIR}/codemirror/mode/perl.js
endif
ifeq (${SUPPORT_PASCAL}, true)
CODEMIRROR += ${DESTDIR}/codemirror/mode/pascal.js
endif
ifeq (${SUPPORT_BASTXT}, true)
CODEMIRROR += ${DESTDIR}/codemirror/mode/bbcbasic.js
endif


EXAMPLE_SOURCES=$(wildcard jfpatch-as-a-service-examples/jfpatch-files/*)

EXAMPLES = $(subst jfpatch-as-a-service-examples/jfpatch-files/,${DESTDIR}/examples/,${EXAMPLE_SOURCES})


#.PHONY: all static all_hsc

all: dirs static all_hsc
dirs:
	mkdir -p ${DESTDIR}
	mkdir -p ${DESTDIR}/icons
	mkdir -p ${DESTDIR}/images
	mkdir -p ${DESTDIR}/examples
	mkdir -p ${DESTDIR}/codemirror/lib
	mkdir -p ${DESTDIR}/codemirror/theme
	mkdir -p ${DESTDIR}/codemirror/mode
	mkdir -p ${DESTDIR}/codemirror/addon/mode

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
 	 	${DESTDIR}/icons/information.png \
 	 	${DESTDIR}/icons/load.png \
 	 	${DESTDIR}/icons/create.png \
 	 	${DESTDIR}/icons/upload.png \
 	 	${DESTDIR}/icons/download.png \
 	 	${DESTDIR}/icons/build.png \
 	 	${DESTDIR}/icons/nextstep.png \
 	 	${DESTDIR}/icons/menu.png \
 	 	${DESTDIR}/images/howitworks.png \
 	 	${DESTDIR}/images/howitworks.svg \
 	 	${CODEMIRROR} \
 	 	${EXAMPLES} \

${DESTDIR}/icons/file_%.png: icons/file_%.svg
	./make-icon.sh --inset 1 $? $@ ${FILETYPE_SIZE}

${DESTDIR}/icons/%.png: icons/%.svg
	./make-icon.sh --trim --inset 1 $? $@ ${ICON_SIZE}

${DESTDIR}/icons/information.png: icons/2119897.svg
	./make-icon.sh --trim $? $@ ${BUTTON_SIZE}

${DESTDIR}/icons/load.png: icons/140273.svg
	./make-icon.sh --trim $? $@ ${BUTTON_SIZE}

${DESTDIR}/icons/create.png: icons/140268.svg
	./make-icon.sh --trim $? $@ ${BUTTON_SIZE}

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

${DESTDIR}/codemirror/%: codemirror/%
	cp $? $@

${DESTDIR}/.htaccess: htaccess
	cp $? $@

${DESTDIR}/colouring.js: colouring.js.in
	./preprocess.pl $(CPPFLAGS) $? $@

versions.hsc: make-version-info.pl versions.munge
	./make-version-info.pl > versions.hsc

${DESTDIR}/examples/%: jfpatch-as-a-service-examples/jfpatch-files/%
	cp -R $? $@

${DESTDIR}/images/howitworks.png ${DESTDIR}/images/howitworks.svg: diagrams/howitworks.png diagrams/howitworks.svg
	cp diagrams/howitworks.png ${DESTDIR}/images/howitworks.png
	cp diagrams/howitworks.svg ${DESTDIR}/images/howitworks.svg

diagrams/howitworks.png diagrams/howitworks.svg:
	cd diagrams && make

${DESTDIR}/%: %
	cp $? $@

.SUFFIXES:
.SUFFIXES: .html .hsc

../dest/%.html: %.hsc
	hsc $(HSCFLAGS) $<

# --- DO NOT MODIFY THIS LINE -- hsc-dependencies follow ---

# dependencies updated: Monday 30-Mar-2020 20:48:21

all_hsc : ../dest/api.html ../dest/codemirror-examples.html \
    ../dest/fileformat.html ../dest/index.html ../dest/about.html \
    ../dest/notfound.html ../dest/codemirror-examples-objasm.html \
    ../dest/codemirror-examples-bbcbasic.html ../dest/history.html

../dest/api.html : api.hsc ../macros.hsc

../dest/codemirror-examples.html : codemirror-examples.hsc ../macros.hsc

../dest/fileformat.html : fileformat.hsc ../macros.hsc

../dest/index.html : index.hsc ../macros.hsc

../dest/about.html : about.hsc ../macros.hsc

../dest/notfound.html : notfound.hsc ../macros.hsc

../dest/codemirror-examples-objasm.html : codemirror-examples-objasm.hsc \
    ../macros.hsc

../dest/codemirror-examples-bbcbasic.html : \
    codemirror-examples-bbcbasic.hsc ../macros.hsc

../dest/history.html : history.hsc ../macros.hsc versions.hsc

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
	cd diagrams && make clean
	-rm -rf "${DESTDIR}" versions.hsc
