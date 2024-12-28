#!/usr/bin/perl

# Copyright 2008, 2009 Kevin Ryde

# This file is part of Perl-Critic-Pulp.
#
# Perl-Critic-Pulp is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Perl-Critic-Pulp is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use Perl::Critic::Policy::Documentation::ProhibitBadAproposMarkup;
use Test::More tests => 13;
use Perl::Critic;

#------------------------------------------------------------------------------
my $want_version = 25;
cmp_ok ($Perl::Critic::Policy::Documentation::ProhibitBadAproposMarkup::VERSION,
        '>=', $want_version, 'VERSION variable');
cmp_ok (Perl::Critic::Policy::Documentation::ProhibitBadAproposMarkup->VERSION,
        '>=', $want_version, 'VERSION class method');
{
  ok (eval { Perl::Critic::Policy::Documentation::ProhibitBadAproposMarkup->VERSION($want_version); 1 }, "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Perl::Critic::Policy::Documentation::ProhibitBadAproposMarkup->VERSION($check_version); 1 }, "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => 'Documentation::ProhibitBadAproposMarkup');
{ my @p = $critic->policies;
  is (scalar @p, 1,
      'single policy ProhibitBadAproposMarkup');

  my $policy = $p[0];
  ok (eval { $policy->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $policy->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

foreach my $data (
                  [ 1, "=head1 NAME\n\nfoo - like C<bar>" ],
                  [ 1, "=head1 NAME \n\nfoo - like C<bar>" ],
                  [ 1, "=head1 \tNAME\t \n\nfoo - like C<bar>" ],

                  [ 0, "=head1 NAME\n\nfoo - like B<bar>" ],
                  [ 0, ("=head1 NAME\n\nfoo - like bar\n\n"
                        . "=head1 NEWSECT\n\nfoo - like C<bar>\n\n") ],

                  [ 0, "=head1 NAME OTHER\n\nfoo - like C<bar>\n" ],
                 ) {
  my ($want_count, $str) = @$data;
  $str = "$str";

  my @violations = $critic->critique (\$str);
  foreach (@violations) {
    diag ($_->description);
  }
  my $got_count = scalar @violations;
  is ($got_count, $want_count, "str: '$str'");
}

exit 0;
