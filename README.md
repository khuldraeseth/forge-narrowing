# Thoughts on type narrowing in Forge

This repository contains scattered stuff relating to type narrowing in Forge. [things-that-make-sense.txt](things-that-make-sense.txt) has examples of ill-typed expressions one could reasonably expect to be well-typed due to type narrowing, with some alternatie forms arising from propositional logic equivalences. It's annotated with some thoughts on how type checking could proceed, either statically at the cost of completeness or using the solver to prove narrowing.

[Rewrite.hs](Rewrite.hs) exports an `Expr` type along with its constructors and a smart `¬` constructor. It also provides `allRewrites :: Expr a -> [Expr a]` that uses equivalences from predicate logic to rewrite an expression in a number of different ways. It's not really helpful for Forge; I just used it in coming up with some of the examples in [things-that-make-sense.txt](things-that-make-sense.txt).

[narrowing-tests.frg](narrowing-tests.frg) is a Relational Forge file with a bunch of these expressions and thus a bunch of type errors. It could be a nice demonstration of narrowing to have this specification typecheck. It could be used to create a test suite by placing the individual expressions in separate files.

There are a couple weird things in [narrowing-tests.frg](narrowing-tests.frg) that look like this:

```forge
sig A {}
pred NeedsNotA[na: univ - A]
x: univ

x not in A and NeedsNotA[x]    -- shouldn't typecheck in current Forge
                               -- without narrowing, who says x is in univ - A?
                               -- but it does typecheck ¯\_(ツ)_/¯
```
