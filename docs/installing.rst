
Installing
----------

This project is based on python (2.7 or 2.6) and python libraries, as specified in
:file:``requirements.txt``. On a posix platform with pip_,
it is possible to satisfy the prerequisites with
``pip install -r requirements.txt``. However, some requirements may be
demanding. On a linux platform, you might need to install development
tools and ``xmllib2-devel``, ``xmllint2-devel`` beforehand. On a MacOS
platform, you would need development tools, either through XCode_ or standalone. 
(Availale here_ for versions of OS X older than 10.8.)

Once the requirements are satisfied, including
scons_, you would first bootstrap the data files
with ``scons``, and then it is possible to do a normal
``python setup.py install``. This process will hopefully be streamlined
in the near future.

On Windows, it is also possible to create a package_ with py2exe_.

Installing this package installs two scripts: lom2mlr and
lom2mlr\_markdown. The latter is used to create the rationale.html file,
which explains design choices. The command to do so is
``lom2mlr_markdown -l -c rationale.md``.

Tests
-----

Use :program:`nosetests`.


.. _pip: http://www.pip-installer.org/en/latest/installing.html#using-the-installer
.. _XCode: http://developer.apple.com/technologies/tools/
.. _here: https://github.com/kennethreitz/osx-gcc-installer
.. _scons: http://scons.org
.. _package: http://www.gtn-quebec.org/lom2mlr/lom2mlr_win.zip
.. _py2exe: http://www.py2exe.org/