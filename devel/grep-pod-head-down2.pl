#!/usr/bin/perl -w

# Copyright 2013 Kevin Ryde

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


use 5.005;
use strict;
use warnings;
use Tie::IxHash;

use lib::abs '.';
use MyLocatePerl;
use MyStuff;

# uncomment this to run the ### lines
# use Smart::Comments;

my $verbose = 0;
my $scope = 'nest';

my $l = MyLocatePerl->new (exclude_t => 1,
                           include_pod => 1,
                           under_directory => '/usr/share/perl5',
                          );
while (my ($filename, $str) = $l->next) {
  if ($verbose) { print "look at $filename\n"; }

  my $prev_level = 0;
  while ($str =~ /^=head(\d+)\s+(.*?)\s*$/mg) {
    my $level = $1;
    my $name = $2;
    my $pos = $-[0];

    if ($level > $prev_level + 1) {
      my ($line, $col) = MyStuff::pos_to_line_and_column ($str, $pos);
      my $s = MyStuff::line_at_pos($str, $pos);
      print "$filename:$line:$col: descend $prev_level -> $level\n  $s";
      print "\n";
    }

    $prev_level = $level;
  }
  # exit 0;

  # my %seen;
  # tie %seen, 'Tie::IxHash';
  # while (my ($name, $aref) = each %seen) {
  #   if (@$aref > 1) {
  #     foreach my $pos (@$aref) {
  #       my ($line, $col) = MyStuff::pos_to_line_and_column ($str, $pos);
  #       my $s = MyStuff::line_at_pos($str, $pos);
  #       print "$filename:$line:$col: duplicate heading\n  $s";
  #     }
  #   }
  # }
}

exit 0;

=head1 FOO

=head2 Dup

=head2 Dup

=head1 BAR

=head2 Dup
