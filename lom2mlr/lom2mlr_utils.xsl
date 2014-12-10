<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:lom="http://ltsc.ieee.org/xsd/LOM"
	xmlns:lomfr="http://www.lom-fr.fr/xsd/LOMFR"
	xmlns:lomfrens="http://pratic.ens-lyon.fr/xsd/LOMFRENS"
	xmlns:regexp="http://exslt.org/regular-expressions"
	xmlns:str="http://exslt.org/strings"
	xmlns:sets="http://exslt.org/sets"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:dc="http://purl.org/dc/elements/1.1/"
	xmlns:vcardconv="http://ntic.org/vcard"
	xmlns:vcard="urn:ietf:params:xml:ns:vcard-4.0"
	xmlns:cos="http://www.inria.fr/acacia/corese#"
    xmlns:oa="http://www.w3.org/ns/oa#"
	xmlns:gtnq="http://www.gtn-quebec.org/ns/"
	xmlns:mlrext="http://standards.iso.org/iso-iec/19788/ext/"
	xmlns:mlr1="http://standards.iso.org/iso-iec/19788/-1/ed-1/en/"
	xmlns:mlr2="http://standards.iso.org/iso-iec/19788/-2/ed-1/en/"
	xmlns:mlr3="http://standards.iso.org/iso-iec/19788/-3/ed-1/en/"
	xmlns:mlr4="http://standards.iso.org/iso-iec/19788/-4/ed-1/en/"
	xmlns:mlr5="http://standards.iso.org/iso-iec/19788/-5/ed-1/en/"
	xmlns:mlr8="http://standards.iso.org/iso-iec/19788/-8/ed-1/en/"
	xmlns:mlr9="http://standards.iso.org/iso-iec/19788/-9/ed-1/en/"
	xmlns:mlr-fr="http://www.ens-lyon.fr/"
	extension-element-prefixes="regexp sets str vcardconv mlrext"
	>
	<xsl:output method="xml" encoding="UTF-8"/>

    <!-- get date datatype -->

    <xsl:template match="lom:date/lom:dateTime" mode="get_date_datatype">
      <xsl:choose>
        <xsl:when test="regexp:test(text(), '^([\+-]?\d{4}(?!\d{2}\b))((-?)((0[1-9]|1[0-2])(\3([12]\d|0[1-9]|3[01]))?|W([0-4]\d|5[0-2])(-?[1-7])?|(00[1-9]|0[1-9]\d|[12]\d{2}|3([0-5]\d|6[1-6]))))$')">
            <xsl:text>http://www.w3.org/2001/XMLSchema#date</xsl:text> 
          </xsl:when>
          <xsl:when test="regexp:test(text(), '^([\+-]?\d{4}(?!\d{2}\b))((-?)((0[1-9]|1[0-2])(\3([12]\d|0[1-9]|3[01]))?|W([0-4]\d|5[0-2])(-?[1-7])?|(00[1-9]|0[1-9]\d|[12]\d{2}|3([0-5]\d|6[1-6])))([T\s]((([01]\d|2[0-3])((:?)[0-5]\d)?|24\:?00)([\.,]\d+(?!:))?)?(\17[0-5]\d([\.,]\d+)?)?([zZ]|([\+-])([01]\d|2[0-3]):?([0-5]\d)?)?)?)?$')">
            <xsl:text>http://www.w3.org/2001/XMLSchema#dateTime</xsl:text> 
          </xsl:when>
      </xsl:choose>
    </xsl:template>

    <xsl:template match="text()" mode="get_date_datatype" />


    <!-- get role -->

    <xsl:template match="lom:contribute/lom:role/lom:value" mode="get_role">
      <xsl:value-of select="text()" />
    </xsl:template>

    <xsl:template match="text()" mode="get_role"/>

</xsl:stylesheet>
