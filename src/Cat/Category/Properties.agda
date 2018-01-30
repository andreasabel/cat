{-# OPTIONS --allow-unsolved-metas --cubical #-}

module Cat.Category.Properties where

open import Agda.Primitive
open import Data.Product
open import Cubical
import Cubical.WrappedPath
module WP = Cubical.WrappedPath

open import Cat.Category
open import Cat.Functor
open import Cat.Categories.Sets

module _ {ℓ ℓ' : Level} {ℂ : Category ℓ ℓ'} { A B : ℂ .Category.Object } {X : ℂ .Category.Object} (f : ℂ .Category.Arrow A B) where
  open Category ℂ
  open IsCategory (isCategory)

  iso-is-epi : Isomorphism {ℂ = ℂ} f → Epimorphism {ℂ = ℂ} {X = X} f
  iso-is-epi (f- , left-inv , right-inv) g₀ g₁ eq =
    begin
    g₀              ≡⟨ sym (proj₁ ident) ⟩
    g₀ ⊕ 𝟙          ≡⟨ cong (_⊕_ g₀) (sym right-inv) ⟩
    g₀ ⊕ (f ⊕ f-)   ≡⟨ assoc ⟩
    (g₀ ⊕ f) ⊕ f-   ≡⟨ cong (λ φ → φ ⊕ f-) eq ⟩
    (g₁ ⊕ f) ⊕ f-   ≡⟨ sym assoc ⟩
    g₁ ⊕ (f ⊕ f-)   ≡⟨ cong (_⊕_ g₁) right-inv ⟩
    g₁ ⊕ 𝟙          ≡⟨ proj₁ ident ⟩
    g₁              ∎

  iso-is-mono : Isomorphism {ℂ = ℂ} f → Monomorphism {ℂ = ℂ} {X = X} f
  iso-is-mono (f- , (left-inv , right-inv)) g₀ g₁ eq =
    begin
    g₀            ≡⟨ sym (proj₂ ident) ⟩
    𝟙 ⊕ g₀        ≡⟨ cong (λ φ → φ ⊕ g₀) (sym left-inv) ⟩
    (f- ⊕ f) ⊕ g₀ ≡⟨ sym assoc ⟩
    f- ⊕ (f ⊕ g₀) ≡⟨ cong (_⊕_ f-) eq ⟩
    f- ⊕ (f ⊕ g₁) ≡⟨ assoc ⟩
    (f- ⊕ f) ⊕ g₁ ≡⟨ cong (λ φ → φ ⊕ g₁) left-inv ⟩
    𝟙 ⊕ g₁        ≡⟨ proj₂ ident ⟩
    g₁            ∎

  iso-is-epi-mono : Isomorphism {ℂ = ℂ} f → Epimorphism {ℂ = ℂ} {X = X} f × Monomorphism {ℂ = ℂ} {X = X} f
  iso-is-epi-mono iso = iso-is-epi iso , iso-is-mono iso

{-
epi-mono-is-not-iso : ∀ {ℓ ℓ'} → ¬ ((ℂ : Category {ℓ} {ℓ'}) {A B X : Object ℂ} (f : Arrow ℂ A B ) → Epimorphism {ℂ = ℂ} {X = X} f → Monomorphism {ℂ = ℂ} {X = X} f → Isomorphism {ℂ = ℂ} f)
epi-mono-is-not-iso f =
  let k = f {!!} {!!} {!!} {!!}
  in {!!}
-}

module _ {ℓ : Level} {ℂ : Category ℓ ℓ} where
  open import Cat.Category
  open Category
  open import Cat.Categories.Cat using (Cat)
  open import Cat.Categories.Fun
  open import Cat.Categories.Sets
  module Cat = Cat.Categories.Cat
  open Exponential
  private
    Catℓ = Cat ℓ ℓ
    prshf = presheaf {ℂ = ℂ}

    -- Exp : Set (lsuc (lsuc ℓ))
    -- Exp = Exponential (Cat (lsuc ℓ) ℓ)
    --   Sets (Opposite ℂ)

    _⇑_ : (A B : Catℓ .Object) → Catℓ .Object
    A ⇑ B = (exponent A B) .obj
      where
        open HasExponentials (Cat.hasExponentials ℓ)

    module _ {A B : ℂ .Object} (f : ℂ .Arrow A B) where
      :func→: : NaturalTransformation (prshf A) (prshf B)
      :func→: = (λ C x → (ℂ ._⊕_ f x)) , λ f₁ → funExt λ x → lem
        where
          lem = (ℂ .isCategory) .IsCategory.assoc
    module _ {c : ℂ .Object} where
      eqTrans : (:func→: (ℂ .𝟙 {c})) .proj₁ ≡ (Fun .𝟙 {o = prshf c}) .proj₁
      eqTrans = funExt λ x → funExt λ x → ℂ .isCategory .IsCategory.ident .proj₂
      eqNat : (i : I) → Natural (prshf c) (prshf c) (eqTrans i)
      eqNat i f = {!!}

      :ident: : (:func→: (ℂ .𝟙 {c})) ≡ (Fun .𝟙 {o = prshf c})
      -- Consider this:
      --     :ident: = {!λ i → eqTrans i , eqNat i!}
      -- Goal:
      --     :func→: (ℂ .𝟙) ≡ Fun .𝟙
      -- Goal if normalized:
      --     PathP (λ _ → Σ ((C : ℂ .Object) → ℂ .Arrow C c → ℂ .Arrow ...
      -- Now consider this:
      --     :ident: = WP.at {!!}
      -- Goal:
      --     WP.PathP
      --       (λ _ →
      --         Σ (Transformation (prshf c) (prshf c))
      --         (Natural (prshf c) (prshf c)))
      --       (:func→: (ℂ .𝟙)) (Fun .𝟙)
      -- Goal if normalized:
      --     WP.PathP (λ _ → Σ ((C : ℂ .Object) → ℂ .Arrow C c → ℂ .Arrow ...
      :ident: = λ i → eqTrans i , eqNat i

  yoneda : Functor ℂ (Fun {ℂ = Opposite ℂ} {𝔻 = Sets {ℓ}})
  yoneda = record
    { func* = prshf
    ; func→ = :func→:
    ; ident = :ident:
    ; distrib = {!!}
    }
