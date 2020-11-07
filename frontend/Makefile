# Makefile to build the front end

# Configurables:
ICON_SIZE = 128
FILETYPE_SIZE = ${ICON_SIZE}
COG_SIZE = ${ICON_SIZE}
BUTTON_SIZE = ${ICON_SIZE}
LARGE_SIZE = 640

SUPPORT_JFPATCH = true
SUPPORT_C = true
SUPPORT_OBJASM = true
SUPPORT_PERL = true
SUPPORT_PASCAL = true
SUPPORT_BASTXT = true
SUPPORT_YAML = true
SUPPORT_PYTHON = false
SUPPORT_SHELL = true


# Main code
DESTDIR = ../dest
PRJFILE = ../hsc.project
PREFS = ../hsc.prefs
STDINC  = ../macros.hsc
# ignore warnings about missing files
# ignore=21
# smartent (used to convert to entities automatically)
# getsize
HSCFLAGS = ignore=49 ignore=79 ignore=87 msgbrowser=throwback \
		   prefsfile=$(PREFS) \
		   xhtml \
		   prjfile=$(PRJFILE) to=$(DESTDIR)/ $(STDINC) serverdir=$(DESTDIR)
# ena=notes

FLAGS = SUPPORT_JFPATCH=${SUPPORT_JFPATCH} \
        SUPPORT_C=${SUPPORT_C} \
        SUPPORT_OBJASM=${SUPPORT_OBJASM} \
        SUPPORT_PERL=${SUPPORT_PERL} \
        SUPPORT_PASCAL=${SUPPORT_PASCAL} \
        SUPPORT_BASTXT=${SUPPORT_BASTXT} \
        SUPPORT_YAML=${SUPPORT_YAML} \
        SUPPORT_PYTHON=${SUPPORT_PYTHON} \
        SUPPORT_SHELL=${SUPPORT_SHELL} \

HSCFLAGS += $(subst =,:BOOL=,$(subst false,, ${FLAGS:SUPPORT_%=define "SUPPORT_%"}))
CPPFLAGS = ${FLAGS:SUPPORT_%=-DSUPPORT_%}

CODEMIRROR = ${DESTDIR}/codemirror/lib/codemirror.js \
             ${DESTDIR}/codemirror/lib/codemirror.css \
             ${DESTDIR}/codemirror/theme/elegant.css \
             ${DESTDIR}/codemirror/theme/liquibyte.css \
             ${DESTDIR}/codemirror/addon/mode/simple.js \
             ${DESTDIR}/colouring.js \

ifeq (${SUPPORT_JFPATCH}, true)
CODEMIRROR += ${DESTDIR}/codemirror/mode/jfpatch.js
endif
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
ifeq (${SUPPORT_PYTHON}, true)
CODEMIRROR += ${DESTDIR}/codemirror/mode/python.js
endif
ifeq (${SUPPORT_YAML}, true)
CODEMIRROR += ${DESTDIR}/codemirror/mode/yaml.js
endif
ifeq (${SUPPORT_SHELL}, true)
CODEMIRROR += ${DESTDIR}/codemirror/mode/shell.js
endif


EXAMPLE_SOURCES = $(wildcard jfpatch-as-a-service-examples/jfpatch-files/*) \
				  $(wildcard jfpatch-as-a-service-examples/misc-examples/*) \
				  $(wildcard jfpatch-as-a-service-examples/c-examples/*) \
				  jfpatch-as-a-service-examples/examples.json \

EXAMPLES = $(subst jfpatch-as-a-service-examples/,${DESTDIR}/examples/,${EXAMPLE_SOURCES})


#.PHONY: all static all_hsc

all: dirs static all_hsc
dirs:
	mkdir -p ${DESTDIR}
	mkdir -p ${DESTDIR}/icons
	mkdir -p ${DESTDIR}/images
	mkdir -p ${DESTDIR}/examples/jfpatch-files
	mkdir -p ${DESTDIR}/examples/misc-examples
	mkdir -p ${DESTDIR}/examples/c-examples
	mkdir -p ${DESTDIR}/codemirror/lib
	mkdir -p ${DESTDIR}/codemirror/theme
	mkdir -p ${DESTDIR}/codemirror/mode
	mkdir -p ${DESTDIR}/codemirror/addon/mode

static: \
		${DESTDIR}/.htaccess \
 	 	${DESTDIR}/ansi_up.js \
 	 	${DESTDIR}/builder.js \
 	 	${DESTDIR}/site.css \
 	 	${DESTDIR}/favicon.ico \
 	 	${DESTDIR}/favicon-patched.ico \
 	 	${DESTDIR}/favicon-buildsite.ico \
 	 	${DESTDIR}/icons/file_a91.png \
 	 	${DESTDIR}/icons/file_ff8.png \
 	 	${DESTDIR}/icons/file_ffa.png \
 	 	${DESTDIR}/icons/file_ffc.png \
 	 	${DESTDIR}/icons/file_xxx.png \
 	 	${DESTDIR}/icons/cog.png \
 	 	${DESTDIR}/icons/patched.png \
 	 	${DESTDIR}/icons/patched-large.png \
 	 	${DESTDIR}/icons/buildsite.png \
 	 	${DESTDIR}/icons/buildsite-large.png \
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

${DESTDIR}/icons/%-large.png: icons/%.svg
	./make-icon.sh --trim --inset 1 $? $@ ${LARGE_SIZE}

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

# Site icon
# 1646265 - spanner and screwdriver crossed.
# 2081656 - screwdriver and spanner.
# 2078671 - crane.
${DESTDIR}/icons/overlay-build-large.png: icons/2078671-edited.svg
	./make-icon.sh --trim $? $@ ${LARGE_SIZE}
${DESTDIR}/icons/overlay-build.png: icons/2078671-edited.svg
	./make-icon.sh --trim $? $@ ${COG_SIZE}

${DESTDIR}/icons/nextstep.png: icons/1920786.svg
	./make-icon.sh --trim $? $@ ${BUTTON_SIZE}

${DESTDIR}/icons/menu.png: icons/2328436.svg
	./make-icon.sh --trim $? $@ ${BUTTON_SIZE}

${DESTDIR}/favicon-patched.ico: ${DESTDIR}/icons/patched.png
	convert $? -define icon:auto-resize=64,48,32,16 $@

${DESTDIR}/favicon-buildsite.ico: ${DESTDIR}/icons/buildsite.png
	convert $? -define icon:auto-resize=64,48,32,16 $@

${DESTDIR}/favicon.ico: ${DESTDIR}/favicon-patched.ico
	cp $? $@

${DESTDIR}/icons/patched.png: ${DESTDIR}/icons/cog.png ${DESTDIR}/icons/plaster.png
	convert -size ${COG_SIZE}x${COG_SIZE} ${DESTDIR}/icons/cog.png \
			-gravity center \( ${DESTDIR}/icons/plaster.png -resize 85% \) \
			-composite $@

${DESTDIR}/icons/patched-large.png: ${DESTDIR}/icons/cog-large.png ${DESTDIR}/icons/plaster-large.png
	convert -size ${LARGE_SIZE}x${LARGE_SIZE} ${DESTDIR}/icons/cog-large.png \
			-gravity center \( ${DESTDIR}/icons/plaster-large.png -resize 85% \) -composite $@

${DESTDIR}/icons/buildsite.png: ${DESTDIR}/icons/cog.png ${DESTDIR}/icons/overlay-build.png
	convert -size ${COG_SIZE}x${COG_SIZE} \
			${DESTDIR}/icons/overlay-build.png \
			\( ${DESTDIR}/icons/cog.png -resize 38% \
			-geometry +$$((${COG_SIZE} * 310 / 640))+$$((${COG_SIZE} * 340 / 640)) \) \
			-composite $@

${DESTDIR}/icons/buildsite-large.png: ${DESTDIR}/icons/cog-large.png ${DESTDIR}/icons/overlay-build-large.png
	convert -size ${LARGE_SIZE}x${LARGE_SIZE} \
			${DESTDIR}/icons/overlay-build-large.png \
			\( ${DESTDIR}/icons/cog-large.png -resize 40% \
			-geometry +$$((${LARGE_SIZE} * 310 / 640))+$$((${LARGE_SIZE} * 340 / 640)) \) \
			-composite $@

${DESTDIR}/codemirror/%: codemirror/%
	cp $? $@

${DESTDIR}/.htaccess: htaccess
	cp $? $@

${DESTDIR}/colouring.js: colouring.js.in
	./preprocess.pl $(CPPFLAGS) $? $@

versions.hsc: make-version-info.pl versions.munge
	./make-version-info.pl > versions.hsc

${DESTDIR}/examples/%: jfpatch-as-a-service-examples/%
	cp -R $? $@

${DESTDIR}/images/howitworks.png ${DESTDIR}/images/howitworks.svg: diagrams/howitworks.png diagrams/howitworks.svg
	cp diagrams/howitworks.png ${DESTDIR}/images/howitworks.png
	cp diagrams/howitworks.svg ${DESTDIR}/images/howitworks.svg

${DESTDIR}/images/builder.png ${DESTDIR}/images/builder.svg: diagrams/builder.png diagrams/builder.svg
	cp diagrams/builder.png ${DESTDIR}/images/builder.png
	cp diagrams/builder.svg ${DESTDIR}/images/builder.svg

${DESTDIR}/images/interfaces.png ${DESTDIR}/images/interfaces.svg: diagrams/interfaces.png diagrams/interfaces.svg
	cp diagrams/interfaces.png ${DESTDIR}/images/interfaces.png
	cp diagrams/interfaces.svg ${DESTDIR}/images/interfaces.svg

diagrams/howitworks.png diagrams/howitworks.svg diagrams/builder.png diagrams/builder.svg diagrams/interfaces.png diagrams/interfaces.svg:
	cd diagrams && make

${DESTDIR}/%: %
	cp $? $@

.SUFFIXES:
.SUFFIXES: .html .hsc

../dest/%.html: %.hsc
	hsc $(HSCFLAGS) $<

# --- DO NOT MODIFY THIS LINE -- hsc-dependencies follow ---

# dependencies updated: Thursday 05-Nov-2020 10:06:32

all_hsc : ../dest/codemirror-examples.html ../dest/fileformat.html \
    ../dest/about.html ../dest/notfound.html \
    ../dest/codemirror-examples-objasm.html \
    ../dest/codemirror-examples-bbcbasic.html ../dest/index.html \
    ../dest/robuildyaml.html ../dest/api.html ../dest/ci-build.html \
    ../dest/history.html ../dest/statistics.html

../dest/codemirror-examples.html : codemirror-examples.hsc ../pages.hsc \
    ../macros.hsc

../dest/fileformat.html : fileformat.hsc ../pages.hsc ../macros.hsc

../dest/about.html : about.hsc ../pages.hsc ../macros.hsc

../dest/notfound.html : notfound.hsc ../pages.hsc ../macros.hsc

../dest/codemirror-examples-objasm.html : codemirror-examples-objasm.hsc \
    ../pages.hsc ../macros.hsc

../dest/codemirror-examples-bbcbasic.html : \
    codemirror-examples-bbcbasic.hsc ../pages.hsc ../macros.hsc

../dest/index.html : index.hsc ../pages.hsc ../macros.hsc

../dest/robuildyaml.html : robuildyaml.hsc ../pages.hsc ../macros.hsc

../dest/api.html : api.hsc ../pages.hsc ../macros.hsc

../dest/ci-build.html : ci-build.hsc ../pages.hsc ../macros.hsc

../dest/history.html : history.hsc ../pages.hsc ../macros.hsc versions.hsc

../dest/statistics.html : statistics.hsc ../pages.hsc ../macros.hsc

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

upload : dirs static all_hsc
	rsync -av "${DESTDIR}"/ u36706922@home106874872.1and1-data.host:riscos/robuild/
