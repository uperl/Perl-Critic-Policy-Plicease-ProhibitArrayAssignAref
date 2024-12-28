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


sub postamble {
  my ($makemaker) = @_;
  my $post = '';

  my $lint_files = '';
  foreach my $dir ('examples', 'devel') {
    my $pattern = "$dir/*.pl";
    if (glob ($pattern)) {
      $lint_files .= " $pattern";
    }
  }
  $post .= "LINT_FILES = \$(EXE_FILES) \$(TO_INST_PM) t/*.t $lint_files\n"
    . <<'HERE';
lint:
	perl -MO=Lint $(LINT_FILES)
pc:
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
copyright-years-check:
	year=`date +%Y`; \
	tar tvfz $(DISTVNAME).tar.gz \
	| egrep '$$year-|debian/copyright' \
	| sed 's:^.*$(DISTVNAME)/::' \
	| (result=0; \
	  while read i; do \
	    case $$i in \
	      '' | */ \
	      | debian/changelog | debian/compat \
	      | COPYING | MANIFEST* | SIGNATURE | META.yml) \
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

debug-constants-check:
	if egrep -n 'DEBUG => [^0]' $(EXE_FILES) $(TO_INST_PM); then exit 1; else exit 0; fi

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

TAG_FILES = $(TO_INST_PM)
TAGS: $(TAG_FILES)
	etags $(TAG_FILES)

HERE

  my $debname = (defined $makemaker->{'EXE_FILES'}
                 ? '$(DISTNAME)'
                 : "\Llib$makemaker->{'DISTNAME'}-perl");
  $post .= "DEBNAME = $debname\n" . <<'HERE';
DEBVNAME = $(DEBNAME)_$(VERSION)-1
DEBFILE = $(DEBVNAME)_all.deb

# ExtUtils::MakeMaker 6.42 of perl 5.10.0 has a very dodgy rule for
# $(DISTVNAME).tar.gz, making it depend on the distdir "$(DISTVNAME)", which
# is always non-existant after a successful dist build, so the .tar.gz is
# always rebuilt.  So although "deb" and $(DEBFILE) depend on
# $(DISTVNAME).tar.gz, don't express that here.
#
deb $(DEBFILE):
	test -f $(DISTVNAME).tar.gz
	rm -rf $(DISTVNAME)
	tar xfz $(DISTVNAME).tar.gz
	cd $(DISTVNAME) \
	  && dpkg-checkbuilddeps debian/control \
	  && fakeroot debian/rules binary
	rm -rf $(DISTVNAME)

lintian-source:
	rm -rf temp-lintian; \
	mkdir temp-lintian; \
	cd temp-lintian; \
	cp ../$(DISTVNAME).tar.gz $(DEBNAME)_$(VERSION).orig.tar.gz; \
	tar xfz $(DEBNAME)_$(VERSION).orig.tar.gz; \
	mv -T $(DISTVNAME) $(DEBNAME)-$(VERSION); \
	dpkg-source -b $(DEBNAME)-$(VERSION) $(DEBNAME)_$(VERSION).orig.tar.gz; \
	lintian -i *.dsc; \
	cd ..; \
	rm -rf temp-lintian

HERE

  return $post;
}

1;
__END__
