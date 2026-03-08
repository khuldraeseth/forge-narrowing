module Rewrite (Expr (..), (∧), (∨), (→), (¬), allRewrites) where

import Control.Monad ((<=<))
import Data.Bifunctor (Bifunctor (first))
import Data.Foldable (find)
import Data.List (nub)

data Expr a where
    Var :: a -> Expr a
    Not :: Expr a -> Expr a
    (:/\) :: Expr a -> Expr a -> Expr a
    (:\/) :: Expr a -> Expr a -> Expr a
    (:->) :: Expr a -> Expr a -> Expr a
    deriving (Eq, Functor, Foldable, Traversable)

infixr 9 :->

(∧) :: Expr a -> Expr a -> Expr a
(∧) = (:/\)

(∨) :: Expr a -> Expr a -> Expr a
(∨) = (:\/)

(→) :: Expr a -> Expr a -> Expr a
(→) = (:->)

infixr 9 →

(¬) :: Expr a -> Expr a
(¬) (Not e) = e
(¬) e = Not e

instance (Show a) => Show (Expr a) where
    showsPrec _ (Var x) = (show x <>)
    showsPrec d (Not e)
        | d <= 4 = ("¬" <>) . showsPrec 4 e
        | otherwise = ("(¬" <>) . showsPrec 4 e . (")" <>)
    showsPrec d (e1 :/\ e2)
        | d <= 3 = showsPrec 3 e1 . (" ∧ " <>) . showsPrec 3 e2
        | otherwise = ("(" <>) . showsPrec 3 e1 . (" ∧ " <>) . showsPrec 3 e2 . (")" <>)
    showsPrec d (e1 :\/ e2)
        | d <= 2 = showsPrec 2 e1 . (" ∨ " <>) . showsPrec 2 e2
        | otherwise = ("(" <>) . showsPrec 2 e1 . (" ∨ " <>) . showsPrec 2 e2 . (")" <>)
    showsPrec d (e1 :-> e2)
        | d <= 1 = showsPrec 1 e1 . (" → " <>) . showsPrec 1 e2
        | otherwise = ("(" <>) . showsPrec 1 e1 . (" → " <>) . showsPrec 1 e2 . (")" <>)

data Crumb a where
    NotCrumb :: Crumb a
    LAndCrumb :: a -> Crumb a
    RAndCrumb :: a -> Crumb a
    LOrCrumb :: a -> Crumb a
    ROrCrumb :: a -> Crumb a
    LImpliesCrumb :: a -> Crumb a
    RImpliesCrumb :: a -> Crumb a
    deriving (Eq, Show, Functor, Foldable, Traversable)

type Zipper a = ([Crumb (Expr a)], Expr a)

zoop :: Zipper a -> Expr a
zoop = uncurry . flip $ foldr go
  where
    go NotCrumb e = (¬) e
    go (LAndCrumb e2) e = e :/\ e2
    go (RAndCrumb e1) e = e1 :/\ e
    go (LOrCrumb e2) e = e :\/ e2
    go (ROrCrumb e1) e = e1 :\/ e
    go (LImpliesCrumb e2) e = e :-> e2
    go (RImpliesCrumb e1) e = e1 :-> e

zippers :: Expr a -> [Zipper a]
zippers e@(Var _) = [pure e]
zippers e@(Not e1) = pure e : rest
  where
    rest = first (NotCrumb :) <$> zippers e1
zippers e@(e1 :/\ e2) = pure e : rest
  where
    rest = (first (LAndCrumb e2 :) <$> zippers e1) <> (first (RAndCrumb e1 :) <$> zippers e2)
zippers e@(e1 :\/ e2) = pure e : rest
  where
    rest = (first (LOrCrumb e2 :) <$> zippers e1) <> (first (ROrCrumb e1 :) <$> zippers e2)
zippers e@(e1 :-> e2) = pure e : rest
  where
    rest = (first (LImpliesCrumb e2 :) <$> zippers e1) <> (first (RImpliesCrumb e1 :) <$> zippers e2)

rewrites' :: Expr a -> [Expr a]
rewrites' e@(Var _) = [e]
rewrites' e@(Not (Not e1)) = [e1]
rewrites' e@(Not e1) = [e]
rewrites' e@(e1 :/\ e2) = [e, (¬) ((¬) e1 :\/ (¬) e2), e2 :/\ e1]
rewrites' e@(e1 :\/ e2) = [e, (¬) ((¬) e1 :/\ (¬) e2), (¬) e1 :-> e2, e2 :\/ e1]
rewrites' e@(e1 :-> e2) = [e, (¬) e1 :\/ e2, (¬) e2 :-> (¬) e1]

rewrites :: (Eq a) => Expr a -> [Expr a]
rewrites e = do
    (cs, e') <- zippers e
    e'' <- rewrites' e'
    pure $ zoop (cs, e'')

converge :: (Eq a) => (a -> a) -> a -> a
converge f x = x'
  where
    ~(Just (x', _)) = find (uncurry (==)) xys
    xys = zip xs (drop 1 xs)
    xs = iterate f x

allRewrites :: (Eq a) => Expr a -> [Expr a]
allRewrites = nub . converge (rewrites <=< nub) . pure

-- e = Var "x in A" :/\ Var "NeedsA[x]"
-- e = Var 'p' :/\ Var 'q'
e = Var 'p' :-> Var 'q' :-> Var 'r'
