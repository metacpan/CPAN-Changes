use strict;
use warnings;
use Test::More;

use CPAN::Changes::Parser;

my $parser = CPAN::Changes::Parser->new;

{
  my $changes = $parser->parse_file('corpus/dists/Module-Rename.changes');

  my $release = $changes->find_release('0.04');
  my @groups = $release->group_values;
  is scalar @groups, 1, 'one group found when no groups present';
  is eval { $groups[0]->name }, '', 'group has empty name';
}

done_testing;
