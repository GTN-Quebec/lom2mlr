<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:oai="http://www.openarchives.org/OAI/2.0/"
  xmlns:lom="http://ltsc.ieee.org/xsd/LOM"
  xmlns:vcardconv="http://ntic.org/vcard"
  xmlns:vcards="urn:ietf:params:xml:ns:vcard-4.0"
  extension-element-prefixes="vcardconv">

<xsl:template match="@*|node()">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()"/>
  </xsl:copy>
</xsl:template>

<xsl:template match="lom:entity">
  <xsl:copy>
    <xsl:variable name="x" select="vcardconv:convert(text())" />
    <xsl:apply-templates select="$x" />
  </xsl:copy>
</xsl:template>

</xsl:stylesheet>
