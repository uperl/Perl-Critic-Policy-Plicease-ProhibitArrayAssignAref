# Copyright 2010, 2011 Kevin Ryde

# This file is part of Perl-Critic-Pulp.

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

package Perl::Critic::Pulp::PodParser;
use 5.006;
use strict;
use warnings;
use Perl::Critic::Pulp::Utils;
use base 'Pod::Parser';

our $VERSION = 55;

# uncomment this to run the ### lines
#use Smart::Comments;

sub new {
  my $class = shift;
  ### Pulp-PodParser new()
  my $self = $class->SUPER::new(@_, violations => []);
  $self->errorsub ('error_handler'); # method name
  return $self;
}
sub error_handler {
  my ($self, $errmsg) = @_;
  return 1;  # error handled

  # Don't think it's the place of this policy to report pod parse errors.
  # Maybe within sections a policy is operating on, on the basis that could
  # affect the goodness of its checks, but better leave it all to podchecker
  # or other perlcritic policies.
  #
  #   my $policy = $self->{'policy'};
  #   my $elem   = $self->{'elem'};
  #   push @{$self->{'violations'}},
  #     $policy->violation ("Pod::Parser $errmsg", '', $elem);
}

sub parse_from_elem {
  my ($self, $elem) = @_;
  ### Pulp-PodParser parse_from_elem(): ref($elem)
  my $elems = ($elem->can('find')
               ? $elem->find ('PPI::Token::Pod')
               : [ $elem ])
    || return;  # find() returns false if nothing found
  foreach my $pod (@$elems) {
    ### pod chunk at linenum: $pod->line_number
    $self->{'elem'} = $pod;
    $self->parse_from_string ($pod->content);
  }
}

# this is generic except for holding onto $str ready for violation override
sub parse_from_string {
  my ($self, $str) = @_;
  $self->{'str'} = $str;
  require IO::String;
  my $fh = IO::String->new ($str);
  $self->parse_from_filehandle ($fh);
}

sub violation_at_linenum {
  my ($self, $message, $linenum) = @_;
  ### violation on elem: ref($self->{'elem'})

  my $policy = $self->{'policy'};
  ### policy: ref($policy)
  my $violation = $policy->violation ($message, '', $self->{'elem'});

  # fix dodgy Perl::Critic::Policy 1.108 violation() ending up with caller
  # package not given $policy
  if ($violation->policy eq __PACKAGE__
      && defined $violation->{'_policy'}
      && $violation->{'_policy'} eq __PACKAGE__) {
    $violation->{'_policy'} = ref($policy);
  }

  Perl::Critic::Pulp::Utils::_violation_override_linenum
      ($violation, $self->{'str'}, $linenum);
  ### $violation
  push @{$self->{'violations'}}, $violation;
}

sub violation_at_linenum_and_textpos {
  my ($self, $message, $linenum, $text, $pos) = @_;
  ### violation_at_linenum_and_textpos()
  ### $message
  ### $linenum
  ### $pos

  my $part = substr($text,0,$pos);
  $linenum += ($part =~ tr/\n//);
  $self->violation_at_linenum ($message, $linenum);
}

# return list of violation objects (possibly empty)
sub violations {
  my ($self) = @_;
  return @{$self->{'violations'}};
}

use constant command => '';
use constant verbatim => '';
use constant textblock => '';


1;
__END__

=for stopwords perlcritic Ryde

=head1 NAME

Perl::Critic::Pulp::PodParser - shared POD parsing code for the Pulp perlcritic add-on

=head1 SYNOPSIS

 use base 'Perl::Critic::Pulp::PodParser';

=head1 DESCRIPTION

This is only meant for internal use yet.

It's some shared parse-from-element, error suppression, no output, violation
accumulation and violation linenum things for POD parsing in policies.

=head1 SEE ALSO

L<Perl::Critic::Pulp>

=head1 HOME PAGE

http://user42.tuxfamily.org/perl-critic-pulp/index.html

=head1 COPYRIGHT

Copyright 2008, 2009, 2010, 2011 Kevin Ryde

Perl-Critic-Pulp is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Perl-Critic-Pulp is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses/>.

=cut
