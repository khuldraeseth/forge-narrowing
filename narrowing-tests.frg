#lang forge

sig A {}
sig B {}

pred NeedsA[a: A] {}
pred NeedsB[b: B] {}
pred NeedsAB[a: A, b: B] {}
pred NeedsNotA[na: univ - A] {}

-- option test_keep last SHOULD run all and report failures. it is not currently 
--   working for `is forge-error` (which is only really used in our internal suites)

-- This one type-checks???
-- Expect SAT here if no pre-solver error, because NeedsNotA has no explicit 
-- constraint enforcing its argument is in (univ-A). Forge's pre-solver checks
-- aren't so strict as to disallow this. 
types_univ_notA: assert { all x: univ |  x not in A and NeedsNotA[x] } is sat
-- This, however, should be caught and isn't:
// types_A_notA: assert { all x: A    |  NeedsNotA[x] } is forge_error
-- Checking whether lack of error is due to set-subtraction in pred defn.
-- This is caught. So set-subtraction in the pred defn may be the cause:
types_univExceptA_A: assert { all x: univ-A    |  NeedsA[x] } is forge_error

pred Foo {
    all x: univ {
        x in A and NeedsA[x]
        x in A implies NeedsA[x]
        x not in A or NeedsA[x]
        x in univ - A or NeedsA[x]

        -- This one type-checks???
        x not in A and NeedsNotA[x]

        x in A => NeedsA[x] else {}
        -- This one too
        x in A => {} else NeedsNotA[x]
    }

    all x: univ, y: univ {
        x in A and y in B and NeedsAB[x, y]
        (x in A and y in B) implies NeedsAB[x, y]
        x in A implies (y in B and NeedsAB[x, y])
        y in B or (x not in A or NeedsAB[x, y])

        -- this one requires resolution, likely out of scope
        (x in A or y in B) and (x not in A implies NeedsB[y])
    }

    all x: A + B {
        -- unclear whether these are in scope
        -- basically the same as the example above I said is likely out of scope
        x not in A and NeedsB[x]
        x not in A implies NeedsB[x]
        x in A or NeedsB[x]
    }
}

assert { Foo or not Foo } is sat
