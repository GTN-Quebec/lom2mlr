# Conversion

## Identité du LOM

### general/identifier

La balise `general/identifier` de LOM est employé de préférence pour l'identité

    :::xml
    <general>
        <identifier>
            <catalog>TEST</catalog>
            <entry>oai:test.licef.ca:123123</entry>
        </identifier>
    </general>

Devient

    :::N3
    <oai:test.licef.ca:123123> a mlr1:RC0002.

### technical/location

Si general/identifier est absent, on prendra le premier URL disponible

    :::xml
    <technical>
        <location>http://xserve.scedu.umontreal.ca/~cyberscol/videos/v00008-640-s.mov</location>
    </technical>

Devient

    :::N3
    <http://xserve.scedu.umontreal.ca/~cyberscol/videos/v00008-640-s.mov> a mlr1:RC0002.

## Identité des contributeurs

### Identifier les personnes

On distingue les personnes des organisations par la présence de l'élément N

    :::xml
    <lifeCycle>
        <contribute>
            <role>
                <source>LOMv1.0</source>
                <value>technical validator</value>
            </role>
            <entity>BEGIN:VCARD
    VERSION:3.0
    FN:Marc-Antoine Parent
    N:Parent;Marc-Antoine;;;
    URL;TYPE=HOME:http://maparent.ca/
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Donnera

    :::N3
    <http://maparent.ca/> a mlr9:RC0001.

### Identifier les organisations

Sans l'élément N, on s'attend à l'élément ORG

    :::xml
    <lifeCycle>
        <contribute>
            <role>
                <source>LOMv1.0</source>
                <value>technical validator</value>
            </role>
            <entity>BEGIN:VCARD
    VERSION:3.0
    FN:GTN-Québec
    ORG:GTN-Québec
    URL;TYPE=HOME:http://gtn-quebec.org/
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Devient

    :::N3
    <http://gtn-quebec.org/> a mlr9:RC0002.

Nous ne devrions donc pas voir

    :::N3
    <http://gtn-quebec.org/> a mlr9:RC0002; mlr9:DES0100 "http://gtn-quebec.org/".

