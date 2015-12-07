<?xml version="1.0" encoding="UTF-8"?>
<xslin:stylesheet version="1.0" 
        xmlns:xslin="http://www.w3.org/1999/XSL/Transform"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform/Out"
        xmlns:vdex="http://www.imsglobal.org/xsd/imsvdex_v1p0"
        xmlns:str="http://exslt.org/strings"
        xmlns:mlr3="http://standards.iso.org/iso-iec/19788/-3/ed-1/en/"
        xmlns:mlr5="http://standards.iso.org/iso-iec/19788/-5/ed-1/en/"
        xmlns:mlr8="http://standards.iso.org/iso-iec/19788/-8/ed-1/en/"
        xmlns:mlr3_eng="http://www.gtn-quebec.org/ns/translation/iso-iec/19788/-3/ed-1/eng/"
        xmlns:mlr5_eng="http://www.gtn-quebec.org/ns/translation/iso-iec/19788/-5/ed-1/eng/"
        xmlns:mlr8_eng="http://www.gtn-quebec.org/ns/translation/iso-iec/19788/-8/ed-1/eng/"
        xmlns:mlr3_fra="http://www.gtn-quebec.org/ns/translation/iso-iec/19788/-3/ed-1/fra/"
        xmlns:mlr5_fra="http://www.gtn-quebec.org/ns/translation/iso-iec/19788/-5/ed-1/fra/"
        xmlns:mlr8_fra="http://www.gtn-quebec.org/ns/translation/iso-iec/19788/-8/ed-1/fra/"
        xmlns:mlr3_rus="http://www.gtn-quebec.org/ns/translation/iso-iec/19788/-3/ed-1/rus/"
        xmlns:mlr5_rus="http://www.gtn-quebec.org/ns/translation/iso-iec/19788/-5/ed-1/rus/"
        xmlns:mlr8_rus="http://www.gtn-quebec.org/ns/translation/iso-iec/19788/-8/ed-1/rus/"
        extension-element-prefixes="vdex"
        >
    <xslin:namespace-alias stylesheet-prefix="xsl" result-prefix="xslin"/>
    <xslin:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
    <xslin:param name="lang">
        <xslin:text>fra</xslin:text>
    </xslin:param>

    <xslin:variable name="voc" select="/vdex:vdex/vdex:vocabIdentifier/text()" />
    <xslin:variable name="voc_id" select="str:replace($voc,'http://purl.iso.org/iso-iec/19788/-', 'mlr')" />

    <xslin:template match="/">
        <xsl:stylesheet version="1.0">
            <xslin:apply-templates />
        </xsl:stylesheet>
    </xslin:template>

    <xslin:template match="vdex:vdex">
        <xsl:template>
            <xslin:attribute name="name">
                <xslin:value-of select="str:replace($voc_id, '/', '_')"/>
            </xslin:attribute>
            <xsl:param name="ename"/>
            <xsl:element>
                <xslin:attribute name="name">
                    <xslin:text>{$ename}</xslin:text>
                </xslin:attribute>
                <xsl:apply-templates select="@*"/>
                <xslin:choose>
                    <xslin:when test="vdex:term/vdex:caption/vdex:langstring[@language=$lang]">
                        <xsl:choose>
                            <xslin:apply-templates />
                            <xsl:otherwise>
                                <xsl:value-of select="text()"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xslin:when>
                    <xslin:otherwise>
                        <xsl:value-of select="text()"/>
                    </xslin:otherwise>
                </xslin:choose>
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