<?xml version="1.0" encoding="UTF-8"?>
<xslin:stylesheet version="1.0" 
        xmlns:xslin="http://www.w3.org/1999/XSL/Transform"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform/Out"
        xmlns:vdex="http://www.imsglobal.org/xsd/imsvdex_v1p0"
        xmlns:mlr3_en="http://standards.iso.org/iso-iec/19788/-3/ed-1/en/en/"
        xmlns:mlr5_en="http://standards.iso.org/iso-iec/19788/-5/ed-1/en/en/"
        xmlns:mlr8_en="http://standards.iso.org/iso-iec/19788/-8/ed-1/en/en/"
        xmlns:mlr3_fr="http://standards.iso.org/iso-iec/19788/-3/ed-1/en/fr/"
        xmlns:mlr5_fr="http://standards.iso.org/iso-iec/19788/-5/ed-1/en/fr/"
        xmlns:mlr8_fr="http://standards.iso.org/iso-iec/19788/-8/ed-1/en/fr/"
        xmlns:mlr3_ru="http://standards.iso.org/iso-iec/19788/-3/ed-1/en/ru/"
        xmlns:mlr5_ru="http://standards.iso.org/iso-iec/19788/-5/ed-1/en/ru/"
        xmlns:mlr8_ru="http://standards.iso.org/iso-iec/19788/-8/ed-1/en/ru/"
        extension-element-prefixes="vdex"
        >
    <xslin:namespace-alias stylesheet-prefix="xsl" result-prefix="xslin"/>
    <xslin:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
    <xslin:param name="lang">
        <xslin:text>fr</xslin:text>
    </xslin:param>

    <xslin:variable name="voc" select="/vdex:vdex/vdex:vocabIdentifier/text()" />

    <xslin:template match="/">
        <xsl:stylesheet version="1.0">
            <xslin:apply-templates />
        </xsl:stylesheet>
    </xslin:template>

    <xslin:template match="vdex:vdex">
        <xsl:template>
            <xslin:attribute name="name">
                <xslin:value-of select="translate($voc,':','-')"/>
            </xslin:attribute>
            <xsl:param name="ename"/>
            <xsl:element>
                <xslin:attribute name="name">
                    <xslin:text>{$ename}</xslin:text>
                </xslin:attribute>
                <xsl:apply-templates select="@*"/>
                <xsl:choose>
                    <xslin:apply-templates />
                    <xsl:otherwise>
                        <xsl:value-of select="text()"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:element>
        </xsl:template>
    </xslin:template>

    <xslin:template match="vdex:term">
        <xslin:variable name="translation">
            <xslin:apply-templates />
        </xslin:variable>
        <xslin:if test="string-length($translation) &gt; 0">
            <xsl:when>
                <xslin:attribute name="test">
                    <xslin:text>text()='</xslin:text>
                    <xslin:value-of select="vdex:termIdentifier/text()"/>
                    <xslin:text>'</xslin:text>
                </xslin:attribute>
                <xsl:attribute name="xml:lang">
                    <xslin:value-of select="$lang"/>
                </xsl:attribute>
                <xslin:value-of select="$translation"/>
            </xsl:when>
        </xslin:if>
    </xslin:template>

    <xslin:template match="vdex:caption">
        <xslin:apply-templates mode="caption"/>
    </xslin:template>
    <xslin:template match="vdex:langstring" mode="caption">
        <xslin:if test="@language = $lang">
            <xslin:value-of select="text()"/>
        </xslin:if>
    </xslin:template>

    <xslin:template match="*">
        <xslin:apply-templates />
    </xslin:template>
    <xslin:template match="text()" />
    <xslin:template match="text()"  mode="caption"/>

</xslin:stylesheet>