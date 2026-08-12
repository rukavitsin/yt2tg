# Installation

## Layout principle

Modules live in bin/lib, next to the executables. Installing means
copying a single directory; scripts and modules stay version-locked.

## Requirements

Runtime:

- Perl >= 5.36 with core modules: JSON::PP, Encode, HTTP::Tiny,
  Getopt::Long, IPC::Open2, FindBin
- POSIX sh (dash) for the orchestrator

Optional:

- IO::Socket::SSL and Net::SSLeay for HTTPS publishing
- cmark for markdown conversion (tgph-md2content)
- curl for manual smoke checks only

Debian/Ubuntu packages:

    apt install perl make cmark
    apt install libio-socket-ssl-perl libnet-ssleay-perl

## Install from source

    make install                          # system-wide (/usr/local)
    make install PREFIX=$HOME/.local      # user-local
    make install DESTDIR=pkg PREFIX=/usr  # packaging

Only bin/ is created inside the prefix (modules ride along in
bin/lib). Add the prefix bin to PATH if needed:

    export PATH="$HOME/.local/bin:$PATH"

No-make deploy also works:

    cp -a bin /opt/tgph-bin
    export PATH="/opt/tgph-bin:$PATH"

## Uninstall

    make uninstall [PREFIX=...]

## Environment

~/.tgrc, sourced by pubtgph:

    TP_TOKEN="your_telegra_ph_access_token"
    TP_URL="https://api.telegra.ph"

Environment override understood by tgph-publish:

    TGPH_ACCESS_TOKEN

Tokens are never printed; dry-run masks them as ***.

## Verify

    tgph-measure --version
    printf '%s' '["a"]' | tgph-validate
    pubtgph --help
