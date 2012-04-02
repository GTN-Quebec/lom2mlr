VOCS := ISO_IEC_19788-3-2011-VA.2 ISO_IEC_19788-5-2012-VA.2 ISO_IEC_19788-5-2012-VA.4\
	ISO_IEC_19788-8-2012-VA.2.1 ISO_IEC_19788-5-2012-VA.1 ISO_IEC_19788-5-2012-VA.3\
	ISO_IEC_19788-5-2012-VA.5 ISO_IEC_19788-8-2012-VA.2.2

VDEX := $(foreach voc, $(VOCS), $(voc).vdex)
SKOS := $(foreach voc, $(VOCS), $(voc).skos)

all: $(SKOS)

%.vdex: %.txt
	./make_vdex.py $< > $@

%.skos: %.vdex
	xsltproc vdex2skos.xsl $< | xmllint --format - > $@

ISO_IEC_19788-3-2011-VA.2.vdex: ISO_IEC_19788-3-2011-VA.2.txt
	./make_vdex.py --lang ru $< > $@	

ISO_IEC_19788-8-2012-VA.2.1.vdex: ISO_IEC_19788-8-2012-VA.2.1.txt
	./make_vdex.py --lang ru $< > $@	

ISO_IEC_19788-8-2012-VA.2.2.vdex: ISO_IEC_19788-8-2012-VA.2.2.txt
	./make_vdex.py --nodef --lang ru $< > $@

ISO_IEC_19788-5-2012-VA.5.vdex: ISO_IEC_19788-5-2012-VA.5.txt
	./make_vdex.py --nodef $< > $@

clean:
	rm *.vdex
