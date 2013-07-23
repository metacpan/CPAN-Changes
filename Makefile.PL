use inc::Module::Install 1.00;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/CPAN/Changes.pm > README' );
}

perl_version '5.010';

name 'CPAN-Changes';
all_from 'lib/CPAN/Changes.pm';

requires 'Text::Wrap';
requires 'version' => '0.79';

test_requires 'Test::More' => '0.96';
extra_tests;

install_script 'tidy_changelog';

repository 'http://github.com/bricas/cpan-changes';

WriteAll;
