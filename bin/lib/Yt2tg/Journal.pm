package Yt2tg::Journal;
use v5.36;
use strict;
use warnings;
use utf8;
use JSON::PP ();

sub find_record {
    my ($file, $video_id) = @_;
    return undef unless defined $file && defined $video_id;
    return undef unless -f $file;

    open my $fh, '<:raw', $file or return undef;
    my $last_match;
    while (my $line = <$fh>) {
        next if $line =~ /^\s*$/;
        my $record = eval { JSON::PP->new->utf8->decode($line) };
        next if $@ || ref($record) ne 'HASH';
        if (defined $record->{video_id} && $record->{video_id} eq $video_id) {
            $last_match = $record;
        }
    }
    close $fh;
    return $last_match;
}

sub append_record {
    my ($file, $record) = @_;
    die "file is required\n" unless defined $file;
    die "record must be a hash reference\n" unless ref($record) eq 'HASH';

    my $json = JSON::PP->new->utf8->canonical->encode($record) . "\n";
    open my $fh, '>>:raw', $file or die "cannot open '$file' for append: $!\n";
    print {$fh} $json;
    close $fh or die "cannot close '$file': $!\n";
    return 1;
}

1;
