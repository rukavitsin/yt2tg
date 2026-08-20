package Tgph::Journal;
use v5.36;
use strict;
use warnings;
use JSON::PP ();
use POSIX qw(strftime);

sub append_record {
    my ($file, $record) = @_;
    die "record must be a hash reference\n" unless ref($record) eq 'HASH';
    $record->{timestamp} //= strftime('%Y-%m-%dT%H:%M:%SZ', gmtime);
    $record->{tool} //= "unknown";
    open my $fh, '>>:raw', $file or die "cannot open '$file' for append: $!\n";
    print $fh JSON::PP->new->utf8->canonical->encode($record), "\n";
    close $fh or die "cannot close '$file': $!\n";
    return $record;
}

sub find_record {
    my ($file, $path) = @_;
    return undef unless -f $file;
    open my $fh, '<:raw', $file or return undef;
    my $found;
    while (my $line = <$fh>) {
        chomp $line;
        next unless length $line;
        my $rec = eval { JSON::PP->new->utf8->decode($line) };
        next if $@ || ref($rec) ne 'HASH';
        if (defined $rec->{path} && $rec->{path} eq $path) {
            $found = $rec;
        }
    }
    close $fh;
    return $found;
}

sub list_entries {
    my ($file) = @_;
    return [] unless -f $file;
    open my $fh, '<:raw', $file or return [];
    my @entries;
    while (my $line = <$fh>) {
        chomp $line;
        next unless length $line;
        my $rec = eval { JSON::PP->new->utf8->decode($line) };
        next if $@ || ref($rec) ne 'HASH';
        push @entries, $rec;
    }
    close $fh;
    return [ reverse @entries ];
}

1;
