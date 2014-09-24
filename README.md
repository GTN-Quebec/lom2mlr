# Project Lom2MLR #

This project aims to convert Learning Object Metadata, [IEEE 1484.12.1-2002](http://ltsc.ieee.org/wg12/files/LOM_1484_12_1_v1_Final_Draft.pdf)
into Metadata for Learning Resources, [ISO/IEC 19788-1:2011](http://www.iso.org/iso/iso_catalogue/catalogue_tc/catalogue_detail.htm?csnumber=50772).
Note that part 1 of the standard is [publically available](http://standards.iso.org/ittf/PubliclyAvailableStandards/).
This tool is developed by 
[Groupe de travail québécois sur les normes et standards TI pour l’apprentissage, l’éducation et la formation](http://www.gtn-quebec.org/), and as such we want to cover LOM files that follow the [Normetic 1.2 profile](http://www.gtn-quebec.org/rea/wp-content/blogs.dir/6/files/2010/11/pdf_Profil_Normetic_1.2_officiel.pdf).

More documentation is available [here](http://lom2mlr.readthedocs.org/en/latest/).

## Usage

The documentation contains installation and usage instructions for the command-line tool. There is also a web application version available [here](http://www.gtn-quebec.org/lom2mlr/index.cgi). This web application is available as a web form, or as a RESTful service (at the same address). In that second case, the LOM data can be POSTED, and optional arguments can be passed as a query string.

The command-line tool requires many components, as detailed in the instructions, but packaged binary applications are available [for Windows](http://www.gtn-quebec.org/lom2mlr/lom2mlr.exe) and [for Mac OS X](http://www.gtn-quebec.org/lom2mlr/lom2mlr.gz). Put it in your executable, and type `lom2mlr --help` for instructions.

## Rationale

Conversion of LOM to MLR is not a linear process, and contains many heuristics. These heuristics are described in the [rationale](http://www.gtn-quebec.org/lom2mlr/rationale.html) document.  The `rationale.html` file is generated from the `rationale.md` markdown file, using the `lom2mlr_markdown` script included in this package.

Besides describing the heuristics, the `rationale.md` file contains testable fragments of LOM to MLR conversion. Use the `nosetest` command to execute those tests.
