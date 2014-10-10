package CPAN::Changes::Group;
use Moo;
use CPAN::Changes::Entry;

has _entry => (
  is => 'ro',
  handles => {
    is_empty => 'has_entries',
  },
);

around BUILDARGS => sub {
  my ($orig, $self, @args) = @_;
  my $args = $self->$orig(@args);
  if (!$args->{_entry}) {
    $args->{_entry} = CPAN::Changes::Entry->new({
      text => $args->{name} || '',
      entries => [ map { CPAN::Changes::Entry->new(text => $_) } @{ $args->{changes} || [] } ],
    });
  }
  $args;
};

sub name {
  my ($self, @changes) = @_;
  my $entry = $self->_entry;
  $entry->can('text') ? $entry->text : '';
}

sub changes {
  my ($self) = @_;
  my $entry = $self->_entry;
  [ map { $_->text } @{$entry->entries || []} ];
}

sub add_changes {
  my ($self, @changes) = @_;
  my $entry = $self->_entry;
  push @{$entry->entries}, map { CPAN::Changes::Entry->new(text => $_) } @changes;
  $self->changes;
}

sub set_changes {
  my ($self, @changes) = @_;
  my $entry = $self->_entry;
  @{$entry->entries} = map { CPAN::Changes::Entry->new(text => $_) } @changes;
  $self->changes;
}

sub clear_changes {
  my ($self) = @_;
  my $entry = $self->_entry;
  @{$entry->entries} = ();
  $self->changes;
}

sub serialize {
  my ($self) = @_;
  my $entry = $_[0]->_entry;
  $entry->_serialize(' ', ' ', ['[]', '-']);
}

1;
