package CPAN::Changes::Group;
use Moo;
use Sub::Quote qw(qsub);
use CPAN::Changes::Entry;

has _entry => (
  is => 'rw',
  handles => {
    is_empty => 'has_entries',
    serialize => 'serialize',
    add_changes => 'add_entry',
  },
  lazy => 1,
  default => qsub q{ CPAN::Changes::Entry->new },
  predicate => 1,
);

around BUILDARGS => sub {
  my ($orig, $self, @args) = @_;
  my $args = $self->$orig(@args);
  if (!$args->{_entry}) {
    $args->{_entry} = CPAN::Changes::Entry->new({
      text => $args->{name} || '',
      entries => $args->{changes} || [],
    });
  }
  $args;
};

sub name {
  my ($self, @changes) = @_;
  return ''
    unless $self->_has_entry;
  my $entry = $self->_entry;
  $entry->can('text') ? $entry->text : '';
}

sub changes {
  my ($self) = @_;
  return []
    unless $self->_has_entry;
  [ map { $_->text } @{ $self->_entry->entries } ];
}

sub set_changes {
  my ($self, @changes) = @_;
  my $entry = $self->_entry->clone(entries => \@changes);
  $self->_entry($entry);
}

sub clear_changes {
  my ($self) = @_;
  my $entry = $self->_entry;
  @{$entry->entries} = ();
  $self->changes;
}

1;
