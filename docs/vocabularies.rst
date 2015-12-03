Build vocabularies
==================

Source format
-------------

Vocabularies sources are in **lom2mlr/vdex** folder following a specific
plain text format:

* The first line is the language present in the file.
* The second line is the full canonical IRI of the vocabulary
* Beginning on the third line there's the terms loop

  * The first line is the term's id - id Tnnn
  * After there is two lines by language present in the header with blank line
    on missing translation.

    * The first line is the term's title
    * The second line is the term's description

* No blank line at the bottom



Build scripts
-------------

The goal is to create xsl files for the translation and a SKOS file for the
triple store.

The first stage is to create vdex files for text. ``make_vdex.py`` take a filename
in argument and create one vdex file by language defined in the text file.

The second stage create a SKOS file from the vdex using ``xsltproc`` and the
``vdex2skos.xsl`` transformation.

The third stage create a XSL file by language then a MLR XSL transformation
grouping all language from the vdex file. It use ``xsltproc`` and the
``make_translation_tolang.xsl`` for the first sub-step and
``make_translation_fromlang.xsl`` for the second one.

The second and the third stages can be done in any order.
