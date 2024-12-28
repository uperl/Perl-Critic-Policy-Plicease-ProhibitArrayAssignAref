# Copyright 2011, 2012 Kevin Ryde

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


# perlcritic -s ProhibitLinkToSelf ProhibitLinkToSelf.pm


package Perl::Critic::Policy::Documentation::ProhibitLinkToSelf;
use 5.006;
use strict;
use warnings;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils;

# uncomment this to run the ### lines
#use Devel::Comments;

our $VERSION = 76;

use constant supported_parameters => ();
use constant default_severity     => $Perl::Critic::Utils::SEVERITY_LOW;
use constant default_themes       => qw(pulp cosmetic);
use constant applies_to           => 'PPI::Document';

sub violates {
  my ($self, $elem, $document) = @_;
  # ### ProhibitLinkToSelf on: $elem->content

  my $parser = Perl::Critic::Pulp::PodParser::ProhibitLinkToSelf->new
    (policy => $self);
  $parser->parse_from_elem ($elem);
  return $parser->violations;
}

package Perl::Critic::Pulp::PodParser::ProhibitLinkToSelf;
use strict;
use warnings;
use Pod::ParseLink;
use base 'Perl::Critic::Pulp::PodParser';

my %command_non_text = (for   => 1,
                        begin => 1,
                        end   => 1,
                        # cut => 1, # not seen unless -process_cut_cmd
                       );
sub command {
  my ($self, $command, $text, $linenum, $pod_obj) = @_;

  # if ($command eq 'for'
  #     && $text =~ /^ProhibitLinkToSelf\b\s*(.*)/) {
  #   my $directive = $1;
  #   ### $directive
  #   if ($directive =~ /^allow next( (\d+))?/) {
  #     # numbered "allow next 5" means up to that many following,
  #     # unnumbered "allow next" means one following
  #     $self->{'allow_next'} = (defined $2 ? $2 : 1);
  #   }

  if ($command eq 'head1') {
    $self->{'in_name'}     = ($text =~ /^\s*NAME\b/);
    $self->{'in_see_also'} = ($text =~ /^\s*SEE\s+ALSO\b/);
    ### in_name now: $self->{'in_name'}
    ### in_see_also: $self->{'in_see_also'}
  }

  unless ($command_non_text{$command}) {
    # padded for the column number right, the leading spaces do no harm here
    _check_text ($self,
                 (' ' x (length($command)+1)) . $text,
                 $linenum,
                 $pod_obj);
  }

  return '';
}

sub textblock {
  my ($self, $text, $linenum, $pod_obj) = @_;
  ### textblock(): "linenum=$linenum"
  ### $text

  my $str = _check_text ($self, $text, $linenum, $pod_obj);
  ### interpolated: $str
  if ($self->{'in_name'}) {
    if ($str =~ /^\s*([[:word:]:]+)\s*-/) {
      ### add own package name: $1
      $self->{'own_package_names'}->{$1} = 1;
    }
  }
  return '';
}

sub _check_text {
  my ($self, $text, $linenum, $pod_obj) = @_;
  ### _check_text() ...
  ### $linenum
  return $self->interpolate($text, $linenum);
}

sub interior_sequence {
  my ($self, $cmd, $text, $pod_obj) = @_;
  ### interior_sequence() ...

  if ($cmd eq 'X') {
    # index entry, no text output, but keep newlines for linenum
    $text =~ tr/\n//cd;

  } elsif ($cmd eq 'L') {
    my ($display, $inferred, $name, $section, $type)
      = Pod::ParseLink::parselink ($text);
    ### $display
    ### $inferred
    ### $name

    if (defined $name && $self->{'own_package_names'}->{$name}) {
      $text =~ /(\s*)$/;
      my $pos = length($text) - length($1); # end of $text
      ### $pos
      (undef, my $linenum) = $pod_obj->file_line;

      $self->violation_at_linenum_and_textpos
        (($self->{'in_see_also'}
          ? "L<> link to this POD itself in \"SEE ALSO\" section, probable typo"
          : "L<> link to this POD itself, suggest just C<> markup is enough"),
         $linenum, $text, $pos);
    }
    return (defined $display ? $display : $name);
  }
  return $text;
}

1;
__END__

=for stopwords addon Ryde clickable one's formatters filename

=head1 NAME

Perl::Critic::Policy::Documentation::ProhibitLinkToSelf - don't LE<lt>E<gt> link to own POD

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
addon.  It asks you not to use C<< LE<lt>E<gt> >> markup to refer to a POD
document itself.

=for ProhibitVerbatimMarkup allow next 6

    =head1 NAME

    My::Package - something

    =head1 DESCRIPTION

    L<My::Package> does blah blah ...     # bad

    =head1 SEE ALSO

    L<My::Package>                        # bad

The idea is that it doesn't make sense to link to a document from within
itself.  If rendered as a clickable link then it may suggest there's
somewhere else to go to read about the module, when in fact you're already
looking at it.

This is only a minor thing though, so this policy is under the C<cosmetic>
theme (see L<Perl::Critic/POLICY THEMES>) and low priority.

In ordinary text the is plain C<< CE<lt>E<gt> >> or similar for one's own
module name,

=for ProhibitVerbatimMarkup allow next

    C<My::Package> does something something ...   # ok

In a "SEE ALSO" a link to self in very likely a typo, or too much cut and
paste, or at least pretty unnecessary since there's no need to "see also"
what you've just read.

If linking to a particular section within one's own document then use
C<< LE<lt>E<gt> >> with just the section part.  This will probably give
better looking output from the formatters too,

=for ProhibitVerbatimMarkup allow next 2

    L<My::Package/SECTION>      # bad

    L</SECTION>                 # ok

For this policy the name of the POD is picked out of the "=head1 NAME"
section, so doesn't depend on the filename or directory where C<perlcritic>
is run.  In the current code multiple names can be given in man-page style,
but not certain yet if that's a good idea.

    =head1 NAME

    My::Package -- blah

    My::Package::Parser -- and its parser

    =head1 DESCRIPTION

Of course it's always possible an C<< LE<lt>E<gt> >> like is right and it's
the "NAME" part which is wrong.  A violation on the C<< LE<lt>E<gt> >> will
at least show there's something fishy in the one or the other.

=head2 Disabling

If you don't care about this then you can always disable
C<ProhibitLinkToSelf> from your F<.perlcriticrc> file in the usual way (see
L<Perl::Critic/CONFIGURATION>),

    [-Documentation::ProhibitLinkToSelf]

Some people may like to more or less always put C<< LE<lt>E<gt> >> on module
names, including in the module's own POD.  For that you may want to disable
this policy.  Perhaps an option could allow link to self in ordinary link
but still rate "SEE ALSO" as a typo or unnecessary.

=head1 SEE ALSO

L<Perl::Critic::Pulp>,
L<Perl::Critic>

L<Perl::Critic::Policy::Documentation::RequirePackageMatchesPodName>,
L<Perl::Critic::Policy::Documentation::ProhibitAdjacentLinks>

=head1 HOME PAGE

http://user42.tuxfamily.org/perl-critic-pulp/index.html

=head1 COPYRIGHT

Copyright 2011, 2012 Kevin Ryde

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
