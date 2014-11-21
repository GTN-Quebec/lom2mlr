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
	extension-element-prefixes="regexp sets str vcardconv mlrext"
	>
<xsl:output method="xml" encoding="UTF-8"/>

<xsl:template match="text()" mode="ensdata"/>

<xsl:template match="lomfr:documentType" mode="general">
 <mlr2:DES0800>
   <xsl:value-of select="lomfr:value/text()" />
 </mlr2:DES0800>
<!-- <xsl:if test="$use_mlr3">
   <xsl:call-template name="lomfr_mlr2_DES0800"/>
 </xsl:if> -->
</xsl:template>

<xsl:template match="lomfrens:ensData" mode="top">
  <xsl:apply-templates mode="ensdata" select="."/>
</xsl:template>

<xsl:template match="lomfrens:ensDocumentType" mode="ensdata">
 <mlr2:DES0800>
   <xsl:value-of select="lomfrens:value/text()" />
 </mlr2:DES0800>
<!-- <xsl:if test="$use_mlr3">
   <xsl:call-template name="lomfrens_mlr2_DES0800"/>
 </xsl:if> -->
</xsl:template>

</xsl:stylesheet>
