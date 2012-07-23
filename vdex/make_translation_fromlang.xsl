<?xml version="1.0" encoding="UTF-8"?>
<xslin:stylesheet version="1.0" 
        xmlns:xslin="http://www.w3.org/1999/XSL/Transform"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform/Out"
        xmlns:vdex="http://www.imsglobal.org/xsd/imsvdex_v1p0"
        xmlns:str="http://exslt.org/strings"
        xmlns:mlr3="http://standards.iso.org/iso-iec/19788/-3/ed-1/en/"
        xmlns:mlr5="http://standards.iso.org/iso-iec/19788/-5/ed-1/en/"
        xmlns:mlr8="http://standards.iso.org/iso-iec/19788/-8/ed-1/en/"
        extension-element-prefixes="vdex str"
        >
    <xslin:namespace-alias stylesheet-prefix="xsl" result-prefix="xslin"/>
    <xslin:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
    <xslin:param name="langs">
        <xslin:text>en fr ru</xslin:text>
    </xslin:param>

    <xslin:variable name="voc" select="/vdex:vdex/vdex:vocabIdentifier/text()" />

    <xslin:template match="/">
        <xsl:stylesheet version="1.0">
            <xslin:apply-templates select="str:tokenize($langs)" mode="lang">
                <xslin:with-param name="root" select="."/>
            </xslin:apply-templates>
        </xsl:stylesheet>
    </xslin:template>

    <xslin:template match="*" mode="lang">
        <xslin:param name="root"/>
        <xslin:apply-templates select="$root/vdex:vdex">
            <xslin:with-param name="lang" select="text()"/>
        </xslin:apply-templates>
    </xslin:template>

    <xslin:template match="vdex:vdex">
        <xslin:param name="lang"/>
        <xsl:template>
            <xslin:attribute name="name">
                <xslin:value-of select="translate($voc,':','-')"/>
                <xslin:text>_</xslin:text>
                <xslin:value-of select="$lang"/>
            </xslin:attribute>
            <xsl:choose>
                <xslin:apply-templates>
                    <xslin:with-param name="lang" select="$lang"/>
                </xslin:apply-templates>
                <xsl:otherwise>
                    <xsl:apply-templates select="@*"/>
                    <xsl:value-of select="text()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:template>
    </xslin:template>

    <xslin:template match="vdex:term">
        <xslin:param name="lang"/>
        <xslin:variable name="translation">
            <xslin:apply-templates>
                <xslin:with-param name="lang" select="$lang"/>
            </xslin:apply-templates>
        </xslin:variable>
        <xslin:if test="string-length($translation) &gt; 0">
            <xsl:when>
                <xslin:attribute name="test">
                    <xslin:text>text()='</xslin:text>
                    <xslin:value-of select="$translation"/>
                    <xslin:text>'</xslin:text>
                </xslin:attribute>
                <xsl:apply-templates select="@*" mode="nolang"/>
                <xslin:value-of select="vdex:termIdentifier/text()"/>
            </xsl:when>
        </xslin:if>
    </xslin:template>

    <xslin:template match="vdex:caption">
        <xslin:param name="lang"/>
        <xslin:apply-templates mode="caption">
            <xslin:with-param name="lang" select="$lang"/>
        </xslin:apply-templates>
    </xslin:template>

    <xslin:template match="vdex:langstring" mode="caption">
        <xslin:param name="lang"/>
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