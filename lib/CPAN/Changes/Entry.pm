package CPAN::Changes::Entry;
use Moo;

with 'CPAN::Changes::HasEntries';

has text    => (is => 'ro');
has line    => (is => 'ro');

sub _serialize {
  my ($self, $indent, $indent_add, $styles) = @_;
  my $style = $styles->[0];
  my $text = $self->text;
  if (length($style) < 2) {
    my $width = 80 - length($indent) - 2 * length($style);
    $text =~ s/\G[ \t]*([^\n]{1,$width}|[^ \t\r\n]+)([ \t\r\n]+|$)/$1\n/mg;
    $text =~ s/[ \t]+\n/\n/g;
    my $space = ' ' x (2*length $style);
    $text =~ s/^(.)/$space$1/mg;
    $text =~ s/^ /$style/;
  }
  elsif (length $style == 2) {
    $text = substr($style, 0, 1) . " $text " . substr($style, 1, 1) . "\n";
  }
  $text =~ s/^(.)/$indent$1/mg;
  return $text;
}

1;
