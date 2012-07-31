# Converting LOM to MLR

TODO: Ouvrir compte GTN-Québec GitHub.
TODO: Lots: Avec ou sans MLR record. (Toggle)
MLR9: Suggestions
    Contribution should be a partial MLR record
    Repository should be a resource with entry point URIs (and repository type?)
    DES1100... pourquoi séquence? Préférences? (Maudit RDF!)
Identifier les heuristiques vs normatif comme telles. (couleur?)
Toggle: Ajouter des informations hors-scope, comme l'addresse de vcard.owl
trouver comment éliminer le marqueur linguistique dans le MLR traduit.

# General principles

## Optional heuristics

This tool aims to parse LOM records and create a MLR-compliant set of RDF triples. Some information needed by MLR cannot be found in a LOM record; this is especially true of VCard information. In this case, the tool uses some heuristics to deduce likely values for the MLR records. The most unreliable heuristics can be individually disabled with command-line options. (See the help.)





TODO:
FOAF: Make sure non-work group! sigh.


## Naming entities

RDF resources can be named with URIs or blank nodes. Only URIs support global references, and for this reason we do not use blank nodes in the scope of MLR. Hovever, since we are converting from a LOM document, where some entities are nameless, it means we have to give new names to some entities. To guarantee uniqueness of those names, one simple way is to use UUIDs. There are [many variants](http://tools.ietf.org/html/rfc4122#section-4.1.1) of UUIDs, only two of which will concern us:

UUID-1
:    Time- and MAC-address based
UUID-5
:    Based on a name in a namespace (uses a SHA1 hash)

When creating a new document, and naming entities that do not have a "natural" URL or URI, it is safe to create a UUID-1, which will fix the identity of the entity; the risk of collision for UUID-1 is negligible, thanks in part to using the unique MAC address of the computer used to generate it. 

In the case of information obtained through conversion, there is an added wrinkle: It is not uncommon for the conversion process to be applied many times to different LOM records describing the same entities, or even the same LOM record more than once. Using UUID-1 in this case would yield a different UUID for the same entity each time. Those can be subsequently identified (using `owl:sameAs`), but it adds complexity to the procedure and should be avoided. Another option is to create, whenever possible, reproducible UUIDs: that is, UUIDs calculated from some properties of the entity that, singly or in combination, identify that entity uniquely. UUID-5 is appropriate for that purpose.


There is an option to mark UUID-1 URIs with an added triple that distinguishes them from UUID-5 URIs; this is a technical function that can guide heuristics that would want to detect and unify such entities when appropriate.

## MLR-2 vs MLR-3 elements

MLR-3 is an application profile, and elements defined here are optional refinements, that can be disabled with a specific switch.

# The conversion

## General ##

### Identifier

What should the RDF identifier (`rdf:about`) of the resource be? There are two aspects here: the RDF resource name, and the mlr2:DES1000 (or mlr3:DES0400) element, which are equivalent to `dc:identifier`. The latter is a literal, whereas the former needs to be a URI.

By design, the LOM 'general/identifier' may be either a global or local identifier. Global identifiers are identified with a known global value for the `identifier/catalog`: Often one of `URI`, `URL`, `ISSN`, `DOI`, `PURL`, `ISBN`, etc. Any of those global identifiers can be made into a URI if it is not one already. This URI can also be used as-is for the literal identifier. Any other catalog value is treated as a local identifier. In the latter case, we cannot use the `mlr3:DES0400` marker, which should refer to a global identifier, unlike `mlr2:DES1000`.





The `general/identifier` LOM tag is preferred as a RDF identification. It is also used for the mlr3:DES0400 element, the equivalent to `dc:identifier`.

Attention: litéral dans DC... en théorie mais souvent un URI en pratique.
Mettre comme litéral dans identifier.

TODO: Traiter l'absence d'identifiants.
Utiliser l'identifiant MLR2 si catalog contextuel vs catalog URI...
(Mettre une note pour les inférences?)
Annexe avec l'ontologie des sous-propriétés pour fins d'inférence.
Utiliser technical location comme seed plutôt que identifier?
S'il y en a plusieurs?



#### URI catalog

This is the simplest case: We can use it both as identity and identifier.

    :::xml
    <general>
        <identifier>
            <catalog>URI</catalog>
            <entry>http://www.example.com/resources/4561</entry>
        </identifier>
    </general>

Becomes

    :::N3
    <http://www.example.com/resources/4561> a mlr1:RC0002;
      mlr3:DES0400 "http://www.example.com/resources/4561" .


#### Other global catalogs

Some other global catalogs are converted to URIs as appropriate on a case-by-case basis, often as `urn:xxx` namespaces: this is true of ISBN, ISSN.
In particular, DOIs can be converted to URIs in three ways: by prefixing with `doi:`, `hdl:` or `http://dx.doi.org/`. Which to chose is a stylesheet parameter, but the `doi:` prefix is the default.

    :::xml
    <general>
        <identifier>
            <catalog>ISBN</catalog>
            <entry>0-201-61633-5</entry>
        </identifier>
    </general>

Becomes

    :::N3
    <urn:ISBN:0-201-61633-5> a mlr1:RC0002;
      mlr3:DES0400 "urn:ISBN:0-201-61633-5" .


#### Local catalog, with a location.

Local catalogs are highly problematic, as we have no guarantee that the catalog name is unique. If there is a `technical/location` in the LOM record, which is a URL and hence a global identifier, we use this for both the identity and the identifier. If there are many locations, we arbitrarily choose the first. This is also the strategy if there is no `general/identifier`.

    :::xml
    <general>
        <identifier>
            <catalog>MyDatabase</catalog>
            <entry>123123</entry>
        </identifier>
    </general>
    <technical>
        <location>http://example.com/resources/123123.html</location>
        <location>http://example.com/resources/123123.variant.html</location>
    </technical>

Becomes

    :::N3
    <http://example.com/resources/123123.html> a mlr1:RC0002;
      mlr3:DES0400 "http://example.com/resources/123123.html" .

But not:

    :::N3 forbidden
    <http://example.com/resources/123123.variant.html> a mlr1:RC0002;
      mlr3:DES0400 "http://example.com/resources/123123.variant.html" .

#### Local catalog, without a location.

If we have a local catalog and no location URL we can use as a global identifier, we use the following heuristics: 

1. Combine the catalog with the local identifier to obtain a local identifier. We use '|' as a separator, since it cannot be part of a URI, and this allows us to differentiate from URI identifiers. This can be used for the `mlr2:DES1000` value. (Recall we cannot use the `mlr3:DES0400` marker, which must refer to a global identifier.)
2. For the resource identity, which must be a URI, generate a UUID-5 from the combined identifier above. This requires a base UUID as a namespace: I suggest we use `UUID5(NAMESPACE_URL, 'http://standards.iso.org/iso-iec/19788/-1/ed-1/en/RC0002')`, which is `cd6fbe1e-df95-5959-8a71-1e8ca353a0f3`.

TODO: Should we include tool id and version in those UUIDs? That makes them change more, not less! So maybe a namespace UUID for the strategy?

In this example, we would use `UUID5(UUID5(NAMESPACE_URL, 'http://standards.iso.org/iso-iec/19788/-1/ed-1/en/RC0002'), 'MyDatabase|123123')` 

    :::xml
    <general>
        <identifier>
            <catalog>MyDatabase</catalog>
            <entry>123123</entry>
        </identifier>
    </general>

Becomes

    :::N3
    <urn:uuid:58f5ee92-9e16-52ef-b0b8-4cc20300c2dd> a mlr1:RC0002;
      mlr2:DES1000 "MyDatabase|123123" .


#### No catalog, no location.

In that case, we have nothing to identify the resource that could be used as a basis for a reproducible URL, and we need to use a UUID-1. 
Note: We could use other heuristics such as a concatenation of resource author emails, date, and resource title; but the risk of errors in this information is still significant. This is not a globally recognizable URI, so we use `mlr2:DES1000` instead of `mlr3:DES0100`.

    :::xml
    <general>
    </general>

Becomes

    :::N3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
      mlr2:DES1000 "urn:uuid:10000000-0000-0000-0000-000000000000" .

(Note that I use a UUID starting with the UUID type followed by many '0's to indicate an unknown UUID.)

### DublinCore elements

Many elements have a direct translation in DublinCore, and hence in MLR-2.

#### general/title

The title is translated directly as `mlr2:DES0100`. The language is carried in the literal as-is, but ISO-639-2 language tags are translated to their ISO-639-3 equivalents.

TODO: What if the language tag is not ISO-639? Should we use it at all? The RDF spec is vague on valid identifiers.


    :::xml
    <general>
        <title>
            <string language="fr-CA">Conditions favorables à l'intégration des TIC...</string>
        </title>
    </general>

Becomes

    :::N3
    [] mlr2:DES0100 "Conditions favorables à l'intégration des TIC..."@fra-CA .

#### general/language following ISO-639-3

Ideally, language should follow ISO-639-3. This can be detected by a regular expression, and we can then translate as `MLR-3:DES0500`. 

    :::xml
    <general>
        <language>fra-CA</language>
    </general>

Becomes

    :::N3
    [] mlr3:DES0500 "fra-CA" .

#### general/language following ISO-639-2

ISO-639-2 language tags can also be detected by a regular expression, and are then translated to their ISO-639-3 equivalents. Note that some letter triplets might not be valid ISO-639-3 (or -2), which would not be detected by a simple regular expression.

    :::xml
    <general>
        <language>fr-CA</language>
    </general>

Becomes

    :::N3
    [] mlr3:DES0500 "fra-CA" .


#### general/language

If the language description does not follow the pattern, we can use the MLR-2 version of that property.

    :::xml
    <general>
        <language>français</language>
    </general>

Becomes

    :::N3
    [] mlr2:DES1200 "français" .

But does not become

    :::N3 forbidden
    [] mlr3:DES0500 "français" .

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
    [] mlr3:DES0200 "L'enseignant identifie les contraintes..."@fra-CA ;
       mlr2:DES0400 "L'enseignant identifie les contraintes..."@fra-CA .

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

Besides those DC elements, each LOM lifecycle element can be expressed as a contribution in MLR5 terms. Note that there is some ambiguity in the document about the nature of pedagogical contributions. The definition of Contribution is given as:

> Set of resources that are instrumental in making up a learning resource.

This may suggest that the contribution consists of a further learning resource, either a component or an adjuntct of the main learning resource; but the Contribution does not have a link to another learning resource. Its only characteristics are the contribution date, and to a person in one of two roles: author or validator. For this reason, we interpret the Contribution in the same way as LOM lifecycle contributions.

Most [LOM v.10 lifeCycle roles](http://www.lom-fr.fr/vdex/lomfrv1-0/lom/vdex_lc_roles.xml) can be mapped to authors, except validators which are named as such in LOM. 

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
            mlr5:DES0800 "T020" ] .

##### Exceptions

The difficult cases are `publisher` and `unknown`, which are not translated as vocabulary entities, but as literals. Note that this is invalid MLR, as the literal MUST be taken from the vocabulary. We use an asterisk to denote the absence from the vocabulary.

Another approach would be to use a different RDF property (through a MLR extension or otherwise) to keep the more precise LOM information.

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
            mlr5:DES0800 "*unknown" ] .



### Person subtypes

Various contributors may be interpreted as entities of the Person type (`mlr1:RC0003`), or the subtypes Natural person (`mlr9:RC0001`) or Organisation (`mlr9:RC0002`).

TODO: The text would be clearer with two full examples.

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

If a natural person has an `ORG` in their vCard, or information of subtype work (whether `URL`, `ADR`, `EMAIL` or `TEL`), there must be an underlying organization. In the case of `ORG`, `URL` and `ADR` (presumed to be of subtype `POST`), it gives us further information to attach to the organization, and we then create a corresponding entity. (That entity's identifying URI is a separate issue.) `EMAIL` and `TEL` elements, on the other hand, are often individual, and are not assigned to the organizational entity. We did consider, and reject, a heuristic that would have assigend the email and telephone to the organization if the person had had both `WORK` and `HOME` emails.

This raises many issues. In some cases, the `URL` or postal `ADR` may refer to that person individual's office or home page rather than the organization's. It is however very difficult to detect this based on a single vCard, which is the scope of our study. In further study, more approaches may be considered:

1. Consider only the domain, either from the work email or the work URL. We could check whether they coincide, but it is not clear what to do otherwise. However, we run the risk of misrepresenting sites of individuals who have a business site with a common ISP.
2. If the email handle is found in the trailing element of the work URL, it could be considered safe for elimination. However, it is not a given that the resulting parent URL is indexable.
3. If we were looking across many vCards, and saw many work URLs with the same domain but different paths, we could consider the shortest common subpath to be the organizational URL, but this is subject to the same risks as above. More important, it makes the work URL non-deterministic, subject to what other vCards have been collected at that point.

Conversely, we could consider that if a work information (esp. phone or email) is shared between different natural persons, it can safely be considered to be corporate. However, this also depends on information collected across vCards, and possibly across LOM elements.

The current heuristic is far from satisfying, but may be the best we can do given the imprecision of available information. Let us not forget, moreover, that the `WORK` subtypes are often left blank, or worse, filled arbitrarily by mail agents' user interfaces, and not systematically corrected by users. 

Out of scope: We have not treated the case of a person with multiple organizations, using the (rare) vCard grouping mechanism.

So to review, here is the information that triggers an organization entity:

##### `ORG`

The `ORG` is carried over in the entity's data as `mlr9:DES1200`.

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
                               mlr9:DES1200 "GTN-Québec" ] ] ] .

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

Work URL also becomes the organization's identifying URL. This identifying URL is both the RDF subject and the `mlr9:0010` identifier. However, that URL is treated as a literal and not as a RDF resource.

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
        mlr9:DES0100 "http://www.gtn-quebec.org/".


### Identifying URLs

As with the resource itself, we have to propose an identity for persons and contributions. Contributions in the LOM standards are not much more than source and content, and there is not adequate information to identify them uniquely other than their content; so we rely on UUID1. 

As for Persons, natural or otherwise, there is a wealth of information in vCards that may uniquely identify them. We have developed heuristics to do so, detailed below. However, be aware that such heuristics, while reasonable, each represent a series of arbitrary choices. On the one hand, this does not matter much, as the identities defined in this fashion can be made to correspond later (using `owl:sameAs`); on the other hand, it would be preferrable if the practices described here were adopted as best practices, so that those UUIDs are made to coincide whenever possible. Otherwise, if we have divergent strategies for deterministic UUIDs, the problem of knowing what to match remains. For example, we could decide that, absent URL and Email, we will generate a UUID based on (e.g.) a person's home phone number or address as a strings in some appropriate namespace. If the strategy were common to all converters, collisions would happen to positive effect. A downside is that different vCards for the same person, with different subsets of identifying information, would again yield different identifiers, and the problem of finding correspondances between named (vs blank) entities reappears. As long as the strategies are shared, this problem is minimal, as we would know how to search for corresponding entities in that case; but until the algorithm for UUID generation is made part of the norm, such strategies may add to the problem instead of solving it.

We nonetheless propose applying a deterministic strategy to a combination of name and email, as the generated UUID is "natural" enough that we feel it should be easy to agree upon even without a common policy. We also propose using it for `ORG`, less natural, but where it has the most payoff.

Here is the rundown of the selected heuristics:

#### Natural persons

In the case of natural persons (and persons), we can use the following information. Some options are disabed by settings, as discussed above.

##### FOAF URL

Though it is not in much use, a strategy exists to identify FOAF URLs in a vCard, as noted in [this study](http://www.w3.org/2002/12/cal/vcard-notes.html). Question: Should we avoid FOAF work URLs?

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
        mlr9:DES0100 "http://maparent.ca/foaf.rdf" .

In preference to 

    :::N3 forbidden
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
        mlr9:DES0100 "http://maparent.ca/resume.fr.html".

In preference to 

    :::N3 forbidden
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
        mlr9:DES0100 "http://maparent.ca/" .


In preference to 

    :::N3 forbidden
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 <http://maparent.ca/resume.fr.html> ] .
    <http://maparent.ca/resume.fr.html> a mlr9:RC0001 .

##### A UUID calculated from non-work email and FN (`person_uuid_from_email_fn`, enabled)

If a non-work email is available, both the email and name are likely to identify a person. We can then create a UUID as follows:

1. Make the first non-work email into an `mailto:` URL (e.g.: `mailto:map@ntic.org`) (Use a preferred email if available.)
2. Create a UUID-5 based on this URL, in the URL namespace. (in our example, we obtain the UUID `75642fb6-e2d3-549b-9bf5-b62743af640d`.)
3. Create a UUID-5 based on the `FN`, using the step 2) UUID as a namespace. In our example, we obtain the UUID `2e53e0a5-38b8-56a2-8841-f9b47cd7f0b1`. Note that the FN is first encoded using UTF-8. (So is the URL, but the URL is rarely unicode.)

As for the identifier, we follow the LDIF practiced as described on [this page](http://www.w3.org/2002/12/cal/vcard-notes.html), using the email and `FN` in the following format: `cn=<FN>,mail=<email>`.

This heuristics is controlled by the `person_uuid_from_email_fn` flag.

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
            mlr5:DES1800 <urn:uuid:2e53e0a5-38b8-56a2-8841-f9b47cd7f0b1> ] .
    <urn:uuid:2e53e0a5-38b8-56a2-8841-f9b47cd7f0b1> a mlr9:RC0001 ;
        mlr9:DES0100 "cn=Marc-Antoine Parent,mail=map@ntic.org" .


##### A UUID calculated from non-work email and `N` (`person_uuid_from_email_fn`, enabled)

In the (pathological) absence of FN, we can recompose it from the `N`.
TODO: Explain name transition.

    :::xml
    <lifeCycle>
        <contribute>
            <role>
                <source>LOMv1.0</source>
                <value>author</value>
            </role>
            <entity>BEGIN:VCARD
    VERSION:3.0
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
            mlr5:DES1800 <urn:uuid:2e53e0a5-38b8-56a2-8841-f9b47cd7f0b1> ] .
    <urn:uuid:2e53e0a5-38b8-56a2-8841-f9b47cd7f0b1> a mlr9:RC0001 ;
        mlr9:DES0100 "cn=Marc-Antoine Parent,mail=map@ntic.org" .

##### The email itself as a URL (`person_url_from_email`, disabled)

Personal emails sometimes suffice to identify natural persons, but collisions do exist. Basically, given that `N` is always present, this option is never relevant.

##### A UUID calculated from FN (`person_uuid_from_fn`, disabled by default)

If there is no email, we could use the `FN` alone. For that, we first need an ad-hoc namespace. In that scheme:

1. we start with the UUID-5 for <http://gtn-quebec.org/ns/vcarduuid/>, which is `73785b33-6319-586e-be8e-fd7d25dcf593`
2. We combine it with the `FN` to obtain `6a1d6673-47dd-5071-9b24-f6c7688f0b64`. 

Note that the danger of `FN` collision is non-negligible, so this is disabled by default, and controlled by the xsl parameter `person_uuid_from_fn`.

However, we may still use the FN itself as an identifier in `mlr9:DES0100`.

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

Uses a UUID1, thus:

    :::N3
    <urn:uuid:10000000-0000-0000-0000-000000000001>  a mlr1:RC0002; 
        mlr5:DES1700 <urn:uuid:10000000-0000-0000-0000-000000000002> .
    <urn:uuid:10000000-0000-0000-0000-000000000002> a mlr5:RC0003;
        mlr5:DES1800 <urn:uuid:10000000-0000-0000-0000-000000000003> .
    <urn:uuid:10000000-0000-0000-0000-000000000003> a mlr9:RC0001 .

Note the absence of mlr9:DES0100 in that case, so we do not have:

    :::N3 forbidden
    <urn:uuid:10000000-0000-0000-0000-000000000003> mlr9:DES0100 "Marc-Antoine Parent" .

But if we set `person_uuid_from_fn`, we then have:

    :::N3 --person_uuid_from_fn
    <urn:uuid:10000000-0000-0000-0000-000000000001>  a mlr1:RC0002; 
        mlr5:DES1700 <urn:uuid:10000000-0000-0000-0000-000000000002> .
    <urn:uuid:10000000-0000-0000-0000-000000000002> a mlr5:RC0003;
        mlr5:DES1800 <urn:uuid:6a1d6673-47dd-5071-9b24-f6c7688f0b64> .
    <urn:uuid:6a1d6673-47dd-5071-9b24-f6c7688f0b64> a mlr9:RC0001 ;
        mlr9:DES0100 "Marc-Antoine Parent" .


##### A UUID calculated from N (`person_uuid_from_fn`, disabled)

The same algorithm applies to a pathological vcard without the `FN` element, which can be reconstructed from the `N`.

    :::xml
    <lifeCycle>
        <contribute>
            <role>
                <source>LOMv1.0</source>
                <value>author</value>
            </role>
            <entity>BEGIN:VCARD
    VERSION:3.0
    N:Parent;Marc-Antoine;;;
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Uses a UUID1, thus:

    :::N3
    <urn:uuid:10000000-0000-0000-0000-000000000001>  a mlr1:RC0002; 
        mlr5:DES1700 <urn:uuid:10000000-0000-0000-0000-000000000002> .
    <urn:uuid:10000000-0000-0000-0000-000000000002> a mlr5:RC0003;
        mlr5:DES1800 <urn:uuid:10000000-0000-0000-0000-000000000003> .
    <urn:uuid:10000000-0000-0000-0000-000000000003> a mlr9:RC0001 .

But if we set `person_uuid_from_fn`, we then have:

    :::N3 --person_uuid_from_fn
    <urn:uuid:10000000-0000-0000-0000-000000000001>  a mlr1:RC0002; 
        mlr5:DES1700 <urn:uuid:10000000-0000-0000-0000-000000000002> .
    <urn:uuid:10000000-0000-0000-0000-000000000002> a mlr5:RC0003;
        mlr5:DES1800 <urn:uuid:6a1d6673-47dd-5071-9b24-f6c7688f0b64> .
    <urn:uuid:6a1d6673-47dd-5071-9b24-f6c7688f0b64> a mlr9:RC0001 ;
        mlr9:DES0100 "Marc-Antoine Parent" .

##### A UUID-1

If we have no information that may uniquely identify a person, and choose not to rely on `FN` or `N`, the last-resort strategy is to use a UUID-1. This is not a proper identifier, however, and will be ommitted from mlr9:DES100.

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

Uses a UUID1, thus:

    :::N3
    <urn:uuid:10000000-0000-0000-0000-000000000001>  a mlr1:RC0002; 
        mlr5:DES1700 <urn:uuid:10000000-0000-0000-0000-000000000002> .
    <urn:uuid:10000000-0000-0000-0000-000000000002> a mlr5:RC0003;
        mlr5:DES1800 <urn:uuid:10000000-0000-0000-0000-000000000003> .
    <urn:uuid:10000000-0000-0000-0000-000000000003> a mlr9:RC0001 .

But not

    :::N3 forbidden
    <urn:uuid:10000000-0000-0000-0000-000000000003> mlr9:DES0100 "Marc-Antoine Parent" .


#### Organization vCard

An organization (outside of a personal vCard) uses the following identifiers:

##### FOAF URL

Just as persons, organizations can have a FOAF URL.

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
        mlr9:DES0100 "http://gtn-quebec.org/foaf.rdf" .

In preference to 

    :::N3 forbidden
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
        mlr9:DES0100 "http://gtn-quebec.org/contact" .

In preference to 

    :::N3 forbidden
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
        mlr9:DES0100 "http://gtn-quebec.org/contact" .

In preference to 

    :::N3 forbidden
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 <http://gtn-quebec.org/> ] .
    <http://gtn-quebec.org/> a mlr9:RC0002 .

##### A UUID calculated from an email and ORG (`org_uuid_from_email_org`, enabled)

As with persons, we do recommend using name and email as an organization identity key. However, it is possible that `ORG` and `FN` do not match; in that case, and if both are available, using `ORG` is preferable as it is more likely to match UUIDs generated with the same heuristics within person's vCards. (Note that an email marked as preferred has priority.) This particular heuristics is controlled by the `org_uuid_from_email_org` flag.

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

The URI will be `UUID5(UUID5(NAMESPACE_URL, 'mailto:info@gtn-quebec.org'), 'Groupe de travail québécois sur les normes et standards TI pour l’apprentissage, l’éducation et la formation')`. The `mlr9:DES0100` identifier will be calculated as it was for persons.

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 <urn:uuid:ebe75f2a-7562-544c-adf2-43a798987650> ] .
    <urn:uuid:ebe75f2a-7562-544c-adf2-43a798987650> a mlr9:RC0002;
        mlr9:DES0100 "cn=Groupe de travail québécois sur les normes et standards TI pour l’apprentissage, l’éducation et la formation,mail=info@gtn-quebec.org".

In preference to `UUID5(UUID5(NAMESPACE_URL, 'mailto:info@gtn-quebec.org'), 'GTN-Québec')`

    :::N3 forbidden
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 <urn:uuid:6b7dd3ef-8633-5111-a963-39c908231a7b> ] .
    <urn:uuid:6b7dd3ef-8633-5111-a963-39c908231a7b> a mlr9:RC0002;
        mlr9:DES0100 "cn=GTN-Québec,mail=info@gtn-quebec.org".


##### A UUID calculated from an email and FN (`org_uuid_from_email_fn`, enabled)

However, if `ORG` is not present, `FN` will be used in combination with the email. This particular heuristics is controlled by the `org_uuid_from_email_fn` flag.

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
            mlr5:DES1800 <urn:uuid:6b7dd3ef-8633-5111-a963-39c908231a7b> ] .
    <urn:uuid:6b7dd3ef-8633-5111-a963-39c908231a7b> a mlr9:RC0002;
        mlr9:DES0100 "cn=GTN-Québec,mail=info@gtn-quebec.org".

##### A URL from a work email alone (`org_url_from_email`, enabled)

Using an organization's email alone as identity is possible, and more appropriate than with in individual's card. An email marked as preferred still has priority. Note that in most cases, the previous algorithm will have been used unless `org_uuid_from_email_org` and `org_uuid_from_email_fn` were set to false.

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

    :::N3 --no-org_uuid_from_email_fn
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 <mailto:info@gtn-quebec.org> ] .
    <mailto:info@gtn-quebec.org> a mlr9:RC0002;
        mlr9:DES0100 "info@gtn-quebec.org".

##### A UUID based on the ORG and address (`org_uuid_from_org_address`, enabled)

It is not clear that the ORG (or an organization's FN) is distinctive enough to identify an organization. However, if the location information (country, region and city) are appended to the organization's name, the resulting localized organization name is likely to be uniquely distinctive, thanks to most country's laws about uniqueness of business names. (Note that the same reasoning does not apply to natural persons, who moreover are more mobile.) What we propose here is the following heuristics:

1. we start with the UUID-5 for <http://gtn-quebec.org/ns/vcarduuid/>, which is `73785b33-6319-586e-be8e-fd7d25dcf593`
2. We combine the `ORG` with the country, region and city of the first available address, separated by ';'. In this example, we would get `GTN-Québec;Canada;Québec;Québec`. This is also used as `mlr9:DES0100`
3. The resulting string is made into a UUID-5 in the namespace in 1: in this example, `f2fd5bf8-502e-5805-bb98-16ffd4929089`. 

Note that the telephone could also concievably give hints as to location, if users were consistent with country codes. This is unfortunately not reliable.


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
    ADR;TYPE=POST,WORK:;;455\, rue du Parvis;Québec;Québec;G1K 9H6;Canada
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 <urn:uuid:f2fd5bf8-502e-5805-bb98-16ffd4929089> ] .
    <urn:uuid:f2fd5bf8-502e-5805-bb98-16ffd4929089> a mlr9:RC0002;
        mlr9:DES0100 "GTN-Québec;Canada;Québec;Québec".

##### A UUID based on the FN and address  (`org_uuid_from_org_address`, enabled)

If there is no `ORG`, the `FN` can be used to the same effect as above.

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
            mlr5:DES1800 <urn:uuid:f2fd5bf8-502e-5805-bb98-16ffd4929089> ] .
    <urn:uuid:f2fd5bf8-502e-5805-bb98-16ffd4929089> a mlr9:RC0002;
        mlr9:DES0100 "GTN-Québec;Canada;Québec;Québec".



##### A UUID based on the ORG (`org_uuid_from_org_or_fn`, disabled)

As mentioned, it is debatable whether the `ORG` alone could be considered distinctive enough to be the basis of a UUID, absent other elements of identification; but duplicate organization names are not uncommon. For this reason, this heuristics is disabled by default. The heuristics is the same:

1. we start with the UUID-5 for <http://gtn-quebec.org/ns/vcarduuid/>, which is `73785b33-6319-586e-be8e-fd7d25dcf593`
2. The `ORG` is made into a UUID-5 in the namespace in 1: in this example, `88e3aa1b-9aec-51c4-86d2-58a8080832b9`.

<!-- -->

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
    TEL;TYPE=WORK:514 332-3000 #6024
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes, with `org_uuid_from_org_or_fn`,

    :::N3 --org_uuid_from_org_or_fn
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 <urn:uuid:88e3aa1b-9aec-51c4-86d2-58a8080832b9> ] .
    <urn:uuid:88e3aa1b-9aec-51c4-86d2-58a8080832b9> a mlr9:RC0002;
        mlr9:DES0100 "GTN-Québec".

##### A UUID based on the FN (`org_uuid_from_org_or_fn`, disabled)

What we said above about `ORG` also applies to `FN`.

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
    TEL;TYPE=WORK:514 332-3000 #6024
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes, with `org_uuid_from_org_or_fn`,

    :::N3 --org_uuid_from_org_or_fn
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 [ a mlr9:RC0002;
                mlr9:DES0100 "GTN-Québec" ] ] .

##### A UUID1

Barring adequate identifying elements, we rely on UUID-1, and do not use.

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
    TEL;TYPE=WORK:514 332-3000 #6024
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 <urn:uuid:10000000-0000-0000-0000-000000000001> ] .
    <urn:uuid:10000000-0000-0000-0000-000000000001> a mlr9:RC0002 .

Note the absence of `mlr9:DES0100`.

    :::N3 forbidden
    <urn:uuid:10000000-0000-0000-0000-000000000001> mlr9:DES0100 "GTN-Québec".


#### Organization within a person's vCard

If the natural person also has organization information, we can create a corresponding `mlr9:RC0002` alongside the `mlr9:RC0001`. The algorithm for the associated organization is the same as for a simple organization vCard, with a few exceptions as follows (besides the obvious, such as unavailability of the `FN`):

##### Work vs personal URL

1. Only `ADR`, `EMAIL`, `URL` and `TEL` elements marked explicitly with `TYPE=WORK` are considered when computing the organization's information. Others are considered personal.

<!-- -->

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
    URL;TYPE=WORK:http://gtn-quebec.org/
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Becomes

    :::N3
    []  a mlr1:RC0002;
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 <http://maparent.ca/> ] .
    <http://maparent.ca/> a mlr9:RC0001;
        mlr9:DES0100 "http://maparent.ca/" ;
        mlr9:DES1100 <http://gtn-quebec.org/> .
    <http://gtn-quebec.org/> a mlr9:RC0002;
        mlr9:DES0100 "http://gtn-quebec.org/" .


##### A UUID calculated from work email and ORG (`suborg_use_work_email`, disabled)

Work emails are not used as a basis for identity, because they are more likely to identify the person's individual email at work than a global organizational email.

If we override this setting, we can calculate a joint UUID just as we did for a person:

1. Make the email into an `mailto:` URL (e.g.: `mailto:map@ntic.org`)
2. Create a UUID-5 based on this URL, in the URL namespace. (in our example, we obtain the UUID `75642fb6-e2d3-549b-9bf5-b62743af640d`.)
3. Create a UUID-5 based on the `ORG`, using the step 2) UUID as a namespace. In our example, we obtain the UUID `e66c8b26-2564-53ee-b271-783ec932e4d5`. Note that the `ORG` is first encoded using UTF-8.

<!-- -->

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
                mlr9:DES0100 "http://maparent.ca/";
                mlr9:DES1100 <urn:uuid:10000000-0000-0000-0000-000000000001> ] ] .
    <urn:uuid:10000000-0000-0000-0000-000000000001> a mlr9:RC0002.

But if `suborg_use_work_email` is set to true:

    :::N3 --suborg_use_work_email
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 [a mlr9:RC0001 ;
                mlr9:DES0100 "http://maparent.ca/";
                mlr9:DES1100 <urn:uuid:e66c8b26-2564-53ee-b271-783ec932e4d5> ] ] .
    <urn:uuid:e66c8b26-2564-53ee-b271-783ec932e4d5> a mlr9:RC0002;
        mlr9:DES0100 "cn=GTN-Québec,mail=map@ntic.org" .

##### Multiple organizations

It is possible for a vCard to associate multiple organizations with a single person, using the vCard grouping mechanism.

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
    URL;TYPE=HOME:http://maparent.ca/
    gtn.URL;TYPE=WORK:http://www.gtn-quebec.org/
    gtn.ORG:GTN-Québec
    vte.URL;TYPE=WORK:http://vteducation.org/
    vte.ORG:Vitrine Technologie-Éducation
    END:VCARD
    </entity>
        </contribute>
    </lifeCycle>

Leading to

    :::N3 --suborg_use_work_email
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 <http://maparent.ca/> ] .
    <http://maparent.ca/> a mlr9:RC0001 ;
                mlr9:DES0100 "http://maparent.ca/" ;
                mlr9:DES1100 <http://www.gtn-quebec.org/> ,
                             <http://vteducation.org/> .
    <http://www.gtn-quebec.org/> a mlr9:RC0002;
        mlr9:DES0100 "http://www.gtn-quebec.org/";
        mlr9:DES1200 "GTN-Québec" .
    <http://vteducation.org/> a mlr9:RC0002;
        mlr9:DES0100 "http://vteducation.org/";
        mlr9:DES1200 "Vitrine Technologie-Éducation" .

### Generic persons

Generic persons have neither `N` nor `ORG`. We use a variant of the algorithm for persons above, since the `FN` is not expected to be an adequate identifier.

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

    :::N3 forbidden
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

    :::N3 forbidden
    []  a mlr1:RC0002; 
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES1800 [ a mlr9:RC0001 ;
                mlr9:DES1000 "1-514-555-9999" ] ].


### Address elements

A work `ADR` element in the vCard is expressed as a geographical location on the organization (`mlr9:RC0003`) through the location property (`mlr9:DES1300`). The `ADR` element is composed of the following components: box, extended, street, city, region, code, country. Those are recomposed using the following pattern:


TODO: Supprimer (et mettre ailleurs)

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

TODO: Pas dans le standard!


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

    :::N3 forbidden
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

    :::N3 forbidden
    []  a mlr1:RC0002;
        mlr5:DES1700 [ a mlr5:RC0003;
            mlr5:DES0700 "mi-XVIème siècle"@fra-CA ] .

## Metametadata

The LOM record is a metadata record, related to but distinct from the the MLR record obtained by converting it. We can use the LOM record's identity as a basis for the translated MLR record, but we must keep them distinct. The MLR record should also mention, besides the original LOM record's identity, the identity of the conversion software used.

### LOM identifier

The LOM identifier is derived from the `metaMetadata/identifier` in much the same way as the resource identifier; though technical URLs, which pertain to the resource, are obviously not taken into account.

#### URI catalog

This is the simplest case: We can use it both as identity and identifier. We use a literal.

    :::xml
    <metaMetadata>
        <identifier>
            <catalog>URI</catalog>
            <entry>http://www.example.com/lom/1234</entry>
        </identifier>
    </metaMetadata>

Becomes

    :::N3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
    mlr8:DES0300 [ a mlr8:RC0001;
        mlr8:DES1400 "http://www.example.com/lom/1234" ] .


#### Other global catalogs

Metadata records, being learning resources in their own right, also sometimes have global identifiers such as ISSN, ISBN, or DOI. Those are treated as for the resource identifier.

    :::xml
    <metaMetadata>
        <identifier>
            <catalog>ISBN</catalog>
            <entry>0-201-61633-5</entry>
        </identifier>
    </metaMetadata>

Becomes

    :::N3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
    mlr8:DES0300 [ a mlr8:RC0001;
        mlr8:DES1400 "urn:ISBN:0-201-61633-5" ] .


#### Local catalog

If we have a local catalog, we can, again, combine the catalog with the local identifier to obtain a local identifier. We use '|' as a separator, since it cannot be part of a URI, and this allows us to differentiate from URI identifiers. 

    :::xml
    <metaMetadata>
        <identifier>
            <catalog>MyDatabase</catalog>
            <entry>123123</entry>
        </identifier>
    </metaMetadata>

Becomes

    :::N3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
    mlr8:DES0300 [ a mlr8:RC0001;
        mlr8:DES1400 "MyDatabase|123123" ] .

#### External URL

TODO: It should be possible to provide the LOM record's URL as a parameter if there is no identifying information in the LOM record itself.

#### No identifier

Even if not identified, the LOM record exists. However, it is not necessary to give it an identity if it has none that can be determined.

    :::xml
    <metaMetadata>
    </metaMetadata>

Becomes

    :::N3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr8:RC0001 .

But not

    :::N3 forbidden
    <urn:uuid:10000000-0000-0000-0000-000000000000> mlr8:DES1400 "urn:uuid:10000000-0000-0000-0000-000000000000"  .

### Converter URL

The converter software has a URL that identifies it, and identifies the record as a converted record. It is also used to construct the MLR record's identity. This URL should include versioning information. Question: should we also integrate conversion settings information?

    :::xml
    <metaMetadata>
    </metaMetadata>

Becomes

    :::N3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr8:RC0001 ;
        mlr8:DES1600 <http://www.gtn-quebec/ns/lom2mlr/version/0.1>  .

### MLR Record identity

With this information in hand, we can often create a repeatable identity for the converted MLR Record.

The identity of the conversion software could also be integrated in the identity given to the converted MLR record.

#### Constructed LOM identity and converter URL 

If we have determined a LOM identity, we can create an identity for the MLR record by combining it with the converter URL, as follows: 

1. First, create a namespace UUID from the converter URL: `UUID5(NAMESPACE_URL, converter_URL)`, which in our case would be `CONVERTER_NAMESPACE_UUID=db3821e4-d6ed-5339-a1a1-1a760b0e1cc4`
2. Second, use this as a namespace for the LOM identity, taken as a string. `UUID5(CONVERTER_NAMESPACE_UUID, LOM_IDENTITY)`. (In our example, 1d9c8ec0-32e4-52be-bcba-ad32ba11a422)

This identity is also the MLR record identifier. This identity also allows to define the bidirectional relationship between the resource and its MLR record, defined in the `mlr8:DES0200-mlr8:DES0300` pair.

    :::xml
    <general>
        <identifier>
            <catalog>URI</catalog>
            <entry>http://www.example.com/entry/4321</entry>
        </identifier>
    </general>
    <metaMetadata>
        <identifier>
            <catalog>URI</catalog>
            <entry>http://www.example.com/lom/1234</entry>
        </identifier>
    </metaMetadata>

Becomes

    :::N3
    <http://www.example.com/entry/4321> a mlr1:RC0002;
        mlr8:DES0300 <urn:uuid:1d9c8ec0-32e4-52be-bcba-ad32ba11a422> .
    <urn:uuid:1d9c8ec0-32e4-52be-bcba-ad32ba11a422> a mlr8:RC0001;
        mlr8:DES0100 "urn:uuid:1d9c8ec0-32e4-52be-bcba-ad32ba11a422" ;
        mlr8:DES0200 <http://www.example.com/entry/4321> ;
        mlr8:DES1400 "http://www.example.com/lom/1234" .

#### Absence of LOM identity

In the absence of LOM identity, the simplest solution is to create a UUID-1.

    :::xml
    <metaMetadata>
    </metaMetadata>

Becomes

    :::N3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr8:DES0300 <urn:uuid:10000000-0000-0000-0000-000000000001> .
    <urn:uuid:10000000-0000-0000-0000-000000000001> a mlr8:RC0001;
        mlr8:DES0100 "urn:uuid:10000000-0000-0000-0000-000000000001" .


### Record as a graph

Some applications may choose to contain the results of metadata conversion in a subgraph, so as to apply different levels of trust to varying sources. In that case, the metadata record's ID can also be used as a graph ID. This is controlled by the `use_subgraph` parameter (which is on by default.)

However, there is no agreed-upon way to identify subgraphs in rdf:xml, which is used internally by the converter. We use the non-standard `cos:graph` attribute, proposed by [INRIA](http://www-sop.inria.fr/members/Fabien.Gandon/docs/NameThatGraph/), but most tools will not carry that information over in translation.

    :::xml
    <metaMetadata>
        <identifier>
            <catalog>URI</catalog>
            <entry>http://www.example.com/lom/1234</entry>
        </identifier>
    </metaMetadata>

Becomes

    :::rdf-xml
    <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" 
            xmlns:cos="http://www.inria.fr/acacia/corese#" 
            xmlns:mlr1="http://standards.iso.org/iso-iec/19788/-1/ed-1/en/"
            xmlns:mlr8="http://standards.iso.org/iso-iec/19788/-8/ed-1/en/">
        <mlr1:RC0002 rdf:about="urn:uuid:10000000-0000-0000-0000-000000000000"
                cos:graph="urn:uuid:1d9c8ec0-32e4-52be-bcba-ad32ba11a422">
            <mlr8:DES0300>
                <mlr8:RC0001 rdf:about="urn:uuid:1d9c8ec0-32e4-52be-bcba-ad32ba11a422">
                    <mlr8:DES0100>urn:uuid:1d9c8ec0-32e4-52be-bcba-ad32ba11a422</mlr8:DES0100>
                    <mlr8:DES0200 rdf:resource="urn:uuid:10000000-0000-0000-0000-000000000000"/>
                    <mlr8:DES1400>http://www.example.com/lom/1234</mlr8:DES1400>
                </mlr8:RC0001>
            </mlr8:DES0300>
        </mlr1:RC0002>
    </rdf:RDF>

### Contributions

Metametadata contributions are treated much as metadata contributions, above.

#### Roles

The roles defined for metametadata contributors in LOM 1.0 are `creator` and `validator`, which correspond to `T001` and `T002` respectively in the `ISO_IEC_19788-8:2012::VA.2.2` vocabulary. 

##### Creator

    :::xml
    <metaMetadata>
        <contribute>
            <role>
                <source>LOMv1.0</source>
                <value>creator</value>
            </role>
            <entity>BEGIN:VCARD
    VERSION:3.0
    FN:Marc-Antoine Parent
    N:Parent;Marc-Antoine;;;
    URL:http://maparent.ca/
    END:VCARD
    </entity>
            <date>
                <dateTime>1999-12-01</dateTime>
            </date>
        </contribute>
    </metaMetadata>

Becomes

    :::N3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr8:RC0001;
        mlr8:DES0700 <urn:uuid:10000000-0000-0000-0000-000000000001> .
    <urn:uuid:10000000-0000-0000-0000-000000000001> a mlr8:RC0002;
        mlr8:DES1200 "T001" ;
        mlr8:DES1000 <http://maparent.ca/> ;
        mlr8:DES1300 "1999-12-01"^^<http://www.w3.org/2001/XMLSchema#date> .

##### Validator

    :::xml
    <metaMetadata>
        <contribute>
            <role>
                <source>LOMv1.0</source>
                <value>validator</value>
            </role>
        </contribute>
    </metaMetadata>

Becomes

    :::N3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr8:RC0001;
        mlr8:DES0700 <urn:uuid:10000000-0000-0000-0000-000000000001> .
    <urn:uuid:10000000-0000-0000-0000-000000000001> a mlr8:RC0002;
        mlr8:DES1200 "T002" .

### Metadata Schema

The LOM `metadataSchema`, is simply carried over to `mlr8:DES0600`.
Note: It would be possible, and maybe desirable, to identify some common metadataschemas as resources, with an appropriate URL. This may be explored in the future.

    :::xml
    <metaMetadata>
        <metadataSchema>LOMv1.0</metadataSchema>
    </metaMetadata>

Becomes

    :::N3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr8:RC0001;
        mlr8:DES0600 "LOMv1.0" .

### Language

Language is treated as before, except that we do not have the distinction between valid and invalid language tags, and either will translated as `mlr8:DES0400`.

#### ISO-639-3

    :::xml
    <metaMetadata>
        <language>fra-CA</language>
    </metaMetadata>

Becomes

    :::N3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr8:RC0001;
        mlr8:DES0400 "fra-CA" .

#### ISO-639-2

ISO-639-2 language tags can also be detected by a regular expression, and are then translated to their ISO-639-3 equivalents.

    :::xml
    <metaMetadata>
        <language>fr-CA</language>
    </metaMetadata>

Becomes

    :::N3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr8:RC0001;
        mlr8:DES0400 "fra-CA" .


#### other language values

    :::xml
    <metaMetadata>
        <language>français</language>
    </metaMetadata>

Becomes

    :::N3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr8:RC0001;
        mlr8:DES0400 "français" .

## Technical

Most technical properties are translated in a straightforward way,  with the exception of requirements.

### Format

Format carries over to `mlr2:DES0900`. 

    :::xml
    <technical>
        <format>interactive</format>
    </technical>

Becomes
    
    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr2:DES0900 "interactive" .

#### Mime types

If the format is a MIME type (recognized by a regexp), it will also be identified as `mlr3:DES0300` (provided mlr3 tags are enabled.)

    :::xml
    <technical>
        <format>text/html</format>
    </technical>

Becomes
    
    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr2:DES0900 "text/html" ;
        mlr3:DES0300 "text/html".


#### non-digital

Similarly for format marked as "non-digital".

    :::xml
    <technical>
        <format>non-digital</format>
    </technical>

Becomes
    
    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr2:DES0900 "non-digital" ;
        mlr3:DES0300 "non-digital".


### Size

LOM size is given in bytes, and is an integer.

    :::xml
    <technical>
        <size>1024</size>
    </technical>

Becomes
    
    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr4:DES0200 "1024"^^<http://www.w3.org/2001/XMLSchema#int> .

### Location

Location URLs are translated as literals.

    :::xml
    <technical>
        <location>http://example.com/resource/1234.html</location>
        <location>http://example.com/resource/1234.pdf</location>
    </technical>

Becomes
    
    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr4:DES0100 "http://example.com/resource/1234.html" ,
             "http://example.com/resource/1234.pdf" .

### Requirement

LOM requirements are highly structured, and allow for disjunction (`orComposite`) of a set of conjoined terms. Each term may involve constraints of type and minimum or maximum version on the OS or browser. Unfortunately, MLR technical requirements are much less structured, and conversion involves translating those structured requirements into a natural language literal. There is a further downside to this: such translation must be language-dependent, whereas most of MLR strives to be language-independant. Downstream translation machinery cannot re-translate the resulting literal, at least in most cases.

We have introduced a `text_language` parameter, defaulting to `eng`, for this linguistic generation.

#### OS requirements
##### Defined OS

LOM defines the OS values `pc-dos`, `ms-windows`, `unix` and `macos`.

    :::xml
    <technical>
        <requirement>
            <orComposite>
                <type>
                    <source>LOMv1.0</source>
                    <value>operating system</value>
                </type>
                <name>
                    <source>LOMv1.0</source>
                    <value>pc-dos</value>
                </name>
            </orComposite>
        </requirement>
    </technical>

Becomes
    
    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr4:DES0400 "The operating system must be MS-DOS."@eng .

Without a known `text_language`, we attempt to give a neutral string.

    :::n3 --text_language xxx
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr4:DES0400 "operating system = pc-dos" .

##### Any OS

LOM also allows the os value to be `multi-os`.

    :::xml
    <technical>
        <requirement>
            <orComposite>
                <type>
                    <source>LOMv1.0</source>
                    <value>operating system</value>
                </type>
                <name>
                    <source>LOMv1.0</source>
                    <value>multi-os</value>
                </name>
            </orComposite>
        </requirement>
    </technical>

Becomes
    
    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr4:DES0400 "The operating system can be any operating system."@eng .

Without a known `text_language`, we attempt to give a neutral string.

    :::n3 --text_language xxx
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr4:DES0400 "operating system = ?" .

##### Any OS

LOM also allows the os value to be `none`.

    :::xml
    <technical>
        <requirement>
            <orComposite>
                <type>
                    <source>LOMv1.0</source>
                    <value>operating system</value>
                </type>
                <name>
                    <source>LOMv1.0</source>
                    <value>none</value>
                </name>
            </orComposite>
        </requirement>
    </technical>

Becomes
    
    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr4:DES0400 "The operating system is not needed."@eng .

Without a known `text_language`, we attempt to give a neutral string.

    :::n3 --text_language xxx
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr4:DES0400 "operating system = 0" .

#### Browser requirements

##### Defined Browser

LOM defines the browser values `netscape communicator`, `ms-internet explorer`, `opera`, `amaya`. 

    :::xml
    <technical>
        <requirement>
            <orComposite>
                <type>
                    <source>LOMv1.0</source>
                    <value>browser</value>
                </type>
                <name>
                    <source>LOMv1.0</source>
                    <value>ms-internet explorer</value>
                </name>
            </orComposite>
        </requirement>
    </technical>

Becomes
    
    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr4:DES0400 "The browser must be Microsoft Internet Explorer."@eng .

Without a known `text_language`, we attempt to give a neutral string.

    :::n3 --text_language xxx
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr4:DES0400 "browser = ms-internet explorer" .

##### Any browser

LOM also allows the browser to be `any`.

    :::xml
    <technical>
        <requirement>
            <orComposite>
                <type>
                    <source>LOMv1.0</source>
                    <value>browser</value>
                </type>
                <name>
                    <source>LOMv1.0</source>
                    <value>any</value>
                </name>
            </orComposite>
        </requirement>
    </technical>

Becomes
    
    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr4:DES0400 "The browser can be any browser."@eng .

Without a known `text_language`, we attempt to give a neutral string.

    :::n3 --text_language xxx
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr4:DES0400 "browser = ?" .

##### No browser

LOM also allows the browser value to be `none`.

    :::xml
    <technical>
        <requirement>
            <orComposite>
                <type>
                    <source>LOMv1.0</source>
                    <value>browser</value>
                </type>
                <name>
                    <source>LOMv1.0</source>
                    <value>none</value>
                </name>
            </orComposite>
        </requirement>
    </technical>

Becomes
    
    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr4:DES0400 "The browser is not needed."@eng .

Without a known `text_language`, we attempt to give a neutral string.

    :::n3 --text_language xxx
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr4:DES0400 "browser = 0" .

##### Unknown browser or operating system

If the browser or operating system is not a known value from the LOMv1.0 vocabulary, it is used as is, and the source is discarded.

    :::xml
    <technical>
        <requirement>
            <orComposite>
                <type>
                    <source>LOMv1.0</source>
                    <value>operating system</value>
                </type>
                <name>
                    <source>http://palm.com</source>
                    <value>PalmOS</value>
                </name>
            </orComposite>
        </requirement>
    </technical>

Becomes
    
    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr4:DES0400 "The operating system must be PalmOS."@eng .

Without a known `text_language`, we attempt to give a neutral string.

    :::n3 --text_language xxx
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr4:DES0400 "operating system = PalmOS" .

##### Unknown requirement type

If the requirement type is not a known value from the LOMv1.0 vocabulary, it is used as is, and the source is discarded.

    :::xml
    <technical>
        <requirement>
            <orComposite>
                <type>
                    <source>http://microsoft.com</source>
                    <value>graphic card</value>
                </type>
                <name>
                    <source>http://microsoft.com</source>
                    <value>DirectX</value>
                </name>
            </orComposite>
        </requirement>
    </technical>

Becomes
    
    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr4:DES0400 "'graphic card' must be DirectX."@eng .

Without a known `text_language`, we attempt to give a neutral string.

    :::n3 --text_language xxx
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr4:DES0400 "graphic card = DirectX" .


#### Minimum version

The minimum version is integrated in the text.

    :::xml
    <technical>
        <requirement>
            <orComposite>
                <type>
                    <source>LOMv1.0</source>
                    <value>operating system</value>
                </type>
                <name>
                    <source>LOMv1.0</source>
                    <value>macos</value>
                </name>
                <minimumVersion>10.6.1</minimumVersion>
            </orComposite>
        </requirement>
    </technical>

Becomes
    
    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr4:DES0400 "The operating system must be Mac OS, version at least 10.6.1."@eng .

Without a known `text_language`, we attempt to give a neutral string.

    :::n3 --text_language xxx
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr4:DES0400 "operating system = macos >= 10.6.1" .


#### Maximum version

So is the maximum version.

    :::xml
    <technical>
        <requirement>
            <orComposite>
                <type>
                    <source>LOMv1.0</source>
                    <value>operating system</value>
                </type>
                <name>
                    <source>LOMv1.0</source>
                    <value>macos</value>
                </name>
                <maximumVersion>10.6</maximumVersion>
            </orComposite>
        </requirement>
    </technical>

Becomes
    
    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr4:DES0400 "The operating system must be Mac OS, version at most 10.6."@eng .

Without a known `text_language`, we attempt to give a neutral string.

    :::n3 --text_language xxx
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr4:DES0400 "operating system = macos <= 10.6" .

#### Both minimum and maximum version

The text is adjusted accordingly when both values are given.

    :::xml
    <technical>
        <requirement>
            <orComposite>
                <type>
                    <source>LOMv1.0</source>
                    <value>operating system</value>
                </type>
                <name>
                    <source>LOMv1.0</source>
                    <value>macos</value>
                </name>
                <minimumVersion>10.4</minimumVersion>
                <maximumVersion>10.7</maximumVersion>
            </orComposite>
        </requirement>
    </technical>

Becomes
    
    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr4:DES0400 "The operating system must be Mac OS, version at least 10.4 and at most 10.7."@eng .

Without a known `text_language`, we attempt to give a neutral string.

    :::n3 --text_language xxx
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr4:DES0400 "operating system = macos >= 10.4 & <= 10.7" .

#### Disjunction

When many `orComposite` elements are given in a technical `requirement`, they represent a logical disjunction.

    :::xml
    <technical>
        <requirement>
            <orComposite>
                <type>
                    <source>LOMv1.0</source>
                    <value>operating system</value>
                </type>
                <name>
                    <source>LOMv1.0</source>
                    <value>macos</value>
                </name>
            </orComposite>
            <orComposite>
                <type>
                    <source>LOMv1.0</source>
                    <value>operating system</value>
                </type>
                <name>
                    <source>LOMv1.0</source>
                    <value>unix</value>
                </name>
            </orComposite>
        </requirement>
    </technical>

Becomes
    
    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr4:DES0400 "One of the following options: the operating system must be Mac OS; or the operating system must be unix."@eng .

Without a known `text_language`, we attempt to give a neutral string.

    :::n3 --text_language xxx
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr4:DES0400 "operating system = macos ⋁ operating system = unix" .


#### Conjunction

Logical conjunction is represented by multiple requirement elements, which are simply translated in so many constraint elements.

    :::xml
    <technical>
        <requirement>
            <orComposite>
                <type>
                    <source>LOMv1.0</source>
                    <value>operating system</value>
                </type>
                <name>
                    <source>LOMv1.0</source>
                    <value>macos</value>
                </name>
            </orComposite>
        </requirement>
        <requirement>
            <orComposite>
                <type>
                    <source>LOMv1.0</source>
                    <value>browser</value>
                </type>
                <name>
                    <source>LOMv1.0</source>
                    <value>amaya</value>
                </name>
            </orComposite>
        </requirement>
    </technical>

Becomes
    
    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr4:DES0400 "The operating system must be Mac OS."@eng,
                     "The browser must be amaya."@eng.

### Installation remarks and other platform requirements

Installation remarks and other platform requirements are also transferred as-is in the technical requirements.


    :::xml
    <technical>
        <installationRemarks>
            <string language="eng">This software requires administrator permissions to install.</string>
        </installationRemarks>
        <otherPlatformRequirements>
            <string language="eng">This software needs internet connectivity.</string>
        </otherPlatformRequirements>
    </technical>

Becomes
    
    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr4:DES0400 
            "This software requires administrator permissions to install."@eng,
            "This software needs internet connectivity."@eng.

### Duration

The LOM duration may be defined using the ISO-8601 duration format, which may be detected by a regexp. In that case, it would be reformatted in the 'hh:mm:ss' format and transferred into the `mlr4:DES0300` field.

    :::xml
    <technical>
        <duration>PT1H12M30S</duration>
    </technical>

Becomes
    
    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr4:DES0300 "01:12:30"^^<http://www.w3.org/2001/XMLSchema#duration>.

#### Unparsable duration

Unparsable duration is ignored:

    :::xml
    <technical>
        <duration>one fortnight</duration>
    </technical>

Becomes
    
    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002.

Without 

    :::n3 forbidden
    <urn:uuid:10000000-0000-0000-0000-000000000000> mlr4:DES0300 "one fortnight".

## Educational

### Learning resource type

The learning resource type is integrated as-is in `mlr2:DES0800`. Moreover, if MLR3 is enabled an the learning resource type is known, and corresponds to a MLR resource type from vocabulary `ISO_IEC_19788-3:2011::VA.2 `, it will be translated in `mlr3:DES0700`.

However, there is extremely limited overlap between known LOM resource types and MLR resource types. We have identified the following:

| LOMv1.0        | ISO_IEC_19788-3:2011::VA.2 |
|:---------------|:------------|
| diagram        |        T011 |
| figure         |        T011 |
| graph          |        T011 |
| slide          |        T011 |
| table          |        T002 |
| narrative text |        T012 |

Leaving out `exercise`, `simulation`, `questionnaire`, `index`, `exam`, `experiment`, `problem statement`, `self assessment`, and `lecture`.

Still, given 

    :::xml
    <educational>
        <learningResourceType>
            <source>LOMv1.0</source>
            <value>table</value>
        </learningResourceType>
    </educational>

We obtain

    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr2:DES0800 "table";
        mlr3:DES0700 "T002".

### Difficulty, semantic density, interactivity level.

Those LOM concepts have no clear MLR equivalent.

### Learning_activity

If learning activity information is found, a new learning activity object with a UUID-1 is created. It is unfortunately impossible to identify learning activities in LOM records.

#### Inferring activity from learning resource types

Some learning resource types allow us to infer learning activity. We have identified the following:

| LOMv1.0        | ISO_IEC_19788-5:2012::VA.3 |
|:---------------|:------------|
|exercise          |T140|
|simulation        |T160|
|questionnaire     |T130|
|exam              |T130|
|experiment        |T150|
|problem statement |T150|
|self assessment   |T130|

Leaving out `diagram`, `figure`, `graph`, `index`, `slide`, `table`, `narrative text` and `lecture`.

Still, given 

    :::xml
    <educational>
        <learningResourceType>
            <source>LOMv1.0</source>
            <value>self assessment</value>
        </learningResourceType>
    </educational>

We obtain

    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr5:DES2000 <urn:uuid:10000000-0000-0000-0000-000000000001>.
    <urn:uuid:10000000-0000-0000-0000-000000000001> a mlr5:RC0005;
        mlr5:DES2100 "T130".

#### Typical learning time

The typical learning time, carries durations over directly to `mlr5:DES3000`. So from

    :::xml
    <educational>
        <typicalLearningTime>
            <duration>P2T</duration>
        </typicalLearningTime>
    </educational>

We obtain

    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr5:DES2000 <urn:uuid:10000000-0000-0000-0000-000000000001>.
    <urn:uuid:10000000-0000-0000-0000-000000000001> a mlr5:RC0005;
        mlr5:DES3000 "P2T"^^<http://www.w3.org/2001/XMLSchema#duration>.

### Audience

As with learning activity, if information relevant to the audience is found, a audience object with a UUID-1 is created.

#### Intended end user role

LOMv1.0 Intended user roles translates to the MLR5 `ISO_IEC_19788-5:2012::VA.2` audience role vocabulary as follows:

| LOMv1.0        | ISO_IEC_19788-5:2012::VA.2 |
|:---------------|:------------|
|teacher|T040|
|author|?|
|learner|T010|
|manager|T020|

So 

    :::xml
    <educational>
        <intendedEndUserRole>
            <source>LOMv1.0</source>
            <value>teacher</value>
        </intendedEndUserRole>
    </educational>

Becomes

    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr5:DES1500 <urn:uuid:10000000-0000-0000-0000-000000000001>.
    <urn:uuid:10000000-0000-0000-0000-000000000001> a mlr5:RC0002;
        mlr5:DES0600 "T040".

#### Typical age range

The LOM typical age range is usually given in one of the following formats. Any other format is ignored.

##### Closed range

    :::xml
    <educational>
        <typicalAgeRange>
            <string>10-13</string>
        </typicalAgeRange>
    </educational>

Becomes

    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr5:DES1500 <urn:uuid:10000000-0000-0000-0000-000000000001>.
    <urn:uuid:10000000-0000-0000-0000-000000000001> a mlr5:RC0002;
        mlr5:DES2600 "10"^^<http://www.w3.org/2001/XMLSchema#int>;
        mlr5:DES2500 "13"^^<http://www.w3.org/2001/XMLSchema#int>.

##### Open range

    :::xml
    <educational>
        <typicalAgeRange>
            <string>10-</string>
        </typicalAgeRange>
    </educational>

Becomes

    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr5:DES1500 <urn:uuid:10000000-0000-0000-0000-000000000001>.
    <urn:uuid:10000000-0000-0000-0000-000000000001> a mlr5:RC0002;
        mlr5:DES2600 "10"^^<http://www.w3.org/2001/XMLSchema#int>.

##### Single year

    :::xml
    <educational>
        <typicalAgeRange>
            <string>10</string>
        </typicalAgeRange>
    </educational>

Becomes

    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr5:DES1500 <urn:uuid:10000000-0000-0000-0000-000000000001>.
    <urn:uuid:10000000-0000-0000-0000-000000000001> a mlr5:RC0002;
        mlr5:DES2600 "10"^^<http://www.w3.org/2001/XMLSchema#int>;
        mlr5:DES2500 "10"^^<http://www.w3.org/2001/XMLSchema#int>.

#### Context

Educational context text is used as-is in `mlr5:DES0500`. (To be improved.)

    :::xml
    <educational>
        <context>
          <source>LOMv1.0</source>
          <value>School</value>
        </context>
    </educational>

Becomes

    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr5:DES1500 <urn:uuid:10000000-0000-0000-0000-000000000001>.
    <urn:uuid:10000000-0000-0000-0000-000000000001> a mlr5:RC0002;
        mlr5:DES0500 "School".

#### Language

The resource educational language is assigned to the audience. It is treated as usual, with ISO-636-2 being converted to ISO-636-3, and other values being used as-is.

    :::xml
    <educational>
        <language>fr</language>
    </educational>

Becomes

    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr5:DES1500 <urn:uuid:10000000-0000-0000-0000-000000000001>.
    <urn:uuid:10000000-0000-0000-0000-000000000001> a mlr5:RC0002;
        mlr5:DES0400 "fra".

### Description

Descriptions are treated as a form of annotation.

    :::xml
    <educational>
        <description>
            <string language="eng">Use this resource for group activities.</string>
        </description>
    </educational>

Becomes

    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr5:DES1300 <urn:uuid:10000000-0000-0000-0000-000000000001>.
    <urn:uuid:10000000-0000-0000-0000-000000000001> a mlr5:RC0001;
        mlr5:DES0200 "Use this resource for group activities."@eng.


## Rights

The MLR rights document is still under discussion, but some aspects of LOM rights can be introduced as `mlr2:DES1500`. Unfortunately, those aspects have to be translated into a linguistic string, so we are again resorting to `text_language` for conversion.

### Copyright description

The description can be transferred as is.

    :::xml
    <rights>
        <description>
            <string language="fra">Domaine public.</string>
        </description>
    </rights>

Becomes

    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr2:DES1500 "Domaine public."@fra .

### Costs

When there is no description, but costs exist, they can be mentioned as such. (Copyright is then assumed to apply.)

    :::xml
    <rights>
        <cost>
            <source>LOMv1.0</source>
            <value>yes</value>
        </cost>
    </rights>

Becomes

    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr2:DES1500 "There are costs."@eng .

### Copyright and other restrictions

When there is no cost, but copyright is mentioned, we can mention that as well.

    :::xml
    <rights>
        <copyrightAndOtherRestrictions>
            <source>LOMv1.0</source>
            <value>yes</value>
        </copyrightAndOtherRestrictions>
    </rights>

Becomes

    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr2:DES1500 "Copyright or other restrictions apply."@eng .

### No cost or copyright

If cost and copyright are both explicitly absent, we can mention that. Other possibilities are not analyzed.


    :::xml
    <rights>
        <cost>
            <source>LOMv1.0</source>
            <value>no</value>
        </cost>
        <copyrightAndOtherRestrictions>
            <source>LOMv1.0</source>
            <value>no</value>
        </copyrightAndOtherRestrictions>
    </rights>

Becomes

    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr2:DES1500 "Free, no copyright."@eng .

## Relations

### Source

The LOMv1.0 relationship `isbasedon` translates to source, that is `mlr2:DES1100` and optionally `mlr3:DES0600`. Identifiers are treated as usual (with a uuid-string for local catalogs, etc.)

    :::xml
    <relation>
        <kind>
            <source>LOMv1.0</source>
            <value>isbasedon</value>
        </kind>
        <resource>
            <identifier>
                <catalog>URI</catalog>
                <entry>http://www.example.com/resources/1234</entry>
            </identifier>
        </resource>
    </relation>

Becomes

    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr2:DES1100 "http://www.example.com/resources/1234" ;
        mlr3:DES0600 "http://www.example.com/resources/1234".

### Other relations

Any other relation are expressed with the `mlr2:DES1300` tag. The nature of the relation is lost.

    :::xml
    <relation>
        <kind>
            <source>LOMv1.0</source>
            <value>requires</value>
        </kind>
        <resource>
            <identifier>
                <catalog>URI</catalog>
                <entry>http://www.example.com/resources/1234</entry>
            </identifier>
        </resource>
    </relation>

Becomes

    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr2:DES1300 "http://www.example.com/resources/1234" .

## Annotation

LOM annotations are treated as educational annotations of an unknown type. Treatment of dates and vcards is as usual.


    :::xml
    <annotation>
        <entity>
            <vcard>BEGIN:VCARD
    VERSION:3.0
    N:Parent;Marc-Antoine.
    FN:Marc-Antoine Parent
    URL:http://maparent.ca/
    END:VCARD
    </vcard>
        </entity>
        <date>
            <dateTime>2004-04-01</dateTime>
        </date>
        <description>
            <string language="fra">Cette ressource exige beaucoup d'aide de l'enseignant.</string>
        </description>
    </annotation>

Becomes

    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr5:DES1300 <urn:uuid:10000000-0000-0000-0000-000000000001>.
    <urn:uuid:10000000-0000-0000-0000-000000000001> a mlr5:RC0001;
        mlr5:DES1400 <http://maparent.ca/> ;
        mlr5:DES0200 "Cette ressource exige beaucoup d'aide de l'enseignant."@fra ;
        mlr5:DES0100 "2004-04-01"^^<http://www.w3.org/2001/XMLSchema#date> .

## Classification

LOMv1.0 distinguishes many purposes of resource classification. 

* discipline
* idea
* prerequisite
* educational objective
* accessibility restrictions
* educational level
* skill level
* security level
* competency

Of those, we translate only discipline and educational level into `mlr2:DES0200` and `mlr5:DES1000` respectively.

### Discipline

#### Description

The discipline description can be translated directly as `mlr2:DES0200`.

    :::xml
    <classification>
        <purpose>
            <source>LOMv1.0</source>
            <value>discipline</value>
        </purpose>
        <description>
            <string language="fra">Mathématiques</string>
        </description>
    </classification>

Becomes

    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr2:DES0300 "Mathématiques"@fra.

#### Keywords

In the absence of description, we can also use keywords as a basis for topic.

    :::xml
    <classification>
        <purpose>
            <source>LOMv1.0</source>
            <value>discipline</value>
        </purpose>
        <keyword>
            <string language="fra">Mathématiques</string>
            <string language="fra">Algèbre linéaire</string>
        </keyword>
    </classification>

Becomes

    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr2:DES0300 "Mathématiques"@fra ;
        mlr2:DES0300 "Algèbre linéaire"@fra .

#### Taxon path

If we have neither description nor keywords, we can use the last (most precise) item of a taxon path. Sometimes, it is necessary to give context rather than the most precise taxon, but that is unfortunately difficult to determine.

    :::xml
    <classification>
        <purpose>
            <source>LOMv1.0</source>
            <value>discipline</value>
        </purpose>
        <taxonPath>
            <source>
                <string language="eng">DDC 22nd ed.</string>
            </source>
            <taxon>
                <entry>
                    <id>500</id>
                    <string language="eng">Natural Sciences and Mathemetics</string>
                </entry>
            </taxon>
            <taxon>
                <entry>
                    <id>510</id>
                    <string language="eng">Mathematics</string>
                </entry>
            </taxon>
            <taxon>
                <entry>
                    <id>512</id>
                    <string language="eng">Algebra</string>
                </entry>
            </taxon>
        </taxonPath>
    </classification>


Becomes

    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr2:DES0300 "Algebra"@eng .


### Educational level

Educational level classifications correspond to Curriculum level in mlr5. This requires creating a curriculum resource with an ad-hoc UUID-1 identity. Otherwise the logic is the same: Use description, keywords or the last element of the taxon path.

    :::xml
    <classification>
        <purpose>
            <source>LOMv1.0</source>
            <value>educational level</value>
        </purpose>
        <description>
            <string language="fra">CÉGEP</string>
        </description>
    </classification>

Becomes

    :::n3
    <urn:uuid:10000000-0000-0000-0000-000000000000> a mlr1:RC0002;
        mlr5:DES1900 <urn:uuid:10000000-0000-0000-0000-000000000001> .
    <urn:uuid:10000000-0000-0000-0000-000000000001> a mlr5:RC0004;
        mlr5:DES1000 "CÉGEP"@fra.
