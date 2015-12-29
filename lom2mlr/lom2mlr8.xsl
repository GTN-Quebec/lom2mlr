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
	xmlns:mlrfrens="http://www.ens-lyon.fr/"
	extension-element-prefixes="regexp sets str vcardconv mlrext"
	>
	<xsl:output method="xml" encoding="UTF-8"/>
  
  
  <xsl:include href="lom2mlr_utils.xsl" />
  
  <xsl:template match="lom:metadataSchema" mode="metaMetadata">
    <!-- note that a URI would be preferrable... Should we identify the frequent ones? -->
    <mlr8:DES0400>
      <xsl:value-of select="text()"/>
    </mlr8:DES0400>
  </xsl:template>
  
  <xsl:template match="lom:contribute" mode="metaMetadata">
    <mlr8:DES1100>
      <mlr8:RC0003>
        <xsl:attribute name="rdf:about">
          <xsl:text>urn:uuid:</xsl:text>
          <xsl:value-of select="mlrext:uuid_unique('mlr8:RC0003')"/>
        </xsl:attribute>
        <xsl:apply-templates mode="metaMetadata"/>
      </mlr8:RC0003>
    </mlr8:DES1100>
  </xsl:template>
  
  
  <xsl:template match="lom:entity" mode="metaMetadata">
    <mlr8:DES1400>
      <xsl:apply-templates mode="mlr9" select="." />
    </mlr8:DES1400>
  </xsl:template>
  
  <xsl:template match="lom:date" mode="metaMetadata">
    <xsl:choose>
      <!-- first cases: valid 8601 date or datetime -->
      <xsl:when test="lom:dateTime and regexp:test(lom:dateTime/text(), '^([\+-]?\d{4}(?!\d{2}\b))((-?)((0[1-9]|1[0-2])(\3([12]\d|0[1-9]|3[01]))?|W([0-4]\d|5[0-2])(-?[1-7])?|(00[1-9]|0[1-9]\d|[12]\d{2}|3([0-5]\d|6[1-6]))))$')">
        <mlr8:DES1300 rdf:datatype="http://www.w3.org/2001/XMLSchema#date">
          <xsl:value-of select="lom:dateTime/text()" />
        </mlr8:DES1300>
      </xsl:when>
      <xsl:when test="lom:dateTime and regexp:test(lom:dateTime/text(), '^([\+-]?\d{4}(?!\d{2}\b))((-?)((0[1-9]|1[0-2])(\3([12]\d|0[1-9]|3[01]))?|W([0-4]\d|5[0-2])(-?[1-7])?|(00[1-9]|0[1-9]\d|[12]\d{2}|3([0-5]\d|6[1-6])))([T\s]((([01]\d|2[0-3])((:?)[0-5]\d)?|24\:?00)([\.,]\d+(?!:))?)?(\17[0-5]\d([\.,]\d+)?)?([zZ]|([\+-])([01]\d|2[0-3]):?([0-5]\d)?)?)?)$')">
        <mlr8:DES1300 rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">
          <xsl:value-of select="lom:dateTime/text()" />
        </mlr8:DES1300>
      </xsl:when>
      <xsl:when test="lom:dateTime">
        <mlr8:DES1300>
          <xsl:value-of select="lom:dateTime/text()" />
        </mlr8:DES1300>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="lom:description/lom:string" mode="langstring">
          <xsl:with-param name="nodename" select="'mlr8:DES1300'"/>
        </xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="lom:role" mode="metaMetadata">
    <xsl:choose>
      <xsl:when test="lom:source">
        <mlr8:DES1200>
          <xsl:text>source: </xsl:text>
          <xsl:value-of select="lom:source/text()" />
          <xsl:text>, value: </xsl:text>
          <xsl:value-of select="lom:value/text()" />
          <xsl:if test="lom:source/text()='LOMv1.0'"><xsl:text>@en</xsl:text></xsl:if>
          <xsl:if test="lom:source/text()='LOMFRv1.0' or lom:source/text()='LOMFRv1.2' or lom:source/text()='LOMFRENSv1.0' or lom:source/text()='LOMFRENSv1.2'">@fr</xsl:if>		    	
        </mlr8:DES1200>
      </xsl:when>
      <xsl:otherwise>
        <mlr8:DES1200>
          <xsl:value-of select="lom:value/text()" />
        </mlr8:DES1200>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="lom:language" mode="metaMetadata">
    <mlr8:DES0200>
      <xsl:call-template name="language">
        <xsl:with-param name="l" select="text()"/>
      </xsl:call-template>
    </mlr8:DES0200>
  </xsl:template>

</xsl:stylesheet>
