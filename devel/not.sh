#!/bin/sh

# Copyright 2008, 2009 Kevin Ryde

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

set -x
perl -I ../lib /usr/bin/perlcritic --single-policy=NotWithCompare \
  /usr/share/perl5/XML/SAX/PurePerl/DTDDecls.pm \
  /usr/share/perl5/Test/More.pm \
  /usr/share/perl/5.10.0/Test/More.pm \
  /usr/share/perl/5.10.0/ExtUtils/Liblist/Kid.pm
