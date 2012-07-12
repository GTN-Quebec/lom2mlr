
TARGETS = correspondances_xsl.xsl documentation.html

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
	./make_documentation.py -l

%.rtf: %.html
	textutil -inputencoding utf-8 -convert rtf $<

%.rtf: %.html
	textutil -inputencoding utf-8 -convert rtf $<
# pandoc -f html -t rtf -o $@ $<
