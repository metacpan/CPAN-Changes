use inc::Module::Install 1.00;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/CPAN/Changes.pm > README' );
}

perl_version '5.006';

name 'CPAN-Changes';
all_from 'lib/CPAN/Changes.pm';

requires 'Text::Wrap';

test_requires 'Test::More';
extra_tests;

repository 'http://github.com/bricas/cpan-changes';

WriteAll;
