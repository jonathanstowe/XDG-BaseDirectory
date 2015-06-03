#!perl6

use v6;
use lib 'lib';

use Test;

use-ok('XDG::BaseDirectory', 'XDG::BaseDirectory can be loaded');
use-ok('XDG::X', 'XDG::X can be loaded');
use-ok('XDG::IniFile', 'XDG::IniFile can be loaded');

done();
