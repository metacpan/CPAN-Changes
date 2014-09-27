package CPAN::Changes::HasEntries;
use Moo::Role;

has entries => (is => 'ro');

sub has_entries {
  my $self = shift;
  !!($self->entries && @{$self->entries});
}

around _serialize => sub {
  my $orig = shift;
  my $self = shift;
  my ($indent, $indent_add, $styles) = @_;
  my $out = $self->$orig(@_);
  $styles = [ @{$styles}[1 .. $#$styles], '-'];
  for my $entry ( @{ $self->entries } ) {
    $out .= $entry->_serialize($indent . $indent_add, $indent_add, $styles);
  }
  return $out;
};

1;
