use strict;
use warnings;

use Test::More tests => 28;

use_ok( 'CPAN::Changes' );

my $changes  = CPAN::Changes->load( 'Changes' );
my @releases = $changes->releases;

isa_ok( $changes, 'CPAN::Changes' );
ok( scalar @releases, 'has releases' );
isa_ok( $_, 'CPAN::Changes::Release' ) for @releases;
