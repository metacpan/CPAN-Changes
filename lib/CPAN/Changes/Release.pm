package CPAN::Changes::Release;
use Moo;

with 'CPAN::Changes::HasEntries';

has version => (is => 'rw');
has date    => (is => 'rw');
has note    => (is => 'rw');
has line    => (is => 'ro');

sub _serialize {
  my ($self, $indent, $indent_add, $styles) = @_;

  my $out = $indent . $self->version;
  if ($self->date || $self->note) {
    $out .= ' ' . join ' ', (grep { defined } $self->date, $self->note);
  }
  $out . "\n";
}

1;
