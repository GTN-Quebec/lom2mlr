<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" 
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        xmlns:skos="http://www.w3.org/2004/02/skos/core#"
        xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
        xmlns:vdex="http://www.imsglobal.org/xsd/imsvdex_v1p0"
        extension-element-prefixes="vdex"
        >
    <xsl:output method="xml" encoding="UTF-8"/>

    <xsl:variable name="voc" select="/vdex:vdex/vdex:vocabIdentifier/text()" />

    <xsl:template match="/">
        <xsl:apply-templates />
    </xsl:template>

    <xsl:template match="vdex:vdex">
        <rdf:RDF>
            <xsl:apply-templates />
        </rdf:RDF>
    </xsl:template>

    <xsl:template match="text()" />
    <xsl:template match="text()"  mode="caption"/>
    <xsl:template match="text()"  mode="description"/>

    <xsl:template match="vdex:term">
        <skos:Concept>
            <xsl:attribute name="rdf:about">
                <xsl:value-of select="concat($voc,'#',vdex:termIdentifier/text())"/>
            </xsl:attribute>
            <xsl:apply-templates />
        </skos:Concept>
    </xsl:template>

    <xsl:template match="vdex:caption">
            <xsl:apply-templates mode="caption"/>
    </xsl:template>
    <xsl:template match="vdex:description">
            <xsl:apply-templates mode="description"/>
    </xsl:template>
    <xsl:template match="vdex:langstring" mode="caption">
        <skos:prefLabel>
            <xsl:attribute name="xml:lang">
                <xsl:value-of select="@language"/>
            </xsl:attribute>
            <xsl:value-of select="text()"/>
        </skos:prefLabel>
    </xsl:template>
    <xsl:template match="vdex:langstring" mode="description">
        <skos:definition>
            <xsl:attribute name="xml:lang">
                <xsl:value-of select="@language"/>
            </xsl:attribute>
            <xsl:value-of select="text()"/>
        </skos:definition>
    </xsl:template>

</xsl:stylesheet>