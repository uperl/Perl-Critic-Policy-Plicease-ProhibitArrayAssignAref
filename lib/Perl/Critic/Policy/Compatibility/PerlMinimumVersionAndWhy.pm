# Copyright 2009, 2010, 2011 Kevin Ryde

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

package Perl::Critic::Policy::Compatibility::PerlMinimumVersionAndWhy;
use 5.006;
use strict;
use warnings;
use version;

# 1.208 for PPI::Token::QuoteLike::Regexp get_modifiers()
use PPI 1.208;

# 1.084 for Perl::Critic::Document highest_explicit_perl_version()
use Perl::Critic::Policy 1.084;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils qw(parse_arg_list);
use Perl::Critic::Pulp::Utils;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 52;

use constant supported_parameters =>
  ({ name        => 'above_version',
     description => 'Check only things above this version of Perl.',
     behavior    => 'string',
     parser      => \&Perl::Critic::Pulp::Utils::parameter_parse_version,
   },
   { name        => 'skip_checks',
     description => 'Version checks to skip (space separated list).',
     behavior    => 'string',
   });
use constant default_severity => $Perl::Critic::Utils::SEVERITY_LOW;
use constant default_themes   => qw(pulp compatibility);
use constant applies_to       => 'PPI::Document';


sub initialize_if_enabled {
  my ($self, $config) = @_;
  # ask that Perl::MinimumVersion is available and still has its
  # undocumented %CHECKS to mangle below
  eval { require Perl::MinimumVersion;
         scalar %Perl::MinimumVersion::CHECKS }
    or return 0;

  _setup_extra_checks();
}

sub violates {
  my ($self, $document) = @_;
  ### $self

  my %skip_checks;
  if (defined (my $skip_checks = $self->{_skip_checks})) {
    @skip_checks{split / /, $self->{_skip_checks}} = (); # hash slice
  }

  my $pmv = Perl::MinimumVersion->new ($document);
  my $config_above_version = $self->{'_above_version'};
  my $explicit_version = $document->highest_explicit_perl_version;

  my @violations;
  foreach my $check (sort keys %Perl::MinimumVersion::CHECKS) {
    next if exists $skip_checks{$check};
    next if $check eq '_constant_hash'; # better by ConstantPragmaHash
    # next if $check =~ /_pragmas$/;  # usually impossible in earlier
    next if $check =~ /_modules$/;  # wrong for dual-life stuff

    my $check_version = $Perl::MinimumVersion::CHECKS{$check};
    next if (defined $explicit_version
             && $check_version <= $explicit_version);
    next if (defined $config_above_version
             && $check_version <= $config_above_version);
    ### $check

    my $elem = do {
      no warnings 'redefine';
      local *PPI::Node::find_any = \&PPI::Node::find_first;
      $pmv->$check
    } || next;
    #     require Data::Dumper;
    #     print Data::Dumper::Dumper($elem);
    #     print $elem->location,"\n";
    push @violations,
      $self->violation ("$check requires $check_version",
                        '',
                        $elem);
  }
  return @violations;
}

#---------------------------------------------------------------------------
# Crib note: $document->find_first wanted func returning undef means the
# element is unwanted and also don't descend into its sub-elements.
#

sub _setup_extra_checks {

  # 5.10.0
  my $v5010 = version->new('5.010');
  unless (eval { Perl::MinimumVersion->VERSION(1.28); 1 }) {
    # fixed in 1.28 up
    $Perl::MinimumVersion::CHECKS{_Pulp__5010_magic__fix}     = $v5010;
    $Perl::MinimumVersion::CHECKS{_Pulp__5010_operators__fix} = $v5010;
  }
  $Perl::MinimumVersion::CHECKS{_Pulp__5010_qr_m_propagate_properly} = $v5010;

  # 5.8.0
  my $v5008 = version->new('5.008');
  $Perl::MinimumVersion::CHECKS{_Pulp__fat_comma_across_newline} = $v5008;

  # 5.6.0
  my $v5006 = version->new('5.006');
  $Perl::MinimumVersion::CHECKS{_Pulp__exists_subr}       = $v5006;
  $Perl::MinimumVersion::CHECKS{_Pulp__exists_array_elem} = $v5006;
  $Perl::MinimumVersion::CHECKS{_Pulp__delete_array_elem} = $v5006;
  $Perl::MinimumVersion::CHECKS{_Pulp__0b_number}         = $v5006;

  # 5.005
  my $v5005 = version->new('5.005');
  unless (exists
          $Perl::MinimumVersion::CHECKS{_bareword_ends_with_double_colon}) {
    # adopted into Perl::MinimumVersion 1.28
    $Perl::MinimumVersion::CHECKS{_Pulp__bareword_double_colon} = $v5005;
  }

  # 5.004
  my $v5004 = version->new('5.004');
  $Perl::MinimumVersion::CHECKS{_Pulp__special_literal__PACKAGE__} = $v5004;
  $Perl::MinimumVersion::CHECKS{_Pulp__use_version_number}         = $v5004;
  $Perl::MinimumVersion::CHECKS{_Pulp__for_loop_variable_using_my} = $v5004;
  $Perl::MinimumVersion::CHECKS{_Pulp__arrow_coderef_call}         = $v5004;
  $Perl::MinimumVersion::CHECKS{_Pulp__sysseek_builtin}            = $v5004;

  # pack()/unpack()
  $Perl::MinimumVersion::CHECKS{_Pulp__pack_format_5004} = $v5004;
  $Perl::MinimumVersion::CHECKS{_Pulp__pack_format_5006} = $v5006;
  $Perl::MinimumVersion::CHECKS{_Pulp__pack_format_5008} = $v5008;
  $Perl::MinimumVersion::CHECKS{_Pulp__pack_format_5010} = $v5010;
}

{
  # Perl::MinimumVersion prior to 1.28 had 'PPI::Token::Operator' and
  # 'PPI::Token::Magic' swapped between the respective operator/magic tests

  package Perl::MinimumVersion;
  use vars qw(%MATCHES);
  sub _Pulp__5010_operators__fix {
    shift->Document->find_first
      (sub {
         $_[1]->isa('PPI::Token::Operator')
           and
             $MATCHES{_perl_5010_operators}->{$_[1]->content}
           } );
  }
  sub _Pulp__5010_magic__fix {
    shift->Document->find_first
      (sub {
         $_[1]->isa('PPI::Token::Magic')
           and
             $MATCHES{_perl_5010_magic}->{$_[1]->content}
           } );
  }
}

sub Perl::MinimumVersion::_Pulp__5010_qr_m_propagate_properly {
  my ($pmv) = @_;
  ### _Pulp__5010_qr_m_propagate_properly check
  $pmv->Document->find_first
    (sub {
       my ($document, $elem) = @_;
       $elem->isa('PPI::Token::QuoteLike::Regexp') || return 0;
       my %modifiers = $elem->get_modifiers;
       ### content: $elem->content
       ### modifiers: \%modifiers
       return ($modifiers{'m'} ? 1 : 0);
     });
}

#-----------------------------------------------------------------------------
# foo \n => fat comma across newline new in 5.8.0
# extra code in 5.8 toke.c under comment "not a keyword" checking for =>
#

# =item *
# 
# C<word [newline] =E<gt>> fat comma quoting across newline new in Perl 5.8.


sub Perl::MinimumVersion::_Pulp__fat_comma_across_newline {
  my ($pmv) = @_;
  ### _Pulp__fat_comma_across_newline check
  $pmv->Document->find_first
    (sub {
       my ($document, $elem) = @_;
       ### elem: "$elem"
       if ($elem->isa('PPI::Token::Operator')
           && $elem->content eq '=>') {
         my ($prev, $saw_newline) = sprevious_sibling_and_newline($elem);
         ### prev: "$prev"
         ### $saw_newline
         if ($saw_newline
             && $prev
             && $prev->isa('PPI::Token::Word')
             && $prev !~ /^-/   # -foo self-quotes
             && ! Perl::Critic::Utils::is_method_call($prev)) { # ->foo
           return 1; # found
         }
       }
       return 0; # continue searching
     });
}

sub sprevious_sibling_and_newline {
  my ($elem) = @_;
  ### sprevious_sibling_and_newline()
  my $saw_newline;
  for (;;) {
    $elem = $elem->previous_sibling || last;
    if ($elem->isa('PPI::Token::Whitespace')) {
      $saw_newline ||= ($elem->content =~ /\n/);
    } elsif ($elem->isa('PPI::Token::Comment')) {
      $saw_newline = 1;
    } else {
      last;
    }
  }
  return ($elem, $saw_newline);
}

#-----------------------------------------------------------------------------

# delete $array[0] and exists $array[0] new in 5.6.0
# two functions so the "exists" or "delete" appears in the check name
#
sub Perl::MinimumVersion::_Pulp__exists_array_elem {
  my ($pmv) = @_;
  ### _Pulp__exists_array_elem check
  return _exists_or_delete_array_elem ($pmv, 'exists');
}
sub Perl::MinimumVersion::_Pulp__delete_array_elem {
  my ($pmv) = @_;
  ### _Pulp__delete_array_elem check
  return _exists_or_delete_array_elem ($pmv, 'delete');
}
sub _exists_or_delete_array_elem {
  my ($pmv, $which) = @_;
  $pmv->Document->find_first
    (sub {
       my ($document, $elem) = @_;
       if ($elem->isa('PPI::Token::Word')
           && $elem eq $which
           && Perl::Critic::Utils::is_function_call($elem)
           && ($elem = _symbol_or_list_symbol($elem->snext_sibling))
           && $elem->symbol_type eq '@') {
         return 1;
       } else {
         return 0;
       }
     });
}

# exists(&subr) new in 5.6.0
#
sub Perl::MinimumVersion::_Pulp__exists_subr {
  my ($pmv) = @_;
  ### _Pulp__exists_subr check
  $pmv->Document->find_first
    (sub {
       my ($document, $elem) = @_;
       if ($elem->isa('PPI::Token::Word')
           && $elem eq 'exists'
           && Perl::Critic::Utils::is_function_call($elem)
           && ($elem = _symbol_or_list_symbol($elem->snext_sibling))
           && $elem->symbol_type eq '&') {
         return 1;
       } else {
         return 0;
       }
     });
}

# 0b110011 binary literals new in 5.6.0
#
sub Perl::MinimumVersion::_Pulp__0b_number {
  my ($pmv) = @_;
  ### _Pulp__0b_number check
  $pmv->Document->find_first
    (sub {
       my ($document, $elem) = @_;
       if ($elem->isa('PPI::Token::Number::Binary')) {
         return 1;
       } else {
         return 0;
       }
     });
}

#-----------------------------------------------------------------------------
# Foo::Bar:: bareword new in 5.005
# generally a compile-time syntax error in 5.004
#
sub Perl::MinimumVersion::_Pulp__bareword_double_colon {
  my ($pmv) = @_;
  ### _Pulp__bareword_double_colon check
  $pmv->Document->find_first
    (sub {
       my ($document, $elem) = @_;
       if ($elem->isa('PPI::Token::Word')
           && $elem =~ /::$/) {
         return 1;
       } else {
         return 0;
       }
     });
}

sub Perl::MinimumVersion::_Pulp__pack_format_5004 {
  my ($pmv) = @_;
  # w - BER integer
  return _pack_format ($pmv, qr/w/);
}
sub Perl::MinimumVersion::_Pulp__pack_format_5006 {
  my ($pmv) = @_;
  # Z - asciz
  # q - signed quad
  # Q - unsigned quad
  # ! - native size
  # / - counted string
  # # - comment
 return _pack_format ($pmv, qr{[ZqQ!/#]});
}
sub Perl::MinimumVersion::_Pulp__pack_format_5008 {
  my ($pmv) = @_;
  # F - NV
  # D - long double
  # j - IV
  # J - UV
  # ( - group
  return _pack_format ($pmv, qr/[FDjJ(]/);
}
sub Perl::MinimumVersion::_Pulp__pack_format_5010 {
  my ($pmv) = @_;
  # < - little endian
  # > - big endian
  return _pack_format ($pmv, qr/[<>]/);
}

my %pack_func = (pack => 1, unpack => 1);
sub _pack_format {
  my ($pmv, $regexp) = @_;
  require Perl::Critic::Policy::Miscellanea::TextDomainPlaceholders;
  $pmv->Document->find_first
    (sub {
       my ($document, $elem) = @_;

       $elem->isa ('PPI::Token::Word') || return 0;
       $pack_func{$elem->content} || return 0;
       Perl::Critic::Utils::is_function_call($elem) || return 0;

       my @args = parse_arg_list ($elem);
       my $format_arg = $args[0];
       ### format: @$format_arg

       my ($str, $any_vars) = Perl::Critic::Policy::Miscellanea::TextDomainPlaceholders::_arg_string ($format_arg);
       ### $str
       ### $any_vars

       if ($any_vars) { return 0; }
       return ($str =~ $regexp);
     });
}

# 5.004 new __PACKAGE__
#
sub Perl::MinimumVersion::_Pulp__special_literal__PACKAGE__ {
  my ($pmv) = @_;
  ### _Pulp__special_literal__PACKAGE__
  $pmv->Document->find_first
    (sub {
       my ($document, $elem) = @_;
       if ($elem->isa('PPI::Token::Word')
           && $elem eq '__PACKAGE__'
           && ! Perl::Critic::Utils::is_hash_key($elem)) {
         return 1;
       } else {
         return 0;
       }
     });
}

# 5.004 new "use VERSION"
#
# "use MODULE VERSION" is not as easy, fairly sure it depends whether the
# target module uses Exporter.pm or not since the VERSION part is passed to
# import() and Exporter.pm checks it.
#
sub Perl::MinimumVersion::_Pulp__use_version_number {
  my ($pmv) = @_;
  ### _Pulp__use_version_number
  $pmv->Document->find_first
    (sub {
       my ($document, $elem) = @_;
       $elem->isa('PPI::Statement::Include') or return 0;
       $elem->type eq 'use' or return 0;
       if ($elem->version ne '') {  # empty string '' for not a "use VERSION"
         return 1;
       } else {
         return 0;
       }
     });
}

# 5.004 new "foreach my $i" lexical loop variable
#
sub Perl::MinimumVersion::_Pulp__for_loop_variable_using_my {
  my ($pmv) = @_;
  ### _Pulp__for_loop_variable_using_my
  $pmv->Document->find_first
    (sub {
       my ($document, $elem) = @_;
       $elem->isa('PPI::Statement::Compound') or return 0;
       $elem->type eq 'foreach' or return 0;
       my $second = $elem->schild(1) || return 0;
       $second->isa('PPI::Token::Word') or return 0;
       if ($second eq 'my') {
         return 1;
       } else {
         return 0;
       }
     });
}

# 5.004 new "$foo->(PARAMS)" coderef call
#
sub Perl::MinimumVersion::_Pulp__arrow_coderef_call {
  my ($pmv) = @_;
  ### _Pulp__arrow_coderef_call
  $pmv->Document->find_first
    (sub {
       my ($document, $elem) = @_;
       $elem->isa('PPI::Token::Operator') or return 0;
       ### operator: "$elem"
       $elem eq '->' or return 0;
       $elem = $elem->snext_sibling || return 0;
       ### next: "$elem"
       if ($elem->isa('PPI::Structure::List')) {
         return 1;
       } else {
         return 0;
       }
     });
}

# 5.004 new sysseek()
#
# prototype() is newly documented in 5.004 but existed earlier, or something
sub Perl::MinimumVersion::_Pulp__sysseek_builtin {
  my ($pmv) = @_;
  ### _Pulp__sysseek_builtin
  $pmv->Document->find_first
    (sub {
       my ($document, $elem) = @_;
       if ($elem->isa('PPI::Token::Word')
           && ($elem eq 'sysseek' || $elem eq 'CORE::sysseek')
           && Perl::Critic::Utils::is_function_call ($elem)) {
         return 1;
       } else {
         return 0;
       }
     });
}


#---------------------------------------------------------------------------
# generic

# if $elem is a symbol or a List of a symbol then return that symbol elem,
# otherwise return an empty list
#
sub _symbol_or_list_symbol {
  my ($elem) = @_;
  if ($elem->isa('PPI::Structure::List')) {
    $elem = $elem->schild(0) || return;
    $elem->isa('PPI::Statement::Expression') || return;
    $elem = $elem->schild(0) || return;
  }
  $elem->isa('PPI::Token::Symbol') || return;
  return $elem;
}


#---------------------------------------------------------------------------

1;
__END__

=for stopwords addon config MinimumVersion Pragma CPAN prereq multi-constant concats

=head1 NAME

Perl::Critic::Policy::Compatibility::PerlMinimumVersionAndWhy - explicit Perl version for features used

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
addon.  It requires that you have an explicit C<use 5.XXX> etc for the Perl
syntax features you use, as determined by
L<C<Perl::MinimumVersion>|Perl::MinimumVersion>.

    use 5.010;       # the // operator is new in perl 5.010
    print $x // $y;  # ok

If you don't have C<Perl::MinimumVersion> then nothing is reported.  Certain
nasty hacks are used to extract reasons and locations from
C<Perl::MinimumVersion>.

This policy is under the "compatibility" theme (see L<Perl::Critic/POLICY
THEMES>).  Its best use is when it picks up things like C<//> or C<qr> which
are only available in a newer Perl than you meant to target.

An explicit C<use 5.xxx> can be tedious, but makes it clear what's needed
(or supposed to be needed) and it gives a good error message if run on an
older Perl.

The config options below let you limit how far back to go.  Or if you don't
care at all about this sort of thing you can always disable the policy
completely from you F<~/.perlcriticrc> file in the usual way,

    [-Compatibility::PerlMinimumVersionAndWhy]

=head2 MinimumVersion Mangling

Some mangling is applied to what C<Perl::MinimumVersion> normally reports
(as of its version 1.20).

=over 4

=item *

A multi-constant hash with the L<C<constant>|constant> module is not
reported, since that's covered better by
L<Compatibility::ConstantPragmaHash|Perl::Critic::Policy::Compatibility::ConstantPragmaHash>.

=item *

Module requirements like C<use Errno> are dropped, since you might get a
back-port from CPAN etc and any need for a module is better expressed in a
distribution "prereq".

The same rationale generally doesn't apply to pragma type modules like C<use
warnings> since they're normally an interface to a feature new in the Perl
version it comes with and can't be back-ported.

=back

=head2 MinimumVersion Extras

The following extra checks are added to what C<Perl::MinimumVersion>
normally reports.

=over 4

=item *

5.10 for C<qr//m>, since the "m" modifier doesn't propagate correctly on a
C<qr> until then.

=item *

5.6 new C<exists &subr>, C<exists $array[0]> or C<delete $array[0]>
support.

=item *

5.6 new C<0b110011> binary number literals.

=item *

5.005 new C<Foo::Bar::> double-colon package name.

=item *

5.004 new C<use 5.006> version check in a C<use>.  For earlier Perl it can
be C<BEGIN { require 5.006 }> etc.

=item *

5.004 new C<__PACKAGE__> special literal.

=item *

5.004 new C<foreach my $foo> lexical loop variable.

=item *

C<pack> and C<unpack> format strings are checked for various new conversions
in Perl 5.004 through 5.10.0.  Currently this only works on formats given as
literal strings or here-documents, without interpolations, or C<.> operator
concats of those.

=back

=head1 CONFIGURATION

=over 4

=item C<above_version> (version string, default none)

Set a minimum version of Perl you always use, so that reports are only about
things higher than this and higher than the document declares.  The value is
anything the L<C<version.pm>|version> module understands.

    [Compatibility::PerlMinimumVersionAndWhy]
    above_version = 5.006

For example if you always use Perl 5.6 and set 5.006 like this then you can
have C<our> package variables without an explicit C<use 5.006>.

=item C<skip_checks> (list of check names, default none)

Skip the given MinimumVersion checks (a space separated list).  The check
names are shown in the violation message and come from
C<Perl::MinimumVersion::CHECKS>.  For example,

    [Compatibility::PerlMinimumVersionAndWhy]
    skip_checks = _some_thing _another_thing

This can be used for checks you believe are wrong, or where the
compatibility matter only affects limited circumstances which you
understand.

The check names are likely to be a bit of a moving target, especially the
Pulp additions.  Unknown checks in the list are quietly ignored.

=back

=head1 OTHER NOTES

C<use warnings> is reported as a Perl 5.6.0 feature since the
lexically-scoped fine grain warnings control is new in that version.  If
targeting earlier versions then it's often enough to make sure your code
works under S<< C<perl -w> >> and leave it to applications to use C<-w> (or
set C<$^W>) or not, as it might desire.

C<warnings::compat> offers a C<use warnings> for earlier versions, but it's
not lexical, instead setting C<$^W> globally.  Doing that from a module is
probably not a good idea, but in a script it could be an alternative to
S<C<#!/usr/bin/perl -w>> (per L<perlrun>).

=head1 SEE ALSO

L<Perl::Critic::Pulp>, L<Perl::Critic>,

L<C<Perl::Critic::Policy::Modules::PerlMinimumVersion>|Perl::Critic::Policy::Modules::PerlMinimumVersion>
is similar, but compares against a Perl version configured in your
F<~/.perlcriticrc> rather than a version in the document.

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
