# XDG::BaseDirectory

Perl 6 access to path information provided by the xdg base directory
specfication http://www.freedesktop.org/wiki/Specifications/basedir-spec/.

## Description

This is loosely based on the interface of python module pyxdg. But due to the
differences between Python and Perl 6 it may do some things differently.

It provides a set of facilities for discovering the location configuration
and data of applications.

I split this out from the XDG module as it has more general usefulness and
no external dependencies.

## Installation

Assuming you have a working perl6 installation you should be able to
install this with *ufo* :

     ufo
     make test
     make install

*ufo* can be installed with *panda* for rakudo:

     panda install ufo


Alternatively you could install with *panda* from the checkout:

     panda install .

or remote:

     panda install XDG::BaseDirectory 

Other install mechanisms may be become available in the future.

## Support

This should be considered experimental software until such time that
Perl 6 reaches an official release.  However suggestions/patches are
welcomed via github at

   https://github.com/jonathanstowe/XDG-BaseDirectory

I'm not able to test on a wide variety of platforms so any help there
would be appreciated.

## Licence

Please see the LICENCE file in the distribution

(C) Jonathan Stowe 2015
