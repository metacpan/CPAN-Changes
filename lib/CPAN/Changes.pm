package CPAN::Changes;
use Moo;

has releases => (is => 'ro', required => 1);
has preamble => (is => 'ro');

sub _numify_version {
    my $version = shift;
    $version = _fix_version($version);
    $version =~ s/_//g;
    if ($version =~ s/^v//i || $version =~ tr/.// > 1) {
        my @parts = split /\./, $version;
        my $n = shift @parts;
        $version = sprintf(join('.', '%s', ('%03s' x @parts)), $n, @parts);
    }
    $version += 0;
    return $version;
}

sub _fix_version {
    my $version = shift;
    return 0 unless defined $version;
    my $v = ($version =~ s/^v//i);
    $version =~ s/[^\d\._].*//;
    $version =~ s/\.[._]+/./;
    $version =~ s/[._]*_[._]*/_/g;
    $version =~ s/\.{2,}/./g;
    $v ||= $version =~ tr/.// > 1;
    $version ||= 0;
    return (($v ? 'v' : '') . $version);
}


sub find_release {
  my ($self, $version) = @_;

  my ($release) = grep { $_->version eq $version } @{ $self->releases };
  return $release
    if $release;
  $version = _numify_version($version) || return undef;
  ($release) = grep { _numify_version($_->version) == $version } @{ $self->releases };
  return $release;
}

sub serialize {
  my ($self) = @_;
  my $out = $self->preamble || '';
  $out .= "\n\n"
    if $out;
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
    $out .= "\n"
      unless $out eq '' || $out =~ /\n\n\z/;
    $out .= $release->_serialize('', '  ', $styles);
  }
  return $out;
}

1;
