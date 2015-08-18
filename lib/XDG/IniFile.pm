use v6;

=begin pod

=head1 NAME

XDG::IniFile - Base Class for DesktopEntry, IconTheme and IconData

=head1 SYNOPSIS

=head1 DESCRIPTION

=end pod


# import re, os, stat, codecs, sys
# from xdg.Exceptions import *
# import xdg.Locale
#

use XDG::X;

class XDG::IniFile {

    has Str $.default-group is rw;
    has Str $.file-extension is rw;
    has Str $.filename is rw;
    has Bool $.tainted = False;
    has Bool $.debug = False;

    has %.content;

    multi submethod BUILD(:$!filename, :$!file-extension, :$!default-group) {
        if $!filename.defined {
            self.parse($!filename);
        }
    }

#    def __cmp__(self, other):
#        return cmp(self.content, other.content)

    method parse( Str $filename, *@headers) {

        require Config::INI;

        if ! $filename.IO.f {
            XDG::X::ParsingError.new(message => "File not found", file => $filename).throw;
        }

        try {
            %!content = Config::INI::parsefile($filename);
            CATCH {
                when X::AdHoc {
                    XDG::X::ParsingError.new(message => $_.message, file => $filename).throw;
                }
                default {
                    $_.rethrow;
                }
            }
        }

        $!filename = $filename;
        $!tainted  = False;

        # check header
        if @headers.elems {
            for @headers -> $header {
                if %!content{$header}:exists {
                    $!default-group = $header;
                    last;
                }
            }
        }
    }

    # start stuff to access the keys
    method get(Str $key, Str $group = Str, Bool $locale = False, Str $type = "string", Bool $list = False) {
        # set default group
        $group //= $!default-group; 

        # return key (with locale)
        #

        my $value;

        if  %!content{$group}{$key}:exists {
            if $locale {
                $value = %!content{$group}{self!add-locale($key,$group)};
            }
            else {
                $value = %!content{$group}{$key};
            }
        }
        else {
            if $!debug {
                if %!content{$group}:exists {
                    XDG::X::NoKeyError.new(group => $key, key => $group, filename => $!filename).throw;
                }
                else {
                    XDG::X::NoGroupError.new(group => $group, filename => $!filename).throw;
                }
            }
            else {
                $value = "";
            }
        }

        my $result;
        my @values;
        if $list {
            @values = self.get-list($value);
            $result = [];
        }
        else {
            @values = ($value);
        }

        for @values -> $val {
            my $value;

            given $type {
                when 'string' {
                    $value = $val;
                }
                when 'boolean' {
                    $value = self!get-boolean($val);
                }
                when 'integer' {
                    try {
                        $value = $val.Int;

                        CATCH {
                            when X::Str::Numeric {
                                $value = 0;
                            }
                        }
                    }
                }
                when "numeric" {
                    try {
                        $value = $val.Num;

                        CATCH {
                            when X::Str::Numeric {
                                $value = 0.0;
                            }
                        }
                    }

                }
                when "regex" {
                    # Of course this may fail to compile
                    $value = rx/<$val>/;
                }
                when "point" {
                    $value = $val.split(/\,/);
                }
                default {
                    note "unrecognized value type $_";
                }
            }

            if $list {
                $result.push($value);
            }
            else {
                $result = $value;
            }
        }

        return $result;
    }

    # start subget
    method get-list($string) {
        my regex semicolon { <?!after \\>\; }
        my regex pipe { <?!after \\>\| }
        my regex comma { <?!after \\>\, }

        my @list;

        given $string {
            when /<semicolon>/ { 
                @list = .split(/<semicolon>/);
            }
            when /<pipe>/ {
                @list = .split(/<pipe>/);
            }
            when /<comma>/ {
                @list = .split(/<comma>/);
            }
            default {
                @list = $string;
            }
        }
        if @list[*-1] eq "" {
            @list.pop()
        }
        return @list;
    }

    method !get-boolean($boolean) returns Bool {
        my Bool $rc = False;
        given $boolean {
            when ("1"|"true"|"True") {
                $rc = True;
            }
            when ("0"|"false"|"False") {
                $rc = False;
            }
        }
        $rc;
    }
    # end subget

    # Need the locale stuff working for this
    # "add locale to key according the current lc_messages"
    method !add-locale(Str $key, Str $group?) {
        # set default group
        if !$group {
            $group = $!default-group;
        }

=begin comment

        for lang in xdg.Locale.langs:
            langkey = "%s[%s]" % (key, lang)
            if langkey in self.content[group]:
                return langkey

=end comment

        $key;
    }

    has @.warnings;
    has @.errors;

    # start validation stuff
    # "validate ... report = All / Warnings / Errors"
    method validate(Str $report = "All") {

        # get file extension
        $!file-extension = $*SPEC.extension($!filename);

        # overwrite this for own checkings
        self.check-extras();

        # check all keys
        for %!content.keys -> $group {
            self.check-group($group);
            for %!content{$group}.keys -> $key {
                my $value = %!content{$group}{$key};
                self.check-key($key, $value, $group);
                # check if value is empty
                if $value eq "" {
                    @!warnings.push(sprintf "Value of Key '%s' is empty" , $key);
                }
            }
        }

        # raise Warnings / Errors
        my Str $msg;

        given $report {
            when ("All"|"Warnings") {
                for @!warnings -> $line {
                    $msg ~= "\n- " ~ $line;
                }
            }
            when ("All"|"Errors") {
                for @!errors -> $line {
                    $msg ~= "\n- " ~ $line;
                }
            }
        }

        if $msg {
            XDG::X::ValidationError.new(message => $msg, filename => $!filename).throw();
        }
    }

    enum Validation<Ok Error Deprecated>;

    # check if group header is valid
    method check-group(Str $group) { * }

    # check if key is valid
    method check-key(Str $key, Str $value, Str $group) { * }

    # check random stuff
    method check-value(Str $key, Str $value, Str $type = "string", Bool $list = False) {

        my @values;

        if $list {
            @values = self.get-list($value);
        }
        else {
            @values = ($value);
        }

        for @values -> $value {

            my $code = do given $type {
                when "string" {
                    self.check-string($value);
                }
                when "boolean" {
                    self.check-boolean($value);
                }
                when "numeric" {
                    self.check-number($value);
                }
                when "integer" {
                    self.check-integer($value);
                }
                when "regex" {
                    self.check-regex($value);
                }
                when "point" {
                    self.check-point($value);
                }
                default {
                    Error;
                }
            }

            given $code {
                when Error {
                    @!errors.push(sprintf("'%s' is not a valid %s", $value, $type));
                }
                when Deprecated {
                    @!warnings.push(sprintf("Value of key '%s' is deprecated", $key));
                }
            }
        }
    }

    method check-extras() { * }

    method check-boolean(Str $value) returns Validation {
        my Validation $rc = do given $value {
            when ("1"|"2") {
                Deprecated;
            }
            when ("true"|"True"|"false"|"False") {
                Ok;
            }
            default {
                Error;
            }
        }
        return $rc;
    }

    method check-number(Str $value) returns Validation {
        my Validation $rc = Ok;
        try {
            $value.Num;
            CATCH {
                when X::Str::Numeric {
                    $rc = Error;
                }
            }
        }
        $rc;
    }

    method check-integer(Str $value) returns Validation {
        my Validation $rc = Ok;
        try {
            $value.Int;
            CATCH {
                when X::Str::Numeric {
                    $rc = Error;
                }
            }
        }
        $rc;
    }

    method check-point(Str $value) returns Validation {
        my $rc = Ok;

        if $value !~~ /^\d+\,\d+$/ {
            $rc = Error;
        }
        $rc;
    }

    # Not entirely sure we need to do anything
    method check-string(Str $value) {
        Ok;
    }

    method check-regex(Str $value) returns Validation {
        my Validation $rc = Ok;
        try {
                # It transpires that currently the only way
                # to check a regex that is interpolated like this
                # is to actually use it.
                my $r = /<$value>/;
                'xhsjsjs' ~~ $r;
                CATCH {
                    default {
                        $rc = Error;
                    }
                }
        }
        $rc;
    }

    # write support
    method write(Str $filename = Str, Bool $trusted = False) {

        my $fname = $filename // $!filename;

        if not $fname {
            XDG::X::ParsingError.new(message => "File not found", file => '');
        }

        $!filename = $fname;

        my IO::Path $file_io = $fname.IO;


        if not $file_io.parent.d {
            $file_io.parent.mkdir;
        }

        my IO::Handle $fp = $file_io.open(:w);

        # An executable bit signifies that the desktop file is
        # trusted, but then the file can be executed. Add hashbang to
        # make sure that the file is opened by something that
        # understands desktop files.
        if $trusted {
            $fp.print("#!/usr/bin/env xdg-open\n");
        }

        require Config::INI::Writer;

        my $out = Config::INI::Writer::dump(%!content);
        $fp.print($out);
        $fp.close;


        # Add executable bits to the file to show that it's trusted.
        # this waits until got modey thing
        if $trusted {
#            oldmode = os.stat(filename).st_mode
#            mode = oldmode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH
#            os.chmod(filename, mode)
        }

        $!tainted = False
    }

    method set(Str $key, Str $value, Str $group = Str, Bool $locale = False) {
        # set default group
        $group //= $!default-group;

        if not %!content{$group}:exists {
            XDG::X::NoGroupError.new( group => $group, filename => $!filename);
        }

        if $locale {
            $key = self!add-locale($key, $group);
        }

        %!content{$group}{$key} = $value;
            
        # not quite sure what this is about as it should always
        # be true but hey.
        $!tainted = ($value eq self.get($key, $group));
    }

    method add-group(Str $group) {
        if self.has-group($group) {
            XDG::X::DuplicateGroupError.new(group => $group, filename => $!filename);
        }
        else {
            %!content{$group} = ();
            $!tainted = True;
        }
    }

    method remove-group(Str $group) {
        my Bool $existed = self.has-group($group);
        if $existed {
            %!content{$group}:delete;
            $!tainted = True
        }
        else {
            if $!debug {
                XDG::X::NoGroupError.new(group => $group, filename => $!filename);
            }
        }
        $existed;
    }

    method remove-key(Str $key, Str $group = Str, Bool $locale = True) {
        $group //= $!default-group;

        my Str $value;

        if $locale {
            $key = self!add-locale($key, $group);
        }

        if not self.has-group($group) {
            if $!debug {
                XDG::X::NoGroup::Error.new(group => $group, filename => $!filename);
            }
        }
        elsif not self.has-key($key, $group) {
            if $!debug {
                XDG::X::NoKeyError.new(key => $key, group => $group, filename => $!filename);
            }
        }
        else {
            $value = %!content{$group}{$key}:delete;
        }

        $value;
    }

    # misc
    method groups() {
        %!content.keys;
    }

    method has-group(Str $group) {
        %!content{$group}:exists;
    }

    method has-key(Str $key, Str $group = Str ) {
        $group //= $!default-group;

        my $rc = False;

        if self.has-group($group) {
            $rc = %!content{$group}{$key}:exists;
        }

        $rc;
    }


    method get-filename() {
        $!filename;
    }
}

# vim: ft=perl6
