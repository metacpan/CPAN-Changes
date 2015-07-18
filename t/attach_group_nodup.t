use strict;
use warnings;

use Test::More;

# ABSTRACT: Ensure duplicates are not created with the same group name.

use CPAN::Changes::Release;
use CPAN::Changes::Group;

my $group = CPAN::Changes::Group->new( text => 'GroupName' );
$group->add_changes("This is a test");

my $dup = CPAN::Changes::Group->new( text => 'GroupName' );
$group->add_changes("This is also a test");

my $release = CPAN::Changes::Release->new();
$release->attach_group($group);
$release->attach_group($dup);

is( scalar @{ $release->entries }, 1, 'Only 1 entry added' );

done_testing;

