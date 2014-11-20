<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output name="theoutput" method="xml" version="1.0" encoding="ISO-8859-1" indent="yes" />
  <xsl:variable name="lomfr" select="document('correspondances_type_lomfr.xml')" />

  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>

  <xsl:template match="group">
    <xsl:copy>
      <xsl:variable name="context" select="@context" />
      <xsl:variable name="element" select="@element" />
      <xsl:variable name="voc" select="@voc" />
      <xsl:variable name="dest" select="@dest" />
      <xsl:variable name="always" select="@always" />
      <xsl:apply-templates select="@*|node()" />
      <xsl:apply-templates select="$lomfr/*/group[@context=$context and @element=$element and @voc=$voc and @dest=$dest and @always=$always]/term"  />
    </xsl:copy>
  </xsl:template>
</xsl:transform>
