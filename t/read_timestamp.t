use strict;
use warnings;

use Test::More tests => 29;

use_ok( 'CPAN::Changes' );

my $changes = CPAN::Changes->load( 't/corpus/timestamp.changes' );

isa_ok( $changes, 'CPAN::Changes' );

my @releases = $changes->releases;
is( scalar @releases, 10, 'has 10 releases' );

my @expected = (
    qw( 2011-03-25T12:16:25Z 2011-03-25T12:18:36Z 2011-03-25 2011-04-11T12:11:10Z 2011-04-11T15:14Z 2011-04-11T21:40:45-03:00 ),
    { d => '2011-04-12T12:00:00Z', n => '# JUNK!', h => undef, },
    { d => '2011-04-13T12:00Z', n => 'Test', h => 'Test', },
    { d => '2011-04-14T12:00:00Z', n => 'America/Halifax', h => 'America/Halifax', },
    '2011-04-14T13:00:00.123Z',
);
for ( 0..@expected - 1 ) {
    isa_ok( $releases[ $_ ], 'CPAN::Changes::Release' );

    if( ref $expected[ $_ ] ) {
        is( $releases[ $_ ]->date,  $expected[ $_ ]->{ d }, 'date' );
        is( $releases[ $_ ]->note,  $expected[ $_ ]->{ n }, 'note' );
        is( $releases[ $_ ]->hint,  $expected[ $_ ]->{ h }, 'hint' );
    }
    else {
        is( $releases[ $_ ]->date,  $expected[ $_ ], 'date' );
    }
}
