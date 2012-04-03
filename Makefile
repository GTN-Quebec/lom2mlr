all: correspondances_xsl.xsl

test:
	nosetests

correspondances_xsl.xsl: correspondances_type.xml correspondances.xsl
	xsltproc -o $@ correspondances.xsl $< 
