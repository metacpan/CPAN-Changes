use strict;
use warnings;

use Test::More tests => 18;

use_ok( 'CPAN::Changes' );

my $changes = CPAN::Changes->load( 't/corpus/timestamp.changes' );

isa_ok( $changes, 'CPAN::Changes' );

my @releases = $changes->releases;
is( scalar @releases, 7, 'has 7 releases' );

my @expected = (
    qw( 2011-03-25T12:16:25Z 2011-03-25T12:18:36Z 2011-03-25 2011-04-11T12:11:10Z 2011-04-11T15:14Z 2011-04-11T21:40:45-03:00 ),
    { d => '2011-04-12T12:00:00Z', n => '# JUNK!' },
);
for ( 0..@expected - 1 ) {
    isa_ok( $releases[ $_ ], 'CPAN::Changes::Release' );

    if( ref $expected[ $_ ] ) {
        is( $releases[ $_ ]->date,  $expected[ $_ ]->{ d }, 'date' );
        is( $releases[ $_ ]->note,  $expected[ $_ ]->{ n }, 'note' );
    }
    else {
        is( $releases[ $_ ]->date,  $expected[ $_ ], 'date' );
    }
}
