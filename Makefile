STYLES = Regular Bold
FONT_FAMILY_NAME = NotoSansDuployan
VERSION = 3.001
RELEASE = --release
CHECK_ARGS = --incomplete
override NOTO = --noto
SUFFIXES = otf ttf
FONTS = $(foreach suffix,$(SUFFIXES),$(addprefix fonts/$(FONT_FAMILY_NAME)/unhinted/$(suffix)/NotoSansDuployan-,$(addsuffix .$(suffix),$(STYLES))))


help:
	@echo "###"
	@echo "# Build targets for $(FONT_FAMILY_NAME)"
	@echo "###"
	@echo
	@echo "  make build:  Builds the fonts and places them in the fonts/ directory"
	@echo "  make test:   Tests the fonts with fontbakery"
	@echo "  make proof:  Creates HTML proof documents in the proof/ directory"
	@echo "  make images: Creates PNG specimen images in the documentation/ directory"
	@echo


venv: venv/touchfile

.PHONY: build
build: venv .init.stamp sources/config*.yaml $(FONTS)


fonts/$(FONT_FAMILY_NAME)/unhinted/otf/NotoSansDuployan-Regular.otf: sources/Duployan.fea sources/*.py venv
	. venv/bin/activate ; python sources/build.py --fea $< $(NOTO) --output $@ $(RELEASE) --version $(VERSION)

fonts/$(FONT_FAMILY_NAME)/unhinted/otf/NotoSansDuployan-Bold.otf: sources/Duployan.fea sources/*.py venv
	. venv/bin/activate ; python sources/build.py --bold --fea $< $(NOTO) --output $@ $(RELEASE) --version $(VERSION)

$(addprefix fonts/$(FONT_FAMILY_NAME)/unhinted/ttf/NotoSansDuployan-,$(addsuffix .ttf,$(STYLES))): fonts/$(FONT_FAMILY_NAME)/unhinted/ttf/%.ttf: fonts/$(FONT_FAMILY_NAME)/unhinted/otf/%.otf venv
	mkdir -p "$$(dirname "$@")"
	. venv/bin/activate ; otf2ttf --output "$@" --overwrite "$<"

$(addprefix fonts/$(FONT_FAMILY_NAME)/hinted/ttf/NotoSansDuployan-,$(addsuffix .ttf,$(STYLES))): fonts/$(FONT_FAMILY_NAME)/hinted/ttf/%.ttf: fonts/$(FONT_FAMILY_NAME)/hinted/otf/%.otf venv
	mkdir -p "$$(dirname "$@")"
	cp $< $@

$(addprefix fonts/$(FONT_FAMILY_NAME)/googlefonts/ttf/NotoSansDuployan-,$(addsuffix .ttf,$(STYLES))): fonts/$(FONT_FAMILY_NAME)/googlefonts/ttf/%.ttf: fonts/$(FONT_FAMILY_NAME)/unhinted/ttf/%.ttf venv
	mkdir -p "$$(dirname "$@")"
	. venv/bin/activate ; python3 scripts/hotfix.py -o $@ $<

.init.stamp: venv
	. venv/bin/activate; python3 scripts/first-run.py

venv/touchfile: requirements.txt
	test -d venv || python3 -m venv venv
	. venv/bin/activate; pip install -Ur requirements.txt
	touch venv/touchfile

test: venv build.stamp
	. venv/bin/activate; python3 -m notoqa

proof: venv build.stamp
	. venv/bin/activate; mkdir -p out/ out/proof; gftools gen-html proof $(shell find fonts/*/unhinted/ttf -type f) -o out/proof

%.png: %.py build.stamp
	python3 $< --output $@

clean:
	rm -rf venv
	find . -name "*.pyc" | xargs rm delete

manual_release: build.stamp
	@echo "Creating release files manually is contraindicated."
	@echo "Please use the CI for releases instead."
	cd fonts; for family in *; do VERSION=`font-v report $$family/unhinted/ttf/* | grep Version | sort -u  | awk '{print $$2}'`; zip -r ../$$family-v$$VERSION.zip $$family; done

