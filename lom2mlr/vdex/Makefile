VOCS := ISO_IEC_19788-3-2011-VA.2 ISO_IEC_19788-5-2012-VA.2 ISO_IEC_19788-5-2012-VA.4\
	ISO_IEC_19788-5-2012-VA.1 ISO_IEC_19788-5-2012-VA.3\
	ISO_IEC_19788-5-2012-VA.5 ISO_IEC_19788-9-2014-VA.2.1\
	GTN_Québec-Normetic-V500

LANGS := fr en ru

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

%_fr.xsl: %.vdex
	xsltproc --stringparam lang fr -o $@ make_translation_tolang.xsl $<

%_en.xsl: %.vdex
	xsltproc --stringparam lang en -o $@ make_translation_tolang.xsl $<

%_ru.xsl: %.vdex
	xsltproc --stringparam lang ru -o $@ make_translation_tolang.xsl $<

%_mlr.xsl: %.vdex
	xsltproc -o $@ make_translation_fromlang.xsl $<
