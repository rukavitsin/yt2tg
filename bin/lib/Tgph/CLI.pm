package Tgph::CLI;

use v5.36;
use strict;
use warnings;

use Getopt::Long qw(GetOptionsFromArray);
use Tgph::Constants;
use Tgph::ExitCodes;
use Tgph::Version;

sub parse {
    my ($argv, %extra) = @_;

    my %options = (
        help    => 0,
        version => 0,
        dry_run => 0,
    );

    my @spec = (
        'help|h'       => \$options{help},
        'version|V'    => \$options{version},
        'dry-run|n'    => \$options{dry_run},
    );

    push @spec, @{ $extra{spec} } if $extra{spec};

    my $ok = GetOptionsFromArray($argv, @spec);

    return (undef, Tgph::ExitCodes::USAGE) unless $ok;

    return (\%options, Tgph::ExitCodes::OK);
}

sub print_help {
    my ($program) = @_;

    $program //= Tgph::Constants::PROJECT_NAME;

    print <<"HELP";
Usage: $program [OPTIONS]

Options:
  -h, --help       Show this help
  -V, --version    Show version
  -n, --dry-run    Do not perform changes

HELP

    return Tgph::ExitCodes::OK;
}

sub print_version {
    print Tgph::Version->VERSION, "\n";
    return Tgph::ExitCodes::OK;
}

1;
