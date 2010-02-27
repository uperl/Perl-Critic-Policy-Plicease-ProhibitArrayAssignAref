# Copyright 2009, 2010 Kevin Ryde

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
use Perl::Critic::Utils qw(:severities
                           is_function_call
                           parse_arg_list);

use Perl::Critic::Pulp;

our $VERSION = 31;

use constant DEBUG => 0;

sub default_severity { return $SEVERITY_LOW }
sub default_themes   { return qw(pulp compatibility) }
sub applies_to       { return 'PPI::Document' }

sub supported_parameters {
  return ({ name        => 'above_version',
            description => 'Check only things above this version of Perl.',
            behavior    => 'string',
            parser      => \&Perl::Critic::Pulp::parameter_parse_version,
          });
}

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

  my $pmv = Perl::MinimumVersion->new ($document);
  my $config_above_version = $self->{'above_version'};
  my $explicit_version = $document->highest_explicit_perl_version;

  my @violations;
  foreach my $check (sort keys %Perl::MinimumVersion::CHECKS) {
    next if $check eq '_constant_hash'; # better my ConstantPragmaHash
    next if $check =~ /(_pragmas|_modules)$/;  # wrong for dual-life stuff

    my $check_version = $Perl::MinimumVersion::CHECKS{$check};
    next if (defined $explicit_version
             && $check_version <= $explicit_version);
    next if (defined $config_above_version
             && $check_version <= $config_above_version);
    if (DEBUG) {
      print "$check\n";
    }

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

sub _setup_extra_checks {
  my $v5004 = version->new('5.004');
  my $v5006 = version->new('5.006');
  my $v5008 = version->new('5.008');
  my $v5010 = version->new('5.010');

  $Perl::MinimumVersion::CHECKS{_my_perl_5010_magic__fix}     = $v5010;
  $Perl::MinimumVersion::CHECKS{_my_perl_5010_operators__fix} = $v5010;
  $Perl::MinimumVersion::CHECKS{_my_perl_5010_qr_m_working_properly} = $v5010;

  $Perl::MinimumVersion::CHECKS{_my_perl_5004_pack_format} = $v5004;
  $Perl::MinimumVersion::CHECKS{_my_perl_5006_pack_format} = $v5006;
  $Perl::MinimumVersion::CHECKS{_my_perl_5008_pack_format} = $v5008;
  $Perl::MinimumVersion::CHECKS{_my_perl_5010_pack_format} = $v5010;
}

{
  # Perl::MinimumVersion as of 1.22 has 'PPI::Token::Operator' and
  # 'PPI::Token::Magic' swapped between the tests

  package Perl::MinimumVersion;
  use vars qw(%MATCHES);
  sub _my_perl_5010_operators__fix {
    shift->Document->find_first
      (sub {
         $_[1]->isa('PPI::Token::Operator')
           and
             $MATCHES{_perl_5010_operators}->{$_[1]->content}
           } );
  }
  sub _my_perl_5010_magic__fix {
    shift->Document->find_first
      (sub {
         $_[1]->isa('PPI::Token::Magic')
           and
             $MATCHES{_perl_5010_magic}->{$_[1]->content}
           } );
  }
}

sub Perl::MinimumVersion::_my_perl_5010_qr_m_working_properly {
  my ($pmv) = @_;
  if (DEBUG) { print "_my_perl_5010_qr_m_working_properly check\n"; }
  $pmv->Document->find_first
    (sub {
       my ($document, $elem) = @_;
       $elem->isa('PPI::Token::QuoteLike::Regexp') || return 0;
       my %modifiers = $elem->get_modifiers;
       if (DEBUG) {
         require Data::Dumper;
         print "  ", $elem->content,
           " modifiers ",Data::Dumper::Dumper(\%modifiers),"\n";
       }
       return $modifiers{'m'};
     });
}

sub Perl::MinimumVersion::_my_perl_5004_pack_format {
  my ($pmv) = @_;
  # w - BER integer
  return _pack_format ($pmv, qr/w/);
}
sub Perl::MinimumVersion::_my_perl_5006_pack_format {
  my ($pmv) = @_;
  # Z - asciz
  # q - signed quad
  # Q - unsigned quad
  # ! - native size
  # / - counted string
  # # - comment
 return _pack_format ($pmv, qr{[ZqQ!/#]});
}
sub Perl::MinimumVersion::_my_perl_5008_pack_format {
  my ($pmv) = @_;
  # F - NV
  # D - long double
  # j - IV
  # J - UV
  # ( - group
  return _pack_format ($pmv, qr/[FDjJ(]/);
}
sub Perl::MinimumVersion::_my_perl_5010_pack_format {
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
       is_function_call($elem) || return 0;

       my @args = parse_arg_list ($elem);
       my $format_arg = $args[0];
       if (DEBUG) { print "  format @$format_arg\n"; }

       my ($str, $any_vars) = Perl::Critic::Policy::Miscellanea::TextDomainPlaceholders::_arg_string ($format_arg);
       if (DEBUG) { print "  str ``$str'' anyvars=",($any_vars?1:0),"\n"; }

       if ($any_vars) { return 0; }
       return ($str =~ $regexp);
     });
}

#---------------------------------------------------------------------------

1;
__END__

=head1 NAME

Perl::Critic::Policy::Compatibility::PerlMinimumVersionAndWhy - explicit perl version for features used

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
THEMES>).  Its best use is when it picks up things like C<//> or C<qr> only
available in a newer Perl than you thought to support.

An explicit C<use 5.xxx> in your code can be tedious, but makes it clear
what you need (or think you need) and it gets a good error message if run on
an older Perl.  The config below lets you limit how far back you might go.
Or if you don't care at all about this sort of thing you can always disable
the policy completely from you F<~/.perlcriticrc> file in the usual way,

    [-Compatibility::PerlMinimumVersionAndWhy]

=head2 MinimumVersion Mangling

A little mangling is applied to what C<Perl::MinimumVersion> normally
reports (as of its version 1.20).

=over 4

=item *

Pragma and module requirements like C<use warnings> are dropped, since you
might get a back-port from CPAN etc and the need for a module is better
expressed in your distribution "prereq".

=item *

A multi-constant hash with the L<C<constant>|constant> module is not
reported, since that's covered better by
L<Compatibility::ConstantPragmaHash|Perl::Critic::Policy::Compatibility::ConstantPragmaHash>.

=back

=head2 MinimumVersion Extras

The following extra checks are added to what C<Perl::MinimumVersion>
normally reports.

=over 4

=item *

C<qr//m> requires Perl 5.10, as the "m" modifier doesn't propagate correctly
on a C<qr> until then.

=item *

C<pack> and C<unpack> format strings are checked for various new conversions
in 5.004 through 5.10.0.  Currently this only works on literal strings or
here-documents without interpolations, plus C<.> operator concats of those.

=back

=head1 CONFIGURATION

=over 4

=item C<above_version> (version string, default none)

Set a minimum version of Perl you always use, so reports are only about
things both higher than this and higher than the document declares.  The
string is anything L<C<version.pm>|version> understands.  For example,

    [Compatibility::PerlMinimumVersionAndWhy]
    above_version = 5.006

For example if you always use Perl 5.6 and set 5.006 like this then you can
have C<our> package variables without an explicit C<use 5.006>.

=back

=head1 SEE ALSO

L<Perl::Critic::Pulp>, L<Perl::Critic>,

L<C<Perl::Critic::Policy::Modules::PerlMinimumVersion>|Perl::Critic::Policy::Modules::PerlMinimumVersion>
is similar, but compares against a Perl version configured in your
F<~/.perlcriticrc> rather than a version in the document.

=cut
