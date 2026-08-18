package Tgph::Diag;
use v5.36;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(diag);

sub diag {
    my ($msg, %opts) = @_;
    my $prefix = $opts{prefix} // '';
    my $indent = $ENV{PUBTG_INDENT} // 0;
    $indent = 0 unless $indent =~ /^\d+$/;
    my $pad = ' ' x $indent;
    print STDERR "${pad}${prefix}${msg}\n";
}

1;
