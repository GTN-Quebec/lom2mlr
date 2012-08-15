# Project Lom2MLR #

## Aim ##

This project aims to convert Learning Object Metadata, [IEEE 1484.12.1-2002](http://ltsc.ieee.org/wg12/files/LOM_1484_12_1_v1_Final_Draft.pdf) into Metadata for Learning Resources, [ISO/IEC 19788-1:2011](http://www.iso.org/iso/iso_catalogue/catalogue_tc/catalogue_detail.htm?csnumber=50772) Note that part 1 of the standard is [publically available](http://standards.iso.org/ittf/PubliclyAvailableStandards/). This tool is developed by [Groupe de travail québécois sur les normes et standards TI pour l’apprentissage, l’éducation et la formation](http://www.gtn-quebec.org/), and as such we want to cover LOM files that follow the [Normetic 1.2 profile](http://www.gtn-quebec.org/rea/wp-content/blogs.dir/6/files/2010/11/pdf_Profil_Normetic_1.2_officiel.pdf) 

## Status ##

This is work in progress. We have a proof of concept that we can extract the [MLR base profile](http://www.iso.org/iso/iso_catalogue/catalogue_tc/catalogue_detail.htm?csnumber=52774), which corresponds to [Dublin Core](http://dublincore.org/).  

## Installation ##

This project is based on python and python libraries, as specified in `requirements.txt`. On a posix platform with [pip](http://www.pip-installer.org/en/latest/installing.html#using-the-installer), it is possible to satisfy the prerequisites with `pip install -r requirements.txt`. However, some requirements may be demanding. On a linux platform, you might need to install development tools and `xmllib2-devel`, `xmllint2-devel` beforehand. On a MacOS platform, you would need `gcc` either through [XCode](http://developer.apple.com/technologies/tools/) or [standalone](https://github.com/kennethreitz/osx-gcc-installer).

Once the requirements are satisfied, including [scons](http://scons.org), you would first bootstrap the data files with `scons`, and then it is possible to do a normal `python setup.py install`. This process will hopefully be streamlined in the near future.

Installing this package installs two scripts: lom2mlr and lom2mlr_markdown. The latter is used to create the rationale.html file, which explains design choices. The command to do so is `lom2mlr_markdown -l -c rationale.md`.

## Tests ##

To be written.
