# Perl::Critic::Policy::Plicease::ProhibitArrayAssignAref ![static](https://github.com/uperl/Perl-Critic-Policy-Plicease-ProhibitArrayAssignAref/workflows/static/badge.svg) ![linux](https://github.com/uperl/Perl-Critic-Policy-Plicease-ProhibitArrayAssignAref/workflows/linux/badge.svg)

Don't assign an anonymous arrayref to an array

# VERSION

version 99

# DESCRIPTION

This policy is a fork of [Perl::Critic::Policy::ValuesAndExpressions::ProhibitArrayAssignAref](https://metacpan.org/pod/Perl::Critic::Policy::ValuesAndExpressions::ProhibitArrayAssignAref).
It differs from the original by not having a dependency on [List::MoreUtils](https://metacpan.org/pod/List::MoreUtils).
It is unfortunately still licensed as GPL3.

It asks you not to assign an anonymous arrayref to an array

```
@array = [ 1, 2, 3 ];       # bad
```

The idea is that it's rather unclear whether an arrayref is intended, or
might have meant to be a list like

```
@array = ( 1, 2, 3 );
```

This policy is under the "bugs" theme (see ["POLICY THEMES" in Perl::Critic](https://metacpan.org/pod/Perl::Critic#POLICY-THEMES))
for the chance `[]` is a mistake, and since even if it's correct it will
likely make anyone reading it wonder.

A single arrayref can still be assigned to an array, but with parens to make
it clear,

```
@array = ( [1,2,3] );       # ok
```

Dereferences or array and hash slices (see ["Slices" in perldata](https://metacpan.org/pod/perldata#Slices)) are
recognised as an array target and treated similarly,

```
@$ref = [1,2,3];            # bad assign to deref
@{$ref} = [1,2,3];          # bad assign to deref
@x[1,2,3] = ['a','b','c'];  # bad assign to array slice
@x{'a','b'} = [1,2];        # bad assign to hash slice
```

## List Assignment Parens

This policy is not a blanket requirement for `()` parens on array
assignments.  It's normal and unambiguous to have a function call or `grep`
etc without parens.

```
@array = foo();                    # ok
@array = grep {/\.txt$/} @array;   # ok
```

The only likely problem from lack of parens in such cases is that the `,`
comma operator has lower precedence than `=` (see [perlop](https://metacpan.org/pod/perlop)), so something
like

```
@array = 1,2,3;   # oops, not a list
```

means

```
@array = (1);
2;
3;
```

Normally the remaining literals in void context provoke a warning from Perl
itself.

An intentional single element assignment is quite common as a statement, for
instance

```
@ISA = 'My::Parent::Class';   # ok
```

And for reference the range operator precedence is high enough,

```
@array = 1..10;               # ok
```

But of course parens are needed if concatenating some disjoint ranges with
the comma operator,

```
@array = (1..5, 10..15);      # parens needed
```

The `qw` form gives a list too

```
@array = qw(a b c);           # ok
```

# SEE ALSO

- [Perl::Critic](https://metacpan.org/pod/Perl::Critic)
- [Perl::Critic::Policy::ValuesAndExpressions::ProhibitArrayAssignAref](https://metacpan.org/pod/Perl::Critic::Policy::ValuesAndExpressions::ProhibitArrayAssignAref)

# HOME PAGE

- [https://github.com/uperl/Perl-Critic-Policy-Plicease-ProhibitArrayAssignAref](https://github.com/uperl/Perl-Critic-Policy-Plicease-ProhibitArrayAssignAref)

# COPYRIGHT

Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2019, 2021 Kevin Ryde

Perl-Critic-Policy-Plicease-ProhibitArrayAssignAref is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Perl-Critic-Policy-Plicease-ProhibitArrayAssignAref is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Perl-Critic-Policy-Plicease-ProhibitArrayAssignAref.  If not, see &lt;http://www.gnu.org/licenses>.

# AUTHOR

Original author: Kevin Ryde

Current maintainer: Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2011-2021 by Kevin Ryde.

This is free software, licensed under:

```
The GNU General Public License, Version 3, June 2007
```
