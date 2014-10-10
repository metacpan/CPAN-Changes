package CPAN::Changes::HasEntries;
use Moo::Role;
use Sub::Quote qw(qsub);
use Types::Standard qw(ArrayRef InstanceOf Str);

my $entry_type = (InstanceOf['CPAN::Changes::Entry'])->plus_coercions(
  Str ,=> qsub q{ CPAN::Changes::Entry->new(text => $_[0]) },
);

has entries => (
  is => 'rw',
  default => sub { [] },
  isa => ArrayRef[$entry_type],
  coerce => (ArrayRef[$entry_type])->coercion,
);

sub has_entries {
  my $self = shift;
  !!($self->entries && @{$self->entries});
}

sub find_entry {
  my ($self, $find) = @_;
  return undef
    unless $self->has_entries;
  if (ref $find ne 'Regexp') {
    $find = qr/\A\Q$find\E\z/;
  }
  my ($entry) = grep { $_->text =~ $find } @{ $self->entries };
  return $entry;
}

around _serialize => sub {
  my $orig = shift;
  my $self = shift;
  my ($indent, $indent_add, $styles) = @_;
  my $out = $self->$orig(@_);
  $styles = [ @{$styles}[1 .. $#$styles], '-'];
  my $entries = $self->entries || [];
  for my $entry ( @$entries ) {
    $out .= $entry->_serialize($indent . $indent_add, $indent_add, $styles);
    $out .= "\n"
      if $entry->has_entries;
  }
  $out =~ s/\n\n+\z/\n/;
  return $out;
};

sub add_entry {
  my ($self, $entry) = @_;
  $entry = $entry_type->coerce($entry);
  push @{ $self->entries }, $entry;
  return $entry;
}

sub remove_entry {
  my ($self, $entry) = @_;
  $entry = ref $entry ? $entry : $self->find_entry($entry);
  return unless $entry;
  my @entries = grep { $_ != $entry } @{ $self->entries };
  $self->entries(\@entries);
}

require CPAN::Changes::Entry;
1;
