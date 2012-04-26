# Conversion LOM vers MLR

## Généralités  ##

### Identifiant

#### Identifiant explicite

La balise `general/identifier` de LOM est employé de préférence pour l'identité. Elle est également employée pour l'élément mlr3:DES0400. 

Question ouvertes: Que faire du `catalog`? Que faire si l'entry n'est pas un URI?

    :::xml
    <general>
        <identifier>
            <catalog>TEST</catalog>
            <entry>oai:test.licef.ca:123123</entry>
        </identifier>
    </general>

Devient

    :::N3
    <oai:test.licef.ca:123123> a mlr1:RC0002;
      mlr3:DES0400 <oai:test.licef.ca:123123> .

#### Emploi de technique/localisation comme identifiant

Si `general/identifier` est absent, on prendra le premier URL disponible dans `technical/location`.

    :::xml
    <technical>
        <location>http://xserve.scedu.umontreal.ca/~cyberscol/videos/v00008-640-s.mov</location>
    </technical>

Devient

    :::N3
    <http://xserve.scedu.umontreal.ca/~cyberscol/videos/v00008-640-s.mov> a mlr1:RC0002.

Mais nous ne l'employons pas pour la balise d'identification de MLR3, donc nous n'aurons pas:

    :::N3
    <http://xserve.scedu.umontreal.ca/~cyberscol/videos/v00008-640-s.mov> a mlr1:RC0002;
      mlr3:DES0400 <http://xserve.scedu.umontreal.ca/~cyberscol/videos/v00008-640-s.mov> .

### Éléments DublinCore

Beaucoup d'éléments ont une traduction directe en DublinCore, et donc en MLR-2.

#### general/title

    :::xml
    <general>
        <title>
            <string language="fra-CA">Conditions favorables à l'intégration des TIC...</string>
        </title>
    </general>

Devient

    :::N3
    [] mlr2:DES0100 "Conditions favorables à l'intégration des TIC..."@fra-CA .

#### general/language suivant ISO 639-3

Idéalement, la langue devrait suivre ISO 639-3. Dans ce cas, nous pouvons employer `MLR-3:DES0500`.

    :::xml
    <general>
        <language>fra-CA</language>
    </general>

Devient

    :::N3
    [] mlr3:DES0500 "fra-CA" .


#### general/language

Mais dans le cas plus général, nous pouvons employer la version MLR-2. (Nous pourrions envisager de traduire les codes ISO 639-2 en ISO 639-3.)

    :::xml
    <general>
        <language>français</language>
    </general>

Devient

    :::N3
    [] mlr2:DES1200 "français" .

#### general/description

La description pourrait se traduire par `mlr2:DES0400`, mais en pratique il n'y a jamais de raison de ne pas plutôt employer `mlr3:DES0200`.

    :::xml
    <general>
        <description>
            <string language="fra-CA">L'enseignant identifie les contraintes...</string>
        </description>
    </general>

Devient

    :::N3
    [] mlr3:DES0200 "L'enseignant identifie les contraintes..."@fra-CA .

Et non pas

    :::N3
    [] mlr2:DES0400 "L'enseignant identifie les contraintes..."@fra-CA .

#### general/keyword ####

Les mots clés peuvent être traités comme des sujets.

    :::xml
    <general>
        <keyword>
          <string language="fra">optique</string>
          <string language="fra">physique</string>
        </keyword>
    </general>

Devient

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

Devient

    :::N3
    [] mlr2:DES1400 "Québec"@fra-CA.

### Aspects non traités

`general/structure` et `general/aggregationLevel` n'ont pas d'équivalent MLR (sauf les composites, traités dans `mlr3:DES0700`)

## Cycle de vie

### Rôles

#### Auteurs 

Une contribution dont le rôle est `LOMv1.0:author` est traitée comme un *Creator* au sens DublinCore (`mlr2:DES0200`). On emploiera alors le `FN` de la `VCARD`.

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

Devient

    :::N3
    [] mlr2:DES0200 "Frédéric Bergeron".

#### Éditeurs

De façon similaire, une contribution dont le rôle est `LOMv1.0:publisher` est traitée comme un *Publisher* au sens DublinCore (`mlr2:DES0500`).

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

Devient

    :::N3
    [] mlr2:DES0500 "Frédéric Bergeron".

#### Collaborateurs

Enfin, tout autre rôle est traité comme un *Contributor* au sens DublinCore (`mlr2:DES0600`).

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

Devient

    :::N3
    [] mlr2:DES0600 "Frédéric Bergeron".

#### `ISO_IEC_19788-5:2012::VA.1:`

La plupart des rôles de LOM ont un équivalent dans le vocabulaire *Agent Role* de MLR-5, employé pour les contributions.

    :::xml
    <lifeCycle>
        <contribute>
            <role>
                <source>LOMv1.0</source>
                <value>technical validator</value>
            </role>
        </contribute>
    </lifeCycle>

Devient

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES0800 <ISO_IEC_19788-5:2012::VA.1:T020> ] .

### Types de personnes

Les différents contributeurs sont également exprimés par une entité de type Personne (`mlr1:RC0003`), Personne naturelle (`mlr9:RC0001`) ou Organisation (`mlr9:RC0002`).

#### Identifier les personnes naturelles

On distingue les personnes naturelles des organisations par la présence de l'élément `N` dans la `VCARD`.

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

Donnera

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 [ a mlr9:RC0001 ] ] .

#### Identifier les organisations

On identifie les organisations par la présence d'un élément `ORG` et l'absence d'un élément `N`.

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

Devient

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 [ a mlr9:RC0002 ] ] .


#### Absence de `N` ou `ORG` dans une `VCARD`

En l'absence de l'un ou l'autre, on se rabat sur la personne générique.

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

Devient

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 [ a mlr1:RC0003 ] ] .
