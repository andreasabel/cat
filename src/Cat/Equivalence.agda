{-# OPTIONS --allow-unsolved-metas --cubical #-}
module Cat.Equivalence where

open import Cubical.Primitives
open import Cubical.FromStdLib renaming (ℓ-max to _⊔_)
open import Cubical.PathPrelude hiding (inverse ; _≃_)
open import Cubical.PathPrelude using (isEquiv ; isContr ; fiber) public
open import Cubical.GradLemma

open import Cat.Prelude using (lemPropF ; setPi ; lemSig ; propSet ; Preorder ; equalityIsEquivalence)

module _ {ℓa ℓb : Level} where
  private
    ℓ = ℓa ⊔ ℓb

  module _ {A : Set ℓa} {B : Set ℓb} where
    -- Quasi-inverse in [HoTT] §2.4.6
    -- FIXME Maybe rename?
    record AreInverses (f : A → B) (g : B → A) : Set ℓ where
      field
        verso-recto : g ∘ f ≡ idFun A
        recto-verso : f ∘ g ≡ idFun B
      obverse = f
      reverse = g
      inverse = reverse
      toPair : Σ _ _
      toPair = verso-recto , recto-verso

    Isomorphism : (f : A → B) → Set _
    Isomorphism f = Σ (B → A) λ g → AreInverses f g

    module _ {f : A → B} {g : B → A}
        (inv : (g ∘ f) ≡ idFun A
             × (f ∘ g) ≡ idFun B) where
      open Σ inv renaming (fst to ve-re ; snd to re-ve)
      toAreInverses : AreInverses f g
      toAreInverses = record
        { verso-recto = ve-re
        ; recto-verso = re-ve
        }

  _≅_ : Set ℓa → Set ℓb → Set _
  A ≅ B = Σ (A → B) Isomorphism

module _ {ℓ : Level} {A B : Set ℓ} {f : A → B}
  (g : B → A) (s : {A B : Set ℓ} → isSet (A → B)) where

  propAreInverses : isProp (AreInverses {A = A} {B} f g)
  propAreInverses x y i = record
    { verso-recto = ve-re
    ; recto-verso = re-ve
    }
    where
    open AreInverses
    ve-re : g ∘ f ≡ idFun A
    ve-re = s (g ∘ f) (idFun A) (verso-recto x) (verso-recto y) i
    re-ve : f ∘ g ≡ idFun B
    re-ve = s (f ∘ g) (idFun B) (recto-verso x) (recto-verso y) i

module _ {ℓ : Level} {A B : Set ℓ} (f : A → B)
  (sA : isSet A) (sB : isSet B) where

  propIsIso : isProp (Isomorphism f)
  propIsIso = res
        where
        module _ (x y : Isomorphism f) where
          module x = Σ x renaming (fst to inverse ; snd to areInverses)
          module y = Σ y renaming (fst to inverse ; snd to areInverses)
          module xA = AreInverses x.areInverses
          module yA = AreInverses y.areInverses
          -- I had a lot of difficulty using the corresponding proof where
          -- AreInverses is defined. This is sadly a bit anti-modular. The
          -- reason for my troubles is probably related to the type of objects
          -- being hSet's rather than sets.
          p : ∀ {f} g → isProp (AreInverses {A = A} {B} f g)
          p {f} g xx yy i = record
            { verso-recto = ve-re
            ; recto-verso = re-ve
            }
            where
            module xxA = AreInverses xx
            module yyA = AreInverses yy
            setPiB : ∀ {X : Set ℓ} → isSet (X → B)
            setPiB = setPi (λ _ → sB)
            setPiA : ∀ {X : Set ℓ} → isSet (X → A)
            setPiA = setPi (λ _ → sA)
            ve-re : g ∘ f ≡ idFun _
            ve-re = setPiA _ _ xxA.verso-recto yyA.verso-recto i
            re-ve : f ∘ g ≡ idFun _
            re-ve = setPiB _ _ xxA.recto-verso yyA.recto-verso i
          1eq : x.inverse ≡ y.inverse
          1eq = begin
            x.inverse                   ≡⟨⟩
            x.inverse ∘ idFun _         ≡⟨ cong (λ φ → x.inverse ∘ φ) (sym yA.recto-verso) ⟩
            x.inverse ∘ (f ∘ y.inverse) ≡⟨⟩
            (x.inverse ∘ f) ∘ y.inverse ≡⟨ cong (λ φ → φ ∘ y.inverse) xA.verso-recto ⟩
            idFun _ ∘ y.inverse         ≡⟨⟩
            y.inverse                   ∎
          2eq : (λ i → AreInverses f (1eq i)) [ x.areInverses ≡ y.areInverses ]
          2eq = lemPropF p 1eq
          res : x ≡ y
          res i = 1eq i , 2eq i

-- In HoTT they generalize an equivalence to have the following 3 properties:
module _ {ℓa ℓb ℓ : Level} (A : Set ℓa) (B : Set ℓb) where
  record Equiv (iseqv : (A → B) → Set ℓ) : Set (ℓa ⊔ ℓb ⊔ ℓ) where
    field
      fromIso      : {f : A → B} → Isomorphism f → iseqv f
      toIso        : {f : A → B} → iseqv f → Isomorphism f
      propIsEquiv  : (f : A → B) → isProp (iseqv f)

    -- You're alerady assuming here that we don't need eta-equality on the
    -- equivalence!
    _~_ : Set ℓa → Set ℓb → Set _
    A ~ B = Σ _ iseqv

    inverse-from-to-iso : ∀ {f} (x : _) → (fromIso {f} ∘ toIso {f}) x ≡ x
    inverse-from-to-iso x = begin
      (fromIso ∘ toIso) x ≡⟨⟩
      fromIso (toIso x)   ≡⟨ propIsEquiv _ (fromIso (toIso x)) x ⟩
      x ∎

    -- `toIso` is abstract - so I probably can't close this proof.
    module _ (sA : isSet A) (sB : isSet B) where
      module _ {f : A → B} (iso : Isomorphism f) where
        module _ (iso-x iso-y : Isomorphism f) where
          open Σ iso-x renaming (fst to x ; snd to inv-x)
          open Σ iso-y renaming (fst to y ; snd to inv-y)
          module inv-x = AreInverses inv-x
          module inv-y = AreInverses inv-y

          fx≡fy : x ≡ y
          fx≡fy = begin
            x             ≡⟨ cong (λ φ → x ∘ φ) (sym inv-y.recto-verso) ⟩
            x ∘ (f ∘ y)   ≡⟨⟩
            (x ∘ f) ∘ y   ≡⟨ cong (λ φ → φ ∘ y) inv-x.verso-recto ⟩
            y ∎

          open import Cat.Prelude

          propInv : ∀ g → isProp (AreInverses f g)
          propInv g t u i = record { verso-recto = a i ; recto-verso = b i }
            where
            module t = AreInverses t
            module u = AreInverses u
            a : t.verso-recto ≡ u.verso-recto
            a i = h
              where
              hh : ∀ a → (g ∘ f) a ≡ a
              hh a = sA ((g ∘ f) a) a (λ i → t.verso-recto i a) (λ i → u.verso-recto i a) i
              h : g ∘ f ≡ idFun A
              h i a = hh a i
            b : t.recto-verso ≡ u.recto-verso
            b i = h
              where
              hh : ∀ b → (f ∘ g) b ≡ b
              hh b = sB _ _ (λ i → t.recto-verso i b) (λ i → u.recto-verso i b) i
              h : f ∘ g ≡ idFun B
              h i b = hh b i

          inx≡iny : (λ i → AreInverses f (fx≡fy i)) [ inv-x ≡ inv-y ]
          inx≡iny = lemPropF propInv fx≡fy

          propIso : iso-x ≡ iso-y
          propIso i = fx≡fy i , inx≡iny i

        inverse-to-from-iso : (toIso {f} ∘ fromIso {f}) iso ≡ iso
        inverse-to-from-iso = begin
          (toIso ∘ fromIso) iso ≡⟨⟩
          toIso (fromIso iso)   ≡⟨ propIso _ _ ⟩
          iso ∎

    fromIsomorphism : A ≅ B → A ~ B
    fromIsomorphism (f , iso) = f , fromIso iso

    toIsomorphism : A ~ B → A ≅ B
    toIsomorphism (f , eqv) = f , toIso eqv

module _ {ℓa ℓb : Level} (A : Set ℓa) (B : Set ℓb) where
  -- A wrapper around PathPrelude.≃
  open Cubical.PathPrelude using (_≃_)
  private
    module _ {obverse : A → B} (e : isEquiv A B obverse) where
      inverse : B → A
      inverse b = fst (fst (e b))

      reverse : B → A
      reverse = inverse

      areInverses : AreInverses obverse inverse
      areInverses = record
        { verso-recto = funExt verso-recto
        ; recto-verso = funExt recto-verso
        }
        where
        recto-verso : ∀ b → (obverse ∘ inverse) b ≡ b
        recto-verso b = begin
          (obverse ∘ inverse) b ≡⟨ sym (μ b) ⟩
          b ∎
          where
          μ : (b : B) → b ≡ obverse (inverse b)
          μ b = snd (fst (e b))
        verso-recto : ∀ a → (inverse ∘ obverse) a ≡ a
        verso-recto a = begin
          (inverse ∘ obverse) a ≡⟨ sym h ⟩
          a'                    ≡⟨ u' ⟩
          a ∎
          where
          c : isContr (fiber obverse (obverse a))
          c = e (obverse a)
          fbr : fiber obverse (obverse a)
          fbr = fst c
          a' : A
          a' = fst fbr
          allC : (y : fiber obverse (obverse a)) → fbr ≡ y
          allC = snd c
          k : fbr ≡ (inverse (obverse a), _)
          k = allC (inverse (obverse a) , sym (recto-verso (obverse a)))
          h : a' ≡ inverse (obverse a)
          h i = fst (k i)
          u : fbr ≡ (a , refl)
          u = allC (a , refl)
          u' : a' ≡ a
          u' i = fst (u i)

      iso : Isomorphism obverse
      iso = reverse , areInverses

    toIsomorphism : {f : A → B} → isEquiv A B f → Isomorphism f
    toIsomorphism = iso

    ≃isEquiv : Equiv A B (isEquiv A B)
    Equiv.fromIso     ≃isEquiv {f} (f~ , iso) = gradLemma f f~ rv vr
      where
      open AreInverses iso
      rv : (b : B) → _ ≡ b
      rv b i = recto-verso i b
      vr : (a : A) → _ ≡ a
      vr a i = verso-recto i a
    Equiv.toIso        ≃isEquiv = toIsomorphism
    Equiv.propIsEquiv  ≃isEquiv = P.propIsEquiv
      where
      import Cubical.NType.Properties as P

  module Equiv≃ where
    open Equiv ≃isEquiv public

module _ {ℓa ℓb : Level} {A : Set ℓa} {B : Set ℓb} where
  open Cubical.PathPrelude using (_≃_)

  module _ {ℓc : Level} {C : Set ℓc} {f : A → B} {g : B → C} where

    composeIsomorphism : Isomorphism f → Isomorphism g → Isomorphism (g ∘ f)
    composeIsomorphism a b = f~ ∘ g~ , inv
      where
      open Σ a renaming (fst to f~ ; snd to inv-a)
      module A = AreInverses inv-a
      open Σ b renaming (fst to g~ ; snd to inv-b)
      module B = AreInverses inv-b
      inv : AreInverses (g ∘ f) (f~ ∘ g~)
      inv = record
        { verso-recto = begin
          (f~ ∘ g~) ∘ (g ∘ f) ≡⟨⟩
          f~ ∘ (g~ ∘ g) ∘ f   ≡⟨ cong (λ φ → f~ ∘ φ ∘ f) B.verso-recto ⟩
          f~ ∘ idFun _ ∘ f    ≡⟨⟩
          f~ ∘ f              ≡⟨ A.verso-recto ⟩
          idFun A             ∎
        ; recto-verso = begin
          (g ∘ f) ∘ (f~ ∘ g~) ≡⟨⟩
          g ∘ (f ∘ f~) ∘ g~   ≡⟨ cong (λ φ → g ∘ φ ∘ g~) A.recto-verso ⟩
          g ∘ g~              ≡⟨ B.recto-verso ⟩
          idFun C             ∎
        }

    composeIsEquiv : isEquiv A B f → isEquiv B C g → isEquiv A C (g ∘ f)
    composeIsEquiv a b = Equiv≃.fromIso A C (composeIsomorphism a' b')
      where
      a' = Equiv≃.toIso A B a
      b' = Equiv≃.toIso B C b

  composeIso : {ℓc : Level} {C : Set ℓc} → (A ≅ B) → (B ≅ C) → A ≅ C
  composeIso {C = C} (f , iso-f) (g , iso-g) = g ∘ f , composeIsomorphism iso-f iso-g

  -- Gives the quasi inverse from an equivalence.
  module Equivalence (e : A ≃ B) where
    open Equiv≃ A B public
    private
      iso : Isomorphism (fst e)
      iso = snd (toIsomorphism e)

    open AreInverses (snd iso) public

    compose : {ℓc : Level} {C : Set ℓc} → (B ≃ C) → A ≃ C
    compose (f , isEquiv) = f ∘ obverse , composeIsEquiv (snd e) isEquiv

    symmetryIso : B ≅ A
    symmetryIso
      = inverse
      , obverse
      , record
        { verso-recto = recto-verso
        ; recto-verso = verso-recto
        }

    symmetry : B ≃ A
    symmetry = B≃A.fromIsomorphism symmetryIso
      where
      module B≃A = Equiv≃ B A

preorder≅ : (ℓ : Level) → Preorder _ _ _
preorder≅ ℓ = record
  { Carrier = Set ℓ ; _≈_ = _≡_ ; _∼_ = _≅_
  ; isPreorder = record
    { isEquivalence = equalityIsEquivalence
    ; reflexive = λ p
      → coe p
      , coe (sym p)
      -- I believe I stashed the proof of this somewhere.
      , record
        { verso-recto = {!refl!}
        ; recto-verso = {!!}
        }
    ; trans = composeIso
    }
  }

module _ {ℓa ℓb : Level} {A : Set ℓa} {B : Set ℓb} where
  open import Cubical.PathPrelude renaming (_≃_ to _≃η_)
  open import Cubical.Univalence using (_≃_)

  doEta : A ≃ B → A ≃η B
  doEta (_≃_.con eqv isEqv) = eqv , isEqv

  deEta : A ≃η B → A ≃ B
  deEta (eqv , isEqv) = _≃_.con eqv isEqv

module NoEta {ℓa ℓb : Level} {A : Set ℓa} {B : Set ℓb} where
  open import Cubical.PathPrelude renaming (_≃_ to _≃η_)
  open import Cubical.Univalence using (_≃_)

  module Equivalence′ (e : A ≃ B) where
    open Equivalence (doEta e) hiding
      ( toIsomorphism ; fromIsomorphism ; _~_
      ; compose ; symmetryIso ; symmetry ) public

    compose : {ℓc : Level} {C : Set ℓc} → (B ≃ C) → A ≃ C
    compose ee = deEta (Equivalence.compose (doEta e) (doEta ee))

    symmetry : B ≃ A
    symmetry = deEta (Equivalence.symmetry (doEta e))

  -- fromIso      : {f : A → B} → Isomorphism f → isEquiv f
  -- fromIso = ?

  -- toIso        : {f : A → B} → isEquiv f → Isomorphism f
  -- toIso = ?

  fromIsomorphism : A ≅ B → A ≃ B
  fromIsomorphism (f , iso) = _≃_.con f (Equiv≃.fromIso _ _ iso)

  toIsomorphism : A ≃ B → A ≅ B
  toIsomorphism (_≃_.con f eqv) = f , Equiv≃.toIso _ _ eqv

-- A few results that I have not generalized to work with both the eta and no-eta variable of ≃
module _ {ℓa ℓb : Level} {A : Set ℓa} {P : A → Set ℓb} where
  open NoEta
  open import Cubical.Univalence using (_≃_)

  -- Equality on sigma's whose second component is a proposition is equivalent
  -- to equality on their first components.
  equivPropSig : ((x : A) → isProp (P x)) → (p q : Σ A P)
    → (p ≡ q) ≃ (fst p ≡ fst q)
  equivPropSig pA p q = fromIsomorphism iso
    where
    f : ∀ {p q} → p ≡ q → fst p ≡ fst q
    f e i = fst (e i)
    g : ∀ {p q} → fst p ≡ fst q → p ≡ q
    g {p} {q} = lemSig pA p q
    ve-re : (e : p ≡ q) → (g ∘ f) e ≡ e
    ve-re = pathJ (\ q (e : p ≡ q) → (g ∘ f) e ≡ e)
              (\ i j → p .fst , propSet (pA (p .fst)) (p .snd) (p .snd) (λ i → (g {p} {p} ∘ f) (λ i₁ → p) i .snd) (λ i → p .snd) i j ) q
    re-ve : (e : fst p ≡ fst q) → (f {p} {q} ∘ g {p} {q}) e ≡ e
    re-ve e = refl
    inv : AreInverses (f {p} {q}) (g {p} {q})
    inv = record
      { verso-recto = funExt ve-re
      ; recto-verso = funExt re-ve
      }
    iso : (p ≡ q) ≅ (fst p ≡ fst q)
    iso = f , g , inv

  -- Sigma that are equivalent on all points in the second projection are
  -- equivalent.
  equivSigSnd : ∀ {ℓc} {Q : A → Set (ℓc ⊔ ℓb)}
    → ((a : A) → P a ≃ Q a) → Σ A P ≃ Σ A Q
  equivSigSnd {Q = Q} eA = res
    where
    f : Σ A P → Σ A Q
    f (a , pA) = a , _≃_.eqv (eA a) pA
    g : Σ A Q → Σ A P
    g (a , qA) = a , g' qA
      where
      k : Isomorphism _
      k = Equiv≃.toIso _ _ (_≃_.isEqv (eA a))
      open Σ k renaming (fst to g')
    ve-re : (x : Σ A P) → (g ∘ f) x ≡ x
    ve-re x i = fst x , eq i
      where
      eq : snd ((g ∘ f) x) ≡ snd x
      eq = begin
        snd ((g ∘ f) x) ≡⟨⟩
        snd (g (f (a , pA))) ≡⟨⟩
        g' (_≃_.eqv (eA a) pA) ≡⟨ lem ⟩
        pA ∎
        where
        open Σ x renaming (fst to a ; snd to pA)
        k : Isomorphism _
        k = Equiv≃.toIso _ _ (_≃_.isEqv (eA a))
        open Σ k renaming (fst to g' ; snd to inv)
        module A = AreInverses inv
        -- anti-funExt
        lem : (g' ∘ (_≃_.eqv (eA a))) pA ≡ pA
        lem i = A.verso-recto i pA
    re-ve : (x : Σ A Q) → (f ∘ g) x ≡ x
    re-ve x i = fst x , eq i
      where
      open Σ x renaming (fst to a ; snd to qA)
      eq = begin
        snd ((f ∘ g) x)                 ≡⟨⟩
        _≃_.eqv (eA a) (g' qA)            ≡⟨ (λ i → A.recto-verso i qA) ⟩
        qA                                ∎
        where
        k : Isomorphism _
        k = Equiv≃.toIso _ _ (_≃_.isEqv (eA a))
        open Σ k renaming (fst to g' ; snd to inv)
        module A = AreInverses inv
    inv : AreInverses f g
    inv = record
      { verso-recto = funExt ve-re
      ; recto-verso = funExt re-ve
      }
    iso : Σ A P ≅ Σ A Q
    iso = f , g , inv
    res : Σ A P ≃ Σ A Q
    res = fromIsomorphism iso

module _ {ℓa ℓb : Level} {A : Set ℓa} {B : Set ℓb} where
  open NoEta
  open import Cubical.Univalence using (_≃_)
  -- Equivalence is equivalent to isomorphism when the domain and codomain of
  -- the equivalence is a set.
  equivSetIso : isSet A → isSet B → (f : A → B)
    → isEquiv A B f ≃ Isomorphism f
  equivSetIso sA sB f =
    let
      obv : isEquiv A B f → Isomorphism f
      obv = Equiv≃.toIso A B
      inv : Isomorphism f → isEquiv A B f
      inv = Equiv≃.fromIso A B
      re-ve : (x : isEquiv A B f) → (inv ∘ obv) x ≡ x
      re-ve = Equiv≃.inverse-from-to-iso A B
      ve-re : (x : Isomorphism f)       → (obv ∘ inv) x ≡ x
      ve-re = Equiv≃.inverse-to-from-iso A B sA sB
      iso : isEquiv A B f ≅ Isomorphism f
      iso = obv , inv ,
        record
          { verso-recto = funExt re-ve
          ; recto-verso = funExt ve-re
          }
    in fromIsomorphism iso
