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
use Perl::Critic::Policy::ValuesAndExpressions::UnexpandedSpecialLiteral;
use Test::More tests => 33;
use Perl::Critic;

my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => 'ValuesAndExpressions::UnexpandedSpecialLiteral');
{ my @p = $critic->policies;
  is (scalar @p, 1,
     'single policy UnexpandedSpecialLiteral');
}

my $want_version = 12;
ok ($Perl::Critic::Policy::ValuesAndExpressions::UnexpandedSpecialLiteral::VERSION >= $want_version, 'VERSION variable');
ok (Perl::Critic::Policy::ValuesAndExpressions::UnexpandedSpecialLiteral->VERSION  >= $want_version, 'VERSION class method');
Perl::Critic::Policy::ValuesAndExpressions::UnexpandedSpecialLiteral->VERSION($want_version);


# confirming what's claimed in the POD and subject to critiquing ...
#
{ my @x = ('MyExtra::'.__PACKAGE__ => 123);
  is_deeply (\@x, [ 'MyExtra::__PACKAGE__', 123 ],
             'list constructor literal on right of a . expression');
}
{ my $hash = { 'Foo'.__FILE__ => 123 };
  my @h = (%$hash);
  is_deeply (\@h, [ 'Foo__FILE__', 123 ],
             'hash constructor literal on right of a . expression');
}


foreach my $data (## no critic (RequireInterpolationOfMetachars)

                  # from the POD
                  [ 1, 'my $seen = { __FILE__ => 1 };' ],
                  [ 1, '$obj->{__PACKAGE__}{myextra} = 123;' ],
                  [ 1, 'my $hash = { \'Foo\'.__FILE__ => 123 };' ],
                  [ 1, 'return (\'MyExtra::\'.__PACKAGE__ => 123);' ],

                  [ 1, '$hash{__PACKAGE__}' ],
                  [ 1, '$hash{__FILE__}' ],
                  [ 1, '$hash{__LINE__}' ],
                  [ 1, '$hash{  __PACKAGE__  }' ],

                  [ 0, '$hash{"__PACKAGE__"}' ],
                  [ 0, '$hash{\'__PACKAGE__\'}' ],
                  [ 0, '$hash{q{__PACKAGE__}}' ],
                  [ 0, '$hash{SOMETHING}' ],
                  [ 0, '$hash{(__PACKAGE__)}}' ],
                  [ 0, '$hash{__PACKAGE__.""}' ],

                  [ 1, '$href = { __PACKAGE__ => 123 }' ],
                  [ 1, '$href = { __FILE__ => 123 }' ],
                  [ 1, '$href = { __LINE__ => 123 }' ],
                  [ 0, '$href = { SOMETHING => 123 }' ],

                  [ 1, '$href = { __PACKAGE__ => 123, FOO => 123 }' ],
                  [ 1, '$href = { FOO => 123, __PACKAGE__ => 123 }' ],
                  [ 1, '$href = { FOO => 123 => __PACKAGE__ => 123 }' ],

                  [ 0, '$href = { __PACKAGE__."x" => 123 }' ],

                  # it's the token immediately left of the => which is
                  # literal, so though __PACKAGE__ is part of a "."
                  # expression it's used literally, not expanded
                  [ 1, '$href = { "x".__PACKAGE__ => 123 }' ],

                  [ 0, '__PACKAGE__' ],
                  [ 0, 'return __PACKAGE__;' ],
                  [ 0, '{__PACKAGE__}' ],
                  [ 0, '{__PACKAGE__; 123}' ],

                  # in a code block return value like this __PACKAGE__ is
                  # still literal, not expanded
                  [ 1, '{; __PACKAGE__ => 123}' ],

                  ## use critic
                 ) {
  my ($want_count, $str) = @$data;
  my @violations = $critic->critique (\$str);
  foreach (@violations) {
    diag ($_->description);
  }
  my $got_count = scalar @violations;
  is ($got_count, $want_count, "str: $str");
}

exit 0;