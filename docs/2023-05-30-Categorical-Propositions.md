---
author: GentleTomZerg
tags: logic
title: Categorical propositions
---

<!--toc:start-->

- [Four Kinds of Categorical propositions](#four-kinds-of-categorical-propositions)
  - [A: Universal Affirmative propositions](#a-universal-affirmative-propositions)
  - [E: Universal Negative propositions](#e-universal-negative-propositions)
  - [I: Particular Affirmative propositions](#i-particular-affirmative-propositions)
  - [O: Particular Negative propositions](#o-particular-negative-propositions)
- [Quality, Quantity and Distribution](#quality-quantity-and-distribution)
  - [Quality](#quality)
  - [Quantity](#quantity)
  - [General Schema](#general-schema)
  - [Distribution](#distribution)
- [The traditional square of opposition](#the-traditional-square-of-opposition)
  - [Contradictories](#contradictories)
  - [Contraries](#contraries)
    - [Contingent:star:](#contingentstar)
  - [Subcontraries](#subcontraries)
  - [Subalternation](#subalternation)
  - [The Square of Opposition](#the-square-of-opposition)
  - [Immediate Inferences](#immediate-inferences)
- [Further Immediate Inferences](#further-immediate-inferences)
  - [Conversion](#conversion)
  - [Classes and Class Complements](#classes-and-class-complements)
  - [Obversion](#obversion)
  - [Contraposition](#contraposition)
- [Existential Import and the Interpretation of Categorical Propositions](#existential-import-and-the-interpretation-of-categorical-propositions)
  - [Existential Import](#existential-import)
  - [:star: **Boolean Interpretation of categorical logic**](#star-boolean-interpretation-of-categorical-logic)
  <!--toc:end-->

# Four Kinds of Categorical propositions

## A: Universal Affirmative propositions

<center> All S is P </center>

## E: Universal Negative propositions

<center> No S is P </center>

## I: Particular Affirmative propositions

<center> Some S is P </center>

## O: Particular Negative propositions

<center> Some S is not P </center>

# Quality, Quantity and Distribution

## Quality

- Affirmative(A, I): the propositions affirms some class inclusion, whether complete or
  partial.
- Negative(E, O): the propositions denies some class inclusion, whether complete or
  partial.

## Quantity

- Universal(A, E): the propositions refers to `all members` of the class as its subjects.
- Particular(I, O): the propositions refers only to `some members` of the class designated
  by its subject.

## General Schema

<center>Quantifier + Subject + Copula + Predicate</center>

## Distribution

A proposition distributes a term if it refers to `all members` of the class
designated by that term.

- the **quantity** of any standard-form Categorical proposition **determines** whether
  its **subject term** is distributed or undistributed.
- the **quality** of any standard-form Categorical proposition **determines** whether
  its **predicate term** is distributed or undistributed.

|                                | Predicate term undistributed | Predicate term distributed |
| ------------------------------ | ---------------------------- | -------------------------- |
| **Subject term distributed**   | A: All S is P                | E: No S is P               |
| **Subject term undistributed** | I: Some S is P               | O: Some S is not P         |

# The traditional square of opposition

- **Opposition**: Standard-form categorical propositions having the **same subject**
  terms and the **same predicate** may **differ from each other in quality or in
  quantity or in both**. Any such kind of differing has been traditionally called
  `opposition`.
- Differ in quality: contraries & subcontraries
- Differ in quantity: subalternation
- Differ in both quality and quantity: contradictories

## Contradictories

- Two propositions are contradictories if one is the **denial** or **negation** of the other.
- They can not be both **true** and cannot be both **false**.
- Example:

  ```tex
  A: All judges are lawyers.
  O: Some judges are not lawyers.
  Both opposed in quality and quantity.
  ```

  ```tex
  E: No politicians are idealists.
  I: Some politicians are idealists.
  Both opposed in quality and quantity.
  ```

## Contraries

- Two propositions are said to be contraries if **they cannot both be true**.
- The **truth of one entails the falsity of the other**.
- **But both can be false**
- Example:

  ```tex
  P1: Texas will win the coming game with Oklahoma.
  P2: Oklahoma will win the coming game with Texas.

  The truth of P1 entails the falsity of P2.
  The truth of P2 entails the falsity of P1.
  P1 and P2 can also be false since Texas and Oklahoma could be a draw.

  A: All poets are dreamers.
  E: No poets are dreamers.
  A and E can not both be true, but can both be false(Some poets are dreamers).
  ```

### Contingent:star:

A and E cannot be regarded as contraries when **either the A or E proposition is
necessarily true**, **if either is a logical or mathematical truth.**

```tex
A: All squares are rectangles.
E: No squares are rectangles.
```

Here, E is a mathematical truth, it has no possibility to be false.
**So, A and E are not contraries. Since two propositions can only be contraries if
they can be both false**.

**`Contingent`**: Propositions that are **neither necessarily true nor necessarily
false** are said to be `contingent`.

## Subcontraries

- Two propositions are said to be `Subcontraries` if **they cannot both be false**,
- **They may both be true**.
- Examples:

  ```tex
  I: Some diamonds are precious stones.
  O: Some diamonds are not precious stones.
  ```

- :star: Contingent

  ```tex
  I: Some squares are rectangles.
  O: Some squares are not rectangles.

  Here, I can never be true, so I and O can not be Subcontraries.
  ```

## Subalternation

- Two propositions have the **same subject** and **same predicate** terms, and
  **agree in quality** (both affirming or both denying) but **differ in quantity** (one universal, the other particular). They are called `Corresponding Propositions`.

- The opposition between a universal proposition and its corresponding particular
  proposition is known as **`Subalternation`**.

- **In classic analysis, the superaltern implies the truth of the subaltern**.
- Example:

  ```tex
  A: All spiders are eight-legged animals. (superaltern of I)
  I: Some spiders are eight-legged animals. (subalternation of A)

  E: No whales are fishes. (superaltern of O)
  O: Some whales are not fishes. (subalternation of E)
  ```

## The Square of Opposition

![square of opposition](assets/logic/square-of-opposition.jpg)

## Immediate Inferences

- A is given as true:E is false; I is true; O is false.
- E is given as true:A is false; I is false; O is true.
- I is given as true:E is false; A and O are undetermined.
- O is given as true:A is false; E and I are undetermined.
- A is given as false:O is true; E and I are undetermined.
- E is given as false:I is true; A and O are undetermined.
- I is given as false:A is false; E is true; O is true.
- O is given as false:A is true; E is false; I is true.

# Further Immediate Inferences

- Interchange S and P: **Conversion**
- Change quality & turn P to non-P: **Obversion**
- Interchange S and P & turn S, P to non-S, non-P: **Contraposition**

## Conversion

`conversion` is an inference that proceeds by **interchanging the subject and
predicate** terms of a proposition.

```tex
E proposition
P1: No men are angles.
P2: No angles are men.
-------------
I proposition
P3: Some writers are women.
P4: Some women are writers.
```

- **Conversion** is perfectly **valid** for all **E** and **I** propositions.
- The conversion of an **O** propositions is **not valid**.

  ```tex
  P1: Some animals are not dogs.
  P2: Some dogs are not animals.
  ```

- **Conversion** of **A** is special

  ```tex
  A: All dogs are animals.
  Converse: All animals are dog. (X)

  ```

  However, we can use `subaltern` to do **Conversion by limitation**

  ```mermaid
  graph TD;
  ""A["A: All dogs are animals"] --> I["I: Some dogs are animals"]
  I --conversion--> I1["I1: Some animals are dogs"]


  a["A: All S is P"] --> i["I: Some P is S"]
  ```

- Summary

  | Convertend         | Converse                      |
  | ------------------ | ----------------------------- |
  | A: All S is P      | I: Some P is S(by limitation) |
  | E: No S is P       | E: No P is S                  |
  | I: Some S is P     | I: Some P is S                |
  | O: Some S is not P | Not valid                     |

## Classes and Class Complements

Every class has, associated with it, a **complementary class**, or **complement**, which is the collection of all things that do not belong to the original class.

- Examples:

  ```tex
  Class: People
  Complement (Class of Non-persons): Contains no People, but contains everything else.
  ```

- Contrary and complementary terms:star:

  ```tex
  Contraries: hero, coward
  Complementary: hero, non-hero
  coward is not non-hero!!!
  ```

## Obversion

**Obversion**: **change its quality** and **replace the predicate term with its
complement**.

- Obversion of A == E

  ```tex
  A: All residents are voters.
  Obverse:
  E: No residents are non-voters.
  ```

- Obversion of E == A

  ```tex
  E: No umpires are partisans.
  Obverse:
  A: All umpires are Non-partisans.
  ```

- Obversion of I == O

  ```tex
  I: Some mentals are conductors.
  Obverse:
  O: Some mentals are not non-conductors.
  ```

- Obversion of O == I

  ```tex
  O: Some nations were not belligerents.
  Obverse:
  I: Some nations were non-belligerents.
  ```

- Summary

  | Obvertend          | Obverse                |
  | ------------------ | ---------------------- |
  | A: All S is P      | E: No S is non-P       |
  | E: No S is P       | A: All S is non-P      |
  | I: Some S is P     | O: Some S is not non-P |
  | O: Some S is not P | I: Some S is non-P     |

## Contraposition

**Contraposition**:

- **replace** the **subject** term with the **complement of its
  predicate** term
- and **replace** its **predicate** term with **the complement of its subject**
  term.
- Neither the quality nor the quantity of the original proposition is changes

---

- Contraposition of A == A

  ```tex
  A: All members are voters.
  Contraposition
  A: All non-voters are non-members.

  --- My example ---
  A: All dogs are animals.
  Contraposition
  A: All non-animals are non-dogs.
  ```

- Contraposition of O == O

  ```tex
  O: Some students are not idealists.
  Contraposition
  O: Some non-idealists are not non-students
  ```

  Another way to explain Contraposition of O

  ```mermaid
  graph TD;
  O["O: Some S is not P"] -- obverts--> I["I: Some S is non-P"];
  I -- conversion--> I1["I1: Some non-P is S"]
  I1 -- obverts--> O1["O1: Some non-P is not non-S"]
  ```

- Contraposition of I != I

  ```tex
  I: Some citizens are nonlegislators.
  Contraposition
  I: Some legislators are non-citizens.
  ```

  Another way to explain the Contraposition of I

  ```mermaid
  graph TD;
  I["I: Some S is P"] -- obverts--> O["O: Some S is not non-P"];
  O -- conversion--> O1["O1: Some non-P is not S"]
  O -- not equal --> O1
  ```

- Contraposition of E != E, however.

  ```tex
  E: No wrestlers are weaklings.
  Contraposition
  E: No non-weakings are non-wrestlers.
  ```

  ```mermaid
  graph TD;
  E[E: No S is P] -- obverts--> A[A: All S is non-P]
  A -- converts by limitation--> I[I: Some non-P is S]
  I -- obverts--> O[O: Some non-P is not non-S]
  E -- Contraposition by limitation--> O
  ```

- Summary

  - **Contraposition** is thus seen to be **valid** only when applied to **A** and **O** propositions.
  - **Not valid** at all for **I** proposition.
  - **Valid** for **E** only by **limitations**.

  | Premise            | Contraposition                            |
  | ------------------ | ----------------------------------------- |
  | A: All S is P      | A: All non-P is non-S                     |
  | E: No S is P       | O: Some non-P is not non-S(by limitation) |
  | I: Some S is P     | not valid                                 |
  | O: Some S is not P | O: Some non-P is not non-S                |

# Existential Import and the Interpretation of Categorical Propositions

## Existential Import

**Existential Import**: A proposition is said to have existential import if it
typically is uttered to **assert the existence of objects of some kind**.

- Consequences of existential import

  I and O propositions have existential import.

  ```tex
  I: Some soldiers are heroes.
  --> there exists at least one soldier who is a hero.
  O: Some dogs are not companions.
  --> there exists at least one dog that is not a companion.
  ```

  In [earlier introduction](#the-square-of-opposition) we supposed that an I
  proposition follows validly from its corresponding A proposition by
  **subalternation**. Similarly, we supposed that an O proposition follows
  validly from its corresponding E proposition.

  Therefore, if I and O propositions have existential import and they follow
  validly from their corresponding A and E propositions, then **A and E
  propositions must also have existential import**. Because a proposition with
  existential import cannot be derived validly from another that does not have
  such import.

- The problem of the Consequences

  In [traditional square of opposition](#the-square-of-opposition), A and O
  propositions are contradictories. **Contradictories can not both be true and
  both be false.** They can only be one true and one false.

  ```tex
  A: All inhabitants of Mars are blonde.
  Contradictories
  O: Some inhabitants of Mars are not blonde.
  ```

  If we interpreted A and O as asserting that there are inhabitants of Mars,
  then **both of these propositions are <u>false</u> if Mars has no inhabitants.**

  **<center>:star: So A and O are not Contradictories!!!</center>**

- How to solve the **Problem**?

  To rescue the square of opposition, we might insist that all propositions(A,
  E, I, O) **PRESUPPOSE** that **the classes to which they refer do have
  members.**

  > To achieve this result, however, we must pay by accepting the **blanket
  > presupposition** that **all classes(including their complements)** designated by our terms do have
  > members---are not empty.

- The cost of **blanket presupposition**

  - we will **never** be able to formulate the proposition that **denies that the
    class has members**. Example:

    ```tex
    No unicorns are creatures that exist.
    ```

  - even ordinary usage of language is not in complete accord with this
    **blanket presupposition**. "All" may refer to possibly empty classes.

    ```tex
    "All trespassers will be prosecuted."
    The speaker said this would be intending to ensure that the class will
    become and remain empty.
    ```

  - In science and other theoretical spheres, we often wish to reason without
    making any presupposition about existence. Example,

    > Newton’s first law of motion, for example, asserts that
    > certain things are true about bodies that are not acted on by any external forces: They remain at
    > rest, or they continue their straight-line motion. The law may be true; a physicist may wish to
    > express and defend it without wanting to presuppose that there actually are any bodies that are
    > not acted on by external forces.

## :star: **Boolean Interpretation of categorical logic**

1. **I** and **O** propositions continue to **have existential import** in the
   **Boolean Interpretation**.

   However, **if the class S is empty**, the propositions "Some S is not P" and
   "Some S is P" are both false.

2. **A** and **E** are the **contradictories** of the particular propositions, **O**
   and **I**.

   However, in the **boolean interpretation**, <u>universal propositions are
   interpreted as having **no** existential import.</u>

   ```tex
   A and E can both be true even if there might be no unicorns
   A: All unicorns have horns.
   E: No unicorns have wings.
   --------------------------
   I and O will both be false if there are no unicorns.
   I: Some unicorns have horns.
   O: Some unicorns do not have wings.
   ```

3. If we utter a **universal proposition** with which we do intend to **assert
   existence**. **Boolean interpretation permits this to be expressed**.

   However, it requires two propositions.

   - one existential in force but particular.
   - the other universal but not existential in force.

   ```tex
   "All planets in our solar system revolve around the sun."
   --> A universal proposition that has no existential import.

   if we express the propositon intending also to assert the existence of
   planets in our solar system that do so revolve, we would need to add:

   "mars is a planet in our solar system."
   --> A particular proposition that has desired existential force.
   ```

4. Changes from adoption of Boolean interpretation

- Corresponding **A** and **E** propositions **can both be true** and are
  therefore
  **not contraries**. This may seem paradoxical, but look at the example:

  ```tex
  A: All unicorns have wings.
  --> if there is a unicorn, then it has wings.
  E: No unicorns have wings.
  --> if there is a unicorn, then it does not have wings.
  ```

  :star:If there is no unicorn, then A and E can both be true.

- Corresponding **I** and **O** propositions **can both be false** and are
  therefore **not subcontraries**.

  ```tex
  I: Some unicorns have wings.
  O: Some unicorns does not have wings.
  ```

  I and O have existential import, if unicorn does not exist, then they both be
  false.

- Subalternation is not valid.

  Because one may not validly infer a proposition that has existential import
  from one that does not.

5. [Immediate Inferences](#immediate-inferences) in Boolean Interpretation

- **Conversion** for **E** and **I** is preserved.
- **Contraposition** for **A** and **O** is preserved.
- **Obversion** for **any proposition** is preserved.
- Conversion by limitation and Contraposition by limitation are not valid.

6. **Summary**

> The traditional square of opposition, in the Boolean Interpretation, is
> transformed in the following general way:

- Relations along the side of the square are undone.
- Relations along the diagonal, contradictory relations remain in force.

> In short, the blanket existential presupposition is rejected by modern logicians. It is a
> mistake, we hold, **to assume that a class has members if it is not asserted explicitly that it does.**
> Any argument that relies on this mistaken assumption is said to commit the **fallacy of existential
> assumption**, or more briefly, the existential fallacy.

# Symbolism and Diagrams for Categorical Propositions

- To say that a class designated by the term S has no members:
  $$ S = 0 $$

- To say that a class designated by the term S has members:
  $$ S \neq 0 $$

- To symbolize a class designated by the term non-S:
  $$ \bar S$$

## Symbolic Representation of Categorical Propositions

| Form | Propositon      | Symbolic Representation |
| ---- | --------------- | ----------------------- |
| A    | All S is P      | $S \bar P = 0$          |
| E    | No S is P       | $S  P = 0$              |
| I    | Some S is P     | $S P \neq 0$            |
| O    | Some S is not P | $S \bar P \neq 0$       |

## Venn Graph Representation

![Venn-Graph-Representation](assets/logic/venn-graph-representation.jpg)
