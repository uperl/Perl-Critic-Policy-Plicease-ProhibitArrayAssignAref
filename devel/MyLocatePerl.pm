# Copyright 2009 Kevin Ryde.

# This file is part of miscbits-el.
#
# miscbits-el is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# miscbits-el is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with miscbits-el; see the file COPYING.  Failing that, go to
# <http://www.gnu.org/licenses/>.

package MyLocatePerl;
use 5.006;
use strict;
use warnings;
use base 'File::Locate::Iterator';
use IO::File;
use IO::Uncompress::AnyInflate;
use MyUniqByInode;
use MyUniqByMD5;

use constant DEBUG => 0;

my $compressed_re = qr/\.gz$/;
my $suffixes_re = qr/\.(t|pm|pl|PL)($compressed_re)?$/o;

# glob => '/usr/share/perl5/Debconf/FrontEnd/*'

sub new {
  my ($class) = @_;
  my $self = $class->SUPER::new (globs => ['/bin/*',
                                           '/usr/bin/*',
                                           '/usr/local/bin/*',
                                           '/usr/local/bin2/*'],
                                 regexp => $suffixes_re);
  $self->{'uniq_ino'} = MyUniqByInode->new;
  $self->{'uniq_md5'} = MyUniqByMD5->new;
  return $self;
}

sub next {
  my ($self) = @_;
  for (;;) {
    defined(my $filename = $self->SUPER::next) or return;
    if (DEBUG) { print "consider $filename\n"; }

    next if $filename =~ m{/blib/};

    my $io;
    if ($filename =~ $compressed_re) {
      $io = IO::Uncompress::AnyInflate->new ($filename);
    } else {
      $io = IO::File->new ($filename, 'r');
    }
    $io or next;
    $self->{'uniq_ino'}->uniq($io) or next;

    my $content = _slurp_if_perl ($filename, $io);
    if (DEBUG) { print "  content ", (defined $content ?"ok":"undef"), "\n"; }
    next if ! defined $content;

    $self->{'uniq_md5'}->uniq_str($content) or next;

    return ($filename, $content);
  }
}

sub _slurp_if_perl {
  my ($filename, $io) = @_;
  if (DEBUG) { print "  slurp $io\n"; }

  my $first = '';
  if ($filename !~ $suffixes_re) {
    # file in /bin etc must have #!.../perl
    $io->read($first, 128) or return;
    if (DEBUG) { print "first part $first\n"; }

    if ($first !~ m{^#!([^\r\n]*/|[ \t]*)perl[ \t\r\n]}) {
      if (DEBUG) { print "  no #!perl\n"; }
      return;
    }
  }

  my $rest = do { local $/; $io->getline }; # slurp
  if (! defined $rest) {
    if (DEBUG) { print "  read error: $!\n"; }
    return;
  }
  return $first . $rest;
}
1;
__END__
