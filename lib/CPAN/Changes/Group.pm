package CPAN::Changes::Group;
use Moo;
use Sub::Quote qw(qsub);
use CPAN::Changes::Entry;

has _entry => (
  is => 'rw',
  handles => {
    is_empty => 'has_entries',
    add_changes => 'add_entry',
    name => 'text',
  },
  lazy => 1,
  default => qsub q{ CPAN::Changes::Entry->new(text => '') },
  predicate => 1,
);

sub _maybe_entry {
  my $self = shift;
  if ($self->can('changes') == \&CPAN::Changes::Group::changes) {
    return $self->_entry;
  }
  else {
    return CPAN::Changes::Entry->new(
      text => $self->name,
      entries => $self->changes,
    );
  }
}

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

sub serialize {
  my ($self, %args) = @_;
  $args{indents} ||= [' ', ' '];
  $args{styles} ||= ['[]', '-'];
  $self->_maybe_entry->serialize(%args);
}

1;
