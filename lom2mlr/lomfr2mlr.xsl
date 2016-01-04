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

<!-- new type -->

<xsl:template match="lomfr:documentType" mode="general">
 <mlr2:DES0800>
   <xsl:value-of select="lomfr:value/text()" />
 </mlr2:DES0800>
 <xsl:if test="$use_mlr3">
   <xsl:call-template name="mlr2_DES0800"/>
 </xsl:if>
</xsl:template>

<xsl:template match="lomfr:activity" mode="educational">
 <mlr-fr:activity>
   <xsl:value-of select="lomfr:value/text()" />
 </mlr-fr:activity>
 <xsl:if test="$use_mlr3">
   <xsl:call-template name="mlr-fr_activity"/>
 </xsl:if>
</xsl:template>

<xsl:template match="lomfr:credit" mode="educational">
 <mlr-fr:credit>
   <xsl:value-of select="lomfr:value/text()" />
 </mlr-fr:credit>
</xsl:template>

<!-- New value in existing type -->

<xsl:template match="lomfr:role" mode="metaMetadata">
 <mlr8:DES1200>
  <xsl:value-of select="lomfr:value/text()" />
 </mlr8:DES1200>
</xsl:template>
<xsl:template match="lomfr:name[lomfr:source/text()='LOMFRv1.0']" mode="tech-requirement">
 <xsl:choose>
  <xsl:when test="lomfr:value/text()='any' or lomfr:value/text()='multi-os'">
   <xsl:choose>
    <xsl:when test="$text_language = 'eng'">
     <xsl:text> can be any </xsl:text>
     <xsl:value-of select="../type/value/text()"/>
     <xsl:choose>
      <xsl:when test="preceding-sibling::lomfr:type/lomfr:value/text() = 'browser'">
       <xsl:text>browser</xsl:text>
      </xsl:when>
      <xsl:when test="preceding-sibling::lomfr:type/lomfr:value/text() = 'operating system'">
       <xsl:text>operating system</xsl:text>
      </xsl:when>
      <xsl:otherwise>
       <xsl:text>'</xsl:text>
       <xsl:value-of select="preceding-sibling::lomfr:type/lomfr:value/text()"/>
       <xsl:text>'</xsl:text>
      </xsl:otherwise>
     </xsl:choose>
    </xsl:when>
    <xsl:when test="$text_language = 'fra'">
     <xsl:text> peut être n'importe quel </xsl:text>
     <xsl:choose>
      <xsl:when test="preceding-sibling::lomfr:type/lomfr:value/text() = 'browser'">
       <xsl:text>navigateur</xsl:text>
      </xsl:when>
      <xsl:when test="preceding-sibling::lomfr:type/lomfr:value/text() = 'operating system'">
       <xsl:text>système d'exploitation</xsl:text>
      </xsl:when>
      <xsl:otherwise>
       <xsl:text>'</xsl:text>
       <xsl:value-of select="preceding-sibling::lomfr:type/lomfr:value/text()"/>
       <xsl:text>'</xsl:text>
      </xsl:otherwise>
     </xsl:choose>
    </xsl:when>
    <xsl:otherwise>
     <xsl:text> = ?</xsl:text>
    </xsl:otherwise>
   </xsl:choose>
  </xsl:when>
  <xsl:when test="lomfr:value/text()='none'">
   <xsl:choose>
    <xsl:when test="$text_language = 'eng'">
     <xsl:text> is not needed</xsl:text>
    </xsl:when>
    <xsl:when test="$text_language = 'fra'">
     <xsl:text> n'est pas nécessaire</xsl:text>
    </xsl:when>
    <xsl:otherwise>
     <xsl:text> = 0</xsl:text>
    </xsl:otherwise>
   </xsl:choose>
  </xsl:when>
  <xsl:otherwise>
   <xsl:choose>
    <xsl:when test="$text_language = 'eng'">
     <xsl:text> must be </xsl:text>
    </xsl:when>
    <xsl:when test="$text_language = 'fra'">
     <xsl:text> doit être </xsl:text>
    </xsl:when>
    <xsl:otherwise>
     <xsl:text> = </xsl:text>
    </xsl:otherwise>
   </xsl:choose>
   <xsl:choose>
    <xsl:when test="$text_language = 'fra' or $text_language = 'eng'">
     <xsl:choose>
      <xsl:when test="lomfr:value/text()='ms-internet explorer'">
       <xsl:text>Microsoft Internet Explorer</xsl:text>
      </xsl:when>
      <xsl:when test="lomfr:value/text()='pc-dos'">
       <xsl:text>MS-DOS</xsl:text>
      </xsl:when>
      <xsl:when test="lomfr:value/text()='ms-windows'">
       <xsl:text>Microsoft Windows</xsl:text>
      </xsl:when>
      <xsl:when test="lomfr:value/text()='macos'">
       <xsl:text>Mac OS</xsl:text>
      </xsl:when>
      <xsl:otherwise>
       <xsl:value-of select="lomfr:value/text()"/>
      </xsl:otherwise>
     </xsl:choose>
    </xsl:when>
    <xsl:otherwise>
     <xsl:value-of select="lomfr:value/text()"/>
    </xsl:otherwise>
   </xsl:choose>
  </xsl:otherwise>
 </xsl:choose>
</xsl:template>


<!-- LOM ens -->

<xsl:template match="text()" mode="ensdata"/>

<xsl:template match="lomfrens:ensData" mode="top">
 <xsl:apply-templates mode="ensdata" select="."/>
</xsl:template>

<xsl:template match="lomfrens:ensDocumentType" mode="ensdata">
 <mlr2:DES0800>
   <xsl:value-of select="lomfrens:value/text()" />
 </mlr2:DES0800>
 <xsl:if test="$use_mlr3">
   <xsl:call-template name="mlr2_DES0800"/>
 </xsl:if>
</xsl:template>

</xsl:stylesheet>
