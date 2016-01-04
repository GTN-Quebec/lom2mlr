<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:v="http://www.w3.org/2006/vcard/ns#"
	>
	<xsl:output method="xml" encoding="UTF-8"/>
	<xsl:template match="text()" />

    <xsl:key name="vcardId" match="rdf:RDF/v:VCard" use="@rdf:about"/>

    <xsl:template match="rdf:RDF" >
     <xsl:copy>
       <xsl:apply-templates select="/rdf:RDF/v:VCard[count( . | key('vcardId', @rdf:about)[1]) = 1]" mode="copy"/>
     </xsl:copy>
    </xsl:template>

    <!-- copy -->
	<xsl:template mode="copy" match="*">
		<xsl:copy>
			<xsl:apply-templates select="@*" mode="copy"/>
			<xsl:apply-templates select="*|text()" mode="copy"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template mode="copy" match="@*|text()">
		<xsl:copy />
	</xsl:template>

</xsl:stylesheet>
