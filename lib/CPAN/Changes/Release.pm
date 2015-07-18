package CPAN::Changes::Release;
use Moo;

with 'CPAN::Changes::HasEntries';

has version => (is => 'rw');
has date    => (is => 'rw');
has note    => (is => 'rw');
has line    => (is => 'ro');

around BUILDARGS => sub {
  my ($orig, $class, @args) = @_;
  my $args = $class->$orig(@args);
  if (my $changes = delete $args->{changes}) {
    if ($args->{entries}) {
      die "Mixing back-compat interface with new interface not allowed";
    }
    $args->{entries} = [];
    for my $group (sort keys %$changes) {
      my @entries = @{$changes->{$group}};

      if ($group eq '') {
        push @{$args->{entries}}, @entries;
      }
      else {
        my $entry = CPAN::Changes::Entry->new(
          text => $group,
          entries => \@entries,
        );
        push @{$args->{entries}}, $entry;
      }
    }
  }
  $args;
};

sub serialize {
  my ($self, %args) = @_;
  my $indents = $args{indents} || ['', ' ', ''];
  my $styles = $args{styles} || ['', '[]'];
  my $width = $args{width} || 76;

  my $out = $indents->[0] . $styles->[0] . $self->version;
  if ($self->date || $self->note) {
    $out .= ' ' . join ' ', (grep { defined } $self->date, $self->note);
  }
  $out . "\n";
}

around serialize => sub {
  my ($orig, $self, %args) = @_;
  $args{indents} ||= ['', ' ', ''];
  $args{styles} ||= ['', '[]'];
  $args{width} ||= 76;
  $self->$orig(%args);
};

sub changes {
  my ($self, $group) = @_;
  if (defined $group) {
    return $self->get_group($group)->changes;
  }
  else {
    return { map { $_ => $self->get_group($_)->changes } $self->groups };
  }
}

sub add_changes {
  my $self = shift;
  my %opts;
  if (@_ > 1 && ref $_[0] eq 'HASH') {
    %opts = %{ +shift };
  }
  $self->get_group($opts{group} || '')->add_changes(@_);
}

sub set_changes {
  my $self = shift;
  my %opts;
  if (@_ > 1 && ref $_[0] eq 'HASH') {
    %opts = %{ +shift };
  }
  $self->get_group($opts{group} || '')->set_changes(@_);
}

sub clear_changes {
  $_[0]->entries([]);
}

sub groups {
  my ($self, %args) = @_;
  my $sort = $args{sort} || sub { sort @_ };
  my %groups;
  for my $entry ( @{ $self->entries } ) {
    if ($entry->has_entries) {
      $groups{$entry->text}++;
    }
    else {
      $groups{''}++;
    }
  }
  return $sort->(keys %groups);
}

sub add_group {
  my ($self, @groups) = @_;
  push @{ $self->entries }, map { CPAN::Changes::Entry->new(text => $_) } @groups;
}

sub delete_group {
  my ($self, @groups) = @_;
  my @entries = @{ $self->entries };
  for my $name (@groups) {
    @entries = grep { $_->text ne $name } @entries;
  }
  $self->entries(\@entries);
}

# this is nonsense, but try to emulate.  if nothing has entries, then there
# are no "groups", so leave everything.
sub delete_empty_groups {
  my ($self) = @_;
  my @entries = grep { $_->has_entries } @{ $self->entries };
  return
    if !@entries;
  $self->entries(\@entries);
}

sub get_group {
  my ($self, $name) = @_;
  require CPAN::Changes::Group;
  if (defined $name && length $name) {
    my ($entry) = grep { $_->text eq $name } @{ $self->entries };
    $entry ||= $self->add_entry($name);
    return CPAN::Changes::Group->new(_entry => $entry);
  }
  else {
    return CPAN::Changes::Group->new(_entry => $self);
  }
}

sub attach_group {
  my ($self, $group) = @_;
  my $entry = $group->_entry;
  if ($entry->text eq '') {
    push @{ $self->entries }, @{ $entry->entries };
  }
  else {
    push @{ $self->entries }, $entry;
  }
}

sub group_values {
  my ($self, @groups) = @_;
  return map { $self->get_group($_) } $self->groups(@groups);
}

1;
