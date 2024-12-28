#!/usr/bin/perl

# Copyright 2008 Kevin Ryde

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
use Test::More tests => 45;
use Perl::Critic;
use PPI;

my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => 'ValuesAndExpressions::ConstantBeforeLt');
{ my @p = $critic->policies;
  is (scalar @p, 1);
}

ok ($Perl::Critic::Policy::ValuesAndExpressions::ConstantBeforeLt::VERSION >= 6);
ok (Perl::Critic::Policy::ValuesAndExpressions::ConstantBeforeLt->VERSION  >= 6);

foreach my $data ([ 'use constant' ],
                  [ 'use constant FOO => 123',
                    'FOO' ],
                  [ 'use constant FOO => 123,456',
                    'FOO' ],
                  [ 'use constant FOO => 123,456,789',
                    'FOO' ],

                  [ 'use constant ()' ],
                  [ 'use constant (FOO, 1, BAR, 2)',
                    'FOO' ],
                  [ 'use constant qw(FOO 1 BAR 2)',
                    'FOO' ],

                  [ 'use constant {}' ],
                  [ 'use constant { FOO => 123, BAR => 456 }',
                    'FOO', 'BAR' ],
                  [ 'use constant { FOO => 1+2+3, BAR => 456 }',
                    'FOO', 'BAR' ],
                  [ 'use constant FOO => 123; if (FOO < 123) {}',
                    'FOO' ],

                  [ 'sub FOO { 123; }'],
                  [ 'sub FOO () { 123; }',
                    'FOO'  ],
                  ## no critic (RequireInterpolationOfMetachars)
                  [ 'sub FOO ($) { 123; }' ],
                  ## use critic

                  # these don't parse as PPI::Statement::Sub
                  # [ 'sub { 123; }' ],
                  # [ 'sub () { 123; }' ],
                  # [ 'sub ($) { 123; }' ],

                 ) {
  my ($str, @want_constants) = @$data;

  foreach my $suffix ('', ';') {
    $str .= $suffix;

    my $document = PPI::Document->new (\$str)
      or die "oops, no parse: $str";
    my $elems = ($document->find ('PPI::Statement::Include')
                    || $document->find ('PPI::Statement::Sub')
                    || die "oops, no target statement in '$str'");
    my $elem = $elems->[0] or die "oops, no Include element";
    my @got_constants = Perl::Critic::Policy::ValuesAndExpressions::ConstantBeforeLt::_use_constants ($elem);
    is_deeply (\@got_constants, \@want_constants, $str);
  }
}


# ok stuff
#
foreach my $str (
                 'use constant FOO => 123; if (FOO < 123) {}',
                 'use constant { FOO => 123 }; if (FOO < 123) {}',
                 'use constant { XX => 1+2, FOO => 123 }; if (FOO < 123) {}',
                 'func <*.c>',
                 'require version < 10;',
                 'if (require version < 10) {}',
                 'Foo->bar < 10',
                 'Foo::Bar->quux < 10',
                 'Foo->SUPER::quux < 10',
                 'time < 2e9',
                ) {
  my @violations = $critic->critique (\$str);
  is_deeply (\@violations, [], $str);
}

# not ok stuff
#
foreach my $data ([ 1, 'DBL_MANT_DIG < 10' ],
                  [ 1, 'use constant FOO => 123;
                        FOO < 10;
                        DBL_MANT_DIG < 10' ],
                  [ 2, 'DBL_MANT_DIG < 10; DBL_MANT_DIG < 10' ],

                  # The first FOO here provokes ConstantBeforeLt because
                  # we're only sure of prototyped constant subs from "use
                  # constant".  In practice that first is likely to be a
                  # mistaken placement and will either tickle an error from
                  # "use strict", or a warning about non-numeric from "use
                  # warnings".
                  #
                  [ 1, 'FOO < 10;
                        use constant FOO => 123;
                        FOO < 10' ],
                 ) {
  my ($want_count, $str) = @$data;

  {
    my @violations = $critic->critique (\$str);
    my $got_count = scalar @violations;
    is ($got_count, $want_count, $str);
  }
}

exit 0;
