use v6;

=begin pod

This module is based on a rox module (LGPL):

http://cvs.sourceforge.net/viewcvs.py/rox/ROX-Lib2/python/rox/basedir.py?rev=1.9&view=log

The freedesktop.org Base Directory specification provides a way for
applications to locate shared data and configuration:

    http://standards.freedesktop.org/basedir-spec/

(based on version 0.6)

This module can be used to load and save from and to these directories.

Typical usage:

    from rox import basedir
    
    for dir in basedir.load_config_paths('mydomain.org', 'MyProg', 'Options'):
        print "Load settings from", dir

    dir = basedir.save_config_path('mydomain.org', 'MyProg')
    print >>file(os.path.join(dir, 'Options'), 'w'), "foo=2"

Note: see the rox.Options module for a higher-level API for managing options.

=end pod

class XDG::BaseDirectory {

    has IO::Path $.xdg-data-home; 
    
    method xdg-data-home() returns IO::Path {
        $!xdg-data-home //= %*ENV<XDG_DATA_HOME>.defined ?? %*ENV<XDG_DATA_HOME>.IO !! $*HOME.child($*SPEC.catfile('.local', 'share'));

    }

    has IO::Path @.xdg-data-dirs;

    method xdg-data-dirs() {
        if ! @!xdg-data-dirs.elems {
            @!xdg-data-dirs = $.xdg-data-home, (%*ENV<XDG_DATA_DIRS> || '/usr/local/share:/usr/share').split(':').map({ $_.IO });
        }
        @!xdg-data-dirs;
    }

    has IO::Path $.xdg-config-home;

    method xdg-config-home() returns IO::Path {
        $!xdg-config-home //= %*ENV<XDG_CONFIG_HOME>.defined ?? %*ENV<XDG_CONFIG_HOME>.IO !! $*HOME.child('.config');
    }

    has IO::Path @.xdg-config-dirs;

    method xdg-config-dirs() {
        if ! @!xdg-config-dirs.elems {
            @!xdg-config-dirs = $.xdg-config-home, (%*ENV<XDG_CONFIG_DIRS> || '/etc/xdg' ).split(':').map({ $_.IO });
        }
        @!xdg-config-dirs;
    }

    has IO::Path $.xdg-cache-home;

    method xdg-cache-home() returns IO::Path {
        $!xdg-cache-home //= %*ENV<XDG_CACHE_HOME> || $*HOME.child('.cache');
    }

=begin pod

=head2 save-config-path(Str *@resource)

Ensure C<$XDG_CONFIG_HOME/<resource>/> exists, and return its path.
'resource' should normally be the name of your application. Use this
when SAVING configuration settings. Use the C<xdg-config-dirs> variable
for loading.

=end pod

    method save-config-path(*@resource where @resource.elems > 0 ) returns IO::Path {
        self!home-path($.xdg-config-home, @resource);
    }

=begin pod

=head3 save-data-path(Str *@resource)

Ensure C<$XDG_DATA_HOME/<resource>/> exists, and return its path.
'resource' is the name of some shared resource. Use this when updating
a shared (between programs) database. Use the C<xdg-data-dirs> variable
for loading.


=end pod

    method save-data-path(*@resource where @resource.elems > 0) {
        self!home-path($.xdg-data-home, @resource);
    }

    # given an IO::Path and a resource description, will return an IO::Path of the
    # appropriate sub-directory which will be created if necessary
    method !home-path(IO::Path $home-path, *@resource where @resource.elems > 0 ) {
        my Str $resource = self!resource-path(@resource);

        my IO::Path $path = $home-path.child($resource);

        if ! $path.d {
            $path.mkdir(mode => 0o700);
        }
        $path.cleanup;
    }

=begin pod

=head3 load-config-paths

Returns an iterator which gives each directory named 'resource' in the
configuration search path. Information provided by earlier directories should
take precedence over later ones (ie, the user's config dir comes first).

=end pod

    method load-config-paths(*@resource ) {
        self!load-resource-paths(@.xdg-config-dirs, @resource);
    }

=begin pod

=head3 load-first-config(Str *@resource) returns L<IO::Path>

Returns the first result from load-config-paths, or None if there is nothing to load.

=end pod

    method load-first-config(*@resource) {
        self.load-config-paths(@resource)[0];
    }

=begin pod

=head3 load-data-paths(Str *@resource) 

Returns an iterator which gives each directory named 'resource' in the
shared data search path. Information provided by earlier directories should
take precedence over later ones.


=end pod 

    method load-data-paths(*@resource where @resource.elems > 0 ) {
        self!load-resource-paths(@.xdg-data-dirs, @resource);
    }

    # given an array of IO::Path objects and a resource description
    # return those resulting resource paths that actually exist
    method !load-resource-paths(@dirs, *@resource where @resource.elems > 0 ) {
        my Str $resource = self!resource-path(@resource);
        gather {
            for @dirs -> $config-dir {
                my $path = $config-dir.child($resource);

                if $path.d {
                    take $path;
                }
            }
        }
    }

    # return a somewhat sanitized path part that can be appended to
    # some config path based on the supplied resource description parts
    method !resource-path(*@resource where @resource.elems > 0) {

        if @resource ~~ $*SPEC.updir {
            die "invalid resource description";
        }
        my Str $resource = $*SPEC.catfile(@resource);

        if $resource.IO.is-absolute {
            die "absolute path $resource is not allowed";
        }

        $resource;
    }
}

# vim: ft=perl6
