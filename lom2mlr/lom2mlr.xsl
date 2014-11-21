<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:lom="http://ltsc.ieee.org/xsd/LOM"
	xmlns:lomfr="http://www.lom-fr.fr/xsd/LOMFR"
	xmlns:lomfrens="http://pratic.ens-lyon.fr/xsd/LOMFRENS"
	xmlns:regexp="http://exslt.org/regular-expressions"
	xmlns:str="http://exslt.org/strings"
	xmlns:sets="http://exslt.org/sets"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:dc="http://purl.org/dc/elements/1.1/"
	xmlns:vcardconv="http://ntic.org/vcard"
	xmlns:vcard="urn:ietf:params:xml:ns:vcard-4.0"
	xmlns:cos="http://www.inria.fr/acacia/corese#"
    xmlns:oa="http://www.w3.org/ns/oa#"
	xmlns:gtnq="http://www.gtn-quebec.org/ns/"
	xmlns:mlrext="http://standards.iso.org/iso-iec/19788/ext/"
	xmlns:mlr1="http://standards.iso.org/iso-iec/19788/-1/ed-1/en/"
	xmlns:mlr2="http://standards.iso.org/iso-iec/19788/-2/ed-1/en/"
	xmlns:mlr3="http://standards.iso.org/iso-iec/19788/-3/ed-1/en/"
	xmlns:mlr4="http://standards.iso.org/iso-iec/19788/-4/ed-1/en/"
	xmlns:mlr5="http://standards.iso.org/iso-iec/19788/-5/ed-1/en/"
	xmlns:mlr8="http://standards.iso.org/iso-iec/19788/-8/ed-1/en/"
	xmlns:mlr9="http://standards.iso.org/iso-iec/19788/-9/ed-1/en/"
	extension-element-prefixes="regexp sets str vcardconv mlrext"
	>
	<xsl:output method="xml" encoding="UTF-8"/>

	<!-- Allow use of MLR3 properties that refine the corresponding mlr2 properties. -->
	<xsl:param name="use_mlr3" select="true()"/>

	<!-- Use email alone as basis for a (natural) person's identity. Never a good idea. -->
	<xsl:param name="person_url_from_email" select="false()"/>

	<!-- Use combination of mail and fn (or N) as basis for a (natural) person's uuid. -->
	<xsl:param name="person_uuid_from_email_fn" select="true()"/>

	<!-- Use fn (or N) alone as basis for a (natural) person's uuid -->
	<xsl:param name="person_uuid_from_fn" select="false()"/>

	<!-- Use the email alone as a basis for an organization's identifying URL. -->
	<xsl:param name="org_url_from_email" select="true()"/>

	<!-- Combine org (or fn) with country, region, city as basis for an organization's uuid -->
	<xsl:param name="org_uuid_from_org_address" select="true()"/>

	<!-- Use the org and email as a basis for an organization's uuid -->
	<xsl:param name="org_uuid_from_email_org" select="true()"/>

	<!-- Use the fn and email as a basis for an organization's uuid -->
	<xsl:param name="org_uuid_from_email_fn" select="true()"/>

	<!-- Use a org (or fn) as a basis for an organization's uuid -->
	<xsl:param name="org_uuid_from_org_or_fn" select="false()"/>

	<!-- If a natural person has a work email,
	assume it is the organization's email and not the person's email at work. -->
	<xsl:param name="suborg_use_work_email" select="false()"/>

	<!-- Mark the record with the graph information using cos:graph. -->
	<xsl:param name="use_subgraph" select="true()"/>

	<!-- If true, unique (non-reproducible) UUIDs will be marked with a gtnq:irreproducible predicate. -->
	<xsl:param name="mark_unique_uuid" select="false()"/>

	<!-- DOI URIs can be formed by prefixing 'doi:', 'hndl:' or 'http://dx.doi.org/'  -->
	<xsl:param name="doi_identity_prefix" select="'doi:'"/>

	<!-- Natural language to be used for text generation (esp. for mlr4:DES0400.) -->
	<xsl:param name="text_language" select="'eng'"/>

	<!-- A URI for the conversion machinery.  -->
	<xsl:param name="converter_id" select="'http://www.gtn-quebec/ns/lom2mlr/version/'"/>

	<!-- Use a mutable MLR record -->
	<xsl:param name="mutable_record" select="false()"/>

	<!-- A URI for the LOM itself if none is specifified in metaMetadata.  -->
	<xsl:param name="lom_uri" select="''"/>

	<!-- the version number of the converter -->
	<xsl:param name="converter_version" select="'0.1'"/>

	<xsl:variable name="mlr_namespace" select="'http://standards.iso.org/iso-iec/19788/'"/>
	<xsl:variable name="mlr1rc2" select="'http://standards.iso.org/iso-iec/19788/-1/ed-1/en/RC0002'"/>
	<xsl:variable name="mlr1rc2_uuid" select="mlrext:uuid_url($mlr1rc2)" />
	<xsl:variable name="gtn_namespace" select="'http://gtn-quebec.org/ns/'"/>
	<xsl:variable name="vcardorg_namespace" select="concat($gtn_namespace,'vcarduuid/org/')"/>
	<xsl:variable name="vcardfn_namespace" select="concat($gtn_namespace,'vcarduuid/fn/')"/>
	<xsl:variable name="vcardorg_namespace_uuid" select="mlrext:uuid_url($vcardorg_namespace)"/>
	<xsl:variable name="vcardfn_namespace_uuid" select="mlrext:uuid_url($vcardfn_namespace)"/>
	<xsl:variable name="converter_id_v" select="concat($converter_id, string($converter_version))"/>
	<xsl:variable name="lc">abcdefghijklmnopqrstuvwxyz</xsl:variable>
	<xsl:variable name="uc">ABCDEFGHIJKLMNOPQRSTUVWXYZ</xsl:variable>

	<!-- vocabularies and utilities -->
	<xsl:include href="correspondances_xsl.xsl"/>
	<xsl:include href="iso639.xsl"/>

	<!-- specific lom version (fr, ensfr) -->
	<xsl:include href="lomfr2mlr.xsl" />

	<!-- top-level templates -->
	<xsl:template match="/">
		<rdf:RDF>
			<xsl:apply-templates/>
		</rdf:RDF>
	</xsl:template>

	<xsl:template match="lom:lom">
		<xsl:if test="sets:intersection(lom:metaMetadata/lom:identifier/lom:entry/text(), lom:general/lom:identifier/lom:entry/text()|lom:technical/lom:location/text())">
			<xsl:message terminate="yes">Error: same identifier used for data and metadata!</xsl:message>
		</xsl:if>
		<xsl:variable name="lom_identifier">
			<xsl:choose>
				<xsl:when test="string-length($lom_uri) &gt; 0">
					<xsl:value-of select="$lom_uri"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates mode="identifier" select="lom:metaMetadata">
						<xsl:with-param name="technical" select="false()"/>
					</xsl:apply-templates>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="record_id">
			<xsl:choose>
				<xsl:when test="$lom_identifier != ''">
					<xsl:text>urn:uuid:</xsl:text>
					<xsl:value-of select="mlrext:uuid_string($lom_identifier, mlrext:uuid_url($converter_id_v))"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>urn:uuid:</xsl:text>
					<xsl:value-of select="mlrext:uuid_unique()"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="identifier">
			<xsl:apply-templates mode="identifier" select="lom:general">
				<xsl:with-param name="technical" select="true()"/>
			</xsl:apply-templates>
		</xsl:variable>
		<xsl:variable name="identity">
			<xsl:choose>
				<xsl:when test="$identifier = ''">
					<xsl:text>urn:uuid:</xsl:text>
					<xsl:value-of select="mlrext:uuid_unique()"/>
				</xsl:when>
				<xsl:when test="substring-after($identifier, '|') != ''">
					<xsl:text>urn:uuid:</xsl:text>
					<xsl:value-of select="mlrext:uuid_string($identifier, $mlr1rc2_uuid)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$identifier"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<mlr1:RC0002>
			<xsl:attribute name="rdf:about">
				<xsl:value-of select="$identity" />
			</xsl:attribute>
			<xsl:if test="$use_subgraph">
				<xsl:attribute name="cos:graph">
					<xsl:value-of select="$record_id"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:choose>
				<xsl:when test="substring-after($identifier, '|') != ''">
					<mlr2:DES1000>
						<xsl:value-of select="$identifier"/>
					</mlr2:DES1000>
				</xsl:when>
				<xsl:when test="$identifier = ''">
					<mlr2:DES1000>
						<xsl:value-of select="$identity"/>
					</mlr2:DES1000>
					<xsl:if test="$mark_unique_uuid">
						<gtnq:irreproducible rdf:datatype="http://www.w3.org/2001/XMLSchema#boolean">true</gtnq:irreproducible>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$use_mlr3">
					<mlr3:DES0400>
						<xsl:value-of select="$identifier"/>
					</mlr3:DES0400>
					<mlr2:DES1000>
						<xsl:value-of select="$identifier"/>
					</mlr2:DES1000>
				</xsl:when>
				<xsl:otherwise>
					<mlr2:DES1000>
						<xsl:value-of select="$identifier"/>
					</mlr2:DES1000>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:apply-templates mode="top"/>
			<xsl:apply-templates mode="metaMetadata" select="lom:metaMetadata">
				<xsl:with-param name="lom_identifier" select="$lom_identifier"/>
				<xsl:with-param name="record_id" select="$record_id"/>
				<xsl:with-param name="resource_id" select="$identity"/>
			</xsl:apply-templates>
		</mlr1:RC0002>
		<xsl:apply-templates mode="annotations">
			<xsl:with-param name="resource" select="$identity"/>
		</xsl:apply-templates>
	</xsl:template>

	<xsl:template match="text()" />
	<xsl:template match="text()" mode="top"/>
	<xsl:template match="text()" mode="general"/>
	<xsl:template match="text()" mode="lifeCycle"/>
	<xsl:template match="text()" mode="metaMetadata"/>
	<xsl:template match="text()" mode="technical"/>
	<xsl:template match="text()" mode="tech-requirement"/>
	<xsl:template match="text()" mode="educational"/>
	<xsl:template match="text()" mode="educational_learning_activity"/>
	<xsl:template match="text()" mode="educational_audience"/>
	<xsl:template match="text()" mode="rights"/>
	<xsl:template match="text()" mode="relation"/>
	<xsl:template match="text()" mode="annotation"/>
	<xsl:template match="text()" mode="annotations"/>
	<xsl:template match="text()" mode="classification"/>
	<xsl:template match="text()" mode="classification_discipline"/>
	<xsl:template match="text()" mode="vcard"/>
	<xsl:template match="text()" mode="vcard_org"/>
	<xsl:template match="text()" mode="vcard_suborg_attributes"/>
	<xsl:template match="text()" mode="vcard_suborg"/>
	<xsl:template match="text()" mode="vcard_np"/>
	<xsl:template match="text()" mode="vcard_person"/>
	<xsl:template match="text()" mode="convert_n_to_fn"/>
	<xsl:template match="text()" mode="address"/>

	<xsl:template match="*">
		<xsl:apply-templates/>
	</xsl:template>


	<!-- top-level templates -->

	<!-- use mode as a context indicator -->
	<xsl:template match="lom:general" mode="top">
		<xsl:apply-templates mode="general"/>
	</xsl:template>

	<xsl:template match="lom:lifeCycle" mode="top">
		<xsl:apply-templates mode="lifeCycle"/>
	</xsl:template>

	<xsl:template match="lom:metaMetadata" mode="metaMetadata">
		<xsl:param name="lom_identifier"/>
		<xsl:param name="record_id"/>
		<xsl:param name="resource_id"/>
		<xsl:choose>
			<xsl:when test="$mutable_record">
				<mlr8:DES0600>
					<mlr8:RC0002>
						<xsl:attribute name="rdf:about">
							<xsl:value-of select="$record_id"/>
						</xsl:attribute>
						<mlr8:DES0700>
							<xsl:value-of select="$record_id"/>
						</mlr8:DES0700>
						<xsl:if test="$lom_identifier">
							<!-- should I create a uuid1? -->
							<mlr8:DES0300>
								<xsl:value-of select="$lom_identifier"/>
							</mlr8:DES0300>
						</xsl:if>
						<mlr8:DES1000>
							<mlr8:RC0004>
								<mlr8:DES1500>IEEE 1484.12.1-2002 LOM</mlr8:DES1500>
							</mlr8:RC0004>
						</mlr8:DES1000>
						<xsl:if test="$mark_unique_uuid and $lom_identifier = ''">
							<gtnq:irreproducible rdf:datatype="http://www.w3.org/2001/XMLSchema#boolean">true</gtnq:irreproducible>
						</xsl:if>
						<xsl:apply-templates mode="metaMetadata"/>
					</mlr8:RC0002>
				</mlr8:DES0600>
			</xsl:when>
			<xsl:otherwise>
				<mlr8:DES0100>
					<mlr8:RC0001>
						<xsl:attribute name="rdf:about">
							<xsl:value-of select="$record_id"/>
						</xsl:attribute>
						<xsl:if test="$lom_identifier">
							<!-- should I create a uuid1? -->
							<mlr8:DES0300>
								<xsl:value-of select="$lom_identifier"/>
							</mlr8:DES0300>
						</xsl:if>
						<mlr8:DES1000>
							<mlr8:RC0004>
								<mlr8:DES1500>IEEE 1484.12.1-2002 LOM</mlr8:DES1500>
							</mlr8:RC0004>
						</mlr8:DES1000>
						<xsl:if test="$mark_unique_uuid and $lom_identifier = ''">
							<gtnq:irreproducible rdf:datatype="http://www.w3.org/2001/XMLSchema#boolean">true</gtnq:irreproducible>
						</xsl:if>
						<xsl:apply-templates mode="metaMetadata"/>
					</mlr8:RC0001>
				</mlr8:DES0100>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="lom:technical" mode="top">
		<xsl:apply-templates mode="technical"/>
	</xsl:template>

	<!-- General templates -->

	<xsl:template match="lom:identifier" mode="general">
		<mlr2:DES1000>
			<xsl:attribute name="rdf:resource">
				<xsl:value-of select="lom:entry/text()"/>
			</xsl:attribute>
		</mlr2:DES1000>
		<xsl:if test="$use_mlr3">
			<mlr3:DES0400>
				<xsl:attribute name="rdf:resource">
					<xsl:value-of select="lom:entry/text()"/>
				</xsl:attribute>
			</mlr3:DES0400>
		</xsl:if>
	</xsl:template>

	<xsl:template match="lom:title" mode="general">
		<xsl:apply-templates select="lom:string" mode="langstring">
			<xsl:with-param name="nodename" select="'mlr2:DES0100'"/>
		</xsl:apply-templates>
	</xsl:template>

	<xsl:template match="lom:language" mode="general">
		<xsl:if test="$use_mlr3 and regexp:test(text(),'^[a-z][a-z][a-z]?(\-[A-Z][A-Z])?$')">
			<mlr3:DES0500>
			<xsl:call-template name="language">
				<xsl:with-param name="l" select="text()"/>
			</xsl:call-template>
			</mlr3:DES0500>
		</xsl:if>
		<mlr2:DES1200>
			<xsl:call-template name="language">
				<xsl:with-param name="l" select="text()"/>
			</xsl:call-template>
		</mlr2:DES1200>
	</xsl:template>

	<xsl:template match="lom:description" mode="general">
		<xsl:apply-templates select="lom:string" mode="langstring">
			<xsl:with-param name="nodename">mlr2:DES0400</xsl:with-param>
		</xsl:apply-templates>
		<xsl:apply-templates select="lom:string[mlrext:is_absolute_iri(text())]" mode="urlstring">
			<xsl:with-param name="nodename">mlr2:DES1800</xsl:with-param>
		</xsl:apply-templates>
		<xsl:if test="$use_mlr3">
			<xsl:apply-templates select="lom:string" mode="langstring">
				<xsl:with-param name="nodename">mlr3:DES0200</xsl:with-param>
			</xsl:apply-templates>
		</xsl:if>
	</xsl:template>

	<xsl:template match="lom:keyword" mode="general">
		<xsl:apply-templates select="lom:string" mode="langstring">
			<xsl:with-param name="nodename" select="'mlr2:DES0300'"/>
		</xsl:apply-templates>
	</xsl:template>

	<xsl:template match="lom:coverage" mode="general">
		<xsl:apply-templates select="lom:string" mode="langstring">
			<xsl:with-param name="nodename" select="'mlr2:DES1400'"/>
		</xsl:apply-templates>
	</xsl:template>

	<!-- lifeCycle -->

	<xsl:template match="lom:contribute[lom:role[lom:source/text()='LOMv1.0' and lom:value/text()='author']]" mode="lifeCycle">
		<xsl:choose>
			<xsl:when test="lom:date/lom:dateTime">
				<mlr2:DES0700>
					<xsl:value-of select="lom:date/lom:dateTime/text()" />
				</mlr2:DES0700>
				<xsl:choose>
					<!-- first cases: valid 8601 date or datetime -->
					<xsl:when test="$use_mlr3 and lom:date/lom:dateTime and regexp:test(lom:date/lom:dateTime/text(), '^([\+-]?\d{4}(?!\d{2}\b))((-?)((0[1-9]|1[0-2])(\3([12]\d|0[1-9]|3[01]))?|W([0-4]\d|5[0-2])(-?[1-7])?|(00[1-9]|0[1-9]\d|[12]\d{2}|3([0-5]\d|6[1-6]))))$')">
						<mlr3:DES0100 rdf:datatype="http://www.w3.org/2001/XMLSchema#date">
							<xsl:value-of select="lom:date/lom:dateTime/text()" />
						</mlr3:DES0100>
					</xsl:when>
					<xsl:when test="$use_mlr3 and lom:date/lom:dateTime and regexp:test(lom:date/lom:dateTime/text(), '^([\+-]?\d{4}(?!\d{2}\b))((-?)((0[1-9]|1[0-2])(\3([12]\d|0[1-9]|3[01]))?|W([0-4]\d|5[0-2])(-?[1-7])?|(00[1-9]|0[1-9]\d|[12]\d{2}|3([0-5]\d|6[1-6])))([T\s]((([01]\d|2[0-3])((:?)[0-5]\d)?|24\:?00)([\.,]\d+(?!:))?)?(\17[0-5]\d([\.,]\d+)?)?([zZ]|([\+-])([01]\d|2[0-3]):?([0-5]\d)?)?)?)?$')">
						<mlr3:DES0100 rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">
							<xsl:value-of select="lom:date/lom:dateTime/text()" />
						</mlr3:DES0100>
					</xsl:when>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="lom:date/lom:description">
				<xsl:apply-templates select="lom:date/lom:description/lom:string" mode="langstring">
					<xsl:with-param name="nodename" select="'mlr2:DES0700'"/>
				</xsl:apply-templates>
			</xsl:when>
		</xsl:choose>
		<xsl:apply-templates mode="lifeCycle">
			<xsl:with-param name="dc_entity_role" select="'mlr2:DES0200'" />
			<xsl:with-param name="mlr9_entity_role" select="'mlr2:DES1600'" />
		</xsl:apply-templates>
	</xsl:template>

	<xsl:template match="lom:entity" mode="lifeCycle">
		<xsl:param name="dc_entity_role"/>
		<xsl:param name="mlr9_entity_role"/>
		<xsl:variable name="vcard" select="vcardconv:convert(text())"/>
		<xsl:element name="{$dc_entity_role}">
			<xsl:value-of select="$vcard/vcard:fn/vcard:text/text()"/>
		</xsl:element>
		<xsl:element name="{$mlr9_entity_role}">
			<xsl:apply-templates mode="vcard" select="$vcard"/>
		</xsl:element>
	</xsl:template>

	<xsl:template match="lom:contribute[lom:role[lom:source/text()='LOMv1.0' and lom:value/text()='publisher']]" mode="lifeCycle">
		<!-- publisher -->
		<xsl:apply-templates mode="lifeCycle">
			<xsl:with-param name="dc_entity_role" select="'mlr2:DES0500'" />
			<xsl:with-param name="mlr9_entity_role" select="'mlr2:DES1900'" />
		</xsl:apply-templates>
	</xsl:template>


	<xsl:template match="lom:contribute" mode="lifeCycle">
		<!-- contributor -->
		<xsl:apply-templates mode="lifeCycle">
			<xsl:with-param name="dc_entity_role" select="'mlr2:DES0600'" />
			<xsl:with-param name="mlr9_entity_role" select="'mlr2:DES2000'" />
		</xsl:apply-templates>
	</xsl:template>

	<!-- vcard handling -->

	<xsl:template match="vcard:vcard" mode="vcard">
		<xsl:choose>
			<xsl:when test="vcard:n and count(vcard:n/vcard:*) &gt; 0">
				<mlr9:RC0001>
					<!-- Whether we will define a organization for that person -->
					<xsl:variable name="has_suborg_groupless" select="vcard:org[not(@group)] or vcard:url[not(@group) and vcard:parameters/vcard:type/vcard:text/text() = 'WORK'] or vcard:adr[not(@group) and vcard:parameters/vcard:type/vcard:text/text() = 'WORK'] or (($suborg_use_work_email) and vcard:email[not(@group) and vcard:parameters/vcard:type/vcard:text/text() = 'WORK'])"/>
					<xsl:variable name="suborg_groups">
						<xsl:text>:</xsl:text>
						<xsl:apply-templates mode="vcard_suborg_search_group" select="*[@group and (name(.) = 'org' or vcard:parameters/vcard:type/vcard:text/text() = 'WORK')]"/>
					</xsl:variable>
					<xsl:variable name="has_group_suborg" select="string-length($suborg_groups) &gt; 1"/>
					<xsl:variable name="has_suborg" select="$has_group_suborg or $has_suborg_groupless"/>
					<xsl:attribute name="rdf:about">
						<xsl:call-template name="natural_person_identity_url">
							<xsl:with-param name="has_suborg" select="$has_suborg"/>
						</xsl:call-template>
					</xsl:attribute>
					<xsl:variable name="identity">
						<xsl:call-template name="natural_person_identity">
							<xsl:with-param name="has_suborg" select="$has_suborg"/>
						</xsl:call-template>
					</xsl:variable>
					<xsl:if test="string($identity) != ''">
						<mlr9:DES0100>
							<xsl:value-of select="$identity"/>
						</mlr9:DES0100>
					</xsl:if>
					<xsl:apply-templates mode="vcard_np" />
					<xsl:if test="$has_suborg_groupless">
						<xsl:apply-templates mode="vcard_suborg" select="."/>
					</xsl:if>
					<xsl:if test="$has_group_suborg">
						<xsl:apply-templates mode="vcard_apply_group_to_suborg" select="str:tokenize($suborg_groups, ':')">
							<xsl:with-param name="vcard" select="."/>
						</xsl:apply-templates>
					</xsl:if>
					<xsl:apply-templates mode="vcard_person" />
					<xsl:apply-templates mode="address" select="vcard:adr[vcard:parameters/vcard:type/vcard:text/text() = 'HOME']"/>
				</mlr9:RC0001>
			</xsl:when>
			<xsl:when test="vcard:org or (vcard:*[vcard:parameters/vcard:type/vcard:text/text() = 'WORK'] and not(vcard:*[vcard:parameters/vcard:type/vcard:text/text() = 'HOME']))">
				<mlr9:RC0002>
					<xsl:attribute name="rdf:about">
						<xsl:call-template name="org_identity_url"/>
					</xsl:attribute>
					<xsl:variable name="identity">
						<xsl:call-template name="org_identity"/>
					</xsl:variable>
					<xsl:if test="string($identity) != ''">
						<mlr9:DES0100>
							<xsl:value-of select="$identity"/>
						</mlr9:DES0100>
					</xsl:if>
					<xsl:apply-templates mode="vcard_org" />
					<xsl:apply-templates mode="address" select="vcard:adr[vcard:parameters/vcard:type/vcard:text/text() = 'WORK']"/>
					<xsl:if test="vcard:geo">
						<mlr9:DES1100>
							<mlr9:RC0003>
								<xsl:attribute name="rdf:about">
									<xsl:text>urn:uuid:</xsl:text>
									<xsl:value-of select="mlrext:uuid_unique()"/>
								</xsl:attribute>
								<xsl:if test="vcard:geo">
									<mlr9:DES1300 rdf:datatype="http://www.w3.org/2001/XMLSchema#float">
										<xsl:value-of select="substring-before(vcard:geo[1]/vcard:uri/text(),';')"/>
									</mlr9:DES1300>
									<mlr9:DES1200 rdf:datatype="http://www.w3.org/2001/XMLSchema#float">
										<xsl:value-of select="substring-after(vcard:geo[1]/vcard:uri/text(),';')"/>
									</mlr9:DES1200>
								</xsl:if>
							</mlr9:RC0003>
						</mlr9:DES1100>
					</xsl:if>
					<xsl:apply-templates mode="vcard_person" />
				</mlr9:RC0002>
			</xsl:when>
			<xsl:otherwise>
				<mlr1:RC0003>
					<!-- for identity, treat persons like natural persons -->
					<xsl:variable name="identity">
						<xsl:call-template name="natural_person_identity"/>
					</xsl:variable>
					<xsl:if test="string($identity) != ''">
						<mlr9:DES0100>
							<xsl:value-of select="$identity"/>
						</mlr9:DES0100>
					</xsl:if>
					<xsl:apply-templates mode="vcard_person" />
					<xsl:apply-templates mode="address" select="vcard:adr[vcard:parameters/vcard:type/vcard:text/text()]"/>
				</mlr1:RC0003>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- VCard: natural persons -->

	<xsl:template name="natural_person_identity_url">
		<xsl:param name="has_suborg"/>
		<xsl:choose>
			<xsl:when test="vcard:x-ablabel[vcard:unknown/text()='FOAF' and @group]">
				<!-- From http://www.w3.org/2002/12/cal/vcard-notes.html -->
				<xsl:variable name='group' select="vcard:x-ablabel[vcard:unknown/text()='FOAF' and @group]/@group"/>
				<xsl:value-of select="vcard:url[@group=$group]/vcard:uri/text()"/>
			</xsl:when>
			<xsl:when test="vcard:url[vcard:parameters/vcard:type/vcard:text/text() = 'pref' and not(vcard:parameters/vcard:type/vcard:text/text() = 'WORK')]">
				<xsl:value-of select="vcard:url[vcard:parameters/vcard:type/vcard:text/text() = 'pref' and not(vcard:parameters/vcard:type/vcard:text/text() = 'WORK')][1]/vcard:uri/text()"/>
			</xsl:when>
			<xsl:when test="vcard:url[not(vcard:parameters/vcard:type/vcard:text/text() = 'WORK')]">
				<xsl:value-of select="vcard:url[not(vcard:parameters/vcard:type/vcard:text/text() = 'WORK')][1]/vcard:uri/text()"/>
			</xsl:when>
			<xsl:when test="$person_uuid_from_email_fn and vcard:email[vcard:parameters/vcard:type/vcard:text/text() = 'pref' and not($has_suborg and vcard:parameters/vcard:type/vcard:text/text() = 'WORK')]">
				<xsl:variable name="fn">
					<xsl:choose>
						<xsl:when test="vcard:fn">
							<xsl:value-of select="vcard:fn/vcard:text/text()"/>
						</xsl:when>
						<xsl:otherwise>
							<!-- we know vcard:n exists -->
							<xsl:apply-templates mode="convert_n_to_fn" select="vcard:n"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:text>urn:uuid:</xsl:text>
				<xsl:value-of select="mlrext:uuid_string($fn, mlrext:uuid_url(concat('mailto:', vcard:email[vcard:parameters/vcard:type/vcard:text/text() = 'pref' and not($has_suborg and vcard:parameters/vcard:type/vcard:text/text() = 'WORK')][1]/vcard:text/text())))"/>
			</xsl:when>
			<xsl:when test="$person_uuid_from_email_fn and vcard:email[not($has_suborg and vcard:parameters/vcard:type/vcard:text/text() = 'WORK')]">
				<xsl:variable name="fn">
					<xsl:choose>
						<xsl:when test="vcard:fn">
							<xsl:value-of select="vcard:fn/vcard:text/text()"/>
						</xsl:when>
						<xsl:otherwise>
							<!-- we know vcard:n exists -->
							<xsl:apply-templates mode="convert_n_to_fn" select="vcard:n"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:text>urn:uuid:</xsl:text>
				<xsl:value-of select="mlrext:uuid_string($fn, mlrext:uuid_url(concat('mailto:', vcard:email[not($has_suborg and vcard:parameters/vcard:type/vcard:text/text() = 'WORK')][1]/vcard:text/text())))"/>
			</xsl:when>
			<xsl:when test="$person_url_from_email and vcard:email[not($has_suborg and vcard:parameters/vcard:type/vcard:text/text() = 'WORK')]">
				<xsl:text>mailto:</xsl:text>
				<xsl:value-of select="vcard:email[not($has_suborg and vcard:parameters/vcard:type/vcard:text/text() = 'WORK')][1]/vcard:text/text()"/>
			</xsl:when>
			<xsl:when test="$person_uuid_from_fn">
				<xsl:variable name="fn">
					<xsl:choose>
						<xsl:when test="vcard:fn">
							<xsl:value-of select="vcard:fn/vcard:text/text()"/>
						</xsl:when>
						<xsl:otherwise>
							<!-- we know vcard:n exists -->
							<xsl:apply-templates mode="convert_n_to_fn" select="vcard:n"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:text>urn:uuid:</xsl:text>
				<xsl:value-of select="mlrext:uuid_string($fn)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>urn:uuid:</xsl:text>
				<xsl:value-of select="mlrext:uuid_unique()"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="natural_person_identity">
		<xsl:param name="has_suborg"/>
		<xsl:choose>
			<xsl:when test="vcard:x-ablabel[vcard:unknown/text()='FOAF' and @group]">
				<!-- From http://www.w3.org/2002/12/cal/vcard-notes.html -->
				<xsl:variable name='group' select="vcard:x-ablabel[vcard:unknown/text()='FOAF' and @group]/@group"/>
				<xsl:value-of select="vcard:url[@group=$group]/vcard:uri/text()"/>
			</xsl:when>
			<xsl:when test="vcard:url[vcard:parameters/vcard:type/vcard:text/text() = 'pref' and not(vcard:parameters/vcard:type/vcard:text/text() = 'WORK')]">
				<xsl:value-of select="vcard:url[vcard:parameters/vcard:type/vcard:text/text() = 'pref' and not(vcard:parameters/vcard:type/vcard:text/text() = 'WORK')][1]/vcard:uri/text()"/>
			</xsl:when>
			<xsl:when test="vcard:url[not(vcard:parameters/vcard:type/vcard:text/text() = 'WORK')]">
				<xsl:value-of select="vcard:url[not(vcard:parameters/vcard:type/vcard:text/text() = 'WORK')][1]/vcard:uri/text()"/>
			</xsl:when>
			<xsl:when test="$person_uuid_from_email_fn and vcard:email[vcard:parameters/vcard:type/vcard:text/text() = 'pref' and not($has_suborg and vcard:parameters/vcard:type/vcard:text/text() = 'WORK')]">
				<xsl:text>cn=</xsl:text>
				<xsl:choose>
					<xsl:when test="vcard:fn">
						<xsl:value-of select="vcard:fn/vcard:text/text()"/>
					</xsl:when>
					<xsl:otherwise>
						<!-- we know vcard:n exists -->
						<xsl:apply-templates mode="convert_n_to_fn" select="vcard:n"/>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:text>,mail=</xsl:text>
				<xsl:value-of select="vcard:email[vcard:parameters/vcard:type/vcard:text/text() = 'pref' and not($has_suborg and vcard:parameters/vcard:type/vcard:text/text() = 'WORK')][1]/vcard:text/text()"/>
			</xsl:when>
			<xsl:when test="$person_uuid_from_email_fn and vcard:email[not($has_suborg and vcard:parameters/vcard:type/vcard:text/text() = 'WORK')]">
				<xsl:text>cn=</xsl:text>
				<xsl:choose>
					<xsl:when test="vcard:fn">
						<xsl:value-of select="vcard:fn/vcard:text/text()"/>
					</xsl:when>
					<xsl:otherwise>
						<!-- we know vcard:n exists -->
						<xsl:apply-templates mode="convert_n_to_fn" select="vcard:n"/>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:text>,mail=</xsl:text>
				<xsl:value-of select="vcard:email[not($has_suborg and vcard:parameters/vcard:type/vcard:text/text() = 'WORK')][1]/vcard:text/text()"/>
			</xsl:when>
			<xsl:when test="$person_url_from_email and vcard:email[not($has_suborg and vcard:parameters/vcard:type/vcard:text/text() = 'WORK')]">
				<xsl:text>mailto:</xsl:text>
				<xsl:value-of select="vcard:email[not($has_suborg and vcard:parameters/vcard:type/vcard:text/text() = 'WORK')][1]/vcard:text/text()"/>
			</xsl:when>
			<xsl:when test="$person_uuid_from_fn">
				<xsl:choose>
					<xsl:when test="vcard:fn">
						<xsl:value-of select="vcard:fn/vcard:text/text()"/>
					</xsl:when>
					<xsl:otherwise>
						<!-- we know vcard:n exists -->
						<xsl:apply-templates mode="convert_n_to_fn" select="vcard:n"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
		</xsl:choose>
	</xsl:template>



	<!-- vcard persons and natural persons -->
	<xsl:template match="vcard:fn" mode="vcard_person">
		<mlr9:DES0200>
			<xsl:value-of select="vcard:text/text()"/>
		</mlr9:DES0200>
		<mlr9:DES0500>
			<xsl:value-of select="vcard:text/text()"/>
		</mlr9:DES0500>
	</xsl:template>

	<xsl:template match="vcard:x-skype" mode="vcard_np">
		<mlr9:DES1400>
			<mlr9:RC0006>
				<mlr9:DES1700>Skype</mlr9:DES1700>
				<mlr9:DES1800><xsl:value-of select="vcard:unknown/text()"/></mlr9:DES1800>
			</mlr9:RC0006>
		</mlr9:DES1400>
	</xsl:template>

	<xsl:template match="vcard:x-skype-username" mode="vcard_np">
		<mlr9:DES1400>
			<mlr9:RC0006>
				<mlr9:DES1700>Skype</mlr9:DES1700>
				<mlr9:DES1800><xsl:value-of select="vcard:unknown/text()"/></mlr9:DES1800>
			</mlr9:RC0006>
		</mlr9:DES1400>
	</xsl:template>

	<xsl:template match="vcard:x-socialprofile" mode="vcard_np">
		<mlr9:DES1400>
			<mlr9:RC0006>
				<mlr9:DES1700><xsl:value-of select="vcard:parameters/vcard:type/vcard:text/text()"/></mlr9:DES1700>
				<mlr9:DES1800><xsl:value-of select="vcard:unknown/text()"/></mlr9:DES1800>
			</mlr9:RC0006>
		</mlr9:DES1400>
	</xsl:template>

	<xsl:template match="vcard:email" mode="vcard_np">
		<!-- TODO: Edge case with a work email but no other org info should also be in. -->
		<xsl:if test="not(vcard:parameters/vcard:type/vcard:text/text() = 'WORK')">
			<mlr9:DES0800>
				<xsl:value-of select="vcard:text/text()"/>
			</mlr9:DES0800>
		</xsl:if>
	</xsl:template>

	<xsl:template match="vcard:tel" mode="vcard_np">
		<mlr9:DES1400>
			<mlr9:RC0007>
				<xsl:if test="vcard:parameters/vcard:type/vcard:text/text() = 'HOME'">
					<mlr9:DES1900>T010</mlr9:DES1900>
				</xsl:if>
				<xsl:if test="vcard:parameters/vcard:type/vcard:text/text() = 'WORK'">
					<mlr9:DES1900>T020</mlr9:DES1900>
				</xsl:if>
				<xsl:if test="vcard:parameters/vcard:type/vcard:text/text() = 'CELL'">
					<mlr9:DES1900>T040</mlr9:DES1900>
				</xsl:if>
				<xsl:if test="vcard:parameters/vcard:type/vcard:text/text() = 'FAX'">
					<mlr9:DES1900>T050</mlr9:DES1900>
				</xsl:if>
				<xsl:if test="vcard:parameters/vcard:type/vcard:text/text() = 'VOICE'">
					<mlr9:DES1900>T060</mlr9:DES1900>
				</xsl:if>
				<!-- heuristics for fixed? If there is a home/work mobile other than self... -->
				<mlr9:DES2000>
					<xsl:value-of select="vcard:text/text()"/></mlr9:DES2000>
			</mlr9:RC0007>
		</mlr9:DES1400>
	</xsl:template>

	<xsl:template match="vcard:n" mode="vcard_np">
		<xsl:if test="not(../vcard:fn)">
			<mlr9:DES0500>
				<xsl:apply-templates mode="convert_n_to_fn" select="."/>
			</mlr9:DES0500>
		</xsl:if>
		<mlr9:DES0600>
			<xsl:value-of select="vcard:surname/text()"/>
			<xsl:text>;</xsl:text>
			<xsl:value-of select="vcard:given/text()"/>
			<xsl:text>;</xsl:text>
			<xsl:value-of select="vcard:additional/text()"/>
			<xsl:text>;</xsl:text>
			<xsl:value-of select="vcard:prefix/text()"/>
			<xsl:text>;</xsl:text>
			<xsl:value-of select="vcard:suffix/text()"/>
		</mlr9:DES0600>
		<mlr9:DES0300>
			<xsl:value-of select="vcard:surname/text()"/>
		</mlr9:DES0300>
		<mlr9:DES0400>
			<xsl:value-of select="vcard:given/text()"/>
		</mlr9:DES0400>
	</xsl:template>

	<xsl:template match="vcard:n" mode="convert_n_to_fn">
		<xsl:variable name="fn">
			<xsl:value-of select="vcard:prefix/text()"/>
			<xsl:if test="vcard:given">
				<xsl:text> </xsl:text>
				<xsl:value-of select="vcard:given/text()"/>
			</xsl:if>
			<xsl:if test="vcard:additional">
				<xsl:text> </xsl:text>
				<xsl:value-of select="vcard:additional/text()"/>
			</xsl:if>
			<xsl:if test="vcard:surname">
				<xsl:text> </xsl:text>
				<xsl:value-of select="vcard:surname/text()"/>
			</xsl:if>
			<xsl:if test="vcard:suffix">
				<xsl:text> </xsl:text>
				<xsl:value-of select="vcard:suffix/text()"/>
			</xsl:if>
		</xsl:variable>
		<xsl:value-of select="normalize-space($fn)"/>
	</xsl:template>

	<!-- vcard: Sub-organization -->

	<xsl:template match="vcard:*" mode="vcard_suborg_search_group">
		<xsl:variable name="group" select="@group"/>
		<xsl:if test="not(preceding-sibling::*[@group=$group and (name(.)='org' or vcard:parameters/vcard:type/vcard:text/text() = 'WORK')])">
			<xsl:value-of select="@group"/>
			<xsl:text>:</xsl:text>
		</xsl:if>
	</xsl:template>

	<xsl:template match="*" mode="vcard_apply_group_to_suborg">
		<xsl:param name="vcard"/>
		<xsl:apply-templates select="$vcard" mode="vcard_suborg">
			<xsl:with-param name="group" select="text()"/>
		</xsl:apply-templates>
	</xsl:template>

	<xsl:template match="vcard:vcard"  mode="vcard_suborg">
		<xsl:param name="group"/>
		<mlr9:DES0900>
			<mlr9:RC0002>
				<xsl:attribute name="rdf:about">
					<xsl:call-template name="suborg_identity_url">
						<xsl:with-param name="group" select="$group"/>
					</xsl:call-template>
				</xsl:attribute>
				<xsl:variable name="identity">
					<xsl:call-template name="suborg_identity">
						<xsl:with-param name="group" select="$group"/>
					</xsl:call-template>
				</xsl:variable>
				<xsl:if test="string($identity) != ''">
					<mlr9:DES0100>
						<xsl:value-of select="$identity"/>
					</mlr9:DES0100>
				</xsl:if>
				<xsl:apply-templates mode="vcard_suborg_attributes">
					<xsl:with-param name="group" select="$group"/>
				</xsl:apply-templates>
				<xsl:apply-templates mode="address" select="vcard:adr[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK']"/>
				<xsl:if test="vcard:adr[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK']">
					<mlr9:DES1100>
						<mlr9:RC0003>
							<xsl:attribute name="rdf:about">
								<xsl:text>urn:uuid:</xsl:text>
								<xsl:value-of select="mlrext:uuid_unique()"/>
							</xsl:attribute>
							<!-- skip geo which might be home address -->
						</mlr9:RC0003>
					</mlr9:DES1100>
				</xsl:if>
			</mlr9:RC0002>
		</mlr9:DES0900>
	</xsl:template>

	<xsl:template name="suborg_identity_url">
		<xsl:param name="group"/>
		<xsl:choose>
			<xsl:when test="vcard:url[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK' and vcard:parameters/vcard:type/vcard:text/text() = 'pref']">
				<xsl:value-of select="vcard:url[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK' and vcard:parameters/vcard:type/vcard:text/text() = 'pref'][1]/vcard:uri/text()"/>
			</xsl:when>
			<xsl:when test="vcard:url[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK']">
				<xsl:value-of select="vcard:url[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK'][1]/vcard:uri/text()"/>
			</xsl:when>
			<xsl:when test="$org_uuid_from_email_org and $suborg_use_work_email and vcard:org[string(@group) = $group] and vcard:email[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK' and vcard:parameters/vcard:type/vcard:text/text() = 'pref']">
				<xsl:text>urn:uuid:</xsl:text>
				<xsl:value-of select="mlrext:uuid_string(vcard:org[string(@group) = $group]/vcard:text/text(), mlrext:uuid_url(concat('mailto:', vcard:email[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK' and vcard:parameters/vcard:type/vcard:text/text() = 'pref'][1]/vcard:text/text())))"/>
			</xsl:when>
			<xsl:when test="$org_uuid_from_email_org and $suborg_use_work_email and vcard:org[string(@group) = $group] and vcard:email[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK']">
				<xsl:text>urn:uuid:</xsl:text>
				<xsl:value-of select="mlrext:uuid_string(vcard:org[string(@group) = $group]/vcard:text/text(), mlrext:uuid_url(concat('mailto:', vcard:email[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK'][1]/vcard:text/text())))"/>
			</xsl:when>
			<xsl:when test="$org_url_from_email and $suborg_use_work_email and vcard:email[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK' and vcard:parameters/vcard:type/vcard:text/text() = 'pref']">
				<xsl:text>mailto:</xsl:text>
				<xsl:value-of select="vcard:email[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK' and vcard:parameters/vcard:type/vcard:text/text() = 'pref'][1]/vcard:text/text()"/>
			</xsl:when>
			<xsl:when test="$org_url_from_email and $suborg_use_work_email and vcard:email[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK']">
				<xsl:text>mailto:</xsl:text>
				<xsl:value-of select="vcard:email[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK'][1]/vcard:text/text()"/>
			</xsl:when>
			<xsl:when test="$org_uuid_from_org_address and vcard:adr[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK'] and vcard:org[string(@group) = $group]">
				<xsl:variable name="id">
					<xsl:value-of select="vcard:org[string(@group) = $group]/vcard:text/text()"/>
					<xsl:if test="vcard:adr[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK']/vcard:country/text()">
						<xsl:text>;</xsl:text>
						<xsl:value-of select="vcard:adr[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK']/vcard:country/text()"/>
					</xsl:if>
					<xsl:if test="vcard:adr[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK']/vcard:region/text()">
						<xsl:text>;</xsl:text>
						<xsl:value-of select="vcard:adr[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK']/vcard:region/text()"/>
					</xsl:if>
					<xsl:if test="vcard:adr[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK']/vcard:city/text()">
						<xsl:text>;</xsl:text>
						<xsl:value-of select="vcard:adr[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK']/vcard:city/text()"/>
					</xsl:if>
				</xsl:variable>
				<xsl:text>urn:uuid:</xsl:text>
				<xsl:value-of select="mlrext:uuid_string($id)"/>
			</xsl:when>
			<xsl:when test="$org_uuid_from_org_or_fn and vcard:org[string(@group) = $group]">
				<xsl:text>urn:uuid:</xsl:text>
				<xsl:value-of select="mlrext:uuid_string(vcard:org[string(@group) = $group]/vcard:text/text())"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>urn:uuid:</xsl:text>
				<xsl:value-of select="mlrext:uuid_unique()"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="suborg_identity">
		<xsl:param name="group"/>
		<xsl:choose>
			<xsl:when test="vcard:url[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK' and vcard:parameters/vcard:type/vcard:text/text() = 'pref']">
				<xsl:value-of select="vcard:url[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK' and vcard:parameters/vcard:type/vcard:text/text() = 'pref'][1]/vcard:uri/text()"/>
			</xsl:when>
			<xsl:when test="vcard:url[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK']">
				<xsl:value-of select="vcard:url[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK'][1]/vcard:uri/text()"/>
			</xsl:when>
			<xsl:when test="$org_uuid_from_email_org and $suborg_use_work_email and vcard:org and vcard:email[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK' and vcard:parameters/vcard:type/vcard:text/text() = 'pref']">
				<xsl:text>cn=</xsl:text>
				<xsl:value-of select="vcard:org/vcard:text/text()"/>
				<xsl:text>,mail=</xsl:text>
				<xsl:value-of select="vcard:email[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK' and vcard:parameters/vcard:type/vcard:text/text() = 'pref'][1]/vcard:text/text()"/>
			</xsl:when>
			<xsl:when test="$org_uuid_from_email_org and $suborg_use_work_email and vcard:org[string(@group) = $group] and vcard:email[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK']">
				<xsl:text>cn=</xsl:text>
				<xsl:value-of select="vcard:org[string(@group) = $group]/vcard:text/text()"/>
				<xsl:text>,mail=</xsl:text>
				<xsl:value-of select="vcard:email[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK'][1]/vcard:text/text()"/>
			</xsl:when>
			<xsl:when test="$org_url_from_email and $suborg_use_work_email and vcard:email[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK' and vcard:parameters/vcard:type/vcard:text/text() = 'pref']">
				<xsl:value-of select="vcard:email[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK' and vcard:parameters/vcard:type/vcard:text/text() = 'pref'][1]/vcard:text/text()"/>
			</xsl:when>
			<xsl:when test="$org_url_from_email and $suborg_use_work_email and vcard:email[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK']">
				<xsl:value-of select="vcard:email[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK'][1]/vcard:text/text()"/>
			</xsl:when>
			<xsl:when test="$org_uuid_from_org_address and vcard:adr[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK'] and vcard:org[string(@group) = $group]">
				<xsl:value-of select="vcard:org[string(@group) = $group]/vcard:text/text()"/>
				<xsl:if test="vcard:adr[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK']/vcard:country/text()">
					<xsl:text>;</xsl:text>
					<xsl:value-of select="vcard:adr[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK']/vcard:country/text()"/>
				</xsl:if>
				<xsl:if test="vcard:adr[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK']/vcard:region/text()">
					<xsl:text>;</xsl:text>
					<xsl:value-of select="vcard:adr[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK']/vcard:region/text()"/>
				</xsl:if>
				<xsl:if test="vcard:adr[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK']/vcard:city/text()">
					<xsl:text>;</xsl:text>
					<xsl:value-of select="vcard:adr[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK']/vcard:city/text()"/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$org_uuid_from_org_or_fn and vcard:org">
				<xsl:value-of select="vcard:org[string(@group) = $group]/vcard:text/text()"/>
			</xsl:when>
		</xsl:choose>
	</xsl:template>


	<xsl:template match="vcard:email[vcard:parameters/vcard:type/vcard:text/text() = 'WORK']" mode="vcard_suborg_attributes">
		<xsl:param name="group"/>
		<xsl:if test="string(@group) = $group">
			<mlr9:DES0800>
				<xsl:value-of select="vcard:text/text()"/>
			</mlr9:DES0800>
		</xsl:if>
	</xsl:template>


	<xsl:template match="vcard:org" mode="vcard_suborg_attributes">
		<xsl:param name="group"/>
		<xsl:if test="string(@group) = $group">
			<mlr9:DES1000>
				<xsl:value-of select="vcard:text/text()"/>
			</mlr9:DES1000>
		</xsl:if>
	</xsl:template>

	<!-- VCard : Organizations -->

	<xsl:template name="org_identity_url">
		<xsl:choose>
			<xsl:when test="vcard:x-ablabel[vcard:unknown/text()='FOAF' and @group]">
				<!-- From http://www.w3.org/2002/12/cal/vcard-notes.html -->
				<xsl:variable name='group' select="vcard:x-ablabel[vcard:unknown/text()='FOAF' and @group]/@group"/>
				<xsl:value-of select="vcard:url[@group=$group]/vcard:uri/text()"/>
			</xsl:when>
			<xsl:when test="vcard:url[vcard:parameters/vcard:type/vcard:text/text() = 'pref']">
				<xsl:value-of select="vcard:url[vcard:parameters/vcard:type/vcard:text/text() = 'pref'][1]/vcard:uri/text()"/>
			</xsl:when>
			<xsl:when test="vcard:url">
				<xsl:value-of select="vcard:url[1]/vcard:uri/text()"/>
			</xsl:when>
			<xsl:when test="$org_uuid_from_email_org and vcard:org and vcard:email[vcard:parameters/vcard:type/vcard:text/text() = 'pref']">
				<xsl:text>urn:uuid:</xsl:text>
				<xsl:value-of select="mlrext:uuid_string(vcard:org/vcard:text/text(), mlrext:uuid_url(concat('mailto:', vcard:email[vcard:parameters/vcard:type/vcard:text/text() = 'pref'][1]/vcard:text/text())))"/>
			</xsl:when>
			<xsl:when test="$org_uuid_from_email_org and vcard:org and vcard:email">
				<xsl:text>urn:uuid:</xsl:text>
				<xsl:value-of select="mlrext:uuid_string(vcard:org/vcard:text/text(), mlrext:uuid_url(concat('mailto:', vcard:email[1]/vcard:text/text())))"/>
			</xsl:when>
			<xsl:when test="$org_uuid_from_email_fn and vcard:email[vcard:parameters/vcard:type/vcard:text/text() = 'pref']">
				<xsl:text>urn:uuid:</xsl:text>
				<xsl:value-of select="mlrext:uuid_string(vcard:fn/vcard:text/text(), mlrext:uuid_url(concat('mailto:', vcard:email[vcard:parameters/vcard:type/vcard:text/text() = 'pref'][1]/vcard:text/text())))"/>
			</xsl:when>
			<xsl:when test="$org_uuid_from_email_fn and vcard:email">
				<xsl:text>urn:uuid:</xsl:text>
				<xsl:value-of select="mlrext:uuid_string(vcard:fn/vcard:text/text(), mlrext:uuid_url(concat('mailto:', vcard:email[1]/vcard:text/text())))"/>
			</xsl:when>
			<xsl:when test="$org_url_from_email and vcard:email[vcard:parameters/vcard:type/vcard:text/text() = 'pref']">
				<xsl:text>mailto:</xsl:text>
				<xsl:value-of select="vcard:email[vcard:parameters/vcard:type/vcard:text/text() = 'pref'][1]/vcard:text/text()"/>
			</xsl:when>
			<xsl:when test="$org_url_from_email and vcard:email">
				<xsl:text>mailto:</xsl:text>
				<xsl:value-of select="vcard:email[1]/vcard:text/text()"/>
			</xsl:when>
			<xsl:when test="$org_uuid_from_org_address and vcard:adr and (vcard:org or vcard:fn)">
				<xsl:variable name="id">
					<xsl:choose>
						<xsl:when test="vcard:org">
							<xsl:value-of select="vcard:org/vcard:text/text()"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="vcard:fn/vcard:text/text()"/>
						</xsl:otherwise>
					</xsl:choose>
					<xsl:if test="vcard:adr/vcard:country/text()">
						<xsl:text>;</xsl:text>
						<xsl:value-of select="vcard:adr/vcard:country/text()"/>
					</xsl:if>
					<xsl:if test="vcard:adr/vcard:region/text()">
						<xsl:text>;</xsl:text>
						<xsl:value-of select="vcard:adr/vcard:region/text()"/>
					</xsl:if>
					<xsl:if test="vcard:adr/vcard:city/text()">
						<xsl:text>;</xsl:text>
						<xsl:value-of select="vcard:adr/vcard:city/text()"/>
					</xsl:if>
				</xsl:variable>
				<xsl:text>urn:uuid:</xsl:text>
				<xsl:value-of select="mlrext:uuid_string($id)"/>
			</xsl:when>
			<xsl:when test="$org_uuid_from_org_or_fn and (vcard:org or vcard:fn)">
				<xsl:variable name="id">
					<xsl:choose>
						<xsl:when test="vcard:org">
							<xsl:value-of select="vcard:org/vcard:text/text()"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="vcard:fn/vcard:text/text()"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:text>urn:uuid:</xsl:text>
				<xsl:value-of select="mlrext:uuid_string($id)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>urn:uuid:</xsl:text>
				<xsl:value-of select="mlrext:uuid_unique()"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="org_identity">
		<xsl:choose>
			<xsl:when test="vcard:x-ablabel[vcard:unknown/text()='FOAF' and @group]">
				<!-- From http://www.w3.org/2002/12/cal/vcard-notes.html -->
				<xsl:variable name='group' select="vcard:x-ablabel[vcard:unknown/text()='FOAF' and @group]/@group"/>
				<xsl:value-of select="vcard:url[@group=$group]/vcard:uri/text()"/>
			</xsl:when>
			<xsl:when test="vcard:url[vcard:parameters/vcard:type/vcard:text/text() = 'pref']">
				<xsl:value-of select="vcard:url[vcard:parameters/vcard:type/vcard:text/text() = 'pref'][1]/vcard:uri/text()"/>
			</xsl:when>
			<xsl:when test="vcard:url">
				<xsl:value-of select="vcard:url[1]/vcard:uri/text()"/>
			</xsl:when>
			<xsl:when test="$org_uuid_from_email_org and vcard:org and vcard:email[vcard:parameters/vcard:type/vcard:text/text() = 'pref']">
				<xsl:text>cn=</xsl:text>
				<xsl:value-of select="vcard:org/vcard:text/text()"/>
				<xsl:text>,mail=</xsl:text>
				<xsl:value-of select="vcard:email[1][vcard:parameters/vcard:type/vcard:text/text() = 'pref']/vcard:text/text()"/>
			</xsl:when>
			<xsl:when test="$org_uuid_from_email_org and vcard:org and vcard:email">
				<xsl:text>cn=</xsl:text>
				<xsl:value-of select="vcard:org/vcard:text/text()"/>
				<xsl:text>,mail=</xsl:text>
				<xsl:value-of select="vcard:email[1]/vcard:text/text()"/>
			</xsl:when>
			<xsl:when test="$org_uuid_from_email_fn and vcard:email[vcard:parameters/vcard:type/vcard:text/text() = 'pref']">
				<xsl:text>cn=</xsl:text>
				<xsl:value-of select="vcard:fn/vcard:text/text()"/>
				<xsl:text>,mail=</xsl:text>
				<xsl:value-of select="vcard:email[1][vcard:parameters/vcard:type/vcard:text/text() = 'pref']/vcard:text/text()"/>
			</xsl:when>
			<xsl:when test="$org_uuid_from_email_fn and vcard:email">
				<xsl:text>cn=</xsl:text>
				<xsl:value-of select="vcard:fn/vcard:text/text()"/>
				<xsl:text>,mail=</xsl:text>
				<xsl:value-of select="vcard:email[1]/vcard:text/text()"/>
			</xsl:when>
			<xsl:when test="$org_url_from_email and vcard:email[vcard:parameters/vcard:type/vcard:text/text() = 'pref']">
				<xsl:value-of select="vcard:email[vcard:parameters/vcard:type/vcard:text/text() = 'pref'][1]/vcard:text/text()"/>
			</xsl:when>
			<xsl:when test="$org_url_from_email and vcard:email">
				<xsl:value-of select="vcard:email[1]/vcard:text/text()"/>
			</xsl:when>
			<xsl:when test="$org_uuid_from_org_address and vcard:adr and (vcard:org or vcard:fn)">
				<xsl:choose>
					<xsl:when test="vcard:org">
						<xsl:value-of select="vcard:org/vcard:text/text()"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="vcard:fn/vcard:text/text()"/>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:if test="vcard:adr/vcard:country/text()">
					<xsl:text>;</xsl:text>
					<xsl:value-of select="vcard:adr/vcard:country/text()"/>
				</xsl:if>
				<xsl:if test="vcard:adr/vcard:region/text()">
					<xsl:text>;</xsl:text>
					<xsl:value-of select="vcard:adr/vcard:region/text()"/>
				</xsl:if>
				<xsl:if test="vcard:adr/vcard:city/text()">
					<xsl:text>;</xsl:text>
					<xsl:value-of select="vcard:adr/vcard:city/text()"/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$org_uuid_from_org_or_fn and vcard:org">
				<xsl:value-of select="vcard:org/vcard:text/text()"/>
			</xsl:when>
			<xsl:when test="$org_uuid_from_org_or_fn and vcard:fn">
				<xsl:value-of select="vcard:fn/vcard:text/text()"/>
			</xsl:when>
		</xsl:choose>
	</xsl:template>




	<xsl:template match="vcard:email" mode="vcard_org">
		<mlr9:DES0800>
			<xsl:value-of select="vcard:text/text()"/>
		</mlr9:DES0800>
	</xsl:template>

	<xsl:template match="vcard:adr" mode="address">
		<mlr9:DES0700>
			<xsl:if test="vcard:box or vcard:extended">
				<xsl:value-of select="vcard:box/text()"/>
				<xsl:text> </xsl:text>
				<xsl:value-of select="vcard:extended/text()"/>
				<xsl:text>
</xsl:text>
			</xsl:if>
			<xsl:value-of select="vcard:street/text()"/>
			<xsl:text>
</xsl:text>
			<xsl:value-of select="vcard:city/text()"/>
			<xsl:text>, </xsl:text>
			<xsl:value-of select="vcard:region/text()"/>
			<xsl:text>, </xsl:text>
			<xsl:value-of select="vcard:code/text()"/>
			<xsl:text>
</xsl:text>
			<xsl:value-of select="vcard:country/text()"/>
		</mlr9:DES0700>
	</xsl:template>

	<xsl:template match="vcard:org" mode="vcard_org">
		<mlr9:DES1000>
			<xsl:value-of select="vcard:text/text()"/>
		</mlr9:DES1000>
	</xsl:template>

	<!-- metametadata -->

	<xsl:template match="*" mode="identifier">
		<xsl:param name="technical"/>
		<xsl:param name="construct" select="true()"/>
		<xsl:choose>
			<xsl:when test="lom:identifier/lom:catalog[text() = 'URI']">
				<xsl:value-of select="lom:identifier[lom:catalog/text() = 'URI'][1]/lom:entry/text()" />
			</xsl:when>
			<xsl:when test="lom:identifier/lom:catalog[text() = 'URL']">
				<xsl:value-of select="lom:identifier[lom:catalog/text() = 'URL'][1]/lom:entry/text()" />
			</xsl:when>
			<xsl:when test="lom:identifier/lom:catalog[text() = 'ISBN']">
				<xsl:text>urn:ISBN:</xsl:text>
				<xsl:value-of select="lom:identifier[lom:catalog/text() = 'ISBN'][1]/lom:entry/text()" />
			</xsl:when>
			<xsl:when test="lom:identifier/lom:catalog[text() = 'ISSN']">
				<xsl:text>urn:ISSN:</xsl:text>
				<xsl:value-of select="lom:identifier[lom:catalog/text() = 'ISSN'][1]/lom:entry/text()" />
			</xsl:when>
			<xsl:when test="lom:identifier/lom:catalog[text() = 'ISSN']">
				<xsl:text>urn:ISSN:</xsl:text>
				<xsl:value-of select="lom:identifier[lom:catalog/text() = 'ISSN'][1]/lom:entry/text()" />
			</xsl:when>
			<xsl:when test="lom:identifier/lom:catalog[text() = 'DOI']">
				<xsl:value-of select="$doi_identity_prefix"/>
				<xsl:value-of select="lom:identifier[lom:catalog/text() = 'DOI'][1]/lom:entry/text()" />
			</xsl:when>
			<xsl:when test="$technical and ../lom:technical/lom:location/text()">
				<xsl:value-of select="../lom:technical/lom:location[1]/text()" />
			</xsl:when>
			<xsl:when test="$construct and lom:identifier">
				<xsl:value-of select="lom:identifier[1]/lom:catalog/text()" />
				<xsl:text>|</xsl:text>
				<xsl:value-of select="lom:identifier[1]/lom:entry/text()" />
			</xsl:when>
		</xsl:choose>
	</xsl:template>


	<xsl:template match="lom:metadataSchema" mode="metaMetadata">
		<!-- note that a URI would be preferrable... Should we identify the frequent ones? -->
		<mlr8:DES0400>
			<xsl:value-of select="text()"/>
		</mlr8:DES0400>
	</xsl:template>

	<xsl:template match="lom:contribute" mode="metaMetadata">
		<mlr8:DES1100>
			<mlr8:RC0003>
				<xsl:attribute name="rdf:about">
					<xsl:text>urn:uuid:</xsl:text>
					<xsl:value-of select="mlrext:uuid_unique()"/>
				</xsl:attribute>
				<xsl:apply-templates mode="metaMetadata"/>
			</mlr8:RC0003>
		</mlr8:DES1100>
	</xsl:template>


	<xsl:template match="lom:entity" mode="metaMetadata">
		<mlr8:DES1400>
			<xsl:apply-templates mode="vcard" select="vcardconv:convert(text())" />
		</mlr8:DES1400>
	</xsl:template>

	<xsl:template match="lom:date" mode="metaMetadata">
		<xsl:choose>
			<!-- first cases: valid 8601 date or datetime -->
			<xsl:when test="lom:dateTime and regexp:test(lom:dateTime/text(), '^([\+-]?\d{4}(?!\d{2}\b))((-?)((0[1-9]|1[0-2])(\3([12]\d|0[1-9]|3[01]))?|W([0-4]\d|5[0-2])(-?[1-7])?|(00[1-9]|0[1-9]\d|[12]\d{2}|3([0-5]\d|6[1-6]))))$')">
				<mlr8:DES1300 rdf:datatype="http://www.w3.org/2001/XMLSchema#date">
					<xsl:value-of select="lom:dateTime/text()" />
				</mlr8:DES1300>
			</xsl:when>
			<xsl:when test="lom:dateTime and regexp:test(lom:dateTime/text(), '^([\+-]?\d{4}(?!\d{2}\b))((-?)((0[1-9]|1[0-2])(\3([12]\d|0[1-9]|3[01]))?|W([0-4]\d|5[0-2])(-?[1-7])?|(00[1-9]|0[1-9]\d|[12]\d{2}|3([0-5]\d|6[1-6])))([T\s]((([01]\d|2[0-3])((:?)[0-5]\d)?|24\:?00)([\.,]\d+(?!:))?)?(\17[0-5]\d([\.,]\d+)?)?([zZ]|([\+-])([01]\d|2[0-3]):?([0-5]\d)?)?)?)?$')">
				<mlr8:DES1300 rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">
					<xsl:value-of select="lom:dateTime/text()" />
				</mlr8:DES1300>
			</xsl:when>
			<xsl:when test="lom:dateTime">
				<mlr8:DES1300>
					<xsl:value-of select="lom:dateTime/text()" />
				</mlr8:DES1300>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="lom:description/lom:string" mode="langstring">
					<xsl:with-param name="nodename" select="'mlr8:DES1300'"/>
				</xsl:apply-templates>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="lom:role" mode="metaMetadata">
		<mlr8:DES1200>
			<xsl:value-of select="lom:value/text()" />
		</mlr8:DES1200>
	</xsl:template>

	<xsl:template match="lom:language" mode="metaMetadata">
		<mlr8:DES0200>
			<xsl:call-template name="language">
				<xsl:with-param name="l" select="text()"/>
			</xsl:call-template>
		</mlr8:DES0200>
	</xsl:template>

	<!-- technical -->

	<xsl:template match="lom:format" mode="technical">
		<mlr2:DES0900>
			<xsl:value-of select="text()"/>
		</mlr2:DES0900>
	</xsl:template>

	<xsl:template match="lom:size" mode="technical">
		<mlr4:DES0200 rdf:datatype="http://www.w3.org/2001/XMLSchema#int">
			<xsl:value-of select="text()"/>
		</mlr4:DES0200>
	</xsl:template>

	<xsl:template match="lom:location" mode="technical">
		<mlr4:DES0100>
			<!-- question: Make this a resource? -->
			<xsl:value-of select="text()"/>
		</mlr4:DES0100>
	</xsl:template>

	<xsl:template match="lom:requirement" mode="technical">
		<mlr4:DES0400>
			<xsl:if test="$text_language = 'eng' or $text_language = 'fra'">
				<xsl:attribute name="xml:lang">
					<xsl:value-of select="$text_language"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:variable name="text">
				<xsl:if test="count(lom:orComposite)&gt;1">
					<xsl:choose>
						<xsl:when test="$text_language = 'eng'">
							<xsl:text>One of the following options: </xsl:text>
						</xsl:when>
						<xsl:when test="$text_language = 'fra'">
							<xsl:text>Une des options suivantes: </xsl:text>
						</xsl:when>
					</xsl:choose>
				</xsl:if>
				<xsl:apply-templates mode="tech-requirement" select="lom:orComposite"/>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="$text_language = 'eng' or $text_language = 'fra'">
					<xsl:value-of select="concat(translate(substring($text, 1, 1),$lc, $uc), substring($text, 2))"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$text"/>
				</xsl:otherwise>
			</xsl:choose>
		</mlr4:DES0400>
	</xsl:template>


	<xsl:template match="lom:orComposite" mode="tech-requirement">
		<xsl:if test="preceding-sibling::lom:orComposite">
			<xsl:choose>
				<xsl:when test="$text_language = 'eng'">
					<xsl:text>; or </xsl:text>
				</xsl:when>
				<xsl:when test="$text_language = 'fra'">
					<xsl:text>; ou </xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text> ⋁ </xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
		<xsl:apply-templates mode="tech-requirement"/>
		<xsl:if test="not(following-sibling::lom:orComposite) and ($text_language = 'eng' or $text_language = 'fra')">
			<xsl:text>.</xsl:text>
		</xsl:if>
	</xsl:template>

	<xsl:template match="lom:type" mode="tech-requirement">
		<xsl:choose>
			<xsl:when test="lom:source/text()='LOMv1.0' and lom:value/text()='browser'">
				<xsl:choose>
					<xsl:when test="$text_language = 'eng'">
						<xsl:text>the browser</xsl:text>
					</xsl:when>
					<xsl:when test="$text_language = 'fra'">
						<xsl:text>le fureteur</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="lom:value/text()"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="lom:source/text()='LOMv1.0' and lom:value/text()='operating system'">
				<xsl:choose>
					<xsl:when test="$text_language = 'eng'">
						<xsl:text>the operating system</xsl:text>
					</xsl:when>
					<xsl:when test="$text_language = 'fra'">
						<xsl:text>le système d'exploitation</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="lom:value/text()"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="$text_language = 'eng' or $text_language = 'fra'">
				<xsl:text>'</xsl:text>
				<xsl:value-of select="lom:value/text()"/>
				<xsl:text>'</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="lom:value/text()"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="lom:name" mode="tech-requirement">
		<xsl:choose>
			<xsl:when test="lom:source/text()='LOMv1.0' and (lom:value/text()='any' or lom:value/text()='multi-os')">
				<xsl:choose>
					<xsl:when test="$text_language = 'eng'">
						<xsl:text> can be any </xsl:text>
						<xsl:value-of select="../type/value/text()"/>
						<xsl:choose>
							<xsl:when test="preceding-sibling::lom:type/lom:value/text() = 'browser'">
								<xsl:text>browser</xsl:text>
							</xsl:when>
							<xsl:when test="preceding-sibling::lom:type/lom:value/text() = 'operating system'">
								<xsl:text>operating system</xsl:text>
							</xsl:when>
							<xsl:otherwise>
								<xsl:text>'</xsl:text>
								<xsl:value-of select="preceding-sibling::lom:type/lom:value/text()"/>
								<xsl:text>'</xsl:text>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:when test="$text_language = 'fra'">
						<xsl:text> peut être n'importe quel </xsl:text>
						<xsl:choose>
							<xsl:when test="preceding-sibling::lom:type/lom:value/text() = 'browser'">
								<xsl:text>fureteur</xsl:text>
							</xsl:when>
							<xsl:when test="preceding-sibling::lom:type/lom:value/text() = 'operating system'">
								<xsl:text>système d'exploitation</xsl:text>
							</xsl:when>
							<xsl:otherwise>
								<xsl:text>'</xsl:text>
								<xsl:value-of select="preceding-sibling::lom:type/lom:value/text()"/>
								<xsl:text>'</xsl:text>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text> = ?</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="lom:source/text()='LOMv1.0' and lom:value/text()='none'">
				<xsl:choose>
					<xsl:when test="$text_language = 'eng'">
						<xsl:text> is not needed</xsl:text>
					</xsl:when>
					<xsl:when test="$text_language = 'fra'">
						<xsl:text> n'est pas nécessaire</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text> = 0</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:choose>
					<xsl:when test="$text_language = 'eng'">
						<xsl:text> must be </xsl:text>
					</xsl:when>
					<xsl:when test="$text_language = 'fra'">
						<xsl:text> doit être </xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text> = </xsl:text>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:choose>
					<xsl:when test="$text_language = 'fra' or $text_language = 'eng'">
						<xsl:choose>
							<xsl:when test="lom:source/text()='LOMv1.0' and lom:value/text()='ms-internet explorer'">
								<xsl:text>Microsoft Internet Explorer</xsl:text>
							</xsl:when>
							<xsl:when test="lom:source/text()='LOMv1.0' and lom:value/text()='pc-dos'">
								<xsl:text>MS-DOS</xsl:text>
							</xsl:when>
							<xsl:when test="lom:source/text()='LOMv1.0' and lom:value/text()='ms-windows'">
								<xsl:text>Microsoft Windows</xsl:text>
							</xsl:when>
							<xsl:when test="lom:source/text()='LOMv1.0' and lom:value/text()='macos'">
								<xsl:text>Mac OS</xsl:text>
							</xsl:when>
							<!-- unix, netscape communicator, opera, and amaya names are used as-is. -->
							<xsl:otherwise>
								<xsl:value-of select="lom:value/text()"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="lom:value/text()"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="lom:minimumVersion" mode="tech-requirement">
		<xsl:if test="text()">
			<xsl:choose>
				<xsl:when test="$text_language = 'eng'">
					<xsl:text>, version at least </xsl:text>
				</xsl:when>
				<xsl:when test="$text_language = 'fra'">
					<xsl:text>, version au moins </xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text> &gt;= </xsl:text>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:value-of select="text()"/>
		</xsl:if>
	</xsl:template>

	<xsl:template match="lom:maximumVersion" mode="tech-requirement">
		<xsl:if test="text()">
			<xsl:choose>
				<xsl:when test="../lom:minimumVersion">
					<xsl:choose>
						<xsl:when test="$text_language = 'eng'">
							<xsl:text> and at most </xsl:text>
						</xsl:when>
						<xsl:when test="$text_language = 'fra'">
							<xsl:text> et au plus </xsl:text>
						</xsl:when>
						<xsl:otherwise>
							<xsl:text> &amp; &lt;= </xsl:text>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<xsl:choose>
						<xsl:when test="$text_language = 'eng'">
							<xsl:text>, version at most </xsl:text>
						</xsl:when>
						<xsl:when test="$text_language = 'fra'">
							<xsl:text>, version au plus </xsl:text>
						</xsl:when>
						<xsl:otherwise>
							<xsl:text> &lt;= </xsl:text>
						</xsl:otherwise>
					</xsl:choose>
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
			<mlr4:DES0300 rdf:datatype="http://www.w3.org/2001/XMLSchema#duration">
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

	<!-- educational -->

	<xsl:template match="lom:educational" mode="top">
		<xsl:variable name="learning_activity">
			<xsl:apply-templates mode="educational_learning_activity"/>
		</xsl:variable>
		<xsl:if test="string-length($learning_activity)&gt;0">
			<mlr5:DES2000>
				<mlr5:RC0005>
					<xsl:attribute name="rdf:about">
						<xsl:text>urn:uuid:</xsl:text>
						<xsl:value-of select="mlrext:uuid_unique()"/>
					</xsl:attribute>
					<xsl:copy-of select="$learning_activity"/>
				</mlr5:RC0005>
			</mlr5:DES2000>
		</xsl:if>
		<xsl:variable name="audience">
			<xsl:apply-templates mode="educational_audience"/>
		</xsl:variable>
		<xsl:if test="string-length($audience)&gt;0">
			<mlr5:DES1500>
				<mlr5:RC0002>
					<xsl:attribute name="rdf:about">
						<xsl:text>urn:uuid:</xsl:text>
						<xsl:value-of select="mlrext:uuid_unique()"/>
					</xsl:attribute>
					<xsl:copy-of select="$audience"/>
				</mlr5:RC0002>
			</mlr5:DES1500>
		</xsl:if>
		<xsl:apply-templates mode="educational"/>
	</xsl:template>

	<xsl:template match="lom:learningResourceType" mode="educational">
        <mlr2:DES0800>
          <xsl:value-of select="lom:value/text()"/>
        </mlr2:DES0800>
		<xsl:if test="$use_mlr3">
			<xsl:call-template name="mlr2_DES0800"/>
		</xsl:if>
	</xsl:template>

	<xsl:template match="lom:description" mode="annotations">
		<xsl:param name="resource"/>
		<oa:Annotation>
			<xsl:attribute name="rdf:about">
				<xsl:text>urn:uuid:</xsl:text>
				<xsl:value-of select="mlrext:uuid_unique()"/>
			</xsl:attribute>
			<oa:hasTarget>
				<xsl:attribute name="rdf:resource">
					<xsl:value-of select="$resource"/>
				</xsl:attribute>
			</oa:hasTarget>
			<!-- add something about oa:motivation being educational -->
			<xsl:apply-templates select="lom:string" mode="langstring">
				<xsl:with-param name="nodename" select="'oa:hasBody'"/>
			</xsl:apply-templates>
		</oa:Annotation>
	</xsl:template>

	<xsl:template match="lom:learningResourceType" mode="educational_learning_activity">
		<xsl:call-template name="mlr5_DES2100"/>
	</xsl:template>

	<xsl:template match="lom:intendedEndUserRole" mode="educational_audience">
		<xsl:call-template name="mlr5_DES0600"/>
	</xsl:template>

	<xsl:template match="lom:typicalLearningTime[lom:duration]" mode="educational_learning_activity">
		<mlr5:DES3000 rdf:datatype="http://www.w3.org/2001/XMLSchema#duration">
			<xsl:value-of select="lom:duration/text()"/>
		</mlr5:DES3000>
	</xsl:template>

	<xsl:template match="lom:context" mode="educational_audience">
		<mlr5:DES0500>
			<xsl:value-of select="lom:value/text()"/>
		</mlr5:DES0500>
	</xsl:template>

	<xsl:template match="lom:typicalAgeRange" mode="educational_audience">
		<xsl:choose>
			<xsl:when test="regexp:test(lom:string/text(),'^[0-9]+-[0-9]+')">
				<mlr5:DES2600 rdf:datatype="http://www.w3.org/2001/XMLSchema#int">
					<xsl:value-of select="substring-before(lom:string/text(),'-')"/>
				</mlr5:DES2600>
				<mlr5:DES2500 rdf:datatype="http://www.w3.org/2001/XMLSchema#int">
					<xsl:value-of select="regexp:match(substring-after(lom:string/text(),'-'),'^[0-9]+')"/>
				</mlr5:DES2500>
			</xsl:when>
			<xsl:when test="regexp:test(lom:string/text(),'^[0-9]+-')">
				<mlr5:DES2600 rdf:datatype="http://www.w3.org/2001/XMLSchema#int">
					<xsl:value-of select="substring-before(lom:string/text(),'-')"/>
				</mlr5:DES2600>
			</xsl:when>
			<xsl:when test="regexp:test(lom:string/text(),'^[0-9]+')">
				<mlr5:DES2600 rdf:datatype="http://www.w3.org/2001/XMLSchema#int">
					<xsl:value-of select="regexp:match(lom:string/text(),'^[0-9]+')"/>
				</mlr5:DES2600>
				<mlr5:DES2500 rdf:datatype="http://www.w3.org/2001/XMLSchema#int">
					<xsl:value-of select="regexp:match(lom:string/text(),'^[0-9]+')"/>
				</mlr5:DES2500>
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="lom:language" mode="educational_audience">
		<mlr5:DES0400>
			<xsl:call-template name="language">
				<xsl:with-param name="l" select="text()"/>
			</xsl:call-template>
		</mlr5:DES0400>
	</xsl:template>


	<!-- rights -->

	<xsl:template match="lom:rights" mode="top">
		<xsl:choose>
			<xsl:when test="lom:description">
				<xsl:apply-templates select="lom:description/lom:string" mode="rights" />
			</xsl:when>
			<xsl:when test="lom:cost[lom:source/text()='LOMv1.0' and lom:value/text()='yes']">
				<xsl:choose>
					<xsl:when test="$text_language='eng'">
						<mlr2:DES1500 xml:lang="eng">There are costs.</mlr2:DES1500>
					</xsl:when>
					<xsl:when test="$text_language='fra'">
						<mlr2:DES1500 xml:lang="fra">Il y a des coûts.</mlr2:DES1500>
					</xsl:when>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="lom:copyrightAndOtherRestrictions[lom:source/text()='LOMv1.0' and lom:value/text()='yes']">
				<xsl:choose>
					<xsl:when test="$text_language='eng'">
						<mlr2:DES1500 xml:lang="eng">Copyright or other restrictions apply.</mlr2:DES1500>
					</xsl:when>
					<xsl:when test="$text_language='fra'">
						<mlr2:DES1500 xml:lang="fra">Un copyright ou d'autres restrictions s'appliquent.</mlr2:DES1500>
					</xsl:when>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="lom:cost[lom:source/text()='LOMv1.0' and lom:value/text()='no'] and lom:copyrightAndOtherRestrictions[lom:source/text()='LOMv1.0' and lom:value/text()='no']">
				<xsl:choose>
					<xsl:when test="$text_language='eng'">
						<mlr2:DES1500 xml:lang="eng">Free, no copyright.</mlr2:DES1500>
					</xsl:when>
					<xsl:when test="$text_language='fra'">
						<mlr2:DES1500 xml:lang="fra">Gratuit, pas de copyright.</mlr2:DES1500>
					</xsl:when>
				</xsl:choose>
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<xsl:template mode="rights" match="lom:string[mlrext:is_absolute_iri(text())]">
		<mlr2:DES2300>
			<mlr2:RC0002>
				<xsl:attribute name="rdf:about">
					<xsl:value-of select="text()"/>
				</xsl:attribute>
			</mlr2:RC0002>
		</mlr2:DES2300>
	</xsl:template>

	<xsl:template mode="rights" match="lom:string[not(mlrext:is_absolute_iri(text()))]">
		<xsl:apply-templates select="." mode="langstring">
			<xsl:with-param name="nodename" select="'mlr2:DES1500'"/>
		</xsl:apply-templates>
	</xsl:template>

	<!-- relations -->

	<xsl:template match="lom:relation" mode="top">
		<xsl:variable name="resource_id">
			<xsl:apply-templates mode="identifier" select="lom:resource">
				<xsl:with-param name="technical" select="false()"/>
			</xsl:apply-templates>
		</xsl:variable>
		<xsl:variable name="resource_id_if_uri">
			<xsl:apply-templates mode="identifier" select="lom:resource">
				<xsl:with-param name="technical" select="false()"/>
				<xsl:with-param name="construct" select="false()"/>
			</xsl:apply-templates>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="string-length($resource_id_if_uri) = 0">
				<xsl:choose>
					<xsl:when test="lom:kind[lom:source/text()='LOMv1.0' and lom:value/text()='isbasedon']">
						<mlr2:DES1100>
							<xsl:value-of select="$resource_id"/>
						</mlr2:DES1100>
						<xsl:if test="$use_mlr3">
							<mlr3:DES0600>
								<xsl:value-of select="$resource_id"/>
							</mlr3:DES0600>
						</xsl:if>
					</xsl:when>
					<xsl:otherwise>
						<mlr2:DES1300>
							<xsl:value-of select="$resource_id"/>
						</mlr2:DES1300>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:choose>
					<xsl:when test="lom:kind[lom:source/text()='LOMv1.0' and lom:value/text()='isbasedon']">
						<mlr2:DES2100>
							<xsl:attribute name="rdf:resource">
								<xsl:value-of select="$resource_id_if_uri"/>
							</xsl:attribute>
						</mlr2:DES2100>
					</xsl:when>
					<xsl:otherwise>
						<mlr2:DES2200>
							<xsl:attribute name="rdf:resource">
								<xsl:value-of select="$resource_id_if_uri"/>
							</xsl:attribute>
						</mlr2:DES2200>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>


	<!-- annotation -->

	<xsl:template match="lom:annotation" mode="annotations">
		<xsl:param name="resource"/>
		<oa:Annotation>
			<xsl:attribute name="rdf:about">
				<xsl:text>urn:uuid:</xsl:text>
				<xsl:value-of select="mlrext:uuid_unique()"/>
			</xsl:attribute>
			<oa:hasTarget>
				<xsl:attribute name="rdf:resource">
					<xsl:value-of select="$resource"/>
				</xsl:attribute>
			</oa:hasTarget>
			<!-- add something about oa:motivation from annotation type -->
			<xsl:apply-templates mode="annotation"/>
		</oa:Annotation>
	</xsl:template>

	<xsl:template match="lom:entity" mode="annotation">
        <oa:annotatedBy>
            <xsl:apply-templates mode="vcard" select="vcardconv:convert(text())" />
        </oa:annotatedBy>
	</xsl:template>

	<xsl:template match="lom:description" mode="annotation">
		<xsl:apply-templates select="lom:string" mode="langstring">
        	<xsl:with-param name="nodename" select="'oa:hasBody'"/>
		</xsl:apply-templates>
	</xsl:template>

	<xsl:template match="lom:date" mode="annotation">
		<xsl:call-template name="date">
			<xsl:with-param name="nodename" select="'oa:annotatedAt'"/>
		</xsl:call-template>
	</xsl:template>


	<!-- classification -->

	<xsl:template match="lom:classification" mode="top">
		<xsl:apply-templates mode="classification" select="." />
	</xsl:template>

	<xsl:template match="lom:classification[lom:purpose[lom:source/text()='LOMv1.0' and lom:value/text()='discipline']]" mode="classification">
		<xsl:variable name="target">
			<xsl:call-template name="classification_content" >
				<xsl:with-param name="nodename" select="'mlr2:DES0300'"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:if test="string-length($target)">
			<xsl:copy-of select="$target"/>
		</xsl:if>
		<xsl:apply-templates mode="classification_discipline"/>
	</xsl:template>

	<xsl:template match="lom:classification[lom:purpose[lom:source/text()='LOMv1.0' and lom:value/text()='educational level']]" mode="classification">
		<xsl:variable name="target">
			<xsl:call-template name="classification_content" >
				<xsl:with-param name="nodename" select="'mlr5:DES1000'"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:if test="string-length($target)&gt;0">
			<mlr5:DES1900>
				<mlr5:RC0004>
					<xsl:attribute name="rdf:about">
						<xsl:text>urn:uuid:</xsl:text>
						<xsl:value-of select="mlrext:uuid_unique()"/>
					</xsl:attribute>
					<xsl:copy-of select="$target"/>
				</mlr5:RC0004>
			</mlr5:DES1900>
		</xsl:if>
	</xsl:template>

	<xsl:template name="classification_content" >
		<xsl:param name="nodename"/>
		<xsl:choose>
			<xsl:when test="lom:description">
				<xsl:apply-templates select="lom:description/lom:string" mode="langstring">
					<xsl:with-param name="nodename" select="$nodename"/>
				</xsl:apply-templates>
			</xsl:when>
			<xsl:when test="lom:keyword">
				<xsl:apply-templates select="lom:keyword/lom:string" mode="langstring">
					<xsl:with-param name="nodename" select="$nodename"/>
				</xsl:apply-templates>
			</xsl:when>
			<xsl:when test="lom:taxonPath[lom:taxon/lom:entry/lom:string]">
				<xsl:apply-templates select="lom:taxonPath/lom:taxon[lom:entry/lom:string][last()]/lom:entry/lom:string" mode="langstring">
					<xsl:with-param name="nodename" select="$nodename"/>
				</xsl:apply-templates>
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<xsl:template mode="classification_discipline" match="lom:taxonPath">
		<xsl:choose>
			<xsl:when test="lom:source/lom:string[mlrext:is_absolute_iri(text())]">
				<mlr2:DES1700>
					<xsl:attribute name="rdf:resource">
						<xsl:value-of select="concat(lom:source/lom:string[mlrext:is_absolute_iri(text())][position()=1]/text(), lom:taxon[last()]/lom:id/text())" />
					</xsl:attribute>
				</mlr2:DES1700>
			</xsl:when>
			<xsl:when test="mlrext:is_absolute_iri(lom:taxon[last()]/lom:id/text())">
				<mlr2:DES1700>
					<xsl:attribute name="rdf:resource">
						<xsl:value-of select="lom:taxon[last()]/lom:id/text()" />
					</xsl:attribute>
				</mlr2:DES1700>
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<!-- utility functions -->

	<xsl:template match="lom:string" mode="langstring">
		<xsl:param name="nodename" />
		<xsl:element name="{$nodename}">
			<xsl:if test="@language">
				<xsl:attribute name="xml:lang">
					<xsl:call-template name="language">
						<xsl:with-param name="l" select="@language"/>
					</xsl:call-template>
				</xsl:attribute>
			</xsl:if>
			<xsl:value-of select="text()" />
		</xsl:element>
	</xsl:template>

	<xsl:template match="lom:string" mode="urlstring">
		<xsl:param name="nodename" />
		<xsl:element name="{$nodename}">
			<xsl:attribute name="rdf:resource">
				<xsl:value-of select="text()" />
			</xsl:attribute>
		</xsl:element>
	</xsl:template>

	<xsl:template match="*" mode="langstring">
		<xsl:message terminate="yes">Langstring called on non-string</xsl:message>
	</xsl:template>

	<xsl:template name="language">
		<xsl:param name="l"/>
		<xsl:choose>
			<xsl:when test="regexp:test($l,'^[a-z][a-z]\-[A-Z][A-Z]$')">
				<xsl:call-template name="iso639_2to3">
					<xsl:with-param name="l" select="substring-before($l,'-')"/>
				</xsl:call-template>
				<xsl:text>-</xsl:text>
				<xsl:value-of select="substring-after($l,'-')"/>
			</xsl:when>
			<xsl:when test="regexp:test($l,'^[a-z][a-z]$')">
				<xsl:call-template name="iso639_2to3">
					<xsl:with-param name="l" select="$l"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$l"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="date">
		<xsl:param name="nodename"/>
		<xsl:choose>
			<!-- first cases: valid 8601 date or datetime -->
			<xsl:when test="lom:dateTime and regexp:test(lom:dateTime/text(), '^([\+-]?\d{4}(?!\d{2}\b))((-?)((0[1-9]|1[0-2])(\3([12]\d|0[1-9]|3[01]))?|W([0-4]\d|5[0-2])(-?[1-7])?|(00[1-9]|0[1-9]\d|[12]\d{2}|3([0-5]\d|6[1-6]))))$')">
				<xsl:element name="{$nodename}">
					<xsl:attribute name="rdf:datatype">
						<xsl:text>http://www.w3.org/2001/XMLSchema#date</xsl:text>
					</xsl:attribute>
					<xsl:value-of select="lom:dateTime/text()" />
				</xsl:element>
			</xsl:when>
			<xsl:when test="lom:dateTime and regexp:test(lom:dateTime/text(), '^([\+-]?\d{4}(?!\d{2}\b))((-?)((0[1-9]|1[0-2])(\3([12]\d|0[1-9]|3[01]))?|W([0-4]\d|5[0-2])(-?[1-7])?|(00[1-9]|0[1-9]\d|[12]\d{2}|3([0-5]\d|6[1-6])))([T\s]((([01]\d|2[0-3])((:?)[0-5]\d)?|24\:?00)([\.,]\d+(?!:))?)?(\17[0-5]\d([\.,]\d+)?)?([zZ]|([\+-])([01]\d|2[0-3]):?([0-5]\d)?)?)?)?$')">
				<xsl:element name="{$nodename}">
					<xsl:attribute name="rdf:datatype">
						<xsl:text>http://www.w3.org/2001/XMLSchema#dateTime</xsl:text>
					</xsl:attribute>
					<xsl:value-of select="lom:dateTime/text()" />
				</xsl:element>
			</xsl:when>
		</xsl:choose>
	</xsl:template>

<!-- copy -->
	<xsl:template match="*" mode="copy">
		<xsl:copy>
			<xsl:apply-templates select="@*" mode="copy"/>
			<xsl:apply-templates select="*|text()" mode="copy"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="@*|text()" mode="copy">
		<xsl:copy />
	</xsl:template>

</xsl:stylesheet>
