package CPAN::Changes::Entry;
use Moo;

with 'CPAN::Changes::HasEntries';

has text    => (is => 'ro');
has line    => (is => 'ro');

sub serialize {
  my ($self, %args) = @_;
  my $indents = $args{indents} || [];
  my $styles = $args{styles} || [];
  my $width = $args{width} || 75;

  my $indent = $indents->[0];
  my $style = $styles->[0];
  my $text = $self->text;
  if (length($style) < 2) {
    my $space = ' ' x (2 * length $style);
    $width -= length $space;
    $text =~ s/\G[ \t]*([^\n]{1,$width}|[^ \t\r\n]+)([ \t\r\n]+|$)/$1\n/mg;
    $text =~ s/[ \t]+\n/\n/g;
    $text =~ s/^(.)/$space$1/mg;
    substr $text, 0, length($style), $style;
  }
  # can't wrap this style
  elsif (length($style) % 2 == 0) {
    my $length = length($style) / 2;
    $text = substr($style, 0, $length) . $text . substr($style, $length) . "\n";
  }
  else {
    die "invalid changelog entry style '$style'";
  }
  return $text;
}

1;
