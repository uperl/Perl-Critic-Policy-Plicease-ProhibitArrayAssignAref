# Copyright 2008, 2009, 2010 Kevin Ryde

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


package Perl::Critic::Policy::ValuesAndExpressions::ProhibitNullStatements;
use 5.006;
use strict;
use warnings;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils;

our $VERSION = 44;


use constant supported_parameters
  => ({ name           => 'allow_perl4_semihash',
        description    => 'Whether to allow Perl 4 style ";#" comments.',
        behavior       => 'boolean',
        default_string => '0',
      });
use constant default_severity => $Perl::Critic::Utils::SEVERITY_MEDIUM;
use constant default_themes   => qw(pulp cosmetic);
use constant applies_to       => 'PPI::Statement::Null';

sub violates {
  my ($self, $elem, $document) = @_;

  # if allow_perl4_semihash then ";# comment ..." ok
  if ($self->{'_allow_perl4_semihash'} && is_perl4_semihash($elem)) {
    return; # ok
  }

  # "for (;;)" is ok, like
  #
  #   PPI::Structure::ForLoop  	( ... )
  #     PPI::Statement::Null
  #       PPI::Token::Structure  	';'
  #     PPI::Statement::Null
  #       PPI::Token::Structure  	';'
  #
  # or the incompatible change in ppi 1.205
  #
  #   PPI::Token::Word         'for'
  #    PPI::Structure::For     ( ... )
  #      PPI::Statement::Null
  #       PPI::Token::Structure        ';'
  #      PPI::Statement::Null
  #       PPI::Token::Structure        ';'

  my $parent = $elem->parent;
  if ($parent->isa('PPI::Structure::For')
      || $parent->isa('PPI::Structure::ForLoop')) {
    return; # ok
  }

  # "map {; ...}" or "grep {; ...}" ok
  if (is_block_disambiguator ($elem)) {
    return; # ok
  }

  # any other PPI::Statement::Null is a bare ";" and is not ok, like
  #
  #   PPI::Statement::Null
  #     PPI::Token::Structure  	';'
  #
  return $self->violation ('Null statement (stray semicolon)',
                           '',
                           $elem);
}

# is_block_disambiguator($elem) takes a PPI::Statement::Null $elem and
# returns true if it's at the start of a "map {; ...}" or "grep {; ...}"
#
# PPI structure like the following, with the Whitespace optional of course,
# and allow comments in there too in case someone wants to write "# force
# block" or something
#
#   PPI::Token::Word    'map'
#   PPI::Token::Whitespace      ' '
#   PPI::Structure::Block       { ... }
#     PPI::Token::Whitespace    ' '
#     PPI::Statement::Null
#       PPI::Token::Structure   ';'
#
sub is_block_disambiguator {
  my ($elem) = @_;

  my $block = $elem->parent;
  $block ->isa('PPI::Structure::Block')
    or return 0;  # not in a block

  # not "sprevious" here, don't want to skip other null statements, just
  # whitespace and comments
  my $prev = $elem->previous_sibling;
  while ($prev && ($prev->isa ('PPI::Token::Whitespace')
                   || $prev->isa ('PPI::Token::Comment'))) {
    $prev = $prev->previous_sibling;
  }
  if ($prev) {
    return 0;  # not at the start of the block
  }

  my $word = $block->sprevious_sibling
    or return 0;   # nothing preceding the block
  $word->isa('PPI::Token::Word')
    or return 0;
  my $content = $word->content;
  return ($content eq 'map' || $content eq 'grep');
}

# is_perl4_semihash($elem) takes a PPI::Statement::Null $elem and returns
# true if it's a Perl 4 style start-of-line ";# comment ..."
#
# When at the very start of a document,
#
#   PPI::Document
#     PPI::Statement::Null
#       PPI::Token::Structure       ';'
#     PPI::Token::Comment   '# foo'
#
# When in the middle,
#
#   PPI::Token::Whitespace        '\n'
#   PPI::Statement::Null
#     PPI::Token::Structure       ';'
#   PPI::Token::Comment   '# hello'
#
sub is_perl4_semihash {
  my ($elem) = @_;

  # must be at the start of the line
  # though not sure about this, the pl2pm program allows whitespace before
  ($elem->location->[1] == 1)
    or return 0;

  # must be immediately followed by a comment
  my $next = $elem->next_sibling;
  return ($next && $next->isa('PPI::Token::Comment'));
}


1;
__END__

=for stopwords addon ie ok boolean Ryde

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitNullStatements - disallow empty statements (stray semicolons)

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
addon.  It prohibits empty statements, ie. bare C<;> semicolons.  This can
be a typo doubling up a semi like

    use Foo;;    # bad

Or a stray left at the end of a control structure like

    if ($foo) {
      print "foo\n";
      return;
    };           # bad

An empty statement is completely harmless, so this policy is only under the
"cosmetic" theme (see L<Perl::Critic/POLICY THEMES>).  It's surprisingly
easy to leave a semi behind when chopping code around, especially when
changing a statement to a loop or a conditional.

=head2 Allowed forms

A C style C<for (;;) { ...}> loop is ok.  Those semicolons are expression
separators and empties are quite usual.

    for (;;) {   # ok
      print "infinite loop\n";
    }

A semicolon at the start of a C<map> or C<grep> block is allowed.  It's
commonly used to ensure Perl parses it as a block, not an anonymous hash.
(Perl decides at the point it parses the C<{>.  A C<;> there forces a block
when it might otherwise guess wrongly.  See L<perlfunc/map> for more on
this.)

    map {; $_, 123} @some_list;      # ok

    grep {# this is a block
          ;                          # ok
          length $_ and $something } @some_list;

The C<map> form is much more common than the C<grep>, but both suffer the
same ambiguity.  C<grep> doesn't normally inspire people to quite such
wildly convoluted forms as C<map> does.

=head1 CONFIGURATION

=over 4

=item C<allow_perl4_semihash> (boolean, default false)

If true then Perl 4 style documentation comments like the following are
allowed.

    ;# Usage: 
    ;#      require 'mypkg.pl';
    ;#      ...

The C<;> must be at the start of the line.  This is fairly outdated, so it's
disabled by default.  If you're crunching through some old code you can
enable it by adding to your F<.perlcriticrc> file

    [ValuesAndExpressions::ProhibitNullStatements]
    allow_perl4_semihash=1

=back

=head1 SEE ALSO

L<Perl::Critic::Pulp>, L<Perl::Critic>

=head1 HOME PAGE

http://user42.tuxfamily.org/perl-critic-pulp/index.html

=head1 COPYRIGHT

Copyright 2008, 2009, 2010 Kevin Ryde

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
