package CPAN::Changes;
use Moo;

has releases => (is => 'ro', required => 1);
has preamble => (is => 'ro');

sub release {
  my ($self, $version) = @_;
  my ($release) = grep { $_->version eq $version } @{ $self->releases };
  return $release;
}

sub serialize {
  my ($self) = @_;
  my $out = $self->preamble . "\n";
  my @styles = ('', '[]', '-', '*');
  my $indent_add = '  ';
  for my $release (@{$self->releases}) {
    my $styles = \@styles;
    if (
      grep {
        length($_->text) > 78 - 4 - length($indent_add) || !$_->has_entries
      } @{ $release->entries }
    ) {
      $styles = [ '', '-', '*' ];
    }
    $out .= "\n" . $release->_serialize('', '  ', $styles);
  }
}

1;
