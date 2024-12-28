# MyMakeMakerExtras.pm -- my shared MakeMaker extras

# Copyright 2009 Kevin Ryde

# MyMakeMakerExtras.pm is shared by several distributions.
#
# MyMakeMakerExtras.pm is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# MyMakeMakerExtras.pm is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.

package MyMakeMakerExtras;
use strict;
use warnings;

sub DEBUG () { 0 };

my %my_options;

sub WriteMakefile {
  my %opts = @_;

  if (exists $opts{'META_MERGE'}) {
    # cf. ExtUtils::MM_Any::metafile_data() default ['t','inc']
    foreach my $dir ('devel', 'examples', 'junk', 'maybe') {
      if (-d $dir) {
        push @{$opts{'META_MERGE'}->{'no_index'}->{'directory'}}, $dir;
      }
    }

    $opts{'META_MERGE'}->{'resources'}->{'license'} ||=
      'http://www.gnu.org/licenses/gpl.html';
    _meta_merge_shared_tests (\%opts);
  }

  $opts{'clean'}->{'FILES'} .= ' temp-lintian $(MY_HTML_FILES)';
  $opts{'realclean'}->{'FILES'} .= ' TAGS';

  if (! defined &MY::postamble) {
    *MY::postamble = \&MyMakeMakerExtras::postamble;
  }

  foreach my $opt ('MyMakeMakerExtras_Pod_Coverage',
                   'MyMakeMakerExtras_LINT_FILES',
                   'MY_NO_HTML') {
    $my_options{$opt} = delete $opts{$opt};
  }

  ExtUtils::MakeMaker::WriteMakefile (%opts);
}

sub strip_comments {
  my ($str) = @_;
  $str =~ s/^\s*#.*\n//mg;
  $str
}

#------------------------------------------------------------------------------
# META_MERGE

sub _meta_merge_shared_tests {
  my ($opts) = @_;
  if (-e 't/0-Test-Pod.t') {
    _meta_merge_req_add (_meta_merge_maximum_tests($opts),
                         'Test::Pod' => '1.00');
  }
  if (-e 't/0-Test-DistManifest.t') {
    _meta_merge_req_add (_meta_merge_maximum_tests($opts),
                         'Test::DistManifest' => 0);
  }
  if (-e 't/0-Test-YAML-Meta.t') {
    _meta_merge_req_add (_meta_merge_maximum_tests($opts),
                         'Test::YAML::Meta' => '0.13');
  }
  if (-e 't/0-META-read.t') {
    _meta_merge_req_add_ver ($opts, 5.00307, 'FindBin' => 0);
    _meta_merge_req_add_ver ($opts, 5.00405, 'File::Spec' => 0);
    _meta_merge_req_add (_meta_merge_maximum_tests($opts),
                         'Test::NoWarnings'  => 0,
                         'YAML'              => 0,
                         'YAML::Syck'        => 0,
                         'YAML::Tiny'        => 0,
                         'YAML::XS'          => 0,
                         'Parse::CPAN::Meta' => 0);
  }
}
sub _meta_merge_maximum_tests {
  my ($opts) = @_;
  $opts->{'META_MERGE'}->{'optional_features'}->{'maximum_tests'} ||=
    { description => 'Have "make test" do as much as possible.',
      requires => { },
    };
  return $opts->{'META_MERGE'}->{'optional_features'}->{'maximum_tests'}->{'requires'};
}
sub _meta_merge_req_add_ver {
  my ($opts, $perlver, @deps) = @_;
  if (! defined $opts->{'MIN_PERL_VERSION'}
      || $opts->{'MIN_PERL_VERSION'} < $perlver) {
    _meta_merge_req_add (_meta_merge_maximum_tests($opts),
                         @deps);
  }
}
sub _meta_merge_req_add {
  my $req = shift;
  if (DEBUG) { local $,=' '; print "MyMakeMakerExtras META_MERGE",@_,"\n"; }
  while (@_) {
    my $module = shift;
    my $version = shift;
    if (defined $req->{$module}) {
      if ($req->{$module} > $version) {
        $version = $req->{$module};
      }
    }
    $req->{$module} = $version;
  }
}

#------------------------------------------------------------------------------
# postamble()

sub postamble {
  my ($makemaker) = @_;
  if (DEBUG) { print "MyMakeMakerExtras postamble() $makemaker\n"; }

  if (DEBUG >= 2) {
    require Data::Dumper;
    print Data::Dumper::Dumper($makemaker);
  }
  my $post = $my_options{'postamble_docs'};

  unless ($my_options{'MY_NO_HTML'}) {
    $post .= <<'HERE';

#------------------------------------------------------------------------------
# docs stuff -- from inc/MyMakeMakerExtras.pm

MY_POD2HTML = $(PERL) inc/my_pod2html

HERE
    if (my $munghtml_extra = $makemaker->{'MY_MUNGHTML_EXTRA'}) {
      $post =~ s/apt-file!'/apt-file!'\\
$munghtml_extra/;
    }

    my @pmfiles = keys %{$makemaker->{'PM'}};
    @pmfiles = grep {!/\.mo$/} @pmfiles; # not LocaleData .mo files
    my @exefiles = (defined $makemaker->{'EXE_FILES'}
                    ? @{$makemaker->{'EXE_FILES'}}
                    : ());
    my %html_files;

    foreach my $pm (@exefiles, @pmfiles) {
      my $fullhtml = $pm;
      $fullhtml =~ s{lib/}{};     # remove lib/
      $fullhtml =~ s{\.p[ml]$}{}; # remove .pm or .pl
      $fullhtml .= '.html';
      my $parthtml = $fullhtml;

      $fullhtml =~ s{/}{-}g;      # so Foo-Bar.html
      unless ($html_files{$fullhtml}++) {
        $post .= <<"HERE";
$fullhtml: $pm Makefile
	\$(MY_POD2HTML) $pm >$fullhtml
HERE
      }
      $parthtml =~ s{.*/}{};      # remove any directory part, just Bar.html
      unless ($html_files{$parthtml}++) {
        $post .= <<"HERE";
$parthtml: $pm Makefile
	\$(MY_POD2HTML) $pm >$parthtml
HERE
      }
    }

    $post .= "MY_HTML_FILES = " . join(' ', keys %html_files) . "\n";
    $post .= <<'HERE';
html: $(MY_HTML_FILES)
HERE
  }

  $post .= <<'HERE';

#------------------------------------------------------------------------------
# development stuff -- from inc/MyMakeMakerExtras.pm

version:
	$(NOECHO)$(ECHO) $(VERSION)

HERE

  my $lint_files = $my_options{'MyMakeMakerExtras_LINT_FILES'};
  if (! defined $lint_files) {
    $lint_files = '$(EXE_FILES) $(TO_INST_PM)';
    # would prefer not to lock down the 't' dir existance at ./Makefile.PL
    # time, but it's a bit hard without without GNU make extensions
    if (-d 't') { $lint_files .= ' t/*.t'; }

    foreach my $dir ('examples', 'devel') {
      my $pattern = "$dir/*.pl";
      if (glob ($pattern)) {
        $lint_files .= " $pattern";
      }
    }
  }

  my $podcoverage = '';
  foreach my $class (@{$my_options{'MyMakeMakerExtras_Pod_Coverage'}}) {
    # the "." obscures it from MyExtractUse.pm
    $podcoverage .= "\t-perl -e 'use "."Pod::Coverage package=>$class'\n";
  }

  $post .= "LINT_FILES = $lint_files\n"
    . <<'HERE';
lint:
	perl -MO=Lint $(LINT_FILES)
pc:
HERE
  # "podchecker -warnings -warnings" too much reporting every < and >
  $post .= $podcoverage . <<'HERE';
	-podchecker $(LINT_FILES)
	perlcritic $(LINT_FILES)
unused:
	for i in $(LINT_FILES); do perl -Mwarnings::unused -I lib -c $$i; done

HERE

  $post .= <<'HERE';
myman:
	-mv MANIFEST MANIFEST.old
	touch SIGNATURE
	(make manifest 2>&1; diff -u MANIFEST.old MANIFEST) |less

# find files in the dist with mod times this year, but without this year in
# the copyright line
check-copyright-years:
	year=`date +%Y`; \
	tar tvfz $(DISTVNAME).tar.gz \
	| egrep "$$year-|debian/copyright" \
	| sed 's:^.*$(DISTVNAME)/::' \
	| (result=0; \
	  while read i; do \
	    case $$i in \
	      '' | */ \
	      | debian/changelog | debian/compat | debian/doc-base \
	      | debian/patches/*.diff \
	      | COPYING | MANIFEST* | SIGNATURE | META.yml \
	      | version.texi | */version.texi \
	      | *.mo | *.locatedb | samp.*) \
	      continue ;; \
	    esac; \
	    if test -e "$(srcdir)/$$i"; then f="$(srcdir)/$$i"; \
	    else f="$$i"; fi; \
	    if ! grep -q "Copyright.*$$year" $$f; then \
	      echo "$$i":"1: this file"; \
	      grep Copyright $$f; \
	      result=1; \
	    fi; \
	  done; \
	  exit $$result)

# only a non-zero number is bad, allow an expression to copy a debug from
# another package
check-debug-constants:
	if egrep -n 'DEBUG => [1-9]' $(EXE_FILES) $(TO_INST_PM); then exit 1; else exit 0; fi

check-spelling:
	if egrep -nHi 'existant|explict|agument|destionation|\bthe the\b|\bnote sure\b' -r . \
	  | egrep -v '(MyMakeMakerExtras|Makefile|dist-deb).*grep -nH'; \
	then false; else true; fi

diff-prev:
	rm -rf diff.tmp
	mkdir diff.tmp
	cd diff.tmp \
	&& tar xfz ../$(DISTNAME)-`expr $(VERSION) - 1`.tar.gz \
	&& tar xfz ../$(DISTNAME)-$(VERSION).tar.gz
	-cd diff.tmp; diff -ur $(DISTNAME)-`expr $(VERSION) - 1` \
	                       $(DISTNAME)-$(VERSION) >tree.diff
	-$${PAGER:-less} diff.tmp/tree.diff
	rm -rf diff.tmp

# in a hash-style multi-const this "use constant" pattern only picks up the
# first constant, unfortunately, but it's better than nothing
TAG_FILES = $(TO_INST_PM)
TAGS: $(TAG_FILES)
	etags \
	  --regex='{perl}/use[ \t]+constant\(::defer\)?[ \t]+\({[ \t]*\)?\([A-Za-z_][^ \t=,;]+\)/\3/' \
	  $(TAG_FILES)

HERE

  my $have_XS = scalar %{$makemaker->{'XS'}};
  my $arch = ($have_XS
              ? `dpkg --print-architecture`
              : 'all');
  chomp($arch);
  my $debname = (defined $makemaker->{'EXE_FILES'}
                 ? '$(DISTNAME)'
                 : "\Llib$makemaker->{'DISTNAME'}-perl");
  $post .=
    "DEBNAME = $debname\n"
    . "DPKG_ARCH = $arch\n"
    . <<'HERE';
DEBVNAME = $(DEBNAME)_$(VERSION)-1
DEBFILE = $(DEBVNAME)_$(DPKG_ARCH).deb

# ExtUtils::MakeMaker 6.42 of perl 5.10.0 makes "$(DISTVNAME).tar.gz" depend
# on "$(DISTVNAME)" distdir directory, which is always non-existent after a
# successful dist build, so the .tar.gz is always rebuilt.
#
# So although the .deb depends on the .tar.gz don't express that here or it
# rebuilds the .tar.gz every time.
#
# The right rule for the .tar.gz would be to depend on the files which go
# into it of course ...
#
# DISPLAY is unset for making a deb since under fakeroot gtk stuff may try
# to read config files like ~/.pangorc from root's home dir /root/.pangorc,
# and that dir will be unreadable by ordinary users (normally), provoking
# warnings and possible failures from Test::NoWarnings.
#
$(DEBFILE) deb:
	test -f $(DISTVNAME).tar.gz || $(MAKE) $(DISTVNAME).tar.gz
	debver="`dpkg-parsechangelog -c1 | sed -n -r -e 's/^Version: (.*)-[0-9.]+$$/\1/p'`"; \
	  echo "debver $$debver", want $(VERSION); \
	  test "$$debver" = "$(VERSION)"
	rm -rf $(DISTVNAME)
	tar xfz $(DISTVNAME).tar.gz
	unset DISPLAY; export DISPLAY; \
	  cd $(DISTVNAME) \
	  && dpkg-checkbuilddeps debian/control \
	  && fakeroot debian/rules binary
	rm -rf $(DISTVNAME)

lintian-deb: $(DEBFILE)
	lintian -i -X new-package-should-close-itp-bug $(DEBFILE)
lintian-source:
	rm -rf temp-lintian; \
	mkdir temp-lintian; \
	cd temp-lintian; \
	cp ../$(DISTVNAME).tar.gz $(DEBNAME)_$(VERSION).orig.tar.gz; \
	tar xfz $(DEBNAME)_$(VERSION).orig.tar.gz; \
        echo 'empty-debian-diff' \
             >$(DISTVNAME)/debian/source.lintian-overrides; \
	mv -T $(DISTVNAME) $(DEBNAME)-$(VERSION); \
	dpkg-source -b $(DEBNAME)-$(VERSION) \
	               $(DEBNAME)_$(VERSION).orig.tar.gz; \
	lintian -i *.dsc; \
	cd ..; \
	rm -rf temp-lintian

HERE

  return $post;
}

1;
__END__
