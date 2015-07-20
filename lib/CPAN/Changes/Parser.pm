package CPAN::Changes::Parser;
use Moo;
use Module::Runtime qw(use_module);
use Carp qw(croak);
use Encode qw(decode FB_CROAK LEAVE_SRC);
use version ();

has _changelog_class => (
  is => 'ro',
  default => 'CPAN::Changes',
  coerce => sub { use_module($_[0]) },
);
has _release_class => (
  is => 'ro',
  default => 'CPAN::Changes::Release',
  coerce => sub { use_module($_[0]) },
);
has _entry_class => (
  is => 'ro',
  default => 'CPAN::Changes::Entry',
  coerce => sub { use_module($_[0]) },
);
has _next_token => (
  is => 'ro',
  init_arg => 'next_token',
);

sub parse_string {
  my ($self, $string) = @_;
  $self->_transform(_parse($string, version_like => $self->_next_token));
}

sub parse_file {
  my ($self, $file, $layers) = @_;
  my $mode = defined $layers ? "<$layers" : '<:raw';
  open my $fh, $mode, $file or croak "Can't open $file: $!";
  my $content = do { local $/; <$fh> };
  if (!defined $layers) {
    # if it's valid UTF-8, decode that.  otherwise, assume latin 1 and leave it.
    eval { $content = decode('UTF-8', $content, FB_CROAK | LEAVE_SRC) };
  }
  $self->parse_string($content);
}

sub _transform {
  my ($self, $data) = @_;

  my $release_class = $self->_release_class;
  my $entry_class = $self->_entry_class;

  $self->_changelog_class->new(
    (defined $data->{preamble} ? (preamble => $data->{preamble}) : ()),
    releases => [
      map {
        $release_class->new(
          version => $_->{version},
          (defined $_->{date} ? (date => $_->{date}) : ()),
          (defined $_->{note} ? (note => $_->{note}) : ()),
          ($_->{entries} ? (
            entries => [
              map { _trans_entry($entry_class, $_) } @{$_->{entries}},
            ],
          ) : () ),
        )
      } @{$data->{releases}},
    ],
  );
}

sub _trans_entry {
  my ($entry_class, $entry) = @_;

  $entry_class->new(
    line => $entry->{line},
    text => $entry->{text},
    $entry->{entries} ? (
      entries => [
        map { _trans_entry($entry_class, $_) } @{$entry->{entries}},
      ],
    ) : (),
  );
}

sub _parse {
  my ($string, %opts) = @_;

  my $version_prefix = qr/version|revision/i;
  $version_prefix = qr/$version_prefix|$opts{version_prefix}/
    if $opts{version_prefix};
  my $version_token = $version::LAX;
  $version_token = qr/$version_token|$opts{version_like}/
    if $opts{version_like};

  my @lines = split /\r\n?|\n/, $string;

  my $preamble = '';
  my @releases;
  my @indents;
  for my $line_number ( 0 .. $#lines ) {
    my $line = $lines[$line_number];
    if ( $line =~ /^(?:$version_prefix\s+)?($version_token)(?:\s+(.*))?$/i ) {
      my $version = $1;
      my $note    = $2;
      my $date;
      if (defined $note) {
        ($date, $note) = split_date($note);
      }

      my $release = {
        version => $version,
        (defined $date ? (date => $date) : ()),
        (defined $note ? (note => $note) : ()),
        entries => [],
        line    => $line_number+1,
      };
      push @releases, $release;
      @indents = ($release);
      next;
    }
    elsif (!@indents) {
      $preamble .= (length $preamble ? "\n" : '') . $line;
      next;
    }

    if ( $line =~ /^[-_*+~#=\s]*$/ ) {
      $indents[-1]{done}++
        if @indents > 1;
      next;
    }

    $line =~ s/\s+$//;
    $line =~ s/^(\s*)//;
    my $indent = 1 + length _expand_tab($1);
    my $change;
    my $done;
    my $nest;
    my $style = '';
    if ( $line =~ /^\[\s*([^\[\]]*)\]$/ ) {
      $done   = 1;
      $nest   = 1;
      $change = $1;
      $style  = '[]';
      $change =~ s/\s+$//;
    }
    elsif ( $line =~ /^([-*+=#]+)\s+(.*)/ ) {
      $style = $1;
      $change = $2;
    }
    else {
      $change = $line;
      if (
        $indent >= $#indents
        && $indents[-1]{text}
        && !$indents[-1]{done}
      ) {
        $indents[-1]{text} .= " $change";
        next;
      }
    }

    my $group;
    my $nested;

    if ( !$nest && $indents[$indent]{nested} ) {
      $nested = $group = $indents[$indent]{nested};
    }
    elsif ( !$nest && $indents[$indent]{nest} ) {
      $nested = $group = $indents[$indent];
    }
    else {
      ($group) = grep {defined} reverse @indents[ 0 .. $indent - 1 ];
    }

    my $entry = {
      text   => $change,
      line   => $line_number+1,
      done   => $done,
      nest   => $nest,
      nested => $nested,
      style  => $style,
    };
    push @{ $group->{entries} ||= [] }, $entry;

    if ( $indent <= $#indents ) {
      $#indents = $indent;
    }

    $indents[$indent] = $entry;
  }
  $preamble =~ s/^\s*\n//;
  $preamble =~ s/\s+$//;
  undef $preamble if !length $preamble;
  my @entries = @releases;
  while ( my $entry = shift @entries ) {
    push @entries, @{ $entry->{entries} } if $entry->{entries};
    delete @{$entry}{qw(done nest nested)};
  }
  return {
    preamble => $preamble,
    releases => [ reverse @releases ],
  };
}

my @months = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
my %months = map {; lc $months[$_] => $_ } 0 .. $#months;
our $_SHORT_DAY = qr{Sun|Mon|Tue|Wed|Thu|Fri|Sat}i;
our ($_SHORT_MONTH) = map qr{$_}i, join('|', @months);
our $_UNKNOWN_DATE = qr{
  Unknown\ Release\ Date
  |Unknown
  |Not\ Released
  |Development\ Release
  |Development
  |Developer\ Release
}xi;

our $_LOCALTIME_DATE = qr{
  (?:$_SHORT_DAY\s+)?
  ($_SHORT_MONTH)\s+
  (\d{1,2})\s+  # date
  (?: ([\d:]+)\s+ )?  # time
  (?: ([A-Z]+)\s+ )?  # timezone
  (\d{4})       # year
}x;

our $_RFC_2822_DATE = qr{
  $_SHORT_DAY,\s+
  (\d{1,2})\s+
  ($_SHORT_MONTH)\s+
  (\d{4})\s+
  (\d\d:\d\d:\d\d)\s+
  ([+-])(\d{2})(\d{2})
}x;

our $_DZIL_DATE = qr{
  (\d{4}-\d\d-\d\d)\s+
  (\d\d:\d\d(?::\d\d)?)(\s+[A-Za-z]+/[A-Za-z_-]+)
}x;

our $_ISO_8601_DATE = qr{
  \d\d\d\d # Year
  (?:
    -\d\d # -Month
    (?:
      -\d\d # -Day
      (?:
        [T\s]
        \d\d:\d\d # Hour:Minute
        (?:
          :\d\d     # :Second
          (?: \.\d+ )?    # .Fractional_Second
        )?
        (?:
          Z          # UTC
          | [+-]\d\d:\d\d    # Hour:Minute TZ offset
            (?: :\d\d )?       # :Second TZ offset
        )?
      )?
    )?
  )?
}x;

sub split_date {
  my $note = shift;
  my $date;
  # munge date formats, save the remainder as note
  if (defined $note && length $note) {
    $note =~ s/^[^\w\s]*\s+//;
    $note =~ s/\s+$//;

    # explicitly unknown dates
    if ( $note =~ s{^($_UNKNOWN_DATE)}{}i ) {
      $date = $1;
    }

    # handle localtime-like timestamps
    elsif ( $note =~ s{^$_LOCALTIME_DATE}{} ) {
      $date = sprintf( '%d-%02d-%02d', $5, 1+$months{lc $1}, $2 );
      if ($3) {
        # unfortunately ignores TZ data ($4)
        $date .= sprintf( 'T%sZ', $3 );
      }
    }

    # RFC 2822
    elsif ( $note =~ s{^$_RFC_2822_DATE}{} ) {
      $date = sprintf( '%d-%02d-%02dT%s%s%02d:%02d',
        $3, 1+$months{lc $2}, $1, $4, $5, $6, $7 );
    }

    # handle dist-zilla style, again ingoring TZ data
    elsif ( $note =~ s{^$_DZIL_DATE}{} ) {
      $date = sprintf( '%sT%sZ', $1, $2 );
      $note = $3 . $note;
    }

    # start with W3CDTF, ignore rest
    elsif ( $note =~ s{^($_ISO_8601_DATE)}{} ) {
      $date = $1;
      $date =~ s{ }{T};

      # Add UTC TZ if date ends at H:M, H:M:S or H:M:S.FS
      $date .= 'Z'
        if length($date) == 16
        || length($date) == 19
        || $date =~ m{\.\d+$};
    }

    $note =~ s/^\s+//;
  }

  defined $_ && !length $_ && undef $_ for ($date, $note);

  return ($date, $note);
}

sub _expand_tab {
  my $string = "$_[0]";
  $string =~ s/([^\t]*)\t/$1 . (" " x (8 - (length $1) % 8))/eg;
  return $string;
}

1;
