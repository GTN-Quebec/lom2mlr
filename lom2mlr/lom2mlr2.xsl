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

    <xsl:template match="lom:contribute" mode="mlr2">
      <xsl:variable name="role">
        <xsl:apply-templates mode="get_role" />
      </xsl:variable>
      <!-- Set the creation date -->
      <xsl:if test="$role='author'">
        <xsl:variable name="date_datatype">
          <xsl:apply-templates mode="get_date_datatype" />
        </xsl:variable>
        <xsl:choose>
          <xsl:when test="$date_datatype">
            <mlr2:DES0700 rdf:datatype="{$date_datatype}">
              <xsl:value-of select="lom:date/lom:dateTime/text()" />
            </mlr2:DES0700>
          </xsl:when>
          <xsl:when test="lom:date/lom:description">
            <xsl:apply-templates select="lom:description/lom:string" mode="langstring">
              <xsl:with-param name="nodename" select="'mlr2:DES0700'"/>
            </xsl:apply-templates>
          </xsl:when>
        </xsl:choose>
      </xsl:if>
      <xsl:apply-templates mode="mlr2" />
    </xsl:template>

    <xsl:template match="lom:entity" mode="mlr2">
      <xsl:param name="role"/>
      <xsl:choose>
        <xsl:when test="$role='author'">
          <mlr2:DES0200>
            <xsl:value-of select="vcard:vcard/vcard:fn/vcard:text"/>
          </mlr2:DES0200>
        </xsl:when>
        <xsl:when test="$role='publisher'">
          <mlr2:DES0500>
            <xsl:value-of select="vcard:vcard/vcard:fn/vcard:text"/>
          </mlr2:DES0500>
        </xsl:when>
        <xsl:otherwise>
          <mlr2:DES0600>
            <xsl:value-of select="vcard:vcard/vcard:fn/vcard:text"/>
          </mlr2:DES0600>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
