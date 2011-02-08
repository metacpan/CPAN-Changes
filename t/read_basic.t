use strict;
use warnings;

use Test::More tests => 10;

use_ok( 'CPAN::Changes' );

my $changes = CPAN::Changes->load( 't/corpus/basic.changes' );

isa_ok( $changes, 'CPAN::Changes' );
is( $changes->preamble, '', 'no preamble' );

my @releases = $changes->releases;

is( scalar @releases, 1, 'has 1 release' );
isa_ok( $releases[ 0 ], 'CPAN::Changes::Release' );
is( $releases[ 0 ]->version, '0.01',       'version' );
is( $releases[ 0 ]->date,    '2010-06-16', 'date' );
is_deeply(
    $releases[ 0 ]->changes,
    { '' => [ 'Initial release' ] },
    'full changes'
);
is_deeply( [ $releases[ 0 ]->groups ], [ '' ], 'only the main group' );
is_deeply(
    $releases[ 0 ]->changes( '' ),
    [ 'Initial release' ],
    'one change line'
);
