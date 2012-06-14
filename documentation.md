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
    ADR;TYPE=POST,WORK:;;455\, rue du Parvis;Québec;Québec;G1K 9H6;Canada
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

#### `WORK` and `HOME` subtypes

Some vCard elements, namely `ADR`, `EMAIL`, `URL` and `TEL` have a `TYPE` indicator, which may take the standard values `WORK` and `HOME`. Absent either a `N` or `ORG` element, the presence of `WORK` elements and the absence of `HOME` elements may together be indicative of an organization.

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
    ADR;TYPE=POST,WORK:;;455\, rue du Parvis;Québec;Québec;G1K 9H6;Canada
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

If a natural person has an `ORG` in their vCard, or information of subtype work (whether `URL`, `ADR`, `EMAIL` or `TEL`), there must be an underlying organization. In the case of `ORG`, `URL` and `ADR` (presumed to be of subtype `POST`), it gives us further information to attach to the organization, and we then create a corresponding entity. (Whether it has a URL is a separate issue.) `EMAIL` and `TEL` elements, on the other hand, are often individual, and are not assigned to the organizational entity. We did consider, and reject, a heuristic that would have assigend the email and telephone to the organization if the person had had both `WORK` and `HOME` emails.

This raises many issues. In some cases, the `URL` or postal `ADR` may refer to that person individual's office or home page rather than the organization's. It is however very difficult to detect this based on a single vCard, which is the scope of our study. In further study, more approaches may be considered:

1. Consider only the domain, either from the work email or the work URL. We could check whether they coincide, but it is not clear what to do otherwise. However, we run the risk of misrepresenting sites of individuals who have a business site with a common ISP.
2. If the email handle is found in the trailing element of the work URL, it could be considered safe for elimination. However, it is not a given that the resulting parent URL is indexable.
3. If we were looking across many vCards, and saw many work URLs with the same domain but different paths, we could consider the shortest common subpath to be the organizational URL, but this is subject to the same risks as above. More important, it makes the work URL non-deterministic, subject to what other vCards have been collected at that point.

Conversely, we could consider that if a work information (esp. phone or email) is shared between different natural persons, it can safely be considered to be corporate. However, this also depends on information collected across vCards, and possibly across LOM elements.

The current heuristic is far from satisfying, but may be the best we can do given the imprecision of available information. Let us not forget, moreover, that the `WORK` subtypes are often left blank, or worse, filled arbitrarily by mail agents' user interfaces, and not systematically corrected by users. 

Out of scope: We have not treated the case of a person with multiple organizations, using the (rare) vCard grouping mechanism.

So to review, here is the information that triggers an organization entity:

##### `ORG`

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
    ADR;TYPE=POST,WORK:;;455\, rue du Parvis;Québec;Québec;G1K 9H6;Canada
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
                        mlr9:DES1700 """455, rue du Parvis
    Québec, Québec, G1K 9H6
    Canada""" ] ] ] ].

##### Work URL

Work URL also becomes the organization's identifying URL. This identifying URL is both the RDF subject and the `mlr9:0010` identifier. (Gilles:  La définition de mlr9:0010 donne litéral, mais il s'agit d'un URL. Devrais-je employer un litéral ou une ressource en ce cas?)

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


### Identifying URLs

There is a controversy within the GTN-Québec. When we do not have a proper identity URL for an identity, there are four options:

1. Use any relevant URL as the entity's identity
2. Use a UUID based on known information in a deterministic manner
3. Use a blank node
4. Use a randomized UUID.


In cases where no URL is available, Gilles Gauthier remarked that successive analysis of the same vCard could pollute the database with as many blank nodes, which gives a valid general reason to prefer deterministic UUIDs (2) to blank nodes (3). Gilles Gauthier also favours random UUIDs (4) over blank nodes, but the rationale given does not justify this preference, since blank nodes would also be regenerated. (Gilles, j'aimerais que tu développes ta position, que je croyais comprendre mais comme tu nous a dit refuser mon dernier contre-argument sans l'avoir justifié, je n'ai aucune façon de savoir si j'ai bien saisi tes raisons.) 

On the other hand, Marc-Antoine Parent believes that blank nodes accurately convey absence of information, which can be preferred in some cases. If a harvester receives MLR information from many converters, and each converter implements a different deterministic UUID, we will have many different identities for the same entity. 

At first sight, this is identical to multiple blank nodes created in the same fashion, and less of an issue than the more frequent blank nodes created by multiple reads. However, either problem needs solving, and a heuristic for declaring entities as identical is necessary. Now, such algorithms are computationally expensive, and it would be convenient to restrict their application to nodes which are known not to have a proper identity, namely blank nodes. Creating many arbitrary identities requires applying identification heuristics to a much greater number of entities.

Actually, it is quite likely that certain graph databases notice when a blank node is re-introduced with exactly the same relations, and optimize it away. This is only possible in a transactional context; otherwise the new blank node might get new relations later. If the blank node were to receive a random UUID on successive introductions, that optimization would be defeated. (We need to check on the state of the art in this regard.)

Note that, in the case of deterministic UUIDs, this problem disappears if they are agreed upon in a norm. Otherwise, if we have divergent strategies for deterministic UUIDs, the problem of knowing what to match remains. For example, we could decide that, absent URL and Email, we will generate a UUID based on (e.g.) a person's home phone number or address as a strings in some appropriate namespace. If the strategy were common to all converters, collisions would happen to positive effect. A downside is that different vCards for the same person, with different subsets of identifying information, would again yield different identifiers, and the problem of finding correspondances between named (vs blank) entities reappears. As long as the strategies are shared, this problem is minimal, as we would know how to search for corresponding entities in that case; but until the algorithm for UUID generation is made part of the norm, such strategies may add to the problem instead of solving it.

We nonetheless propose applying a deterministic strategy to a combination of name and email, as the generated UUID is "natural" enough that we feel it should be easy to agree upon even without a common policy. We also propose using it for `ORG`, less natural, but where it has the most payoff.

As an additional point, Marc-Antoine Parent believes that some objects only have a source and content; if the source URL is not known, there is no information that may act as a "natural" identifier other than the content itself. Comments fall in this category. Using (a hash of) the content to generate a URL subverts the meaning of URLs, which designate the entity rather than embody it.

Concretely, what do we recommend? 

#### Natural persons

In the case of natural persons (and persons), we can use the following information. Some options are disabed by settings, as discussed above.

##### FOAF URL

Though it is not in much use, a strategy exists to identify FOAF URLs in a vCard, as noted in [this study](http://www.w3.org/2002/12/cal/vcard-notes.html). 

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
    item1.URL:http://maparent.ca/
    item2.URL:http://maparent.ca/foaf.rdf
    item2.X-ABLabel:FOAF
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 <http://maparent.ca/foaf.rdf> ] .
    <http://maparent.ca/foaf.rdf> a mlr9:RC0001;
        mlr9:DES0100 <http://maparent.ca/foaf.rdf>.

In preference to 

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 <http://maparent.ca/> ] .
    <http://maparent.ca/> a mlr9:RC0001 .

##### Preferred URL

Also, some URLs can be marked to be preferred in the vCard.

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
    URL;TYPE=pref:http://maparent.ca/resume.fr.html
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 <http://maparent.ca/resume.fr.html> ] .
    <http://maparent.ca/resume.fr.html> a mlr9:RC0001;
        mlr9:DES0100 <http://maparent.ca/resume.fr.html>.

In preference to 

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 <http://maparent.ca/> ] .
    <http://maparent.ca/> a mlr9:RC0001 .

##### Any URL (non-work)

Otherwise, the first non-work URL will be used.

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
    URL:http://maparent.ca/resume.fr.html
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 <http://maparent.ca/> ] .
    <http://maparent.ca/> a mlr9:RC0001 ;
        mlr9:DES0100 <http://maparent.ca/> .


In preference to 

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 <http://maparent.ca/resume.fr.html> ] .
    <http://maparent.ca/resume.fr.html> a mlr9:RC0001 .

##### A UUID calculated from non-work email and FN

If a non-work email is available, both the email and name are likely to identify a person. We can then create a UUID as follows:

1. Make the email into an `mailto:` URL (e.g.: `mailto:map@ntic.org`)
2. Create a UUID-5 based on this URL, in the URL namespace. (in our example, we obtain the UUID `75642fb6-e2d3-549b-9bf5-b62743af640d`.)
3. Create a UUID-3 based on the `FN`, using the step 2) UUID as a namespace. In our example, we obtain the UUID `a06d8251-3b16-3f19-9dce-31d0e9a1f6b8`.

As for the identifier, we follow the LDIF practiced as described on [this page](http://www.w3.org/2002/12/cal/vcard-notes.html), using the email and `FN` in the following format: `cn=<FN>,mail=<email>`.

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
    <urn:uuid:a06d8251-3b16-3f19-9dce-31d0e9a1f6b8> a mlr9:RC0001 ;
        mlr9:DES0100 "cn=Marc-Antoine Parent,mail=map@ntic.org" .


##### A UUID calculated from non-work email (disabled)

It would also be possible to use the email-based UUID (step 2 above) directly; but, since the FN is always available, it does not seem appropriate. 

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
    <urn:uuid:a06d8251-3b16-3f19-9dce-31d0e9a1f6b8> a mlr9:RC0001 ;
        mlr9:DES0100 "cn=Marc-Antoine Parent,mail=map@ntic.org" .

But not

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 <urn:uuid:75642fb6-e2d3-549b-9bf5-b62743af640d> ] .
    <urn:uuid:75642fb6-e2d3-549b-9bf5-b62743af640d> a mlr9:RC0001 ;
        mlr9:DES0100 "map@ntic.org" .

##### A URL of non-work email (disabled)

For the same reason, we do not reccomend using the email itself.

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
    <urn:uuid:a06d8251-3b16-3f19-9dce-31d0e9a1f6b8> a mlr9:RC0001 ;
        mlr9:DES0100 "cn=Marc-Antoine Parent,mail=map@ntic.org" .

But not

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 <mailto:map@ntic.org> ] .
    <mailto:map@ntic.org> a mlr9:RC0001 ;
        mlr9:DES0100 "map@ntic.org" .

##### A UUID calculated from FN (disabled)

We also considered using the `FN` alone; for example as a UUID-3 based on an ad-hoc namespace. In that scheme, we would start with the UUID for <http://gtn-quebec.org/ns/vcarduuid/fn/>, which is `7b5f0e28-5d98-5559-9a2f-c70843822a64`, and combine it with the `FN` to obtain `d37cac8d-50b5-3b1f-aa3c-343ea4fd87bb`. But the danger of `FN` collision is non-negligible, so we advise against it. However, we may still use it as identifier in `mlr9:DES0100`.

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

Uses a blank node, thus:

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 [a mlr9:RC0001 ;
                mlr9:DES0100 "Marc-Antoine Parent" ] ] .

and does not become

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 <urn:uuid:d37cac8d-50b5-3b1f-aa3c-343ea4fd87bb> ] .
    <urn:uuid:d37cac8d-50b5-3b1f-aa3c-343ea4fd87bb> a mlr9:RC0001 ;
        mlr9:DES0100 "Marc-Antoine Parent" .

##### A random UUID (disabled)

The worst last-resort strategy would be to use a non-deterministic random UUID.

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

Uses a blank node

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 [a mlr9:RC0001 ;
                mlr9:DES0100 "Marc-Antoine Parent" ] ] .

and does not become

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 <urn:uuid:d4836d01-8411-4eda-bb93-6f28de7bda1f> ] .
    <urn:uuid:d4836d01-8411-4eda-bb93-6f28de7bda1f> a mlr9:RC0001.

#### Organization within a person's vCard

If the natural person also has organization information, we can create a corresponding `mlr9:RC0002`. The identities we can use are as follows:

##### Work URL

We can use the work URL. (Note: Should we look for a preferred work URL first?)

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
    URL;TYPE=WORK:http://gtn-quebec.org/
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 [a mlr9:RC0001 ;
                mlr9:DES0100 "Marc-Antoine Parent";
                mlr9:DES1100 <http://gtn-quebec.org/> ] ] .
    <http://gtn-quebec.org/> a mlr9:RC0002;
        mlr9:DES0100 <http://gtn-quebec.org/> .

##### A UUID calculated from work email and ORG

If a work email is given, we do not have enough information, but if a work email and an ORG are given, we can calculate a joint UUID just as we did for a person. As stated before, this makes the rash assumption that the work email is the company's email.

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
    EMAIL;TYPE=INTERNET,WORK:map@ntic.org
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 [a mlr9:RC0001 ;
                mlr9:DES0100 "Marc-Antoine Parent";
                mlr9:DES1100 <urn:uuid:0a449567-b242-3586-a14e-4c24afd49adf> ] ] .
    <urn:uuid:0a449567-b242-3586-a14e-4c24afd49adf> a mlr9:RC0002;
        mlr9:DES0100 "cn=GTN-Québec,mail=map@ntic.org" .


##### A UUID calculated from work email (disabled)

It would be even more rash to simply use the work email as a basis for UUID.


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
    EMAIL;TYPE=INTERNET,WORK:map@ntic.org
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 [a mlr9:RC0001 ;
                mlr9:DES0100 "Marc-Antoine Parent" ] ] .

And not

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 [a mlr9:RC0001 ;
                mlr9:DES0100 "Marc-Antoine Parent";
                mlr9:DES1100 <urn:uuid:75642fb6-e2d3-549b-9bf5-b62743af640d> ] ] .
    <urn:uuid:75642fb6-e2d3-549b-9bf5-b62743af640d> a mlr9:RC0002;
        mlr9:DES0100 "map@ntic.org" .

##### A URL of work email (disabled)

For the same reason, we do not use the work email itself.


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
    EMAIL;TYPE=INTERNET,WORK:map@ntic.org
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 [a mlr9:RC0001 ;
                mlr9:DES0100 "Marc-Antoine Parent" ] ] .

And not

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 [a mlr9:RC0001 ;
                mlr9:DES0100 "Marc-Antoine Parent";
                mlr9:DES1100 <mailto:map@ntic.org> ] ] .
    <mailto:map@ntic.org> a mlr9:RC0002;
        mlr9:DES0100 "map@ntic.org" .


##### A random UUID (disabled)

The worst last-resort strategy would be, again, to use a non-deterministic random UUID.

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
    ADR;TYPE=POST,WORK:;;455\, rue du Parvis;Québec;Québec;G1K 9H6;Canada
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Uses a blank node to become

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 [a mlr9:RC0001 ;
                mlr9:DES0100 "Marc-Antoine Parent";
                    mlr9:DES1100 [ a mlr9:RC0002;
                            mlr9:DES1300 [ a mlr9:RC0003;
                                    mlr9:DES1700 """455, rue du Parvis
    Québec, Québec, G1K 9H6
    Canada""" ] ] ] ].

And not

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 [a mlr9:RC0001 ;
                mlr9:DES0100 "Marc-Antoine Parent";
                mlr9:DES1100 <urn:uuid:1102ba9f-49c9-4864-88e3-81baf69d2f25> ] ] .
    <urn:uuid:1102ba9f-49c9-4864-88e3-81baf69d2f25> a mlr9:RC0002;
        mlr9:DES1300 [ a mlr9:RC0003;
            mlr9:DES1700 """455, rue du Parvis
    Québec, Québec, G1K 9H6
    Canada""" ].

#### Organization vCard

Finally, an organization uses the following identifiers:

##### FOAF URL

Just as persons, organizations can have a FOAF URL. Further investigation: we should also look for SIOC information.

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
    item1.URL:http://gtn-quebec.org/
    item2.URL:http://gtn-quebec.org/foaf.rdf
    item2.X-ABLabel:FOAF
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 <http://gtn-quebec.org/foaf.rdf> ] .
    <http://gtn-quebec.org/foaf.rdf> a mlr9:RC0002;
        mlr9:DES0100 <http://gtn-quebec.org/foaf.rdf>.

In preference to 

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 <http://gtn-quebec.org/> ] .
    <http://gtn-quebec.org/> a mlr9:RC0002 .


##### Preferred URL

And a preferred URL will be preferred to others.

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
    URL:http://gtn-quebec.org/
    URL;TYPE=pref:http://gtn-quebec.org/contact
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 <http://gtn-quebec.org/contact> ] .
    <http://gtn-quebec.org/contact> a mlr9:RC0002;
        mlr9:DES0100 <http://gtn-quebec.org/contact>.

In preference to 

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 <http://gtn-quebec.org/> ] .
    <http://gtn-quebec.org/> a mlr9:RC0002 .

##### Any URL

Otherwise, the first URL will be used.

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
    URL:http://gtn-quebec.org/contact
    URL:http://gtn-quebec.org/
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 <http://gtn-quebec.org/contact> ] .
    <http://gtn-quebec.org/contact> a mlr9:RC0002;
        mlr9:DES0100 <http://gtn-quebec.org/contact>.

In preference to 

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 <http://gtn-quebec.org/> ] .
    <http://gtn-quebec.org/> a mlr9:RC0002 .

##### A UUID calculated from an email and ORG

As with persons, we do reccommend using name and email as an organization identity key. However, it is possible that `ORG` and `FN` do not match; in that case, and if both are available, using `ORG` is preferable as it is more likely to match UUIDs generated with the same heuristics within person's vCards.

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
    ORG:Groupe de travail québécois sur les normes et standards TI pour l’apprentissage\, l’éducation et la formation
    EMAIL;TYPE=INTERNET:info@gtn-quebec.org
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

The URI will be `UUID3(UUID5(NAMESPACE_URL, 'mailto:info@gtn-quebec.org'), 'Groupe de travail québécois sur les normes et standards TI pour l’apprentissage, l’éducation et la formation')`

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 <urn:uuid:b4b3bff1-8c2d-3f32-99ac-715dbac5e8ed> ] .
    <urn:uuid:b4b3bff1-8c2d-3f32-99ac-715dbac5e8ed> a mlr9:RC0002;
        mlr9:DES0100 "cn=Groupe de travail québécois sur les normes et standards TI pour l’apprentissage, l’éducation et la formation,mail=info@gtn-quebec.org".

In preference to `UUID3(UUID5(NAMESPACE_URL, 'mailto:info@gtn-quebec.org'), 'GTN-Québec')`

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 <urn:uuid:4e45353d-cf87-3306-8dd7-7ed052064228> ] .
    <urn:uuid:4e45353d-cf87-3306-8dd7-7ed052064228> a mlr9:RC0002;
        mlr9:DES0100 "cn=GTN-Québec,mail=info@gtn-quebec.org".


##### A UUID calculated from an email and FN

However, if `ORG` is not present, `FN` will be used.

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
    EMAIL;TYPE=WORK,INTERNET:info@gtn-quebec.org
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 <urn:uuid:4e45353d-cf87-3306-8dd7-7ed052064228> ] .
    <urn:uuid:4e45353d-cf87-3306-8dd7-7ed052064228> a mlr9:RC0002;
        mlr9:DES0100 "cn=GTN-Québec,mail=info@gtn-quebec.org".

##### A UUID calculated from an email (disabled)

Calculting a UUID from an organization's email alone is not advised, as mentioned before.

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
    EMAIL;TYPE=WORK,INTERNET:info@gtn-quebec.org
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 <urn:uuid:4e45353d-cf87-3306-8dd7-7ed052064228> ] .
    <urn:uuid:4e45353d-cf87-3306-8dd7-7ed052064228> a mlr9:RC0002;
        mlr9:DES0100 "cn=GTN-Québec,mail=info@gtn-quebec.org".

and not

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 <urn:uuid:e2c7f47e-85a9-54c1-bf69-18913bbe985c> ] .
    <urn:uuid:e2c7f47e-85a9-54c1-bf69-18913bbe985c> a mlr9:RC0002;
        mlr9:DES0100 "info@gtn-quebec.org".

##### A URL of an email (disabled)

The same comment applies to using the email as an URL.

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
    EMAIL;TYPE=WORK,INTERNET:info@gtn-quebec.org
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 <urn:uuid:4e45353d-cf87-3306-8dd7-7ed052064228> ] .
    <urn:uuid:4e45353d-cf87-3306-8dd7-7ed052064228> a mlr9:RC0002;
        mlr9:DES0100 "cn=GTN-Québec,mail=info@gtn-quebec.org".

and not

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 <mailto:info@gtn-quebec.org> ] .
    <mailto:info@gtn-quebec.org> a mlr9:RC0002;
        mlr9:DES0100 "info@gtn-quebec.org".

##### A UUID calculated from ORG

However, the `ORG` is considered distinctive enough that we are considering that the ad-hoc namespace strategy may be sound in this one case. Namely, we start with the UUID for <http://gtn-quebec.org/ns/vcarduuid/org/>, which is `5286b081-5077-5b10-9741-70b66eda3f61`, and combine it with the `ORG` value to obtain a UUID (for example `3f2de431-0221-3e25-b714-eda47cb4df39`). The danger of `ORG` collision is probably lower than that of `FN` collision.

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
            mlr5:DES1800 <urn:uuid:3f2de431-0221-3e25-b714-eda47cb4df39> ] .
    <urn:uuid:3f2de431-0221-3e25-b714-eda47cb4df39> a mlr9:RC0002;
        mlr9:DES0100 "GTN-Québec".

##### A UUID calculated from FN (disabled)

We could use the same logic with `FN`, but we feel that it would be inconsistent with the decision for natural persons. Still, we could use the same <http://gtn-quebec.org/ns/vcarduuid/fn/> namespace, which is `7b5f0e28-5d98-5559-9a2f-c70843822a64`, and combine it with the `FN` value to obtain a UUID (for example `3f2de431-0221-3e25-b714-eda47cb4df39`).

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
    ADR;TYPE=POST,WORK:;;455\, rue du Parvis;Québec;Québec;G1K 9H6;Canada
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 [ a mlr9:RC0002;
                mlr9:DES0100 "GTN-Québec" ] ] .

But not 

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 <urn:uuid:3f2e62c0-b275-3ebb-8516-196fe3807f4b> ] .
    <urn:uuid:3f2e62c0-b275-3ebb-8516-196fe3807f4b> a mlr9:RC0002;
        mlr9:DES0100 "GTN-Québec".

##### A random UUID (disabled)

The worst last-resort strategy would be, again, to use a non-deterministic random UUID.

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
    ADR;TYPE=POST,WORK:;;455\, rue du Parvis;Québec;Québec;G1K 9H6;Canada
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Uses a blank node to become

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 [ a mlr9:RC0002;
                mlr9:DES0100 "GTN-Québec" ] ] .

But not, for example,

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 <urn:uuid:1800e33b-08c4-41f7-8a41-3a59943178b3> ] .
    <urn:uuid:1800e33b-08c4-41f7-8a41-3a59943178b3> a mlr9:RC0002;
        mlr9:DES0100 "GTN-Québec".

### Vcard elements

The VCard contains much useful information besides the name and identity. However, much information can be ambiguous, and we have to resort to heuristics. Note that information coming from the vCard is normally considered non-linguistic.

#### `N` and `FN`

The `FN` element, when applied to a natural person, is carried over directly as `mlr9:DES0800`.

The `N` element breaks down into the following components: surname, given, additional, prefix, and suffix.
This is used both integrally in `mlr9:DES0700`, decomposed in `mlr9:DES0300` (family name) and `mlr9:DES0400` (given name), and re-composed in `mlr9:DES0500`. In the latter case, we simply use a standard order: "prefix given additional surname suffix".

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
    N:Parent;Marc;Antoine;M.;M.Sc.
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 [ a mlr9:RC0001 ;
                mlr9:DES0100 "Marc-Antoine Parent";
                mlr9:DES0300 "Parent";
                mlr9:DES0400 "Marc";
                mlr9:DES0500 "M. Marc Antoine Parent M.Sc.";
                mlr9:DES0700 "Parent;Marc;Antoine;M.;M.Sc.";
                mlr9:DES0800 "Marc-Antoine Parent" ] ] .

#### `FN` for a generic person

The `FN` element, when applied to a generic person, is carried over directly as `mlr9:DES0200`.

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
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 [ a mlr1:RC0003 ;
                mlr9:DES0200 "Marc-Antoine Parent" ] ] .


#### Organization

The `ORG` element is also directly expressed as `mlr9:DES1200`, always on a `mlr9:RC0002` sub-element.

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
            mlr5:DES1800 [ a mlr9:RC0002 ;
                mlr9:DES1200 "GTN-Québec" ] ].


#### Skype

MLR-9 defines a field for skype: `mlr9:DES0600`. There is no standard field for skype in vCard, but two extensions are in common use: `X-SKYPE` and `X-SKYPE-USERNAME`.

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
    X-SKYPE:maparent
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 [ a mlr9:RC0001 ;
                mlr9:DES0600 "maparent" ] ].

##### #####

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
    X-SKYPE-USERNAME:maparent
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 [ a mlr9:RC0001 ;
                mlr9:DES0600 "maparent" ] ].

#### Email

The `EMAIL` element is also directly expressed as `mlr9:DES0900`. 

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
            mlr5:DES1800 [ a mlr9:RC0001 ;
                mlr9:DES0900 "map@ntic.org" ] ].

##### #####

Similarly for organizations.

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
    EMAIL;TYPE=INTERNET,WORK:map@ntic.org
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 [ a mlr9:RC0002 ;
                mlr9:DES0900 "map@ntic.org" ] ].


##### #####

There is the issue of whether a work email should be attributed to a person or organization when the vCard contains both. We currently attribute it to the latter, but this is under review.


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
    EMAIL;TYPE=INTERNET,HOME:maparent@gmail.com
    EMAIL;TYPE=INTERNET,WORK:map@ntic.org
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
                mlr9:DES0900 "maparent@gmail.com";
                mlr9:DES1100 [ a mlr9:RC0002 ;
                    mlr9:DES0900 "map@ntic.org" ] ] ].

and not

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 [ a mlr9:RC0001 ;
                mlr9:DES0900 "map@ntic.org";
                mlr9:DES0900 "maparent@gmail.com" ] ].

#### `TEL`

Only work phones are considered by MLR-9. They are expressed by `mlr9:DES1000` and attached to the person. Note: We feel the specifications should be altered so the range encompasses generic persons.

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
    TEL;TYPE=VOICE,HOME:1-514-555-9999
    TEL;TYPE=VOICE,WORK:1-514-555-8888
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 [ a mlr9:RC0001 ;
                mlr9:DES1000 "1-514-555-8888" ] ].

and not

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 [ a mlr9:RC0001 ;
                mlr9:DES1000 "1-514-555-9999" ] ].


### Address elements

A work `ADR` element in the vCard is expressed as a geographical location on the organization (`mlr9:RC0003`) through the location property (`mlr9:DES1300`). The `ADR` element is composed of the following components: box, extended, street, city, region, code, country. Those are recomposed using the following pattern:

    :::
    box extended
    street
    city, region, code
    country

This recomposed address is then attributed to the location using `mlr9:DES1700`.

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
    ADR;TYPE=POST,WORK:;;455\, rue du Parvis;Québec;Québec;G1K 9H6;Canada
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    [] a mlr1:RC0002;
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 [ a mlr9:RC0001;
                mlr9:DES1100 [ a mlr9:RC0002;
                    mlr9:DES1300 [ a mlr9:RC0003;
                        mlr9:DES1700 """455, rue du Parvis
    Québec, Québec, G1K 9H6
    Canada""" ] ] ] ] .

#### `GEO`

vCard Geo information is also attached to the geographical location in the case of an organization. We have to decompose in latitude (`mlr9:DES1500`) and longitude (`mlr9:DES1400`).

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
    GEO:37.386013;-122.082932
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    [] a mlr1:RC0002;
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 [ a mlr9:RC0002;
                mlr9:DES1300 [ a mlr9:RC0003;
                    mlr9:DES1400 "-122.082932"^^<http://www.w3.org/2001/XMLSchema#float>;
                    mlr9:DES1500 "37.386013"^^<http://www.w3.org/2001/XMLSchema#float> ] ] ] .

##### `GEO` for persons

However, for persons, the GEO information may apply either to the home or work address; it is dropped for that reason. (Again, we could choose to rely on vCard grouping information, but did not so far.)

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
    GEO:37.386013;-122.082932
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    [] a mlr1:RC0002;
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 [ a mlr9:RC0001;
                mlr9:DES1100 [ a mlr9:RC0002 ] ] ].

But not

    :::N3
    [] a mlr1:RC0002;
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 [ a mlr9:RC0001;
                mlr9:DES1100 [ a mlr9:RC0002;
                    mlr9:DES1300 [ a mlr9:RC0003;
                        mlr9:DES1400 "-122.082932"^^<http://www.w3.org/2001/XMLSchema#float>;
                        mlr9:DES1500 "37.386013"^^<http://www.w3.org/2001/XMLSchema#float> ] ] ] ] .


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

## Technical
### Format
### Size
### Location
### Requirement
### Installation remarks
### Other platform requirements
## Educational
### Learning_activity
#### Learning resource type
#### Typical learning time
### Audience
#### Intended end user role
#### Typical age range
#### Context
### Annotation
### Learning resource type
### Description
### Language
## Rights
## Relations
## Classification
### Discipline
### Curriculum
#### Educational level
