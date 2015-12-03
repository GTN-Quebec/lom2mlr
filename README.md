# Project Lom2MLR #


This project aims to convert Learning Object Metadat, [IEEE 1484.12.1-2002](http://ltsc.ieee.org/wg12/files/LOM_1484_12_1_v1_Final_Draft.pdf)
into Metadata for Learning Resources, [ISO/IEC 19788-1:2011](http://www.iso.org/iso/iso_catalogue/catalogue_tc/catalogue_detail.htm?csnumber=50772).

This repository is a fork of [github's lom2mlr repository](https://github.com/GTN-Quebec/lom2mlr).

This this repository for more fondamental information.

## Usage

The documentation contains installation and usage instructions for the command-line tool.

The command-line tool requires many components, as detailed in the instructions, but packaged binary applications are available [for Windows](http://www.gtn-quebec.org/lom2mlr/lom2mlr.exe) and [for Mac OS X](http://www.gtn-quebec.org/lom2mlr/lom2mlr.gz). Put it in your executable PATH, and type `lom2mlr --help` for instructions.

This project contains 3 different tools. Thoses tools need to be used together to translate a lom file to a mlr file.

- Read vcard included in lom xml and translate it in xcard. Generating a new lom file with xcard instead of vcard

$ extendvcard -o elom lomfile.lom

- Transform to mlr

$ lom2mlr -o mlrfile.ttl -f 'turtle' lomfile.elom

- You may want to extract rdfvcard from the the elom file:

$ extractvcard -o vcardfile.ttl -f 'turtle' lomfile.elom



## TODO

Propose a hookable structure for developers:

- hook functions use the same signature

- hook function applied on only one document

- implement walkers to process collections

- lom2mlr script become an implementation example
