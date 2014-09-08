<?xml version="1.0" encoding="UTF-8"?>
<xslin:stylesheet version="1.0" 
	xmlns:xslin="http://www.w3.org/1999/XSL/Transform"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform/Out"
    xmlns:oa="http://www.w3.org/ns/oa#"
    xmlns:oa_eng="http://www.w3.org/ns/oa#"
	xmlns:mlr1="http://standards.iso.org/iso-iec/19788/-1/ed-1/en/"
	xmlns:mlr2="http://standards.iso.org/iso-iec/19788/-2/ed-1/en/"
	xmlns:mlr3="http://standards.iso.org/iso-iec/19788/-3/ed-1/en/"
	xmlns:mlr4="http://standards.iso.org/iso-iec/19788/-4/ed-1/en/"
	xmlns:mlr5="http://standards.iso.org/iso-iec/19788/-5/ed-1/en/"
	xmlns:mlr8="http://standards.iso.org/iso-iec/19788/-8/ed-1/en/"
	xmlns:mlr9="http://standards.iso.org/iso-iec/19788/-9/ed-1/en/"
	xmlns:mlr1_eng="http://www.gtn-quebec.org/ns/translation/iso-iec/19788/-1/ed-1/eng/"
	xmlns:mlr2_eng="http://www.gtn-quebec.org/ns/translation/iso-iec/19788/-2/ed-1/eng/"
	xmlns:mlr3_eng="http://www.gtn-quebec.org/ns/translation/iso-iec/19788/-3/ed-1/eng/"
	xmlns:mlr4_eng="http://www.gtn-quebec.org/ns/translation/iso-iec/19788/-4/ed-1/eng/"
	xmlns:mlr5_eng="http://www.gtn-quebec.org/ns/translation/iso-iec/19788/-5/ed-1/eng/"
	xmlns:mlr8_eng="http://www.gtn-quebec.org/ns/translation/iso-iec/19788/-8/ed-1/eng/"
	xmlns:mlr9_eng="http://www.gtn-quebec.org/ns/translation/iso-iec/19788/-9/ed-1/eng/"
	xmlns:mlr1_fra="http://www.gtn-quebec.org/ns/translation/iso-iec/19788/-1/ed-1/fra/"
	xmlns:mlr2_fra="http://www.gtn-quebec.org/ns/translation/iso-iec/19788/-2/ed-1/fra/"
	xmlns:mlr3_fra="http://www.gtn-quebec.org/ns/translation/iso-iec/19788/-3/ed-1/fra/"
	xmlns:mlr4_fra="http://www.gtn-quebec.org/ns/translation/iso-iec/19788/-4/ed-1/fra/"
	xmlns:mlr5_fra="http://www.gtn-quebec.org/ns/translation/iso-iec/19788/-5/ed-1/fra/"
	xmlns:mlr8_fra="http://www.gtn-quebec.org/ns/translation/iso-iec/19788/-8/ed-1/fra/"
	xmlns:mlr9_fra="http://www.gtn-quebec.org/ns/translation/iso-iec/19788/-9/ed-1/fra/"
	xmlns:mlr1_rus="http://www.gtn-quebec.org/ns/translation/iso-iec/19788/-1/ed-1/rus/"
	xmlns:mlr2_rus="http://www.gtn-quebec.org/ns/translation/iso-iec/19788/-2/ed-1/rus/"
	xmlns:mlr3_rus="http://www.gtn-quebec.org/ns/translation/iso-iec/19788/-3/ed-1/rus/"
	xmlns:mlr4_rus="http://www.gtn-quebec.org/ns/translation/iso-iec/19788/-4/ed-1/rus/"
	xmlns:mlr5_rus="http://www.gtn-quebec.org/ns/translation/iso-iec/19788/-5/ed-1/rus/"
	xmlns:mlr8_rus="http://www.gtn-quebec.org/ns/translation/iso-iec/19788/-8/ed-1/rus/"
	xmlns:mlr9_rus="http://www.gtn-quebec.org/ns/translation/iso-iec/19788/-9/ed-1/rus/"
	>

	<!-- TODO changer les namespaces pour GTN-Québec-->
	<xslin:namespace-alias stylesheet-prefix="xsl" result-prefix="xslin"/>
	<xslin:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
	<xslin:param name="lang">
		<xslin:text>fra</xslin:text>
	</xslin:param>
	<xslin:variable name="trfrom"> '’</xslin:variable>
	<xslin:variable name="trto">___</xslin:variable>

	<xslin:template match="text()"/>

	<xslin:template match="/">
		<xsl:stylesheet version="1.0">
			<xslin:apply-templates mode="includes"/>
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
		<xslin:if test="term[@lang = $lang] or @vocab">
			<xsl:template>
				<xslin:attribute name="match">
					<xslin:value-of select="concat(@ns,':',@id)"/>
				</xslin:attribute>
				<xslin:variable name="destname">
					<xslin:choose>
						<xslin:when test="term[@lang = $lang]">
							<xslin:value-of select="concat(@ns,'_',$lang,':',translate(term[@lang = $lang]/text(),$trfrom,$trto))"/>
						</xslin:when>
						<xslin:otherwise>
							<xslin:value-of select="concat(@ns,':',@id)"/>
						</xslin:otherwise>
					</xslin:choose>
				</xslin:variable>
				<xslin:choose>
					<xslin:when test="@vocab">
						<xsl:call-template>
							<xslin:attribute name="name">
								<xslin:value-of select="translate(@vocab,':','_')"/>
							</xslin:attribute>
							<xsl:with-param name="ename">
								<xslin:value-of select="$destname"/>
							</xsl:with-param>
						</xsl:call-template>
					</xslin:when>
					<xslin:otherwise>
						<xslin:element name="{$destname}">
							<xsl:apply-templates select="@*"/>
							<xsl:apply-templates/>
						</xslin:element>
					</xslin:otherwise>
				</xslin:choose>
				<!-- <xslin:apply-templates select="term[@lang = $lang]"/> -->
			</xsl:template>
		</xslin:if>
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
					<xslin:text>_</xslin:text>
					<xslin:value-of select="$lang"/>
					<xslin:text>.xsl</xslin:text>
				</xslin:attribute>
			</xsl:include>
		</xslin:if>
	</xslin:template>

</xslin:stylesheet>
