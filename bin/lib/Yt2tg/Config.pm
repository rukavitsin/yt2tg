package Yt2tg::Config;
use v5.36;
use strict;
use warnings;
use Encode qw(decode FB_CROAK);

sub load {
    my (%opts) = @_;
    my $home = $opts{home} // $ENV{HOME} // '';

    my %config;

    my $tgrc = "$home/.tgrc";
    if (-f $tgrc) {
        my $data = _read_file($tgrc);
        my $parsed = _parse_env_file($data);
        $config{tg_token}   = $parsed->{TG_TOKEN}   if exists $parsed->{TG_TOKEN};
        $config{tg_chat_id} = $parsed->{TG_CHAT_ID} if exists $parsed->{TG_CHAT_ID};
        $config{tp_token}   = $parsed->{TP_TOKEN}   if exists $parsed->{TP_TOKEN};
        $config{tg_url}     = $parsed->{TG_URL}     if exists $parsed->{TG_URL};
        $config{tp_url}     = $parsed->{TP_URL}     if exists $parsed->{TP_URL};
    }

    my $geminirc = "$home/.geminirc";
    if (-f $geminirc) {
        my $data = _read_file($geminirc);
        my $parsed = _parse_env_file($data);
        $config{gemini_api_key} = $parsed->{GEMINI_API_KEY} if exists $parsed->{GEMINI_API_KEY};
        $config{url_gemini}     = $parsed->{URL_GEMINI}     if exists $parsed->{URL_GEMINI};
    }

    return \%config;
}

sub _read_file {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot open '$path': $!";
    my $bytes = do { local $/; <$fh> };
    close $fh or die "cannot close '$path': $!";
    return decode('UTF-8', $bytes, FB_CROAK);
}

sub _parse_env_file {
    my ($text) = @_;
    my %vars;
    for my $line (split /
/, $text) {
        $line =~ s/\s+\z//;
        next if $line =~ /\A\s*\z/;
        next if $line =~ /\A\s*#/;
        if ($line =~ /\A([A-Za-z_][A-Za-z0-9_]*)=(.*)\z/) {
            my $key = $1;
            my $val = $2;
            $val =~ s/\A["']//;
            $val =~ s/["']\z//;
            $vars{$key} = $val;
        }
    }
    return \%vars;
}
1;
