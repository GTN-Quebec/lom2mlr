# Converting LOM to MLR

## General ##

### Identifier

What should the RDF identifier (`rdf:about`) of the resource be?

#### Explicit identifier

The `general/identifier` LOM tag is preferred as a RDF identification. It is also used for the mlr3:DES0400 element, the equivalent to `dc:identifier`.

Open questions: How to incorporate the `catalog` information? What if the identifier `entry` is not a URI?

    :::xml
    <general>
        <identifier>
            <catalog>TEST</catalog>
            <entry>oai:test.licef.ca:123123</entry>
        </identifier>
    </general>

Becomes

    :::N3
    <oai:test.licef.ca:123123> a mlr1:RC0002;
      mlr3:DES0400 <oai:test.licef.ca:123123> .

#### Use of technical/location as identifier

If `general/identifier` is undefined, we would use the first available URL in `technical/location`. This is a heuristics, as there is no automated way to distinguish multiple URLs. However, we would not use this for the MLR3 identifier tag.

    :::xml
    <technical>
        <location>http://xserve.scedu.umontreal.ca/~cyberscol/videos/v00008-640-s.mov</location>
    </technical>

Becomes

    :::N3
    <http://xserve.scedu.umontreal.ca/~cyberscol/videos/v00008-640-s.mov> a mlr1:RC0002.

but not:

    :::N3
    <http://xserve.scedu.umontreal.ca/~cyberscol/videos/v00008-640-s.mov> a mlr1:RC0002;
      mlr3:DES0400 <http://xserve.scedu.umontreal.ca/~cyberscol/videos/v00008-640-s.mov> .

### DublinCore elements

Many elements have a direct translation in DublinCore, and hence in MLR-2.

#### general/title

The title is translated directly as `mlr2:DES0100`.

    :::xml
    <general>
        <title>
            <string language="fra-CA">Conditions favorables à l'intégration des TIC...</string>
        </title>
    </general>

Becomes

    :::N3
    [] mlr2:DES0100 "Conditions favorables à l'intégration des TIC..."@fra-CA .

#### general/language suivant ISO 639-3

Ideally, language should follow ISO 639-3. This can be detected by a regular expression, and we can then translate as `MLR-3:DES0500`. Note that some letter triplets might not be valid ISO 639-3, which would not be detected by a simple regular expression.

    :::xml
    <general>
        <language>fra-CA</language>
    </general>

Becomes

    :::N3
    [] mlr3:DES0500 "fra-CA" .


#### general/language

If the language description does not follow the pattern, we can use the MLR-2 version of that property. (We may translate ISO 639-2 codes to ISO 639-3.)

    :::xml
    <general>
        <language>français</language>
    </general>

Becomes

    :::N3
    [] mlr2:DES1200 "français" .

#### general/description

Description could be interpreted as `mlr2:DES0400`, but in practice there is never any reason not to use `mlr3:DES0200` instead.

    :::xml
    <general>
        <description>
            <string language="fra-CA">L'enseignant identifie les contraintes...</string>
        </description>
    </general>

Becomes

    :::N3
    [] mlr3:DES0200 "L'enseignant identifie les contraintes..."@fra-CA .

And not

    :::N3
    [] mlr2:DES0400 "L'enseignant identifie les contraintes..."@fra-CA .

#### general/keyword ####

Keywords can be interpreted an equivalent to `dc:subject`, hence `mlr2:DES0300`.

    :::xml
    <general>
        <keyword>
          <string language="fra">optique</string>
          <string language="fra">physique</string>
        </keyword>
    </general>

Becomes

    :::N3
    [] mlr2:DES0300 "optique"@fra; 
       mlr2:DES0300 "physique"@fra .

#### general/coverage ####

Coverage is an equivalent concept between LOM and DC.

    :::xml
    <general>
        <coverage>
            <string language="fra-CA">Québec</string>
        </coverage>
    </general>

Becomes

    :::N3
    [] mlr2:DES1400 "Québec"@fra-CA.

### Elements that are not covered

`general/structure` and `general/aggregationLevel` have no MLR equivalent (except composites, treated in `mlr3:DES0700`).

## Life cycle

### Version and State

Learning resource version and state have no equivalent in MLR.

### Contributions

All LOM contributions become `mlr5:RC0003` contribution entities through a `mlr5:DES1700` relationships.

    :::xml
    <lifeCycle>
        <contribute>
            <role>
                <source>LOMv1.0</source>
                <value>publisher</value>
            </role>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002;
        mlr5:DES1700 [ a mlr5:RC0003 ] .

### Roles

#### Authors

A contribution whose role is `LOMv1.0:author` is interpreted as a `dc:creator` (`mlr2:DES0200`). We would then use the `FN` of the `VCARD`.

    :::xml
    <lifeCycle>
        <contribute>
            <role>
                <source>LOMv1.0</source>
                <value>author</value>
            </role>
            <entity>BEGIN:VCARD
    VERSION:3.0
    FN:Frédéric Bergeron
    N:Bergeron;Frédéric;;;
    EMAIL;TYPE=INTERNET:frederic.bergeron@licef.org
    TEL;TYPE=WORK,VOICE:+1-514-948-1234
    TEL;TYPE=WORK,FAX:+1-514-948-1231
    ADR;TYPE=WORK,POST:;;7400,boul. Saint-Laurent,Bureau 530;Montréal;Québec;H2R 2Y1;Canada
    ORG:LICEF
    END:VCARD
    </entity>
            <date>
                <dateTime>1999-12-01</dateTime>
                <description><string language="fr">non disponible</string></description>
            </date>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    [] mlr2:DES0200 "Frédéric Bergeron".

#### Éditeurs

Similarly, a contribution whose role is `LOMv1.0:publisher` is interpreted as a `dc:publisher` (`mlr2:DES0500`).

    :::xml
    <lifeCycle>
        <contribute>
            <role>
                <source>LOMv1.0</source>
                <value>publisher</value>
            </role>
            <entity>BEGIN:VCARD
    VERSION:3.0
    FN:Frédéric Bergeron
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    [] mlr2:DES0500 "Frédéric Bergeron".

#### Collaborateurs

Finally, all other roles are interpreted as `dc:contributor` (`mlr2:DES0600`).

    :::xml
    <lifeCycle>
        <contribute>
            <role>
                <source>LOMv1.0</source>
                <value>technical validator</value>
            </role>
            <entity>BEGIN:VCARD
    VERSION:3.0
    FN:Frédéric Bergeron
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    [] mlr2:DES0600 "Frédéric Bergeron".

#### `ISO_IEC_19788-5:2012::VA.1:`

Besides those DC elements, each LOM lifecycle element can be expressed as a contribution in MLR5 terms.
The mlr5 *Agent Role* vocabulary is simplistic, containing only author and validator. 
Most [LOM v.10 lifeCycle roles](http://www.lom-fr.fr/vdex/lomfrv1-0/lom/vdex_lc_roles.xml) can be mapped authors, except validators which are named as such in LOM. 

    :::xml
    <lifeCycle>
        <contribute>
            <role>
                <source>LOMv1.0</source>
                <value>technical validator</value>
            </role>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES0800 <ISO_IEC_19788-5:2012::VA.1:T020> ] .

##### Exceptions

The difficult cases are `publisher` and `unknown`, which are not translated as vocabulary entities, but as literals.

    :::xml
    <lifeCycle>
        <contribute>
            <role>
                <source>LOMv1.0</source>
                <value>unknown</value>
            </role>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES0800 "unknown" ] .



### Person identities

Various contributors may be interpreted as entities of the Person type (`mlr1:RC0003`), or the subtypes Natural person (`mlr9:RC0001`) or Organisation (`mlr9:RC0002`).

#### Identifying natural persons

Natural persons are distinguished from organizations through the presence of the `N` element in the `VCARD`.

    :::xml
    <lifeCycle>
        <contribute>
            <role>
                <source>LOMv1.0</source>
                <value>author</value>
            </role>
            <entity>BEGIN:VCARD
    VERSION:3.0
    FN:Marc-Antoine Parent
    N:Parent;Marc-Antoine;;;
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 [ a mlr9:RC0001 ] ] .

#### Identifying organizations

Conversely, organizations are distinguished by the presence of a `ORG` element and the absence of a `N` element.

    :::xml
    <lifeCycle>
        <contribute>
            <role>
                <source>LOMv1.0</source>
                <value>author</value>
            </role>
            <entity>BEGIN:VCARD
    VERSION:3.0
    FN:GTN-Québec
    ORG:GTN-Québec
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 [ a mlr9:RC0002 ] ] .


#### Absence of `N` or `ORG` in a `VCARD`

Absent either those attributes, we fall back on the generic person entity.

    :::xml
    <lifeCycle>
        <contribute>
            <role>
                <source>LOMv1.0</source>
                <value>author</value>
            </role>
            <entity>BEGIN:VCARD
    VERSION:3.0
    FN:va savoir
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 [ a mlr1:RC0003 ] ] .



#### Natural person with work information

If a natural person has an `ORG` in their vCard, or information of subtype work (whether `URL`, `ADR`, `EMAIL` or `TEL`), there must be an underlying organization. In the case of `ORG`, `URL` and `ADR` (presumed to be of subtype `POST`), it gives us further information to attach to the organization, and we then create a corresponding entity. `EMAIL` and `TEL` elements, on the other hand, are often individual, and are not assigned to the organizational entity. We did consider, and reject, a heuristic that would have assigend the email and telephone to the organization if the person had had both `WORK` and `HOME` emails.

This raises many issues. In some cases, the `URL` or postal `ADR` may refer to that person individual's office or home page rather than the organization's. It is however very difficult to detect this based on a single vCard, which is the scope of our study. In further study, more approaches may be considered:

1. Consider only the domain, either from the work email or the work URL. We could check whether they coincide, but it is not clear what to do otherwise. However, we run the risk of misrepresenting sites of individuals who have a business site with a common ISP.
2. If the email handle is found in the trailing element of the work URL, it could be considered safe for elimination. However, it is not a given that the resulting parent URL is indexable.
3. If we were looking across many vCards, and saw many work URLs with the same domain but different paths, we could consider the shortest common subpath to be the organizational URL, but this is subject to the same risks as above. More important, it makes the work URL non-deterministic, subject to what other vCards have been collected at that point.

Conversely, we could consider that if a work information (esp. phone or email) is shared between different natural persons, it can safely be considered to be corporate. However, this also depends on information collected across vCards, and possibly across LOM elements.

The current heuristic is far from satisfying, but may be the best we can do given the imprecision of available information. Let us not forget, moreover, that the `WORK` subtypes are often left blank, or worse, filled arbitrarily by mail agents' user interfaces, and not systematically corrected by users. 

All this considered, we have settled on the following heuristics:

##### Some work information triggers an organization entity

###### `ORG`

The `ORG` is carried over in the entity's data as `mlr9:DES1200`. It is also used as identifier (`mlr9:DES0100`) unless a work URL is present. 

    :::xml
    <lifeCycle>
        <contribute>
            <role>
                <source>LOMv1.0</source>
                <value>author</value>
            </role>
            <entity>BEGIN:VCARD
    VERSION:3.0
    FN:Marc-Antoine Parent
    N:Parent;Marc-Antoine;;;
    ORG:GTN-Québec
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 [ a mlr9:RC0001 ;
                mlr9:DES1100 [ a mlr9:RC0002;
                               mlr9:DES1200 "GTN-Québec";
                               mlr9:DES0100 "GTN-Québec" ] ] ] .

##### `ADR` of subtype `WORK`

The vCard address is broken down into the following subcomponents:

1. Box
2. Extended
3. Street
4. City
5. Region
6. Code
7. Country

We format the address according to the following schema:

    :::
    street
    city, region, code
    country 

 and use it as a `mlr9:DES1700` address for a `mlr9:RC0003` (Geographical location.)

    :::xml
    <lifeCycle>
        <contribute>
            <role>
                <source>LOMv1.0</source>
                <value>author</value>
            </role>
            <entity>BEGIN:VCARD
    VERSION:3.0
    FN:Marc-Antoine Parent
    N:Parent;Marc-Antoine;;;
    ADR;TYPE=WORK,POST:;;7400,boul. Saint-Laurent,Bureau 530;Montréal;Québec;H2R 2Y1;Canada
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 [ a mlr9:RC0001 ;
                mlr9:DES1100 [ a mlr9:RC0002;
                    mlr9:DES1300 [ a mlr9:RC0003;
                        mlr9:DES1700 """7400 boul. Saint-Laurent Bureau 530
    Montréal, Québec, H2R 2Y1
    Canada""" ] ] ] ].

##### Work URL

Work URL also becomes the organization's identifying URL. This identifying URL is both the RDF subject and the `mlr9:0010` identifier. Note that we did not discern any case when `mlr9:0010` is distinct from the RDF subject identifier.

    :::xml
    <lifeCycle>
        <contribute>
            <role>
                <source>LOMv1.0</source>
                <value>author</value>
            </role>
            <entity>BEGIN:VCARD
    VERSION:3.0
    FN:Marc-Antoine Parent
    N:Parent;Marc-Antoine;;;
    URL;TYPE=WORK:http://www.gtn-quebec.org/
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 [ a mlr9:RC0001 ;
                mlr9:DES1100 <http://www.gtn-quebec.org/> ] ] .
    <http://www.gtn-quebec.org/> a mlr9:RC0002;
        mlr9:DES0100 <http://www.gtn-quebec.org/>.


#### Actor's URL

There is a controversy within the GTN-Québec. When we do not have a proper identity URL for an identity, there are four options:

1. Use any relevant URL as the entity's identity
2. Use a UUID based on known information in a deterministic manner
3. Use a blank node
4. Use a randomized UUID.


In cases where no URL is available, Gilles Gauthier remarked that successive analysis of the same vCard could pollute the database with as many blank nodes, which gives a valid general reason to prefer deterministic UUIDs (2) to blank nodes (3). Gilles Gauthier also favours random UUIDs (4) over blank nodes, but the rationale given does not justify this preference, since blank nodes would also be regenerated. (Gilles, je te laisse développer ta position, que je croyais comprendre mais comme tu nous a dit refuser mon dernier contre-argument sans l'avoir justifié, je n'ai aucune façon de savoir si j'ai bien saisi tes raisons.) 

On the other hand, Marc-Antoine Parent believes that blank nodes accurately convey absence of information, which can be preferred in some cases. If a harvester receives MLR information from many converters, and each converter implements a different deterministic UUID, we will have many different identities for the same entity. 

At first sight, this is identical to multiple blank nodes created in the same fashion, and less of an issue than the more frequent blank nodes created by multiple reads. However, either problem needs solving, and a heuristic for declaring entities as identical is necessary. Now, such algorithms are computationally expensive, and it would be convenient to restrict their application to nodes which are known not to have a proper identity, namely blank nodes. Creating many arbitrary identities requires applying identification heuristics to a much greater number of entities.

Note that, if the deterministic UUIDs were agreed upon in a norm, that argument would fall. We could decide that, absent URL and Email, we will generate a UUID based on (e.g.) a person's home phone number or address as a strings in some appropriate namespace. If the strategy were common to all converters, collisions would happen to positive effect. A downside is that different vCards for the same person, with different subsets of identifying information, would again yield different identifiers, and the problem of finding correspondances between named (vs blank) entities reappears. As long as the strategies are shared, this problem is minimal, as we would know how to search for corresponding entities in that case; but until the algorithm for UUID generation is made part of the norm, such strategies may add to the problem instead of solving it.

We nonetheless propose applying a deterministic strategy Emails, as the generated UUID is "natural" enough that we feel it should be easy to agree upon even without a common policy.

Finally, Marc-Antoine Parent believes that some objects only have a source and content; if the source URL is not known, there is no information that may act as a "natural" identifier other than the content itself. Comments fall in this category. Using (a hash of) the content to generate a URL subverts the meaning of URLs, which designate the entity rather than embody it.

Concretely, what do we recommend? In the case of natural persons (and persons), we can use the following information. Some options are disabed by settings, as discussed above.

1. FOAF URL
2. Preferred URL
3. Any URL (non-work)
4. A UUID calculated from non-work email and FN
5. A UUID calculated from non-work email (disabled)
6. A UUID calculated from FN (disabled)
7. A random UUID (disabled)

If the natural person also has organization information, we can also use the following information:

1. Work URL
2. A UUID calculated from work email and ORG
3. A UUID calculated from work email (disabled)
4. A random UUID (disabled)

Finally, an organization uses the following identifiers:

1. FOAF URL
2. Preferred URL
3. Any URL
4. A UUID calculated from an email and ORG
4. A UUID calculated from an email and FN
5. A UUID calculated from an email (disabled)
6. A UUID calculated from ORG
6. A UUID calculated from FN (disabled)
7. A random UUID (disabled)

##### Person's URL as an identifier

If a person's vCard has a URL, it will be used as identifier.
Note that this is not a safe assumption in general; we should get the FOAF URI of the person, but that is not specified by the vCard protocol, or any extension we could find. It would be relevant to propose such an extension.

    :::xml
    <lifeCycle>
        <contribute>
            <role>
                <source>LOMv1.0</source>
                <value>author</value>
            </role>
            <entity>BEGIN:VCARD
    VERSION:3.0
    FN:Marc-Antoine Parent
    N:Parent;Marc-Antoine;;;
    URL:http://maparent.ca/
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 <http://maparent.ca/> ] .
    <http://maparent.ca/> a mlr9:RC0001 .

##### Person's email as basis for identifier

If a person's vCard has an email, we could use the `mailto:` URL directly as an identifier, but it is almost certain to conflict with that person's real URI. We prefer in this case to create a UUID based on the email, in a custom namespace, as follows:

1. Make the email into an `mailto:` URL (e.g.: `mailto:map@ntic.org`)
2. Create a UUID-5 URN based on this URL, in the URL namespace. (in our example, we obtain `urn:uuid:a06d8251-3b16-3f19-9dce-31d0e9a1f6b8`.)

The resulting URN is used as the person's URI.

    :::xml
    <lifeCycle>
        <contribute>
            <role>
                <source>LOMv1.0</source>
                <value>author</value>
            </role>
            <entity>BEGIN:VCARD
    VERSION:3.0
    FN:Marc-Antoine Parent
    N:Parent;Marc-Antoine;;;
    EMAIL;TYPE=INTERNET:map@ntic.org
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 <urn:uuid:a06d8251-3b16-3f19-9dce-31d0e9a1f6b8> ] .
    <urn:uuid:a06d8251-3b16-3f19-9dce-31d0e9a1f6b8> a mlr9:RC0001 .

##### Use blank nodes

Otherwise, we use blank nodes to designate the person's identity.


### Vcard elements

The VCard contains much useful information besides the name and identity. However, much information can be ambiguous, and we have to resort to heuristics. Note that information coming from the vCard is normally considered non-linguistic.

#### Organization

If a person has an ORG field in their VCard, it can be expressed as an organization.


    :::xml
    <lifeCycle>
        <contribute>
            <role>
                <source>LOMv1.0</source>
                <value>author</value>
            </role>
            <entity>BEGIN:VCARD
    VERSION:3.0
    FN:Marc-Antoine Parent
    N:Parent;Marc-Antoine;;;
    ORG:GTN-Québec
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 [ a mlr9:RC0001 ;
                mlr9:DES1100 [ a mlr9:RC0002; ] ] ] .


#### URL

If a person has a URL marked as "work" in their vCard, it may refer to them specifically or to their organization as a whole. We assume the latter.

    :::xml
    <lifeCycle>
        <contribute>
            <role>
                <source>LOMv1.0</source>
                <value>author</value>
            </role>
            <entity>BEGIN:VCARD
    VERSION:3.0
    FN:Marc-Antoine Parent
    N:Parent;Marc-Antoine;;;
    URL;TYPE=WORK:http://www.gtn-quebec.org/
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 [ a mlr9:RC0001 ;
                mlr9:DES1100 <http://www.gtn-quebec.org/> ] ] .
    <http://www.gtn-quebec.org/> a mlr9:RC0002.


### Contribution Date

#### Authorship date

The author's contribution date gets translated as `mlr2:DES0700`.

    :::xml
    <lifeCycle>
        <contribute>
            <role>
                <source>LOMv1.0</source>
                <value>author</value>
            </role>
            <date>
                <description>
                    <string language="fra-CA">mi-XVIème siècle</string>
                </description>
            </date>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002;
        mlr2:DES0700 "mi-XVIème siècle"@fra-CA.

#### Parsable date

If the author's contribution can be interpreted as a ISO 8601 date or datetime, we can be more precise and use `mlr3:DES0100`.

    :::xml
    <lifeCycle>
        <contribute>
            <role>
                <source>LOMv1.0</source>
                <value>author</value>
            </role>
            <date>
                <dateTime>2012-01-01</dateTime>
            </date>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002;
        mlr3:DES0100 "2012-01-01"^^<http://www.w3.org/2001/XMLSchema#date>.

##### #####

    :::xml
    <lifeCycle>
        <contribute>
            <role>
                <source>LOMv1.0</source>
                <value>author</value>
            </role>
            <date>
                <dateTime>2012-01-01T00:00</dateTime>
            </date>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002;
        mlr3:DES0100 "2012-01-01T00:00"^^<http://www.w3.org/2001/XMLSchema#dateTime>.

#### Contribution dates

Dates are transferred within the `mlr5:DES0700` contribution entities, as long as they can be parsed.

    :::xml
    <lifeCycle>
        <contribute>
            <role>
                <source>LOMv1.0</source>
                <value>publisher</value>
            </role>
            <date>
                <dateTime>2012-01-01T00:00</dateTime>
            </date>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002;
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES0700 "2012-01-01T00:00"^^<http://www.w3.org/2001/XMLSchema#dateTime> ] .

##### #####

Unparsable dates are simply ignored.

    :::xml
    <lifeCycle>
        <contribute>
            <role>
                <source>LOMv1.0</source>
                <value>publisher</value>
            </role>
            <description>
                <string language="fra-CA">mi-XVIème siècle</string>
            </description>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002;
        mlr5:DES1700 [ a mlr5:RC0003 ].

without

    :::N3
    []  a mlr1:RC0002;
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES0700 "mi-XVIème siècle"@fra-CA ] .

