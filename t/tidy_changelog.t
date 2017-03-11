use strict;
use warnings;

use Test::More;

{ # use filename
    my $tidy_changes = qx{$^X -Ilib bin/tidy_changelog t/corpus/basic.changes};

    is( $tidy_changes, <<"    EOTIDY", "output correct (filename)" );
0.01 2010-06-16
 - Initial release
    EOTIDY
}

{ # use filtermode
    my $basic_changes = do { local (@ARGV, $/) = ('t/corpus/basic.changes'); <> };
    open( my $pipe, '|-', "$^X -Ilib bin/tidy_changelog - > pipe_basic.changes" ) or die "Cannot fork: $!";
    print $pipe $basic_changes;
    close( $pipe );

    my $tidy_changes = do { local (@ARGV, $/) = ('pipe_basic.changes'); <> };
    is( $tidy_changes, <<"    EOTIDY", "output correct (pipe)" );
0.01 2010-06-16
 - Initial release
    EOTIDY

    unlink 'pipe_basic.changes';
}

done_testing();
