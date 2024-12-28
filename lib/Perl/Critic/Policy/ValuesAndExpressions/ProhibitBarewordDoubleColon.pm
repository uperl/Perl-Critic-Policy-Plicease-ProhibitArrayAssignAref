# Copyright 2010, 2011 Kevin Ryde

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

package Perl::Critic::Policy::ValuesAndExpressions::ProhibitBarewordDoubleColon;
use 5.006;
use strict;
use warnings;
use List::Util;

use base 'Perl::Critic::Policy';
use Perl::Critic::Utils;

use Perl::Critic::Pulp;
use Perl::Critic::Pulp::Utils;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 63;

use constant supported_parameters =>
  ({ name           => 'allow_indirect_syntax',
     description    => 'Whether to allow double-colon in indirect object syntax "new Foo:: arg,arg".',
     behavior       => 'boolean',
     default_string => '1',
   });

use constant default_severity => $Perl::Critic::Utils::SEVERITY_LOWEST;
use constant default_themes   => qw(pulp cosmetic);
use constant applies_to       => 'PPI::Token::Word';

sub violates {
  my ($self, $elem, $document) = @_;

  $elem =~ /::$/ or return;

  if ($self->{'_allow_indirect_syntax'}) {
    if (_word_is_indirect_classname($elem)) {
      return;
    }
  }

  return $self->violation
    ('Use plain string instead of Foo:: bareword',
     '',
     $elem);
}

# $elem is a PPI::Token::Word.
# Return true if it's the class name in an indirect object syntax method call.
#
sub _word_is_indirect_classname {
  my ($elem) = @_;
  ### _word_is_indirect_classname

  my $prev = $elem->sprevious_sibling || return 0;
  ### prev: ref $prev, $prev->content
  $prev->isa('PPI::Token::Word') || return 0;

  # What about "foo bar Foo::"?  Assume its function foo and method bar?
  #
  #   $prev = $prev->sprevious_sibling;
  #   ### prev-prev: ref $prev, $prev->content
  #   if ($prev && $prev->isa('PPI::Token::Word')) { return 0; }

  if (elem_is_comma_operator ($elem->snext_sibling)) { return 0; }
  return 1;
}

# $elem is any PPI::Element.
# return true if it's a comma operator.
#
sub elem_is_comma_operator {
  my ($elem) = @_;
  return ($elem->isa('PPI::Token::Operator')
          && $Perl::Critic::Pulp::Utils::COMMA{$elem});
}

1;
__END__

=for stopwords barewords addon bareword disambiguates ie ProhibitIndirectSyntax runtime boolean Ryde

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitBarewordDoubleColon - don't use Foo:: style barewords

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
addon.  It asks you not to use the double-colon bareword like

    $class = Foo::Bar::;     # bad

but instead a plain string

    $class = 'Foo::Bar';     # ok

This is intended as a building block for a restricted coding style, or a
matter of personal preference if you think the C<::> is a bit obscure and
that it's clearer to write a string when you mean a string.  On that basis
the policy is lowest priority and under the "cosmetic" theme (see
L<Perl::Critic/POLICY THEMES>).

=head2 Indirect Object Syntax

By default a double-colon is allowed in the indirect object syntax (see
L<perlobj/Indirect Object Syntax>).

    my $obj = new Foo::Bar:: $arg1,$arg2;   # ok

This is because C<::> there is important to disambiguate a class name
C<Foo::Bar> from a function C<Foo::Bar()>, ie. function C<Bar()> in package
C<Foo>.

Whether you actually want indirect object syntax is a matter for other
policies, like
L<ProhibitIndirectSyntax|Perl::Critic::Policy::Objects::ProhibitIndirectSyntax>.
If you don't want the double-colon bareword then switch to arrow style
C<< Foo::Bar->new($arg,...) >>.

=head2 Double-Colon Advantages

The C<::> bareword is for package names, not general bareword quoting.  If
there's no such package at compile time a warning is given (see
L<perldiag/Bareword "%s" refers to nonexistent package>)

    my $class = No::Such::Package::;  # perl warning

This warning can help pick up typos, though it can't know if a package will
be loaded at runtime and so will fire wrongly in that case.  For reference,
a warning isn't given for the indirect object syntax, which rather limits
its benefit.

=head2 Disabling

If you don't care about this you can always disable
C<ProhibitBarewordDoubleColon> from your F<.perlcriticrc> in the usual way
(see L<Perl::Critic/CONFIGURATION>),

    [-ValuesAndExpressions::ProhibitBarewordDoubleColon]

=head1 CONFIGURATION

=over 4

=item C<allow_indirect_syntax> (boolean, default true)

If true then allow double-colon in the indirect object syntax as shown
above.  If false then report double-colons everywhere as violations

    # bad under allow_indirect_syntax=false
    my $obj = new Foo::Bar:: $arg1,$arg2;

This can be controlled from your F<~/.perlcriticrc> in the usual way.  For
example

    [ValuesAndExpressions::ProhibitBarewordDoubleColon]
    allow_indirect_syntax=no

=back

=head1 SEE ALSO

L<Perl::Critic::Pulp>,
L<Perl::Critic>,
L<Perl::Critic::Policy::Objects::ProhibitIndirectSyntax>

L<perl5005delta/"C<Foo::> can be used as implicitly quoted package name">

=head1 HOME PAGE

http://user42.tuxfamily.org/perl-critic-pulp/index.html

=head1 COPYRIGHT

Copyright 2010, 2011 Kevin Ryde

Perl-Critic-Pulp is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Perl-Critic-Pulp is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses>.

=cut
