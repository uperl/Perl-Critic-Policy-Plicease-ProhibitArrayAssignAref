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


package Perl::Critic::Policy::Documentation::ProhibitBadAproposMarkup;
use 5.006;
use strict;
use warnings;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils qw(:severities);

our $VERSION = 26;

sub supported_parameters { return; }
sub default_severity { return $SEVERITY_LOWEST;  }
sub default_themes   { return qw(pulp cosmetic); }
sub applies_to       { return 'PPI::Document';   }

sub violates {
  my ($self, $elem, $document) = @_;
  my $str = $elem->serialize;

  my $parser = Perl::Critic::Policy::Documentation::ProhibitBadAproposMarkup::Parser->new
    (policy => $self,
     elem => $elem,
     str => $str);
  my $fh = IO::String->new ($str);
  $parser->parse_from_filehandle ($fh);
  return @{$parser->{'violations'}};
}

package Perl::Critic::Policy::Documentation::ProhibitBadAproposMarkup::Parser;
use strict;
use warnings;
use base 'Pod::Parser';
use IO::String;

use constant DEBUG => 0;

sub new {
  my $class = shift;
  return $class->SUPER::new(@_, violations => []);
}

sub command {
  my $self = shift;
  my ($command, $text, $linenum, $paraobj) = @_;
  if (DEBUG) { print "command: $command -- ",
                 (defined $text ? ">>$text<<" : 'undef'), "\n"; }

  if ($command eq 'head1') {
    $self->{'in_NAME'} = ($text =~ /^NAME\s*$/ ? 1 : 0);
  }
  if (DEBUG) { print "  in_NAME now ",($self->{'in_NAME'}?1:0),"\n"; }
  return '';
}

sub verbatim {
  return '';
}

sub textblock {
  my ($self, $text, $linenum, $paraobj) = @_;
  if (DEBUG) { print "textblock\n"; }
  return $self->interpolate ($text, $linenum);
}

sub interior_sequence {
  my ($self, $command, $arg, $seq_obj) = @_;
  if (DEBUG) {
    print "interior: $command -- $arg seq=$seq_obj\n";
    print "  raw_text ", $seq_obj->raw_text, "\n";
    print "  left ", $seq_obj->left_delimiter, "\n";
    if (my $outer = $seq_obj->nested) {
      print "  nested ", $outer->cmd_name, "\n";
    }
  }

  if ($self->{'in_NAME'} && $command eq 'C') {
    my ($filename, $linenum) = $seq_obj->file_line;
    my $policy = $self->{'policy'};
    my $elem   = $self->{'elem'};
    my $str    = $self->{'str'};
    my $violation = $policy->violation
      ("C<> markup in NAME section is bad for \"apropos\".",
       '',
       $elem);
    require Perl::Critic::Policy::Compatibility::PodMinimumVersion;
    Perl::Critic::Policy::Compatibility::PodMinimumVersion::_violation_override_linenum ($violation, $str, $linenum);
    push @{$self->{'violations'}}, $violation;
  }
  return '';
}

1;
__END__

=head1 NAME

Perl::Critic::Policy::Documentation::ProhibitBadAproposMarkup - don't use CE<lt>E<gt> markup in a NAME section

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
addon.  It asks you not to write CE<lt>E<gt> markup in the NAME section of
the POD because it comes out badly in man's "apropos" database.  For
example,

    =head1 NAME

    foo - like the C<bar> program     # bad

C<pod2man> uses macros for "CE<lt>E<gt>" which "man-db"'s C<lexgrog> program
doesn't expand, resulting in unattractive description lines from C<apropos
foo> like

    foo - like the *(C`bar*(C' program

Man's actual formatted output is fine, and the desired text is in there,
just surrounded by *(C bits.  On that basis this policy is low priority and
under the "cosmetic" theme (see L<Perl::Critic/POLICY THEMES>).

The NAME section is everything from "=head1 NAME" to the next "=head1".
Other markup like "BE<lt>E<gt>", "IE<lt>E<gt>" and "FE<lt>E<gt>" are
allowed, because C<pod2man> uses builtin "\fB" etc directives for them,
which C<lexgrog> recognises.

As always if you don't care about this you can disable
C<ProhibitBadAproposMarkup> from your F<.perlcriticrc> in the usual way,

    [-Documentation::ProhibitBadAproposMarkup]

=head1 SEE ALSO

L<Perl::Critic::Pulp>, L<Perl::Critic>,
L<Perl::Critic::Policy::Documentation::RequirePackageMatchesPodName>,
L<Perl::Critic::Policy::Documentation::RequirePodSections>

=head1 HOME PAGE

http://user42.tuxfamily.org/perl-critic-pulp/index.html

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
Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses/>.

=cut
