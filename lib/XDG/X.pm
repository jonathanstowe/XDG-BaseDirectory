use v6;

=begin pod

Exception Classes for the xdg package

=end pod


module XDG::X {

    my Bool $debug = False;

    class Error is Exception {
        has $.message;

        method message {
            return $!message;
        }
    }

    role FileError is Error {
        has $.file;
        has $.message;
    }


    class ValidationError does FileError {
        method message {
            sprintf "ValidationError in file '%s': %s", $!file, $!message;
        }
    }

    class ParsingError does FileError {
        method message {
            sprintf "ParsingError in file '%s': %s", $!file, $!message;
        }
    }


    class NoKeyError does FileError {
        has $.key;
        has $.group;

        method message {
            sprintf "No key '%s' in group %s of file %s", $!key, $!group, $!file;
        }
    }

    class DuplicateKeyError does FileError {
        has $.key;
        has $.group;

        method message {
            sprintf "Duplicate key '%s' in group %s of file %s", $!key, $!group, $!file;
        }
    }


    class NoGroupError does FileError {
        has $.group;
        method message {
            sprintf "No group: %s in file %s", $!group, $!file;
        }
    }



    class DuplicateGroupError does FileError {
        has $.group;
        method message {
            sprintf "Duplicate group: %s in file %s", $!group, $!file;
        }
    }

    class NoThemeError is Error {
        has $.theme;
        method message {
            sprintf "No such icon-theme: %s", $!theme;
        }
    }
}

# vim: ft=perl6
