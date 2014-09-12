Usage
=====

lom2mlr
-------

The main entry point is the :program:`lom2mlr` executable, which is self-documenting with the ``--help`` flag.
It will convert a single LOM file into a RDF file following the MLR standard. Here are the main options controlling output:

``--format``
    output format. The 'rawxml' is given directly through the XSLT stylesheet; other formats transit through one of the :py:mod:`rdflib serializers <rdflib:rdflib.plugins.serializers.n3>`.
``--language``
    Express MLR elements using a given language (given by a ISO-639-3 code.)
``--output``
    Output file name. (STDIN if ommitted.)

Other flags reflect export options, and are documented in the :file:`rationale` document.

There is also a `web application
<http://www.gtn-quebec.org/lom2mlr/index.cgi>`_ version available. This web application is available as a web form, or as a RESTful service (at the same address). In that second case, the LOM data can be POSTED, and optional arguments can be passed as a query string.

lom2mlr_markdown
----------------

The :program:`lom2mlr_markdown` program (also self-documenting) will apply markdown transformation to a markdown document, using the Markdown_ library, generating a HTML file.

A few further transformations are applied to the document, through relevant extensions:

1. Code blocks marked as of type ``xml`` or ``N3`` are assumed to be LOM and MLR fragments, respectively.
2. MLR code blocks are translated to their linguistic expressions, according to languages available in the :file:`lom2mlr/translations/translation.xml` file. (depends on ``-l`` flag.)
3. If the ``-c`` flag is activated, the transformation acts as a doctest for the LOM and MLR blocks. Specifically:

Every time a MLR block follows a LOM block, the LOM block is transformed into a MLR graph, using flags specified in the MLR block if present. All MLR statements found in the document's block should be found in the graph obtained from LOM, or an error is signalled (and explained in the resulting HTML document.) Similarly, if a MLR block marked `forbidden` is found after a LOM block and a MLR block, any triple found in the "forbidden" graph and the LOM transformation graph, but not in the previous (permitted) MLR block will be signalled as an error.

Note: Some aspects of the transformation generate random UUID. For testing purposes, we use a system of wildcard UUIDs to match document test UUIDs to generated UUIDs. 

This script is mostly used to validate the :file:`rationale.md` document, which explains the design rationale of this tool.

.. _Markdown: http://packages.python.org/Markdown/
