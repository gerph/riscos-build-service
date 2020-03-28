# To run automatically when changed, with fswatch:
#
#   fswatch -o *.dot.in *.dot.pp | while read ; do make -j 10 ; done &

artifact_dir=.
in_files=$(wildcard *.dot.in)

svg_files=$(patsubst %,${artifact_dir}/%,${dot_files:.dot=.svg})
png_files=$(patsubst %,${artifact_dir}/%,${dot_files:.dot=.png})
dot_files=$(in_files:.dot.in=.dot) $(wildcard *.dot)

pcpp_check = $(shell pcpp /dev/null 2>&1)
pcpp_version = $(shell pcpp --version 2>&1)
ifneq (${pcpp_check},)
$(error The tool 'pcpp' needs to be installed (try: pip install pcpp))
endif


.PHONY: all clean artifacts_dir temp_dir
.INTERMEDIATE: $(in_files:.dot.in=.dot)

all: ${png_files} ${dot_files} ${svg_files}
	@echo "Used PCPP version ${pcpp_version}"
	@echo "Built ${png_files} ${dot_files} ${svg_files}"

clean:
	rm -rf "${artifact_dir}" tmp

artifacts_dir:
	@mkdir -p "${artifact_dir}"
temp_dir:
	@mkdir -p tmp

tmp/%.png: %.dot artifacts_dir temp_dir
	dot -Tpng -o $@ $<

${artifact_dir}/%.svg: %.dot artifacts_dir
	dot -Tsvg -o $@ $< && ./embed-images-in-svg.pl $@ .

${artifact_dir}/%.png: tmp/%.png
	pngquant --nofs --force --output $@ 64 -- $<


%.dot: %.dot.in transform.sed
	pcpp $< | sed -E -f transform.sed > $@
