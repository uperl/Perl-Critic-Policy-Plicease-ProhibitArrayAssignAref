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
use Perl::Critic::Policy::Documentation::RequireEndBeforeLastPod;
use Test::More tests => 16;
use Perl::Critic;

my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => 'Documentation::RequireEndBeforeLastPod');
{ my @p = $critic->policies;
  is (scalar @p, 1,
     'single policy RequireEndBeforeLastPod');
}

ok ($Perl::Critic::Policy::Documentation::RequireEndBeforeLastPod::VERSION >= 10,
    'VERSION variable');
ok (Perl::Critic::Policy::Documentation::RequireEndBeforeLastPod->VERSION  >= 10,
    'VERSION method');

# ^Z is equivalent to __END__, but don't exercise that because PPI 1.204
# doesn't support it
#
foreach my $data (## no critic (RequireInterpolationOfMetachars)

                  # examples from the POD
                  [ 0, '
program_code();

1;
__END__

=head1 NAME
...' ],

#---------------------------------
                  [ 0, '1;' ],
                  [ 0, '__END__' ],
                  [ 0, '' ],

#---------------------------------
# end with code
                  [ 0, '
=head2 Foo

=cut

1;' ],

#---------------------------------
# end with pod
                  [ 1, '
1;

=head2 Foo
' ],


#---------------------------------
# with an __END__
                  [ 0, '
__END__

# comment

=head2 Foo
' ],

#---------------------------------
# with an __END__ and comment
                  [ 0, '
__END__

=head2 Foo

=cut

# comment
' ],

#---------------------------------
# end with comments
                  [ 0, '
=head2 Foo

=cut

# comment1

# comment2
' ],

#---------------------------------
# no code, but some comments
                  [ 0, '
=head2 Foo

=cut

# comment

=head2 Bar

=cut
' ],

#---------------------------------
# bad, with a final comments
                  [ 1, '
code;

=head2 Foo

=cut

# comment
' ],

#---------------------------------
# bad, with a comment in between
                  [ 1, '
code;
# comment

=head2 Foo

=cut
' ],

#---------------------------------
# with __DATA__ instead is ok
                  [ 0, '
code;

=head2 Foo

=cut

__DATA__
something
' ],

#---------------------------------
                  ## use critic
                 ) {
  my ($want_count, $str) = @$data;

  my @violations = $critic->critique (\$str);
  my $got_count = scalar @violations;
  is ($got_count, $want_count, $str);
}

exit 0;
