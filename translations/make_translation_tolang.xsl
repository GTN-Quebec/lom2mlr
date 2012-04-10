<?xml version="1.0" encoding="UTF-8"?>
<xslin:stylesheet version="1.0" 
	xmlns:xslin="http://www.w3.org/1999/XSL/Transform"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform/Out"
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
	>
	<xslin:namespace-alias stylesheet-prefix="xsl" result-prefix="xslin"/>
	<xslin:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
	<xslin:param name="lang">
		<xslin:text>fr</xslin:text>
	</xslin:param>

	<xslin:template match="text()"/>

	<xslin:template match="/">
		<xsl:stylesheet version="1.0">
			<xslin:apply-templates/>
			<xsl:template match="*">
				<xsl:copy>
					<xsl:apply-templates select="@*"/>
					<xsl:apply-templates select="*|text()"/>
				</xsl:copy>
			</xsl:template>
			<xsl:template match="@*|text()">
				<xsl:copy />
			</xsl:template>
		</xsl:stylesheet>
	</xslin:template>

	<xslin:template match="translation">
			<xslin:apply-templates/>
	</xslin:template>

	<xslin:template match="id">
		<xslin:if test="term[@lang = $lang]">
			<xsl:template>
				<xslin:attribute name="match">
					<xslin:value-of select="concat(@ns,':',@id)"/>
				</xslin:attribute>
				<xslin:apply-templates select="term[@lang = $lang]"/>
			</xsl:template>
		</xslin:if>
	</xslin:template>

	<xslin:template match="term">
		<xslin:variable name="trfrom"> '’</xslin:variable>
		<xslin:element name="{concat(../@ns,'_',$lang,':',translate(text(),$trfrom,'___'))}">
			<xsl:apply-templates select="@*"/>
			<xsl:apply-templates/>
		</xslin:element>
	</xslin:template>

</xslin:stylesheet>
