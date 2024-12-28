#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

# This file is part of Perl-Critic-Pulp.
#
# Perl-Critic-Pulp is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Perl-Critic-Pulp is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses/>.


# Pod::Checker

# /usr/lib/perl/5.10.1/Compress/Zlib.pm
# /usr/share/perl/5.10.1/ExtUtils/ParseXS.pm

use 5.005;
use strict;
use warnings;
use Perl6::Slurp;

use lib::abs '.';
use MyLocatePerl;
use MyStuff;
use Text::Tabs ();

my $verbose = 0;

my $l = MyLocatePerl->new;
while (my ($filename, $str) = $l->next) {
  if ($verbose) { print "look at $filename\n"; }

  next if ($filename =~ /\/doc\.pl$/);
  next if ($filename =~ /\/junk\.pl$/);
  next if ($filename =~ /\.t$/);

  #   if ($str =~ /^__END__/m) {
  #     substr ($str, $-[0], length($str), '');
  #   }

  while ($str =~ /(([^\n]+)\n=([a-z][a-z0-9]*)[^\n]*)/sg) {
    my $bad = $1;
    my $pre = $2;
    my $cmd = $3;
    my $pos = pos($str) - length($bad) + length($pre) + 1;

    next if ($cmd eq 'cut');
    next if ($cmd eq 'pod');

    next if $pre =~ /^\s*$/; # whitespace-only ok

    my ($line, $col) = MyStuff::pos_to_line_and_column ($str, $pos);
    print "$filename:$line:$col: no blank before\n$bad\n";
  }
}

exit 0;
