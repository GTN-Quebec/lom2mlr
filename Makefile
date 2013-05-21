
TARGETS = rationale.html result.rdf.xml

SUBDIRS = lom2mlr

.PHONY: subdirs $(SUBDIRS)

all: subdirs $(TARGETS)
	-for d in $(SUBDIRS); do (cd $$d; $(MAKE) ); done

clean:
	rm -f $(TARGETS)
	-for d in $(SUBDIRS); do (cd $$d; $(MAKE) clean); done

subdirs: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@

test:
	nosetests

rationale.html: rationale.md lom2mlr/lom2mlr.xsl
	python -m lom2mlr.markdown -l -c rationale.md

result.rdf.xml: lom2mlr/tests/data/Valid.xml lom2mlr/lom2mlr.xsl
	python -m lom2mlr.transform -o $@ $<

%.rtf: %.html
	textutil -inputencoding utf-8 -convert rtf $<

%.rtf: %.html
	textutil -inputencoding utf-8 -convert rtf $<
# pandoc -f html -t rtf -o $@ $<
