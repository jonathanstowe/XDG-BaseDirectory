#!perl6

use v6;
use lib 'lib';
use Test;

use XDG::X;

my $e;
# XDG::X::Error

ok($e = XDG::X::Error.new(message => "test message"), "XDG::X::Error.new");
isa-ok($e, Exception, "XDG::X::Error is an Exception");
is($e.message, "test message", "got good message");
throws-like { $e.throw }, XDG::X::Error, message => "test message";

# XDG::X::ValidationError
ok($e = XDG::X::ValidationError.new(message => "problem", file => "test_file"), "XDG::X::ValidationError.new");
isa-ok($e, Exception, "XDG::X::ValidationError is an Exception");
is($e.message, "ValidationError in file 'test_file': problem", "got good message");
throws-like { $e.throw }, XDG::X::ValidationError, message => "ValidationError in file 'test_file': problem";

# XDG::X::ParsingError
ok($e = XDG::X::ParsingError.new(message => "problem", file => "test_file"), "XDG::X::ParsingError.new");
isa-ok($e, Exception, "XDG::X::ParsingError is an Exception");
is($e.message, "ParsingError in file 'test_file': problem", "got good message");
throws-like { $e.throw }, XDG::X::ParsingError, message => "ParsingError in file 'test_file': problem";
# XDG::X::NoKeyError
ok($e = XDG::X::NoKeyError.new(message => "problem", file => "test_file", key => 'key', group => 'group'), "XDG::X::NoKeyError.new");
isa-ok($e, Exception, "XDG::X::NoKeyError is an Exception");
is($e.message, "No key 'key' in group group of file test_file", "got good message");
throws-like { $e.throw }, XDG::X::NoKeyError, message => "No key 'key' in group group of file test_file";
# XDG::X::DuplicateKeyError
ok($e = XDG::X::DuplicateKeyError.new(message => "problem", file => "test_file", key => 'key', group => 'group'), "XDG::X::DuplicateKeyError.new");
isa-ok($e, Exception, "XDG::X::DuplicateKeyError is an Exception");
is($e.message, "Duplicate key 'key' in group group of file test_file", "got good message");
throws-like { $e.throw }, XDG::X::DuplicateKeyError, message => "Duplicate key 'key' in group group of file test_file";
# XDG::X::NoGroupError
ok($e = XDG::X::NoGroupError.new(message => "problem", file => "test_file", group => 'group'), "XDG::X::NoGroupError.new");
isa-ok($e, Exception, "XDG::X::NoGroupError is an Exception");
is($e.message, "No group: group in file test_file", "got good message");
throws-like { $e.throw }, XDG::X::NoGroupError, message => "No group: group in file test_file";
# XDG::X::DuplicateGroupError
ok($e = XDG::X::DuplicateGroupError.new(message => "problem", file => "test_file", group => 'group'), "XDG::X::DuplicateGroupError.new");
isa-ok($e, Exception, "XDG::X::DuplicateGroupError is an Exception");
is($e.message, "Duplicate group: group in file test_file", "got good message");
throws-like { $e.throw }, XDG::X::DuplicateGroupError, message => "Duplicate group: group in file test_file";
# XDG::X::NoThemeError
ok($e = XDG::X::NoThemeError.new(message => "problem", theme => 'test_theme'), "XDG::X::NoThemeError.new");
isa-ok($e, Exception, "XDG::X::NoThemeError is an Exception");
is($e.message, "No such icon-theme: test_theme", "got good message");
throws-like { $e.throw }, XDG::X::NoThemeError, message => "No such icon-theme: test_theme";

done;

# vim: ft=6
