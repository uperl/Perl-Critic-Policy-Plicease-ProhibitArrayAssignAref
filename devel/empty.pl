#!/usr/bin/perl

# Copyright 2008 Kevin Ryde

# This file is part of Perl-Critic-Pulp.
#
# Perl-Critic-Pulp is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 2, or (at your option) any
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
use Data::Dumper;

my @x = 1 .. 5;
my @y = map {1=>2}, @x;
print Dumper(\@y);

@y = map {;1=>2} @x;
print Dumper(\@y);

@y = map {1=>$_}, @x;
print Dumper(\@y);

exit 0;
