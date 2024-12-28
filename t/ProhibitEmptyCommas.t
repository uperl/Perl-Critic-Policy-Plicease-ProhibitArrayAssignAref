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
use Perl::Critic::Policy::ValuesAndExpressions::ProhibitEmptyCommas;
use Test::More tests => 24;
use Perl::Critic;

my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => 'ValuesAndExpressions::ProhibitEmptyCommas');
{ my @p = $critic->policies;
  is (scalar @p, 1,
     'single policy ProhibitEmptyCommas');
}

ok ($Perl::Critic::Policy::ValuesAndExpressions::ProhibitEmptyCommas::VERSION >= 10,
    'VERSION variable');
ok (Perl::Critic::Policy::ValuesAndExpressions::ProhibitEmptyCommas->VERSION  >= 10,
    'VERSION method');

foreach my $data (## no critic (RequireInterpolationOfMetachars)

                  # examples from the POD
                  [ 1, "print 'foo',,'bar';" ],
                  [ 1, '    @a = (,1,2)' ],
                  [ 1, "foo (x, => 123);"    ],
                  [ 1, "a =>=> 456;" ],
                  [ 1, 'for (; $i++<10; $i++,,)' ],
                  [ 1, 'foo (1, , 2)' ],
                  [ 1, 'bar (start =>, end   => 20)' ],
                  [ 1, '@a = (1,,6);' ],
                  [ 0, '@b = (\'foo\',\'bar\',);' ],

                  # reporting each one of a run
                  [ 2, 'a => , => 123' ],

                  # not an operator
                  [ 0, '$x =~ s,abc,,' ],

                  # trailing multiples
                  [ 1, '@a = (1,2,,)' ],
                  [ 1, '@a = (1,2, # foo
                              ,)' ],

                  # start of list
                  [ 1, '@a = ( , 1)' ],
                  [ 1, '@a = ( # foo
                              ,1)' ],
                  [ 2, '@a = (=>=>1,2)' ],

                  # alone in a list
                  # intended to be bad, for now at least
                  [ 1, '@a = (,)' ],

                  # comma in a string not an operator
                  [ 0, '@a = (\',\' , 123)' ],

                  # freaky PPI list compound+expression
                  [ 0, 'return bless({@_}, $class)' ],
                  [ 1, 'return bless(# a comment
                                     , $class)' ],
                  [ 0, 'return bless({@_}
                                     # a comment
                                     , $class)' ],

                  ## use critic
                 ) {
  my ($want_count, $str) = @$data;

  my @violations = $critic->critique (\$str);
  my $got_count = scalar @violations;
  is ($got_count, $want_count, $str);
}

exit 0;
