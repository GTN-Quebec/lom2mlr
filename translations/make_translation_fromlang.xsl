<?xml version="1.0" encoding="UTF-8"?>
<xslin:stylesheet version="1.0" 
	xmlns:xslin="http://www.w3.org/1999/XSL/Transform"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform/Out"
    xmlns:str="http://exslt.org/strings"
	xmlns:mlr1="http://standards.iso.org/iso-iec/19788/-1/ed-1/en/"
	xmlns:mlr2="http://standards.iso.org/iso-iec/19788/-2/ed-1/en/"
	xmlns:mlr3="http://standards.iso.org/iso-iec/19788/-3/ed-1/en/"
	xmlns:mlr4="http://standards.iso.org/iso-iec/19788/-4/ed-1/en/"
	xmlns:mlr5="http://standards.iso.org/iso-iec/19788/-5/ed-1/en/"
	xmlns:mlr8="http://standards.iso.org/iso-iec/19788/-8/ed-1/en/"
	xmlns:mlr9="http://standards.iso.org/iso-iec/19788/-9/ed-1/en/"
	xmlns:mlr1_en="http://standards.iso.org/iso-iec/19788/-1/ed-1/en/en/"
	xmlns:mlr2_en="http://standards.iso.org/iso-iec/19788/-2/ed-1/en/en/"
	xmlns:mlr3_en="http://standards.iso.org/iso-iec/19788/-3/ed-1/en/en/"
	xmlns:mlr4_en="http://standards.iso.org/iso-iec/19788/-4/ed-1/en/en/"
	xmlns:mlr5_en="http://standards.iso.org/iso-iec/19788/-5/ed-1/en/en/"
	xmlns:mlr8_en="http://standards.iso.org/iso-iec/19788/-8/ed-1/en/en/"
	xmlns:mlr9_en="http://standards.iso.org/iso-iec/19788/-9/ed-1/en/en/"
	xmlns:mlr1_fr="http://standards.iso.org/iso-iec/19788/-1/ed-1/en/fr/"
	xmlns:mlr2_fr="http://standards.iso.org/iso-iec/19788/-2/ed-1/en/fr/"
	xmlns:mlr3_fr="http://standards.iso.org/iso-iec/19788/-3/ed-1/en/fr/"
	xmlns:mlr4_fr="http://standards.iso.org/iso-iec/19788/-4/ed-1/en/fr/"
	xmlns:mlr5_fr="http://standards.iso.org/iso-iec/19788/-5/ed-1/en/fr/"
	xmlns:mlr8_fr="http://standards.iso.org/iso-iec/19788/-8/ed-1/en/fr/"
	xmlns:mlr9_fr="http://standards.iso.org/iso-iec/19788/-9/ed-1/en/fr/"
	xmlns:mlr1_ru="http://standards.iso.org/iso-iec/19788/-1/ed-1/en/ru/"
	xmlns:mlr2_ru="http://standards.iso.org/iso-iec/19788/-2/ed-1/en/ru/"
	xmlns:mlr3_ru="http://standards.iso.org/iso-iec/19788/-3/ed-1/en/ru/"
	xmlns:mlr4_ru="http://standards.iso.org/iso-iec/19788/-4/ed-1/en/ru/"
	xmlns:mlr5_ru="http://standards.iso.org/iso-iec/19788/-5/ed-1/en/ru/"
	xmlns:mlr8_ru="http://standards.iso.org/iso-iec/19788/-8/ed-1/en/ru/"
	xmlns:mlr9_ru="http://standards.iso.org/iso-iec/19788/-9/ed-1/en/ru/"
    extension-element-prefixes="str"
	>
	<xslin:namespace-alias stylesheet-prefix="xsl" result-prefix="xslin"/>
	<xslin:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
	<xslin:variable name="trfrom"> '’</xslin:variable>
	<xslin:variable name="trto">___</xslin:variable>
    <xslin:param name="langs">
        <xslin:text>en fr ru</xslin:text>
    </xslin:param>

	<xslin:template match="text()"/>

	<xslin:template match="/">
		<xsl:stylesheet version="1.0">
			<xslin:apply-templates mode="includes"/>
            <xslin:apply-templates select="str:tokenize($langs)" mode="lang">
                <xslin:with-param name="root" select="."/>
            </xslin:apply-templates>
			<xsl:template match="*">
				<xsl:copy>
					<xsl:apply-templates select="@*"/>
					<xsl:apply-templates select="*|text()"/>
				</xsl:copy>
			</xsl:template>
			<xsl:template match="@*|text()">
				<xsl:copy />
			</xsl:template>
			<xsl:template match="@*" mode="nolang">
				<xsl:copy />
			</xsl:template>
			<xsl:template match="@xml:lang" mode="nolang"/>
			<xsl:template match="text()" mode="nolang"/>
		</xsl:stylesheet>
	</xslin:template>

    <xslin:template match="*" mode="lang">
        <xslin:param name="root"/>
        <xslin:apply-templates select="$root/translation/id">
            <xslin:with-param name="lang" select="text()"/>
        </xslin:apply-templates>
    </xslin:template>

	<xslin:template match="id">
        <xslin:param name="lang"/>
		<xslin:variable name="sourcename">
			<xslin:choose>
				<xslin:when test="term[@lang = $lang]">
					<xslin:value-of select="concat(@ns,'_',$lang,':',translate(term[@lang = $lang]/text(),$trfrom,$trto))"/>
				</xslin:when>
				<xslin:otherwise>
					<xslin:value-of select="concat(@ns,':',@id)"/>
				</xslin:otherwise>
			</xslin:choose>
		</xslin:variable>
		<xsl:template>
			<xslin:attribute name="match">
				<xslin:value-of select="$sourcename"/>
			</xslin:attribute>
			<xslin:element name="{concat(@ns,':',@id)}">
				<xslin:choose>
					<xslin:when test="@vocab">
						<xsl:call-template>
							<xslin:attribute name="name">
								<xslin:value-of select="translate(@vocab,':','_')"/>
								<xslin:text>_</xslin:text>
								<xslin:value-of select="$lang"/>
							</xslin:attribute>
						</xsl:call-template>
					</xslin:when>
					<xslin:otherwise>
						<xsl:apply-templates select="@*"/>
						<xsl:apply-templates/>
					</xslin:otherwise>
				</xslin:choose>
			</xslin:element>
		</xsl:template>
	</xslin:template>

	<xslin:template match="*">
		<xslin:apply-templates/>
	</xslin:template>

	<xslin:template match="text()" mode="includes"/>

	<xslin:template match="*" mode="includes">
		<xslin:apply-templates mode="includes"/>
	</xslin:template>

	<xslin:template match="id[@vocab]" mode="includes">
		<xslin:variable name="vocab" select="@vocab"/>
		<xslin:if test="not(preceding-sibling::id[@vocab=$vocab])">
			<xsl:include>
				<xslin:attribute name="href">
					<xslin:text>../vdex/</xslin:text>
					<xslin:value-of select="@vocab"/>
					<xslin:text>_mlr.xsl</xslin:text>
				</xslin:attribute>
			</xsl:include>
		</xslin:if>
	</xslin:template>

</xslin:stylesheet>
