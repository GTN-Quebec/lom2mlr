<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:lom="http://ltsc.ieee.org/xsd/LOM"
	xmlns:regexp="http://exslt.org/regular-expressions"
	xmlns:str="http://exslt.org/strings"
	xmlns:vcardconv="http://ntic.org/vcard"
	xmlns="urn:ietf:params:xml:ns:vcard-4.0"
	extension-element-prefixes="regexp str vcardconv"
	>
	<xsl:output method="xml" encoding="UTF-8"/>
	<xsl:template match="/">
		<vcards>
			<xsl:apply-templates/>
		</vcards>
	</xsl:template>

	<xsl:template match="*">
		<xsl:apply-templates/>
	</xsl:template>
	<xsl:template match="text()" />
	<xsl:template match="lom:entity">
		<xsl:variable name="x" select="vcardconv:convert(text())" />
		<xsl:apply-templates mode="copy" select="$x" />
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
