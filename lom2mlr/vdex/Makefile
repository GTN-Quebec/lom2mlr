VOCS := ISO_IEC_19788-3-2011-VA.2 ISO_IEC_19788-5-2012-VA.2 ISO_IEC_19788-5-2012-VA.4\
	ISO_IEC_19788-5-2012-VA.1 ISO_IEC_19788-5-2012-VA.3\
	ISO_IEC_19788-5-2012-VA.5 ISO_IEC_19788-9-2014-VA.2.1

LANGS := fra eng rus

VDEX := $(foreach voc, $(VOCS), $(voc).vdex)
SKOS := $(foreach voc, $(VOCS), $(voc).skos)
TO_LANG := $(foreach voc, $(VOCS), $(foreach lang, $(LANGS), $(voc)_$(lang).xsl))
FROM_LANG := $(foreach voc, $(VOCS), $(voc)_mlr.xsl)

all: $(SKOS) $(VDEX) $(TO_LANG) $(FROM_LANG)

clean:
	rm $(VDEX) $(SKOS) $(TO_LANG) $(FROM_LANG)

%.vdex: %.txt
	./make_vdex.py $<

%.skos: %.vdex
	xsltproc vdex2skos.xsl $< | xmllint --format - > $@

%_fra.xsl: %.vdex
	xsltproc --stringparam lang fra -o $@ make_translation_tolang.xsl $<

%_eng.xsl: %.vdex
	xsltproc --stringparam lang eng -o $@ make_translation_tolang.xsl $<

%_rus.xsl: %.vdex
	xsltproc --stringparam lang rus -o $@ make_translation_tolang.xsl $<

%_mlr.xsl: %.vdex
	xsltproc -o $@ make_translation_fromlang.xsl $<
