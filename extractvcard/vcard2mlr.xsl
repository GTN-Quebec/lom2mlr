<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:v="http://www.w3.org/2006/vcard/ns#"
	xmlns:vcard="urn:ietf:params:xml:ns:vcard-4.0"
	xmlns:lom="http://ltsc.ieee.org/xsd/LOM"
	xmlns:mlrext="http://standards.iso.org/iso-iec/19788/ext/"
	extension-element-prefixes="mlrext"
	>
	<xsl:output method="xml" encoding="UTF-8"/>
	<xsl:template match="text()" mode="individual" />
	<xsl:template match="text()" mode="is-org" />
	<xsl:template match="text()" mode="extract-org" />
	<xsl:template match="text()" />

    <xsl:strip-space elements="vcard:org vcard:fn" />

    <xsl:template match="/" >
     <rdf:RDF>
      <xsl:apply-templates select="node()"/>
     </rdf:RDF>
    </xsl:template>

    <xsl:template match="lom:contribute">
      <xsl:variable name="role" select="lom:role/lom:value/text()" />
      <xsl:choose>
        <!-- Always use the "normal" mode to extract parent
               organisation from current organisation
        <xsl:when test="$role = 'editor' or $role = 'publisher'">
          <xsl:apply-templates select="node()" mode="is-org"/>
        </xsl:when> -->
        <xsl:when test="0" />
        <xsl:otherwise>
          <xsl:apply-templates select="node()" mode="individual"/>
          <xsl:apply-templates select="node()" mode="extract-org" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:template>

    <xsl:template match="vcard:vcard" mode="individual">
      <v:VCard>
        <xsl:attribute name="rdf:about">
          <xsl:text>urn:uuid:</xsl:text>
          <xsl:value-of select="mlrext:vcard_uuid(@uuidstr)" />
        </xsl:attribute>
        <xsl:apply-templates />
        <xsl:apply-templates mode="individual" />
      </v:VCard>
    </xsl:template>

    <xsl:template match="vcard:vcard" mode="is-org">
      <v:VCard>
        <xsl:attribute name="rdf:about">
          <xsl:text>urn:uuid:</xsl:text>
          <xsl:value-of select="mlrext:vcard_uuid(@uuidstr)"/>
        </xsl:attribute>
        <xsl:apply-templates />
        <xsl:apply-templates mode="is-org" />
      </v:VCard>
    </xsl:template>

    <xsl:template match="vcard:vcard" mode="extract-org">
        <xsl:apply-templates mode="extract-org" />
    </xsl:template>

    <xsl:template match="vcard:vcard/vcard:n">
      <v:n>
        <rdf:Description>
          <xsl:apply-templates/>
        </rdf:Description>
      </v:n>
    </xsl:template>

    <xsl:template match="vcard:vcard/vcard:adr">
      <v:adr>
        <rdf:Description>
          <xsl:apply-templates/>
        </rdf:Description>
      </v:adr>
    </xsl:template>

    <!-- no genenric org -->
    <xsl:template match="vcard:vcard/vcard:org">
    </xsl:template>

    <xsl:template match="vcard:vcard/vcard:org" mode="individual">
     <v:org>
       <xsl:text>urn:uuid:</xsl:text>
       <xsl:value-of select="mlrext:vcard_uuid(@uuidstr)" />
     </v:org>
    </xsl:template>

    <xsl:template match="vcard:vcard/vcard:org" mode="is-org">
     <v:org>
       <xsl:apply-templates select="node()" mode="org_fullname"/>
     </v:org>
    </xsl:template>

    <xsl:template match="vcard:vcard/vcard:org" mode="extract-org">
     <v:VCard>
      <xsl:attribute name="rdf:about">
          <xsl:text>urn:uuid:</xsl:text>
          <xsl:value-of select="mlrext:vcard_uuid(@uuidstr)" />
        </xsl:attribute>
      <v:fn>
        <xsl:apply-templates select="node()" mode="org_fullname"/>
      </v:fn>
     </v:VCard>
    </xsl:template>

    <xsl:template match="vcard:org/vcard:text" mode="org_fullname">
       <xsl:value-of select="text()"/>
       <xsl:if test="not(position()=last())">
         <xsl:text>;</xsl:text>
       </xsl:if>
    </xsl:template>


    <xsl:template match="vcard:vcard/vcard:geo">
     <v:geo>
       <rdf:Description>
         <rdf:type rdf:ressource='concat("http://www.w3.org/2006/vcard/ns#","Location")' />
         <v:latitude />
         <v:longitude />
       </rdf:Description>
     </v:geo>
    </xsl:template>

    <xsl:template match="vcard:vcard/vcard:label">
    </xsl:template>

    <xsl:template match="vcard:vcard/vcard:tel">
     <v:tel>
       <rdf:type rdf:ressource='concat("http://www.w3.org/2006/vcard/ns#",vcard:parameters/vcard:type/vcard:text/text())' />
       <xsl:value-of select="vcard:text/text()"/>
     </v:tel>
    </xsl:template>

    <xsl:template match="vcard:vcard/vcard:email">
     <v:email>
       <xsl:value-of select="vcard:text/text()"/>
     </v:email>
    </xsl:template>

    <!-- Generic template to translate vcard fields -->
    <xsl:template match="vcard:vcard/*">
     <xsl:element name="{concat('v:', local-name())}">
       <xsl:value-of select="." />
     </xsl:element>
    </xsl:template>

    <!-- Generic template to translate vcard:n fields -->
    <xsl:template match="vcard:n/*">
     <xsl:element name="{concat('v:', local-name())}">
       <xsl:value-of select="." />
     </xsl:element>
    </xsl:template>

    <!-- Generic template to translate vcard:adr fields -->
    <xsl:template match="vcard:adr/*">
     <xsl:element name="{concat('v:', local-name())}">
       <xsl:value-of select="." />
     </xsl:element>
    </xsl:template>

    <xsl:template match="vcard:adr/vcard:type">
     <xsl:call-template name="toRDFtype" select="nodes()" />
    </xsl:template>

    <xsl:template name="toRDFtype">
     <rdf:type>
       <xsl:attribute name="rdf:ressource" value="concat('http://www.w3.org/2006/vcard/ns#', text())" />
     </rdf:type>
    </xsl:template>

</xsl:stylesheet>
