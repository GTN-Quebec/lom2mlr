LANGS = en fr ru

TRANS := $(foreach lang, $(LANGS), translation_$(lang).xsl)

TARGETS = translation_mlr.xsl $(TRANS)

all: $(TARGETS)

clean:
	rm $(TARGETS)

correspondances_xsl.xsl: correspondances_type.xml correspondances.xsl
	xsltproc -o $@ correspondances.xsl $< 

translation_mlr.xsl: translation.xml make_translation_fromlang.xsl
	xsltproc -o $@ make_translation_fromlang.xsl $<

translation_%.xsl: translation.xml make_translation_tolang.xsl
	xsltproc --stringparam lang $* -o $@ make_translation_tolang.xsl $<
