#lang forge

sig A {}
sig B {}

pred NeedsA[a: A] {}
pred NeedsB[b: B] {}
pred NeedsAB[a: A, b: B] {}
pred NeedsNotA[na: univ - A] {}

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
