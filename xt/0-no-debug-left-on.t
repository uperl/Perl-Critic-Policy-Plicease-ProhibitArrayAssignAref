#!/usr/bin/perl -w

# 0-no-debug-left-on.t -- check EXE_FILES use #!perl for interpreter

# Copyright 2011 Kevin Ryde

# 0-no-debug-left-on.t is shared by several distributions.
#
# 0-no-debug-left-on.t is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# 0-no-debug-left-on.t is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.

require 5;
use strict;

Test::NoDebugLeftOn->Test_More(verbose => 1);
exit 0;

package Test::NoDebugLeftOn;
use strict;
use ExtUtils::Manifest;

sub Test_More {
  my ($class, %options) = @_;
  require Test::More;
  Test::More::plan (tests => 1);
  Test::More::ok ($class->check (diag => \&Test::More::diag,
                                 %options));
  1;
}

sub check {
  my ($class, %options) = @_;
  my $diag = $options{'diag'};
  if (! -e 'Makefile.PL') {
    &$diag ('skip, no Makefile.PL so not ExtUtils::MakeMaker');
    return 1;
  }

  my $href = ExtUtils::Manifest::maniread();
  my @files = keys %$href;

  @files = grep {m{
                    ^lib/
                  |^examples/.*\.pl$
                  |^Makefile.PL$
                  |t/.*\.t$
                }x
              } @files;

  my $good = 1;
  foreach (@files) {
    my $filename = $_;
    if (! open FH, "< $filename") {
      &$diag ("Oops, cannot open $filename: $!");
      $good = 0;
      next;
    }
    my $line;
    while (<FH>) {
      if (/^__END__/) {
        last;
      }
      # only a DEBUG=> a non-zero number is bad, so an expression can copy a
      # debug from another package
      if (/(DEBUG\s*=>\s*[1-9][0-9]*)/
          || /^[ \t]*((use|no) Smart::Comments)/) {
        print STDERR "\n$filename:$.: leftover: $_\n";
        $good = 0;
      }
    }
    if (! close FH) {
      &$diag ("Oops, error closing $filename: $!");
      $good = 0;
      next;
    }
  }
  return $good;
}
