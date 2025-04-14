use Test::More;
eval "use Test::Pod::Coverage::TrustMe";
plan skip_all => "Test::Pod::Coverage::TrustMe required for testing pod coverage" if $@;
plan tests => 1;
all_pod_coverage_ok($_, { require_link => 1 });
