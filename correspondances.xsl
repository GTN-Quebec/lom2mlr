<?xml version="1.0" encoding="UTF-8"?>
<xslin:stylesheet version="1.0" 
	xmlns:xslin="http://www.w3.org/1999/XSL/Transform"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform/Out"
	xmlns:lom="http://ltsc.ieee.org/xsd/LOM"
	xmlns:mlr3="http://standards.iso.org/iso-iec/19788/-3/ed-1/en/"
	xmlns:mlr5="http://standards.iso.org/iso-iec/19788/-5/ed-1/en/"
	xmlns:mlr8="http://standards.iso.org/iso-iec/19788/-8/ed-1/en/"
	>
	<xslin:namespace-alias stylesheet-prefix="xsl" result-prefix="xslin"/>
	<xslin:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
	<xslin:param name="dest"/>
	<xslin:param name="otherwise" select="true()"/>

	<xslin:template match="text()"/>

	<xslin:template match="/">
		<xsl:stylesheet version="1.0">
			<xslin:apply-templates/>
		</xsl:stylesheet>
	</xslin:template>

	<xslin:template match="*">
		<xslin:apply-templates/>
	</xslin:template>

	<xslin:template match="group">
		<xsl:template>
			<xslin:attribute name="name">
				<xslin:value-of select="concat(substring-before(@dest,':'),'_',substring-after(@dest,':'))"/>
			</xslin:attribute>
			<xsl:choose>
				<xslin:if test="@dest='mlr3:DES0700'">
					<xsl:when test="/lom:lom/lom:general/lom:aggregationLevel[lom:source/text()='LOMv1.0' and lom:value/text()='collection']">
						<mlr3:DES0700><xslin:value-of select="@voc"/>:T001</mlr3:DES0700> <!-- collection -->
					</xsl:when>
					<xsl:when test="../lom:interactivityLevel[lom:source/text()='LOMv1.0' and (lom:value/text()='high' or lom:value/text()='very high')] or ../lom:interactivityType[lom:source/text()='LOMv1.0' and lom:value/text()='active']">
						<mlr3:DES0700><xslin:value-of select="@voc"/>:T005</mlr3:DES0700> <!-- interactive ressource -->
					</xsl:when>
				</xslin:if>
				<xslin:apply-templates/>
				<xslin:if test="$otherwise">
					<xsl:otherwise>
						<xslin:element name="{@dest}">
							<xsl:value-of select="lom:value/text()"/>
						</xslin:element>
					</xsl:otherwise>
				</xslin:if>
			</xsl:choose>
		</xsl:template>
	</xslin:template>

	<xslin:template match="term[@dest!='']">
		<xsl:when>
			<xslin:attribute name="test">
				<xslin:text>lom:source/text()='</xslin:text>
				<xslin:value-of select="@source"/>
				<xslin:text>' and lom:value/text()='</xslin:text>
				<xslin:value-of select="@value"/>
				<xslin:text>'</xslin:text>
			</xslin:attribute>
			<xslin:element name="{../@dest}">
				<xslin:value-of select="concat(../@voc,':',@dest)"/>
			</xslin:element>
		</xsl:when>
	</xslin:template>

</xslin:stylesheet>