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
	xmlns:mlr3="http://standards.iso.org/iso-iec/19788/-3/ed-1/en/"
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
			<!-- first cases: valid 8601 date or datetime -->
			<xsl:when test="lom:date/lom:dateTime and regexp:test(lom:date/lom:dateTime/text(), '^([\+-]?\d{4}(?!\d{2}\b))((-?)((0[1-9]|1[0-2])(\3([12]\d|0[1-9]|3[01]))?|W([0-4]\d|5[0-2])(-?[1-7])?|(00[1-9]|0[1-9]\d|[12]\d{2}|3([0-5]\d|6[1-6]))))$')">
				<mlr3:DES0100 rdf:datatype="http://www.w3.org/2001/XMLSchema#date">
					<xsl:value-of select="lom:date/lom:dateTime/text()" />
				</mlr3:DES0100>
			</xsl:when>
			<xsl:when test="lom:date/lom:dateTime and regexp:test(lom:date/lom:dateTime/text(), '^([\+-]?\d{4}(?!\d{2}\b))((-?)((0[1-9]|1[0-2])(\3([12]\d|0[1-9]|3[01]))?|W([0-4]\d|5[0-2])(-?[1-7])?|(00[1-9]|0[1-9]\d|[12]\d{2}|3([0-5]\d|6[1-6])))([T\s]((([01]\d|2[0-3])((:?)[0-5]\d)?|24\:?00)([\.,]\d+(?!:))?)?(\17[0-5]\d([\.,]\d+)?)?([zZ]|([\+-])([01]\d|2[0-3]):?([0-5]\d)?)?)?)?$')">
				<mlr3:DES0100 rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">
					<xsl:value-of select="lom:date/lom:dateTime/text()" />
				</mlr3:DES0100>
			</xsl:when>
			<xsl:when test="lom:date/lom:dateTime">
				<mlr2:DES0700 rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">
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
			<xsl:with-param name="nodename" select="'mlr3:DES0200'"/>
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
		<xsl:choose>
			<xsl:when test="/lom:lom/lom:general/lom:aggregationLevel[lom:source/text()='LOMv1.0' and lom:value/text()='collection']">
				<mlr3:DES0700>T001</mlr3:DES0700> <!-- collection -->
			</xsl:when>
			<xsl:when test="../lom:interactivityLevel[lom:source/text()='LOMv1.0' and (lom:value/text()='high' or lom:value/text()='very high')] or ../lom:interactivityType[lom:source/text()='LOMv1.0' and lom:value/text()='active']">
				<mlr3:DES0700>T005</mlr3:DES0700> <!-- interactive ressource -->
			</xsl:when>
			<xsl:when test="lom:source/text()='LOMv1.0' and lom:value/text()='narrative text'">
				<mlr3:DES0700>T012</mlr3:DES0700> <!-- text -->
			</xsl:when>
			<xsl:when test="lom:source/text()='LOMv1.0' and (lom:value/text()='slide' or lom:value/text()='diagram' or lom:value/text()='figure' or lom:value/text()='graph')">
				<mlr3:DES0700>T011</mlr3:DES0700> <!-- still image -->
			</xsl:when>
			<xsl:when test="lom:source/text()='LOMv1.0' and lom:value/text()='table'">
				<mlr3:DES0700>T002</mlr3:DES0700> <!-- dataset -->
			</xsl:when>
			<xsl:when test="lom:source/text()='http://eureka.ntic.org/vdex/NORMETICv1.1_element_5_2_type_de_ressource_voc.xml' and lom:value/text()='outils'">
				<mlr3:DES0700>T009</mlr3:DES0700> <!-- software -->
			</xsl:when>
			<xsl:otherwise>
				<mlr2:DES0800>
					<xsl:value-of select="lom:value/text()"/>
				</mlr2:DES0800>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="lom:size" mode="technical">
		<mlr4:DES0200>
			<xsl:value-of select="text()"/>
		</mlr4:DES0200>
	</xsl:template>

	<xsl:template match="lom:format" mode="technical">
		<xsl:choose>
			<xsl:when test="text()='non-digital'">
				<mlr3:DES0300>
					<xsl:value-of select="text()"/>
				</mlr3:DES0300>
			</xsl:when>
			<xsl:when test="regexp:test(text(),'^\w+\/\w+$')">
				<mlr3:DES0300>
					<xsl:value-of select="text()"/>
				</mlr3:DES0300>
			</xsl:when>
			<xsl:otherwise>
				<mlr2:DES0900>
					<xsl:value-of select="text()"/>
				</mlr2:DES0900>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="lom:location" mode="technical">
		<mlr4:DES0100>
			<xsl:value-of select="text()"/>
		</mlr4:DES0100>
	</xsl:template>

	<xsl:template name="as_00num">
		<xsl:param name="v"/>
		<xsl:choose>
			<xsl:when test="number($v)&gt;9">
				<xsl:value-of select="number($v)"/>
			</xsl:when>
			<xsl:when test="number($v)&gt;0">
				<xsl:text>0</xsl:text>
				<xsl:value-of select="number($v)"/>
			</xsl:when>
			<xsl:otherwise>00</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="lom:duration" mode="technical">
		<xsl:if test="lom:duration and regexp:test(lom:duration/text(),'^PT([0-9]+H)?([0-9]+M)?([0-9]+S)?$')">
			<mlr4:DES0300>
				<xsl:call-template name="as_00num">
					<xsl:with-param name="v" select="substring-before(regexp:match(lom:duration/text(),'[0-9]+H'),'H')"/>
				</xsl:call-template>
				<xsl:text>:</xsl:text>
				<xsl:call-template name="as_00num">
					<xsl:with-param name="v" select="substring-before(regexp:match(lom:duration/text(),'[0-9]+M'),'M')"/>
				</xsl:call-template>
				<xsl:text>:</xsl:text>
				<xsl:call-template name="as_00num">
					<xsl:with-param name="v" select="substring-before(regexp:match(lom:duration/text(),'[0-9]+S'),'S')"/>
				</xsl:call-template>
			</mlr4:DES0300>
		</xsl:if>
	</xsl:template>

	<xsl:template match="lom:requirement" mode="technical">
		<mlr4:DES0400 xml:lang="fr-CA">
			<xsl:variable name="multiple" select="count(lom:orComposite)&gt;1"/>
			<xsl:if test="$multiple">
				<xsl:text>Une des options suivantes:&#160;</xsl:text>
			</xsl:if>
			<xsl:apply-templates mode="tech-requirement" select="lom:orComposite">
				<xsl:with-param name="multiple" select="$multiple"/>
			</xsl:apply-templates>
		</mlr4:DES0400>
	</xsl:template>

	<xsl:template match="text()" mode="tech-requirement"/>

	<xsl:template match="lom:orComposite" mode="tech-requirement">
		<xsl:param name="multiple"/>
		<xsl:if test="$multiple">
			<xsl:value-of select="position()"/>
			<xsl:text>.&#160;</xsl:text>
		</xsl:if>
		<xsl:apply-templates mode="tech-requirement"/>
		<xsl:text>. </xsl:text>
	</xsl:template>

	<xsl:template match="lom:type" mode="tech-requirement">
		<xsl:choose>
			<xsl:when test="lom:source/text()='LOMv1.0' and lom:value/text()='browser'">
				<xsl:text>Le fureteur</xsl:text>
			</xsl:when>
			<xsl:when test="lom:source/text()='LOMv1.0' and lom:value/text()='operating system'">
				<xsl:text>Le système d'exploitation</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="lom:value/text()"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="lom:name" mode="tech-requirement">
		<xsl:choose>
			<xsl:when test="lom:source/text()='LOMv1.0' and lom:value/text()='ms-internet-explorer'">
				<xsl:text> doit être Microsoft Internet Explorer</xsl:text>
			</xsl:when>
			<xsl:when test="lom:source/text()='LOMv1.0' and lom:value/text()='any'">
				<xsl:text> peut être n'importe lequel</xsl:text>
			</xsl:when>
			<xsl:when test="lom:source/text()='LOMv1.0' and lom:value/text()='none'">
				<xsl:text> n'est pas pertinent</xsl:text>
			</xsl:when>
			<xsl:when test="lom:source/text()='LOMv1.0' and lom:value/text()='multi-os'">
				<xsl:text> peut être n'importe lequel</xsl:text>
			</xsl:when>
			<xsl:when test="lom:source/text()='LOMv1.0' and lom:value/text()='pc-dos'">
				<xsl:text> doit être DOS</xsl:text>
			</xsl:when>
			<xsl:when test="lom:source/text()='LOMv1.0' and lom:value/text()='ms-windows'">
				<xsl:text> doit être Microsoft Windows</xsl:text>
			</xsl:when>
			<xsl:when test="lom:source/text()='LOMv1.0' and lom:value/text()='macos'">
				<xsl:text> doit être Mac OS</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text> doit être </xsl:text>
				<xsl:value-of select="lom:value/text()"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="lom:minimumVersion" mode="tech-requirement">
		<xsl:if test="text()">
			<xsl:text>, version au moins </xsl:text>
			<xsl:value-of select="text()"/>
		</xsl:if>
	</xsl:template>

	<xsl:template match="lom:maximumVersion" mode="tech-requirement">
		<xsl:if test="text()">
			<xsl:choose>
				<xsl:when test="../lom:minimumVersion">
					<xsl:text> et au plus </xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>, version au plus </xsl:text>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:value-of select="text()"/>
		</xsl:if>
	</xsl:template>

	<xsl:template match="lom:installationRemarks" mode="technical">
		<xsl:apply-templates select="lom:string" mode="langstring">
			<xsl:with-param name="nodename" select="'mlr4:DES0400'"/>
		</xsl:apply-templates>
	</xsl:template>

	<xsl:template match="lom:otherPlatformRequirements" mode="technical">
		<xsl:apply-templates select="lom:string" mode="langstring">
			<xsl:with-param name="nodename" select="'mlr4:DES0400'"/>
		</xsl:apply-templates>
	</xsl:template>

	<xsl:template match="lom:identifier" mode="general">
		<mlr3:DES0400>
			<xsl:value-of select="lom:entry/text()"/>
		</mlr3:DES0400>
	</xsl:template>

	<xsl:template match="lom:relation[lom:kind[lom:source/text()='LOMv1.0' and lom:value/text()='isbasedon']]" mode="top">
		<mlr3:DES0600>
			<xsl:value-of select="lom:resource/lom:identifier/lom:entry/text()"/>
		</mlr3:DES0600>
	</xsl:template>

	<xsl:template match="lom:language" mode="general">
		<xsl:choose>
			<xsl:when test="regexp:test(text(),'^[a-z][a-z][a-z]?(\-[A-Z][A-Z])?$')">
				<mlr3:DES0500>
					<xsl:value-of select="text()"/>
				</mlr3:DES0500>
			</xsl:when>
			<xsl:otherwise>
				<mlr2:DES1200>
					<xsl:value-of select="text()"/>
				</mlr2:DES1200>
			</xsl:otherwise>
		</xsl:choose>
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
