<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:vcardconv="http://ntic.org/vcard"
	xmlns:vcard="urn:ietf:params:xml:ns:vcard-4.0"
	xmlns:mlrext="http://standards.iso.org/iso-iec/19788/ext/"
	xmlns:mlr1="http://standards.iso.org/iso-iec/19788/-1/ed-1/en/"
	xmlns:mlr2="http://standards.iso.org/iso-iec/19788/-2/ed-1/en/"
	xmlns:mlr3="http://standards.iso.org/iso-iec/19788/-3/ed-1/en/"
	xmlns:mlr4="http://standards.iso.org/iso-iec/19788/-4/ed-1/en/"
	xmlns:mlr5="http://standards.iso.org/iso-iec/19788/-5/ed-1/en/"
	xmlns:mlr8="http://standards.iso.org/iso-iec/19788/-8/ed-1/en/"
	xmlns:mlr9="http://standards.iso.org/iso-iec/19788/-9/ed-1/en/"
	>
	<xsl:output method="xml" encoding="UTF-8"/>


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
				<xsl:apply-templates select="vcard:org" mode="vcard_fullname"/>
				<xsl:text>,mail=</xsl:text>
				<xsl:value-of select="vcard:email[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK' and vcard:parameters/vcard:type/vcard:text/text() = 'pref'][1]/vcard:text/text()"/>
			</xsl:when>
			<xsl:when test="$org_uuid_from_email_org and $suborg_use_work_email and vcard:org[string(@group) = $group] and vcard:email[string(@group) = $group and vcard:parameters/vcard:type/vcard:text/text() = 'WORK']">
				<xsl:text>cn=</xsl:text>
				<xsl:apply-templates select="vcard:org[string(@group) = $group]" mode="vcard_fullname"/>
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
				<xsl:apply-templates select="vcard:org[string(@group) = $group]" mode="vcard_fullname"/>
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
				<xsl:apply-templates select="vcard:org[string(@group) = $group]" mode="vcard_fullname"/>
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
			    <xsl:apply-templates select="node()" mode="vcard_fullname"/>
			</mlr9:DES1000>
		</xsl:if>
	</xsl:template>

    <xsl:template match="vcard:org" mode="vcard_fullname">
      <xsl:apply-templates select="node()" mode="vcard_fullname"/>
    </xsl:template>

    <xsl:template match="vcard:org/vcard:text" mode="vcard_fullname">
       <xsl:value-of select="text()"/>
       <xsl:if test="not(position()=last())">
         <xsl:text>;</xsl:text>
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
							<xsl:apply-templates select="vcard:org" mode="vcard_fullname"/>
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
						    <xsl:apply-templates select="vcard:org" mode="vcard_fullname"/>
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
				<xsl:apply-templates select="vcard:org" mode="vcard_fullname"/>
				<xsl:text>,mail=</xsl:text>
				<xsl:value-of select="vcard:email[1][vcard:parameters/vcard:type/vcard:text/text() = 'pref']/vcard:text/text()"/>
			</xsl:when>
			<xsl:when test="$org_uuid_from_email_org and vcard:org and vcard:email">
				<xsl:text>cn=</xsl:text>
				<xsl:apply-templates select="vcard:org" mode="vcard_fullname"/>
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
						<xsl:apply-templates select="vcard:org" mode="vcard_fullname"/>
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
				<xsl:apply-templates select="vcard:org" mode="vcard_fullname"/>
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

</xsl:stylesheet>
