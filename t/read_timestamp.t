use strict;
use warnings;

use Test::More tests => 9;

use_ok( 'CPAN::Changes' );

my $changes = CPAN::Changes->load( 't/corpus/timestamp.changes' );

isa_ok( $changes, 'CPAN::Changes' );

my @releases = $changes->releases;
is( scalar @releases, 3, 'has 3 releases' );

# sorting by ASCENDING date
my @expected = qw( 2011-03-25 2011-03-25T12:16:25Z 2011-03-25T12:18:36Z );
for ( 0..2 ) {
    isa_ok( $releases[ $_ ], 'CPAN::Changes::Release' );
    is( $releases[ $_ ]->date,  $expected[ $_ ], 'date' );
}
