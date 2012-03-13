<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:lom="http://ltsc.ieee.org/xsd/LOM"
	xmlns:regexp="http://exslt.org/regular-expressions"
	xmlns:str="http://exslt.org/strings"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:dc="http://purl.org/dc/elements/1.1/"
	xmlns:vcardconv="http://ntic.org/vcard"
	xmlns:vcard="urn:ietf:params:xml:ns:vcard-4.0"
	xmlns:mlr2="http://standards.iso.org/iso-iec/19788/-2/ed-1/en/"
	xmlns:mlr4="http://standards.iso.org/iso-iec/19788/-4/ed-1/en/"
	xmlns:mlr5="http://standards.iso.org/iso-iec/19788/-5/ed-1/en/"
	xmlns:mlr8="http://standards.iso.org/iso-iec/19788/-8/ed-1/en/"
	extension-element-prefixes="regexp str vcardconv"
	>
	<xsl:output method="xml" encoding="UTF-8"/>

	<xsl:template match="/">
		<rdf:RDF>
			<xsl:apply-templates/>
		</rdf:RDF>
	</xsl:template>

	<xsl:template match="lom:lom">
		<rdf:Description>
			<xsl:attribute name="rdf:about">
				<xsl:choose>
					<xsl:when test="lom:general/lom:identifier/lom:entry">
						<xsl:value-of select="lom:general/lom:identifier[1]/lom:entry/text()" />
					</xsl:when>
					<xsl:when test="lom:technical/lom:location">
						<xsl:value-of select="lom:technical/lom:location[1]/text()" />
					</xsl:when>
				</xsl:choose>
			</xsl:attribute>
			<xsl:apply-templates mode="top"/>
		</rdf:Description>
	</xsl:template>

	<xsl:template match="text()" />
	<xsl:template match="text()" mode="top"/>
	<xsl:template match="text()" mode="general"/>
	<xsl:template match="text()" mode="lifeCycle"/>
	<xsl:template match="text()" mode="metaMetadata"/>
	<xsl:template match="text()" mode="technical"/>
	<xsl:template match="text()" mode="educational"/>
	<xsl:template match="text()" mode="rights"/>
	<xsl:template match="text()" mode="relation"/>
	<xsl:template match="text()" mode="classification"/>

	<xsl:template match="*">
		<xsl:apply-templates/>
	</xsl:template>

	<!-- use mode as a context indicator -->
	<xsl:template match="lom:general" mode="top">
		<xsl:apply-templates mode="general"/>
	</xsl:template>
	<xsl:template match="lom:lifeCycle" mode="top">
		<xsl:apply-templates mode="lifeCycle"/>
	</xsl:template>
	<xsl:template match="lom:metaMetadata" mode="top">
		<xsl:apply-templates mode="metaMetadata"/>
	</xsl:template>
	<xsl:template match="lom:technical" mode="top">
		<xsl:apply-templates mode="technical"/>
	</xsl:template>
	<xsl:template match="lom:educational" mode="top">
		<xsl:apply-templates mode="educational"/>
	</xsl:template>
	<xsl:template match="lom:classification" mode="top">
		<xsl:apply-templates mode="classification" select="." />
	</xsl:template>

	<xsl:template match="lom:title" mode="general">
		<xsl:apply-templates select="lom:string" mode="langstring">
			<xsl:with-param name="nodename" select="'mlr2:DES0100'"/>
		</xsl:apply-templates>
	</xsl:template>

	<xsl:template match="lom:contribute[lom:role[lom:source/text()='LOMv1.0' and lom:value/text()='author']]" mode="lifeCycle">
		<mlr2:DES0200> <!-- creator -->
			<xsl:value-of select="vcardconv:convert(lom:entity/text())/vcard:fn/vcard:text/text()" />
		</mlr2:DES0200>
		<xsl:choose>
			<xsl:when test="lom:date/lom:dateTime">
				<mlr2:DES0700 rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime"> <!-- dateTime -->
					<xsl:value-of select="lom:date/lom:dateTime/text()" />
				</mlr2:DES0700>
			</xsl:when>
			<xsl:when test="lom:date/lom:description">
				<xsl:apply-templates select="lom:date/lom:description/lom:string" mode="langstring">
					<xsl:with-param name="nodename" select="'mlr2:DES0700'"/>
				</xsl:apply-templates>
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="lom:classification[lom:purpose[lom:source/text()='LOMv1.0' and lom:value/text()='discipline']]" mode="classification">
		<xsl:choose>
			<xsl:when test="lom:description">
				<xsl:apply-templates select="lom:description/lom:string" mode="langstring">
					<xsl:with-param name="nodename" select="'mlr2:DES0300'"/>
				</xsl:apply-templates>
			</xsl:when>
			<xsl:when test="lom:keyword">
				<xsl:apply-templates select="lom:keyword/lom:string" mode="langstring">
					<xsl:with-param name="nodename" select="'mlr2:DES0300'"/>
				</xsl:apply-templates>
			</xsl:when>
			<xsl:when test="lom:taxonPath">
				<xsl:apply-templates select="lom:taxonPath/lom:taxon[last()]/lom:entry/lom:string" mode="langstring">
					<xsl:with-param name="nodename" select="'mlr2:DES0300'"/>
				</xsl:apply-templates>
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="lom:description" mode="general">
		<xsl:apply-templates select="lom:string" mode="langstring">
			<xsl:with-param name="nodename" select="'mlr2:DES0400'"/>
		</xsl:apply-templates>
	</xsl:template>


	<xsl:template match="lom:contribute[lom:role[lom:source/text()='LOMv1.0' and lom:value/text()='publisher']]" mode="lifeCycle">
		<mlr2:DES0500> <!-- publisher -->
			<xsl:value-of select="vcardconv:convert(lom:entity/text())/vcard:fn/vcard:text/text()" />
		</mlr2:DES0500>
	</xsl:template>


	<xsl:template match="lom:contribute" mode="lifeCycle">
		<mlr2:DES0600> <!-- contributor -->
			<xsl:value-of select="vcardconv:convert(lom:entity/text())/vcard:fn/vcard:text/text()" />
		</mlr2:DES0600>
	</xsl:template>

	<xsl:template match="lom:learningResourceType" mode="educational">
		<mlr2:DES0800>
			<xsl:value-of select="lom:value/text()"/>
		</mlr2:DES0800>
	</xsl:template>

	<xsl:template match="lom:format" mode="technical">
		<mlr2:DES0900>
			<xsl:value-of select="text()"/>
		</mlr2:DES0900>
	</xsl:template>

	<xsl:template match="lom:identifier" mode="general">
		<mlr2:DES1000>
			<xsl:value-of select="lom:entry/text()"/>
		</mlr2:DES1000>
	</xsl:template>

	<xsl:template match="lom:relation[lom:kind[lom:source/text()='LOMv1.0' and lom:value/text()='isbasedon']]" mode="top">
		<mlr2:DES1100>
			<xsl:value-of select="lom:resource/lom:identifier/lom:entry/text()"/>
		</mlr2:DES1100>
	</xsl:template>

	<xsl:template match="lom:language" mode="general">
		<mlr2:DES1200>
			<xsl:value-of select="text()"/>
		</mlr2:DES1200>
	</xsl:template>

	<xsl:template match="lom:relation" mode="top">
		<mlr2:DES1300>
			<xsl:value-of select="lom:resource/lom:identifier/lom:entry/text()"/>
		</mlr2:DES1300>
	</xsl:template>

	<xsl:template match="lom:coverage" mode="general">
		<xsl:apply-templates select="lom:string" mode="langstring">
			<xsl:with-param name="nodename" select="'mlr2:DES1400'"/>
		</xsl:apply-templates>
	</xsl:template>

	<xsl:template match="lom:rights" mode="top">
		<xsl:choose>
			<xsl:when test="lom:description">
				<xsl:apply-templates select="lom:description/lom:string" mode="langstring">
					<xsl:with-param name="nodename" select="'mlr2:DES1500'"/>
				</xsl:apply-templates>
			</xsl:when>
			<xsl:when test="lom:cost[lom:source/text()='LOMv1.0' and lom:value/text()='yes']">
				<mlr2:DES1500 xml:lang="fr">Coût</mlr2:DES1500>
			</xsl:when>
			<xsl:when test="lom:copyrightAndOtherRestrictions[lom:source/text()='LOMv1.0' and lom:value/text()='yes']">
				<mlr2:DES1500 xml:lang="fr">Copyright ou autres restrictions</mlr2:DES1500>
			</xsl:when>
			<xsl:when test="lom:cost[lom:source/text()='LOMv1.0' and lom:value/text()='no'] and lom:copyrightAndOtherRestrictions[lom:source/text()='LOMv1.0' and lom:value/text()='no']">
				<mlr2:DES1500 xml:lang="fr">Pas de copyright</mlr2:DES1500>
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<!-- utility functions -->

	<xsl:template mode="langstring" match="lom:string">
		<xsl:param name="nodename" />
		<xsl:element name="{$nodename}">
			<xsl:if test="@language">
				<xsl:attribute name="xml:lang"><xsl:value-of select="@language" /></xsl:attribute>
			</xsl:if>
			<xsl:value-of select="text()" />
		</xsl:element>
	</xsl:template>
	<xsl:template mode="langstring" match="*">
		<xsl:message terminate="yes">Langstring called on non-string</xsl:message>
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
