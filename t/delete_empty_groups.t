use strict;
use warnings;

use Test::More tests => 2;

use CPAN::Changes;

my $changes = CPAN::Changes->load_string(<<'END_CHANGES');
0.2 2012-02-01
    [D]
    [E]
    - Yadah

0.1 2011-01-01
    [A]
    - Stuff
    [B]
    [C]
    - Blah
END_CHANGES

$changes->delete_empty_groups;

is_deeply( [ sort( ($changes->releases)[0]->groups ) ], [ qw/ A C / ] );
is_deeply( [ sort( ($changes->releases)[1]->groups ) ], [ 'E' ] );


