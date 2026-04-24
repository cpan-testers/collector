package CPAN::Testers::Collector::Parse;

our $VERSION = '0.001';

=head1 SYNOPSIS

    my $parser = CPAN::Testers::Collector::Parse->new;
    my $enriched = $parser->parse( $report );

=head1 DESCRIPTION

This module enriches the plain reports with additional data as parsed out from
the output sections.

This was started from Andreas König's L<CPAN::Testers::ParseReport>
with modifications to support additional report format data.

=head1 SEE ALSO

L<CPAN::Testers::ParseReport>

=cut

use v5.40;
use Mojo::Base -base, -signatures;
use Mojo::Loader qw( load_class );
use Log::Any qw( $LOG );

=method parse

Parse the report and return a copy of the data structure with the enhanced
data.

=cut

my %headings = (
  'program output' => 'tests',
  'prerequisites' => 'prerequisites',
  'environment and other context' => 'environment',
  'tester comments' => 'ignore',
);

my %sections = (
  ignore => sub {},
  tests => \&_parse_tests,
  prerequisites => \&_parse_prerequisites,
  environment => \&_parse_environment,
  configuration => \&_parse_configuration,
);

sub _parse_tests( $report, @lines ) {
  for my $line ( @lines ) {
    if ($line =~ /^Result: (\w+)/) {
      my $grade = lc $1;
      if (!$report->{output}{grade}) {
        $report->{output}{grade} = $grade;
      }
      else {
        if ($report->{output}{grade} ne $grade) {
          warn "Found grade $grade does not match report grade $report->{output}{grade}";
        }
      }
    }
  }
}

sub _parse_prerequisites( $report, @lines ) {
  my $phase = 'requires';
  my $need_idx = 1;
  my $have_idx = 2;
  for my $line ( @lines ) {
    # There are "report prereqs" tests that write out as TAP comments, so remove a leading TAP comment marker.
    $line =~ s/^# //;

    next if $line =~ /\s*prerequisite\s+modules\s+/i;
    next if $line =~ /\s*module\s+need\s+have\s*/i;
    next if $line =~ /\s*no\s+requirements\s+found/i;
    next if $line =~ /^[\s-]*$/;

    # CPANPLUS-0.9178 has "name, have, want"
    if ($line =~ /module name\s+have\s+want/i) {
      $need_idx = 2;
      $have_idx = 1;
      next;
    }

    # CPANPLUS-0.9178 adds toolchain versions in this section
    if ($line =~ /Perl module toolchain versions installed:/) {
      $phase = 'toolchain';
      next;
    }

    # CPAN::Reporter phase change
    if ($line =~ /^([^:\s]+):/) {
      $phase = $1;
      $phase =~ s/_requires$//;
      next;
    }

    # 00-report-prereqs phase change
    if ($line =~ /^=+\s+(\S+)\s+(\S+)\s+=+$/) {
      $phase = lc "$1_$2";
      $phase =~ s/_requires$//;
      next;
    }

    # Only continue for lines that look like a prereq definition
    my $version_re = qr{(?:[0-9._-]+\S*|n/a|any)};
    next unless $line =~ m{^\s+(?:!\s+)?\S+\s+$version_re(\s+$version_re)?\s*$};

    # App::cpanminus::reporter adds "!" before prereqs it couldn't find
    my @parts = grep { /\S/ && !/!/ } map { s/^\s+|\s+$//gr } split /\s+/, $line;
    my ($name, $need, $have);
    if (@parts >= 3) {
      $name = $parts[0];
      $need = $parts[$need_idx];
      $have = $parts[$have_idx];
    }
    elsif (@parts >= 2) {
      $name = $parts[0];
      $have = $parts[1];
    }

    # Some things report "any" instead of "0", so normalize to "0"
    for ($need, $have) {
      s/any/0/ if $_;
    }

    if ($phase eq 'toolchain') {
      $report->{environment}{system}{toolchain}{$name} = $have;
    }
    else {
      push $report->{distribution}{prerequisites}->@*, {
        phase => $phase,
        name => $name,
        need => $need,
        have => $have,
      }
    }
  }
}

my %env_sections = (
  env => '',
  special => '',
  toolchain => '',
);

sub _parse_environment( $report, @lines ) {
  my $section = '';
  for my $line ( @lines ) {
    next if $line =~ /^[\s-]*$/;
    if ($line =~ /^\S[^:]+:/) {
      # Section change
      if ($line =~ /^environment/i) {
        $section = 'env';
      }
      elsif ($line =~ /special variables/i) {
        $section = 'special';
      }
      elsif ($line =~ /toolchain versions/i) {
        $section = 'toolchain';
      }
      else {
        warn "Unknown environment section '$line'";
        $section = '';
      }
      next;
    }

    if ($section =~ /^(env|special)$/) {
      # Separated by `=`
      my ($key, $value) = map { s/^\s+|\s+$//gr } split /=/, $line, 2;
      if ($section eq 'env') {
        $report->{environment}{system}{variables}{$key} = $value;
      }
      elsif ($section eq 'special') {
        # CPANPLUS-0.9178 includes the English name and the punctuation variable
        if ($key =~ /^(\w+):/) {
          $key = '$' . $1;
        }
        # App-cpanminus-reporter-0.12 doesn't have a leading $
        elsif ($key !~ /^\$/) {
          $key = '$' . $key;
        }
        $report->{environment}{language}{variables}{$key} = $value;
      }
    }
    elsif ($section =~ /^(toolchain)$/) {
      # A prerequisites section
      next if $line =~ /\s*Module\s+Have/i;
      my ($key, $value) = grep "$_", map { s/^\s+|\s+$//gr } split /\s+/, $line;
      $report->{environment}{system}{toolchain}{$key} = $value;
    }
  }
}

sub _parse_configuration( $report, @lines ) {
  for my $line ( @lines ) {

  }
}

sub parse( $self, $report ) {
  my %gathered = (
    prerequisites => 0,
    tests => 0,
    environment => 0,
    configuration => 0,
  );

  my @lines = split /\n/, $report->{result}{output}{uncategorized};
  my $current_section;
  my $section_start = 0;
  my $heading_start = 0;

  my $flush = sub($i) {
    # dump the current section into its individual parser
    $sections{$current_section}->($report, @lines[$section_start..$i]);
    $section_start = 0;
    undef $current_section;
  };

  for my $i ( 0 .. $#lines ) {
    my $line = $lines[$i];

    # Handle section headings
    if ($line =~ /^---+$/) {

      # This is not a section heading if...
      #   - It matches "Test Summary Report"
      unless ($lines[$i-1] =~ /Test Summary Report/i) {
        # This is a section heading, so flush the section
        $flush->($i) if ($current_section);
        if (!$heading_start) {
          $heading_start = $i+1;
        }
        else {
          my $heading = lc join " ", @lines[$heading_start..$i-1];
          $current_section = $headings{ $heading };
          if (!$current_section) {
            warn "Unknown section $heading";
            # Try re-starting the heading maybe?
            $heading_start = $i+1;
            next;
          }
          $section_start = $i + 1;
          $heading_start = 0;
        }
        next;
      }
    }

    # Summary of my ...
    if ($line =~ /Summary of my /) {
      $flush->($i-1) if ($current_section);
      $current_section = 'configuration';
      $section_start = $i;
      next;
    }

    # CPANPLUS ~0.9113 - 0.9908 does not have dashes for markers
    if ($line =~ /^TEST RESULTS:/ && !$current_section) {
      $current_section = 'tests';
      $section_start = $i + 1;
    }
    # CPANPLUS ~0.9113 puts "MAKE TEST passed" on the same line as the `make
    # test` output.
    elsif ($line =~ /^MAKE TEST passed:/ && !$current_section) {
      $current_section = 'tests';
      $section_start = $i;
    }
    elsif ($line =~ /^PREREQUISITES:/ && $current_section eq 'tests') {
      $flush->($i);
      $current_section = 'prerequisites';
      $section_start = $i + 1;
    }

    # There are "tests" that report prereqs in TAP comment lines
    if ($line =~ /^# versions for all modules/i && $current_section eq 'tests') {
      # This needs to still be part of the 'tests' section, but also should be used
      # to determine prereqs. So we'll skip ahead and parse these prereqs.
      for my $j ($i..$#lines) {
        if ($lines[$j] !~ /^#/) {
          _parse_prerequisites($report, @lines[$i..$j-1]);
          last;
        }
      }
    }

  }

  $flush->($#lines) if ($current_section);

  return $report;
}

my @date_patterns = (
  "%Y-%m-%dT%TZ", # 2010-07-07T14:01:40Z
  "%a, %d %b %Y %T %z", # Sun, 28 Sep 2008 12:23:12 +0100
  "%b %d, %Y %R", # July 10,...
  "%b  %d, %Y %R", # July  4,...
  "%b %d %Y %T", # Sep 28 2008 12:23:12
);

sub _parse_date( $string ) {
  my $dt;
  for my $pat (@date_patterns) {
    $dt = eval {
      my $p = DateTime::Format::Strptime->new(
        locale => "en",
        time_zone => "UTC",
        pattern => $pat,
      );
      $p->parse_datetime($string)
    };
    return $dt if $dt;
  }

  warn "Could not parse date[$string], setting to epoch 0";
  return DateTime->from_epoch( epoch => 0 );
}

sub _parse_user_agent( $string ) {
  # Run the current line and the previous line through this
  my $user_agent;
  if ($string =~ /CPANPLUS, version (\S+)/) {
    $user_agent = "CPANPLUS $1";
  }
  elsif ($string =~ /created by (App::cpanminus::reporter \S+)/) {
    $user_agent = $1;
  }
  elsif ($string =~ /created (?:automatically )?by (\S+)/) {
    $user_agent = $1;
  }
  elsif ($string =~ /This report was machine-generated by (\S+) (\S+)/) {
    $user_agent = "$1 $2";
  }
  $user_agent =~ s/[\.,]$// if $user_agent;
  return $user_agent;
}

1;
