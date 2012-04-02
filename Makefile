all: correspondances_xsl.xsl

test:
	nosetests

correspondances_xsl.xsl: correspondances_type.xml
	xsltproc -o $@ correspondances.xsl $< 
