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

If `general/identifier` we would use the first available URL in `technical/location`. This is a heuristics, as there is no automated way to distinguish multiple URLs.

    :::xml
    <technical>
        <location>http://xserve.scedu.umontreal.ca/~cyberscol/videos/v00008-640-s.mov</location>
    </technical>

Becomes

    :::N3
    <http://xserve.scedu.umontreal.ca/~cyberscol/videos/v00008-640-s.mov> a mlr1:RC0002.

However, we would not use this for the MLR3 identifier tag, so we would *not* get:

    :::N3
    <http://xserve.scedu.umontreal.ca/~cyberscol/videos/v00008-640-s.mov> a mlr1:RC0002;
      mlr3:DES0400 <http://xserve.scedu.umontreal.ca/~cyberscol/videos/v00008-640-s.mov> .

### DublinCore elements

Many elements have a direct translation in DublinCore, and hence in MLR-2.

#### general/title

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

Ideally, language should follow ISO 639-3. This can be detected by a regular expression, and we can then translate as `MLR-3:DES0500`.

    :::xml
    <general>
        <language>fra-CA</language>
    </general>

Becomes

    :::N3
    [] mlr3:DES0500 "fra-CA" .


#### general/language

But more generally, we can use the MLR-2 version of that property. (We may translate ISO 639-2 codes to ISO 639-3.)

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

Most LOM roles have an equivalent in the MLR-5 *Agent Role* vocabulary, used for contributions.

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
