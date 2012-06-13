
TARGETS = correspondances_xsl.xsl  documentation_x.rtf documentation.html documentation_en.html

DIRS = translations vdex

.PHONY: subdirs $(SUBDIRS)

all: $(TARGETS)
	-for d in $(DIRS); do (cd $$d; $(MAKE) ); done

clean:
	rm -f $(TARGETS)
	-for d in $(DIRS); do (cd $$d; $(MAKE) clean); done 


subdirs: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@

test:
	nosetests

correspondances_xsl.xsl: correspondances_type.xml correspondances.xsl
	xsltproc -o $@ correspondances.xsl $< 


documentation.html: documentation.md lom2mlr.xsl
	./make_documentation.py

documentation_x.html: documentation.md lom2mlr.xsl
	./make_documentation.py --output $@ --delete

documentation_fr.html: documentation.md lom2mlr.xsl
	./make_documentation.py -l fr

documentation_en.html: documentation.md lom2mlr.xsl
	./make_documentation.py -l en

documentation_ru.html: documentation.md lom2mlr.xsl
	./make_documentation.py -l ru

%.rtf: %.html
	textutil -inputencoding utf-8 -convert rtf $<

%.rtf: %.html
	textutil -inputencoding utf-8 -convert rtf $<
# pandoc -f html -t rtf -o $@ $<
