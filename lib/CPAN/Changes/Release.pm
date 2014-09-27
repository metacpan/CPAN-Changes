package CPAN::Changes::Release;
use Moo;

with 'CPAN::Changes::HasEntries';

has version => (is => 'ro');
has date    => (is => 'ro');
has note    => (is => 'ro');
has line    => (is => 'ro');

sub _serialize {
  my ($self, $indent, $indent_add, $styles) = @_;

  $indent . $self->version . ' - ' . $self->date . ' ' . $self->note . "\n";
}

1;
