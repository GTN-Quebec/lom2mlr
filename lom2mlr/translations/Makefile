LANGS = eng fra rus

TRANS := $(foreach lang, $(LANGS), translation_$(lang).xsl) translation_mlr.xsl

TARGETS = translation_mlr.xsl $(TRANS)

all: $(TARGETS)

clean:
	rm $(TARGETS)

translation_mlr.xsl: translation.xml make_translation_fromlang.xsl
	xsltproc -o $@ make_translation_fromlang.xsl $<

translation_%.xsl: translation.xml make_translation_tolang.xsl
	xsltproc --stringparam lang $* -o $@ make_translation_tolang.xsl $<
