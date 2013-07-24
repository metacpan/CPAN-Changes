use strict;
use warnings;

use Test::More tests => 16;

use_ok( 'CPAN::Changes' );

my $changes = CPAN::Changes->load( 't/corpus/unknown_date.changes' );

isa_ok( $changes, 'CPAN::Changes' );
is( $changes->preamble, '', 'no preamble' );

my @releases = $changes->releases;

is( scalar @releases, 4, 'has 4 releases' );

my @expected = (
    { version => '0.01', date => 'Unknown' },
    { version => '0.02', date => 'Not Released' },
    { version => '0.03', date => 'Unknown Release Date' },
    { version => '0.04', date => 'Development Release' },
);

for ( 0..@expected - 1 ) {
    isa_ok( $releases[ $_ ], 'CPAN::Changes::Release' );
    is( $releases[ $_ ]->version, $expected[ $_ ]->{ version }, 'version' );
    is( $releases[ $_ ]->date, $expected[ $_ ]->{ date }, 'date' );
}
