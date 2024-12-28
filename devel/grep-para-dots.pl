#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011 Kevin Ryde

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

use strict;
use warnings;
use Perl6::Slurp;

use lib::abs '.';
use MyLocatePerl;
use MyStuff;

my $verbose = 0;

my $l = MyLocatePerl->new (include_pod => 1);
my $p = MyParser->new;
my $count = 0;
my $filename;
while (($filename, my $str) = $l->next) {
  if ($verbose) { print "look at $filename\n"; }
  $p->parse_from_string ($str, $filename);
}
print "total $count\n";

exit 0;

package MyParser;
use base 'Perl::Critic::Pulp::PodParser';
sub textblock {
  my ($self, $text, $linenum, $paraobj) = @_;
  # if ($text =~ /[^.]\.\.\s*$/sg) {
  #   print "$filename:$linenum: end with dots\n";
  #   $count++;
  # }
  # $[. is ok
  # :-(. sad face
  # !. not too bad
  if ($text =~ /[,;\\!?({[<]\.\s*$/sg) {
    print "$filename:$linenum: end with dots\n";
    $count++;
  }
}
