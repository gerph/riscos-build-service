# To run automatically when changed, with fswatch:
#
#   fswatch -o *.dot.in *.dot.pp icons/*.svg | while read ; do make -j 10 ; done &

# Configurables
ICON_SIZE = 256


artifact_dir=.
in_files=$(wildcard *.dot.in)

svg_files=$(patsubst %,${artifact_dir}/%,${dot_files:.dot=.svg})
png_files=$(patsubst %,${artifact_dir}/%,${dot_files:.dot=.png})
dot_files=$(in_files:.dot.in=.dot) $(wildcard *.dot)

icon_svg_files=$(wildcard icons/*.svg)
icon_png_files=${icon_svg_files:.svg=.png}

pcpp_check = $(shell pcpp /dev/null 2>&1)
pcpp_version = $(shell pcpp --version 2>&1)
ifneq (${pcpp_check},)
$(error The tool 'pcpp' needs to be installed (try: pip install pcpp))
endif


.PHONY: all clean artifacts_dir temp_dir
.INTERMEDIATE: $(in_files:.dot.in=.dot)

all: ${icon_png_files} ${png_files} ${dot_files} ${svg_files}
	@echo "Used PCPP version ${pcpp_version}"
	@echo "Built ${png_files} ${dot_files} ${svg_files}"

clean:
	rm -rf "${artifact_dir}"/*.png "${artifact_dir}"/*.svg tmp icons/*.png

artifacts_dir:
	@mkdir -p "${artifact_dir}"
temp_dir:
	@mkdir -p tmp

icons: ${icon_png_files}


tmp/%.png: %.dot artifacts_dir temp_dir icons
	dot -Tpng -o $@ $<

${artifact_dir}/%.svg: %.dot artifacts_dir icons
	dot -Tsvg -o $@ $< && ./embed-images-in-svg.pl $@ .

${artifact_dir}/%.png: tmp/%.png
	pngquant --nofs --force --output $@ 96 -- $<

icons/%.raw.png: icons/%.svg
	../make-icon.sh --inset 1 $? $@ ${ICON_SIZE}

icons/%.png: icons/%.raw.png
	pngquant --nofs --force --output $@ 96 -- $<


%.dot: %.dot.in transform.sed
	pcpp $< | sed -E -f transform.sed > $@
