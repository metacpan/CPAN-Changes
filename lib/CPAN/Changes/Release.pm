package CPAN::Changes::Release;

use strict;
use warnings;

sub new {
    my $class = shift;
    return bless {
        changes => {},
        @_,
    }, $class;
}

sub version {
    my $self = shift;

    if ( @_ ) {
        $self->{ version } = shift;
    }

    return $self->{ version };
}

sub date {
    my $self = shift;

    if ( @_ ) {
        $self->{ date } = shift;
    }

    return $self->{ date };
}

sub note {
    my $self = shift;

    if ( @_ ) {
        $self->{ note } = shift;
    }

    return $self->{ note };
}

sub changes {
    my $self = shift;

    if ( @_ ) {
        my $group = shift;
        return unless exists $self->{ changes }->{ $group };
        return $self->{ changes }->{ $group };
    }

    return $self->{ changes };
}

sub add_changes {
    my $self  = shift;
    my $group = '';

    if ( ref $_[ 0 ] ) {
        $group = shift->{ group };
    }

    if ( !exists $self->{ changes }->{ $group } ) {
        $self->{ changes }->{ $group } = [];
    }

    push @{ $self->{ changes }->{ $group } }, @_;
}

sub set_changes {
    my $self  = shift;
    my $group = '';

    if ( ref $_[ 0 ] ) {
        $group = shift->{ group };
    }

    $self->{ changes }->{ $group } = \@_;
}

sub clear_changes {
    my $self = shift;
    $self->{ changes } = {};
}

sub groups {
    my $self = shift;
    my %args = @_;

    $args{ sort } ||= sub { sort @_ };

    return $args{ sort }->( keys %{ $self->{ changes } } );
}

sub add_group {
    my $self = shift;
    $self->{ changes }->{ $_ } = [] for @_;
}

sub delete_group {
    my $self   = shift;
    my @groups = @_;

    @groups = ( '' ) unless @groups;

    delete $self->{ changes }->{ $_ } for @groups;
}

sub delete_empty_groups {
    my $self = shift;

    $self->delete_group($_) 
        for grep { !@{ $self->changes( $_ ) } } $self->groups;
}

sub serialize {
    my $self = shift;
    my %args = @_;

    my $output = join( ' ', grep { defined } ( $self->version, $self->date, $self->note ) )
        . "\n";

    $output .= join "\n",
        map { $self->_serialize_group( $_ ) }
        $self->groups( sort => $args{ group_sort } );
    $output .= "\n";

    return $output;
}

sub _serialize_group {
    my ( $self, $group ) = @_;

    my $output = '';

    $output .= sprintf " [%s]\n", $group if length $group;
    $output .= Text::Wrap::wrap( ' - ', '   ', $_ ) . "\n"
        for @{ $self->changes( $group ) };

    return $output;
}

1;

__END__

=head1 NAME

CPAN::Changes::Release - Information about a particular release

=head1 SYNOPSIS

    my $rel = CPAN::Changes::Release->new(
        version => '0.01',
        date    => '2009-07-06',
    );
    
    $rel->add_changes(
        { group => 'THINGS THAT MAY BREAK YOUR CODE' },
        'Return a Foo object instead of a Bar object in foobar()'
    );

=head1 DESCRIPTION

A changelog is made up of one or more releases. This object provides access
to all of the key data that embodies a release including the version number, 
date of release, and all of the changelog information lines. Any number of 
changelog lines can be grouped together under a heading.

=head1 METHODS

=head2 new( %args )

Creates a new release object, using C<%args> as the default data.

=head2 version( [ $version ] )

Gets/sets the version number for this release.

=head2 date( [ $date ] )

Gets/sets the date for this release.

=head2 note( [ $note ] )

Gets/sets the note for this release.

=head2 changes( [ $group ] )

Gets the list of changes for this release as a hashref of group/changes 
pairs. If a group name is specified, an array ref of changes for that group 
is returned. Should that group not exist, undef is returned.

=head2 add_changes( [ \%options ], @changes )

Appends a list of changes to the release. Specifying a C<group> option 
appends them to that particular group. NB: the default group is represented 
by and empty string.

    # Append to default group
    $release->add_changes( 'Added foo() function' );
    
    # Append to a particular group
    $release->add_changes( { group => 'Fixes' }, 'Fixed foo() function' );

=head2 set_changes( [ \%options ], @changes )

Replaces the existing list of changes with the supplied values. Specifying
a C<group> option will only replace change items in that group.

=head2 clear_changes( )

Clears all changes from the release.

=head2 groups( sort => \&sorting_function )

Returns a list of current groups in this release.

If I<sort> is provided, groups are
sorted according to the given function. If not,
they are sorted alphabetically.

=head2 add_group( @groups )

Creates an empty group under the names provided.

=head2 delete_group( @groups )

Deletes the groups of changes specified.

=head2 delete_empty_groups( )

Deletes all groups that don't contain any changes.

=head2 serialize( group_sort => \&sorting_function )

Returns the release data as a string, suitable for inclusion in a Changes 
file.

If I<group_sort> is provided, change groups are
sorted according to the given function. If not,
groups are sorted alphabetically.

=head1 SEE ALSO

=over 4

=item * L<CPAN::Changes::Spec>

=item * L<CPAN::Changes>

=item * L<Test::CPAN::Changes>

=back

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011-2013 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
