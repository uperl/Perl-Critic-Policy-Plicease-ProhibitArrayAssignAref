# Copyright 2009 Kevin Ryde

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


package Perl::Critic::Policy::Miscellanea::TextDomainUnused;
use strict;
use warnings;

use base 'Perl::Critic::Policy';
use Perl::Critic::Utils qw(:severities
                           is_function_call);

our $VERSION = 16;

use constant DEBUG => 0;

sub supported_parameters { return; }
sub default_severity { return $SEVERITY_LOW;   }
sub default_themes   { return qw(pulp cosmetic);      }
sub applies_to       { return 'PPI::Document';  }

sub violates {
  my ($self, $elem, $document) = @_;

  my $use = _find_use_locale_textdomain($document) || return;
  if (_any_calls_locale_textdomain($document))   { return; }
  if (_any_vars_locale_textdomain($document))    { return; }
  if (_any_strings_locale_textdomain($document)) { return; }

  return $self->violation
          ('Locale::TextDomain imported, but none of its functions used',
           '',
           $use);
}

# return a PPI::Statement::Include which is a "use" or "require" of
# Locale::TextDomain, or return false if there's no such
sub _find_use_locale_textdomain {
  my ($document) = @_;
  my $aref = $document->find ('PPI::Statement::Include')
    || return; # if no includes at all
  return List::Util::first { $_->type ne 'no'
                               && ($_->module||'') eq 'Locale::TextDomain'
                             } @$aref;
}

my %funcs = (__   => 1,
             __n  => 1,
             __nx => 1,
             __x  => 1,
             __xn => 1,
             N__  => 1,
             N__n => 1);
# and also as full "Locale::TextDomain::..."
foreach (keys %funcs) {
  $funcs{"Locale::TextDomain::$_"} = 1;
}

# return true if $document has any of the Locale::TextDomain functions used,
# like __() etc
sub _any_calls_locale_textdomain {
  my ($document) = @_;
  my $aref = $document->find ('PPI::Token::Word')
    || return; # if no word tokens at all
  return List::Util::first { $funcs{$_->content}
                               && is_function_call($_)
                             } @$aref;
}

## no critic (RequireInterpolationOfMetachars)
my %vars = ('$__' => 1,
            '%__' => 1);
## use critic

sub _any_vars_locale_textdomain {
  my ($document) = @_;
  my $aref = $document->find ('PPI::Token::Symbol')
    || return; # if no symbols at all
  return List::Util::first { $vars{$_->symbol} } @$aref;
}
sub _any_strings_locale_textdomain {
  my ($document) = @_;
  my $aref = $document->find ('PPI::Token::Quote')
    || return; # if no strings at all
  return List::Util::first { ($_->isa('PPI::Token::Quote::Interpolate')
                               || $_->isa('PPI::Token::Quote::Double'))
                               && $_->string =~ /\$__(\W|$)/ } @$aref;
}

1;
__END__

=head1 NAME

Perl::Critic::Policy::Miscellanea::TextDomainUnused - check for Locale::TextDomain imported but unused

=head1 DESCRIPTION

This policy is part of the Perl::Critic::Pulp addon.  It reports when you
include L<C<Locale::TextDomain>|Locale::TextDomain> like

    use Locale::TextDomain ('MyMessageDomain');

but then don't use one of its functions or variables

    __ __n __nx __x __xn
    N__ N__n
    %__ $__

C<Locale::TextDomain> is unnecessary in that case, but it's also not
actively harmful so this policy is only low priority and under the
C<cosmetic> theme (see L<Perl::Critic/POLICY THEMES>).

The check is good if you've got C<Locale::TextDomain> as boilerplate code in
most of your program, but in some modules it's not used.  You might want to
remove it entirely from non-interactive modules, or comment it out from
modules which might have messages but don't yet.  The best thing picked up
is when your boilerplate has got into a programmatic module which shouldn't
say anything at the user level.

The saving from removing unused C<Locale::TextDomain> is modest, just some
imports and a hash entry recording the textdomain for the package.  It's
easy to imagine a general kind of "module imported but unused", but in
practice its hard for perlcritic to know the automatic imports of every
module, and quite a few modules have side-effects, so this TextDomainUnused
just starts with one case of an unused include.

=head2 Interpolated Variables

The variables C<%__> and C<$__> are recognised in double-quote interpolated
strings just by looking for a C<$__> somewhere in the string, eg.

    print "*** $__{'A Message'} ***\n";  # ok

It's not hard to trick the recognition with escapes, or a hash slice style,
but in general taking any C<$__> to be a TextDomain use is close enough.
(Perhaps in the future PPI will do a full parse of interpolated
expressions.)

=head1 SEE ALSO

L<Perl::Critic::Pulp>, L<Perl::Critic>, L<Locale::TextDomain>,
L<Perl::Critic::Policy::Miscellanea::TextDomainPlaceholders>

=head1 HOME PAGE

L<http://www.geocities.com/user42_kevin/perl-critic-pulp/index.html>

=head1 COPYRIGHT

Copyright 2009 Kevin Ryde

Perl-Critic-Pulp is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Perl-Critic-Pulp is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Perl-Critic-Pulp.  If not, see L<http://www.gnu.org/licenses>.

=cut
