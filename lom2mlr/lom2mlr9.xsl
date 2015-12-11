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
  <!-- vocabularies and utilities -->
  <xsl:import href="correspondances_xsl.xsl"/>

  <xsl:output method="xml" encoding="UTF-8"/>

  <xsl:template match="lom:role" mode="mlr9">
    <xsl:choose>
      <xsl:when test="lom:source/text()='LOMv1.0' or lom:source/text()='LOMFRv1.0' or lom:source/text()='LOMFRv1.2' or lom:source/text()='LOMFRENSv1.0' or lom:source/text()='LOMFRENSv1.2'">
        <xsl:call-template name="mlr5_DES0800" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>source: </xsl:text>
        <xsl:value-of select="lom:source/text()" />
        <xsl:text>, value: </xsl:text>
        <xsl:value-of select="lom:value/text()" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

    <xsl:template match="lom:contribute" mode="mlr9">
      <xsl:variable name="role">
        <xsl:apply-templates mode="get_role" />
      </xsl:variable>
      <xsl:variable name="date_datatype">
        <xsl:apply-templates mode="get_date_datatype" />
      </xsl:variable>
      <xsl:variable name="urlid">
        <xsl:text>urn:uuid:</xsl:text>
        <xsl:value-of select="mlrext:person_uuid(lom:entity/vcard:vcard/@uuidstr)" />
      </xsl:variable>
      <mlr5:DES1700>
        <mlr5:RC0003>
          <xsl:attribute name="rdf:about">
            <xsl:text>urn:uuid:</xsl:text>
            <xsl:value-of select="mlrext:uuid_unique('mlr8:RC0001')" />
          </xsl:attribute>
          <mlr5:DES1800>
            <xsl:apply-templates select="lom:entity" mode="mlr9" />
          </mlr5:DES1800>
            <xsl:apply-templates select="lom:role" mode="mlr9" />
          <mlr5:DES0700 rdf:datatype="{$date_datatype}">
            <xsl:value-of select="lom:date/lom:dateTime/text()"/>
          </mlr5:DES0700>
        </mlr5:RC0003>
      </mlr5:DES1700>
      <xsl:choose>
        <xsl:when test="$role='author'">
          <mlr2:DES1600>
            <xsl:attribute name="rdf:resource">
              <xsl:value-of select="$urlid" />
            </xsl:attribute>
          </mlr2:DES1600>
        </xsl:when>
        <xsl:when test="$role='publisher'">
          <mlr2:DES1900>
            <xsl:attribute name="rdf:resource">
              <xsl:value-of select="$urlid" />
            </xsl:attribute>
          </mlr2:DES1900>
        </xsl:when>
        <xsl:otherwise>
          <mlr2:DES2000>
            <xsl:attribute name="rdf:resource">
              <xsl:value-of select="$urlid" />
            </xsl:attribute>
          </mlr2:DES2000>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:template>


    <xsl:template match="lom:entity" mode="mlr9">
      <xsl:variable name="urlid">
        <xsl:text>urn:uuid:</xsl:text>
        <xsl:value-of select="mlrext:person_uuid(vcard:vcard/@uuidstr)" />
      </xsl:variable>
        <mlr9:RC0001>
          <xsl:attribute name="rdf:about">
            <xsl:value-of select="$urlid" />
          </xsl:attribute>
          <mlr9:DES0100>
            <xsl:value-of select="mlrext:vcard_uuid(vcard:vcard/@uuidstr)" />
          </mlr9:DES0100>
          <mlr9:DES0200>
            <xsl:value-of select="vcard:vcard/vcard:fn/vcard:text" />
          </mlr9:DES0200>
          <xsl:if test="vcard:vcard/vcard:n/vcard:surname">
            <mlr9:DES0300>
              <xsl:value-of select="vcard:vcard/vcard:n/vcard:surname" />
            </mlr9:DES0300>
          </xsl:if>
          <xsl:if test="vcard:vcard/vcard:n/vcard:given">
            <mlr9:DES0400>
              <xsl:value-of select="vcard:vcard/vcard:n/vcard:given" />
            </mlr9:DES0400>
          </xsl:if>
          <xsl:if test="vcard:vcard/vcard:email">
            <mlr9:DES0800>
              <xsl:value-of select="vcard:vcard/vcard:email" />
            </mlr9:DES0800>
          </xsl:if>
          <mlr9:DES3000>
            <xsl:text>urn:uuid:</xsl:text>
            <xsl:value-of select="mlrext:vcard_uuid(vcard:vcard/@uuidstr)" />
          </mlr9:DES3000>
        </mlr9:RC0001>
    </xsl:template>

</xsl:stylesheet>
