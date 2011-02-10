package CPAN::Changes;

use strict;
use warnings;

use CPAN::Changes::Release;
use Text::Wrap   ();
use Scalar::Util ();

our $VERSION = '0.04';

sub new {
    my $class = shift;
    return bless {
        preamble => '',
        releases => {},
        @_,
    }, $class;
}

sub load {
    my ( $class, $file ) = @_;

    open( my $fh, '<', $file ) or die $!;
    my $changes = $class->load_string(
        do { local $/; <$fh>; }
    );
    close( $fh );

    return $changes;
}

sub load_string {
    my ( $class, $string ) = @_;

    my $changes  = $class->new;
    my $preamble = '';
    my ( @releases, $ingroup, $indent );

    $string =~ s/(?:\015{1,2}\012|\015|\012)/\n/gs;
    my @lines = split( "\n", $string );

    $preamble .= shift @lines while @lines && $lines[ 0 ] !~ m{^[v0-9]};

    while ( @lines ) {
        my $l = shift @lines;

        # Version & Date
        if ( $l =~ m{^[v0-9]} ) {

            # currently ignores data after the date; could be useful later
            my ( $v, $d ) = split( m{ +}, $l );
            push @releases,
                CPAN::Changes::Release->new(
                version => $v,
                date    => $d,
                );
            $ingroup = undef;
            $indent  = undef;
            next;
        }

        # Grouping
        if ( $l =~ m{^\s+\[\s*(.+)\s*\]} ) {
            $ingroup = $1;
            $releases[ -1 ]->add_group( $1 );
            next;
        }

        $ingroup = '' if !defined $ingroup;

        next if $l =~ m{^\s*$};

        if ( !defined $indent ) {
            $indent
                = $l =~ m{^(\s+)}
                ? '\s' x length $1
                : '';
        }

        $l =~ s{^$indent}{};

        # Change line cont'd
        if ( $l =~ m{^\s} ) {
            $l =~ s{^\s+}{};
            my $changeset = $releases[ -1 ]->changes( $ingroup );
            $changeset->[ -1 ] .= " $l";
        }

        # Start of Change line
        else {
            $l =~ s{^[^[:alnum:]]+\s}{};    # remove leading marker
            $releases[ -1 ]->add_changes( { group => $ingroup }, $l );
        }

    }

    $changes->preamble( $preamble );
    $changes->releases( @releases );

    return $changes;
}

sub preamble {
    my $self = shift;

    if ( @_ ) {
        my $preamble = shift;
        $preamble =~ s{\s+$}{}s;
        $self->{ preamble } = $preamble;
    }

    return $self->{ preamble };
}

sub releases {
    my $self = shift;

    if ( @_ ) {
        $self->{ releases } = {};
        $self->add_release( @_ );
    }

    return sort { $a->date cmp $b->date } values %{ $self->{ releases } };
}

sub add_release {
    my $self = shift;

    for my $release ( @_ ) {
        $release = CPAN::Changes::Release->new( %$release )
            if !Scalar::Util::blessed $release;
        $self->{ releases }->{ $release->version } = $release;
    }
}

sub delete_release {
    my $self = shift;

    delete $self->{ releases }->{ $_ } for @_;
}

sub release {
    my ( $self, $version ) = @_;

    return unless exists $self->{ releases }->{ $version };
    return $self->{ releases }->{ $version };
}

sub serialize {
    my $self = shift;

    my $output;

    $output = $self->preamble . "\n\n" if $self->preamble;
    $output .= join( "\n", $_->serialize ) for reverse $self->releases;

    return $output;
}

1;

__END__

=head1 NAME

CPAN::Changes - Read and write Changes files

=head1 SYNOPSIS

    # Load from file
    my $changes = CPAN::Changes->load( 'Changes' );

    # Create a new Changes file
    $changes = CPAN::Changes->new(
        preamble => 'Revision history for perl module Foo::Bar'
    );
    
    $changes->add_release( {
        version => '0.01',
        date    => '2009-07-06',
    } );

    $changes->serialize;

=head1 DESCRIPTION

It is standard practice to include a Changes file in your distribution. The 
purpose the Changes file is to help a user figure out what has changed since 
the last release.

People have devised many ways to write the Changes file. A preliminary 
specification has been created (L<CPAN::Changes::Spec>) to encourage module
authors to write clear and concise Changes.

This module will help users programmatically read and write Changes files that 
conform to the specification.

=head1 METHODS

=head2 new( %args )

Creates a new object using C<%args> as the initial data.

=head2 load( $filename )

Parses C<$filename> as per L<CPAN::Changes::Spec>.

=head2 load_string( $string )

Parses C<$string> as per L<CPAN::Changes::Spec>.

=head2 preamble( [ $preamble ] )

Gets/sets the preamble section.

=head2 releases( [ @releases ] )

Without any arguments, a list of current release objects is returned sorted 
by ascending release date. When arguments are specified, all existing 
releases are removed and replaced with the supplied information. Each release 
may be either a regular hashref, or a L<CPAN::Changes::Release> object.

    # Hashref argument
    $changes->releases( { version => '0.01', date => '2009-07-06' } );
    
    # Release object argument
    my $rel = CPAN::Changes::Release->new(
        version => '0.01', date => '2009-07-06
    );
    $changes->releases( $rel );

=head2 add_release( @releases )

Adds the release to the changes file. If a release at the same version exists, 
it will be overwritten with the supplied data.

=head2 delete_release( @versions )

Deletes all of the releases specified by the versions supplied to the method.

=head2 release( $version )

Returns the release object for the specified version. Should there be no 
matching release object, undef is returned.

=head2 serialize( )

Returns all of the data as a string, suitable for saving as a Changes 
file.

=head1 SEE ALSO

=over 4

=item * L<CPAN::Changes::Spec>

=item * L<Test::CPAN::Changes>

=back

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
