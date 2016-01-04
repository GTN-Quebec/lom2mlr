
TARGETS = correspondances_xsl.xsl correspondances_type.xml

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

correspondances_type.xml: correspondances_type_lom.xml correspondances_type_lomfr.xml
	python build_correspondances_type.py -o $@ $^

correspondances_xsl.xsl: correspondances_type.xml correspondances.xsl
	xsltproc -o $@ correspondances.xsl $< 
