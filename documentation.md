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

Contribution version and state have no equivalent in MLR.

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

### Person subtypes

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


#### Person's URL as an identifier

If a person's vCard has a URL, it will be used as identifier.
Note that this is not a safe assumption in general; we should get the FOAF URI of the person, but that is not specified by the vCard protocol, or any extension we could find. This should be proposed.

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

#### Person's email as basis for identifier

If a person's vCard has an email, we could use the `mailto:` URL directly as an identifier, but it is almost certain to conflict wit that person's real URI. We prefer in this case to create a UUID based on the email, in a custom namespace, as follows:

1. Start with a URL for MLR: <http://standards.iso.org/iso-iec/19788/>
2. Create a UUID-5 URN based on this URL, in the URL namespace: we obtain `urn:uuid:27d3ab52-3979-57d6-b974-03a2e74312d5`.
3. Use this URN as the basis for a new UUID-5 based on the `mailto:` URL of the person's address.

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
            mlr5:DES1800 <urn:uuid:ed065995-91e8-5b03-a317-1be0aca4e277> ] .
    <urn:uuid:ed065995-91e8-5b03-a317-1be0aca4e277> a mlr9:RC0001 .

### Date


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

If the author's contribution can be interpreted as a ISO 8601 datetime, we can be more precise and use `mlr3:DES0100`.

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

Otherwise, date is part of the contribution, as long as it can be parsed.

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

