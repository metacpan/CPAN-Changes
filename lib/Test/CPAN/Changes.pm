package Test::CPAN::Changes;

use strict;
use warnings;

use CPAN::Changes;
use Test::Builder;

my $Test       = Test::Builder->new;
my $date_re    = '^\d{4}-\d{2}-\d{2}'; # "Looks like" a W3CDTF
my $version_re = '^[._\-[:alnum:]]+$'; # "Looks like" a version

sub import {
    my $self = shift;

    my $caller = caller;
    no strict 'refs';
    *{ $caller . '::changes_ok' }      = \&changes_ok;
    *{ $caller . '::changes_file_ok' } = \&changes_file_ok;

    $Test->exported_to( $caller );
    $Test->plan( @_ );
}

sub changes_ok {
    $Test->plan( tests => 4 );
    return changes_file_ok( undef, @_ );
}

sub changes_file_ok {
    my ( $file ) = @_;
    $file ||= 'Changes';

    my $changes = eval { CPAN::Changes->load( $file ) };

    if ( $@ ) {
        $Test->ok( 0, "Unable to parse $file" );
        $Test->diag( "  ERR: $@" );
        return;
    }

    $Test->ok( 1, "$file is loadable" );

    my @releases = $changes->releases;

    if( !@releases ) {
        $Test->ok( 0, "$file does not contain any releases" );
        return;
    }

    $Test->ok( 1, "$file contains at least one release" );

    for( @releases ) {
        if( $_->date !~ m{$date_re} ) {
            $Test->ok( 0, "$file contains an invalid release date" );
            $Test->diag( '  ERR: ' . $_->date );
            return;
        }
        if( $_->version !~ m{$version_re} ) {
            $Test->ok( 0, "$file contains an invalid version number" );
            $Test->diag( '  ERR: ' . $_->version );
            return;
        }
    }

    $Test->ok( 1, "$file contains valid release dates" );
    $Test->ok( 1, "$file contains valid version numbers" );

    return $changes;
}

1;

__END__

=head1 NAME

Test::CPAN::Changes - Validation of the Changes file in a CPAN distribution

=head1 SYNOPSIS

    use Test::More;
    eval 'use Test::CPAN::Changes';
    plan skip_all => 'Test::CPAN::Changes required for this test' if $@;
    changes_ok();

=head1 DESCRIPTION

This module allows CPAN authors to write automated tests to ensure their 
changelogs match the specification.

=head1 METHODS

=head2 changes_ok( )

Simple wrapper around C<changes_file_ok>. Declares a four test plan, and 
uses the default filename of C<Changes>.

=head2 changes_file_ok( [ $file ] )

Checks the contents of the changes file against the specification. No plan 
is declared and if no filename is specified, C<Changes> is used.

=head1 SEE ALSO

=over 4

=item * L<CPAN::Changes::Spec>

=item * L<CPAN::Changes>

=back

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
