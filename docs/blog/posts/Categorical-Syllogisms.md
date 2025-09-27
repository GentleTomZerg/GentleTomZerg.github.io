---
authors:
  - GentleTomZerg
categories:
  - Logic
date: 2023-05-20
title: Categorical Syllogisms
---

<!--toc:start-->

- [Standard-Form Categorical Syllogisms](#standard-form-categorical-syllogisms)
  - [Terms of the Syllogisms: Major, Minor, and Middle](#terms-of-the-syllogisms-major-minor-and-middle)
  - [The mood of the Syllogism](#the-mood-of-the-syllogism)
  - [The figure of the Syllogism](#the-figure-of-the-syllogism)
  <!-- more -->
- [The Formal Nature of Syllogistic Argument](#the-formal-nature-of-syllogistic-argument)
- [Venn Diagram Technique for Testing Syllogisms](#venn-diagram-technique-for-testing-syllogisms)
  - [Example: Venn Graph for AAA-1](#example-venn-graph-for-aaa-1)
  - [Diagram the universal premise first](#diagram-the-universal-premise-first)
  - [:star: Put x at border](#star-put-x-at-border)
  - [Technique Summary](#technique-summary)
  - [:star:Why Venn Diagram can tell the validity?](#starwhy-venn-diagram-can-tell-the-validity)
- [Syllogistic Rules and Syllogistic Fallacies](#syllogistic-rules-and-syllogistic-fallacies)
  - [Rule 1: Avoid Four Terms](#rule-1-avoid-four-terms)
  - [Rule 2: Distribute the middle term in at least one premise](#rule-2-distribute-the-middle-term-in-at-least-one-premise)
  - [:star:Rule 3: Any term distributed in the conclusion must be distributed in the premises.](#starrule-3-any-term-distributed-in-the-conclusion-must-be-distributed-in-the-premises)
  - [Rule 4: Avoid two negative premises](#rule-4-avoid-two-negative-premises)
  - [Rule 5: If either premise is negative, the conclusion must be negative](#rule-5-if-either-premise-is-negative-the-conclusion-must-be-negative)
  - [Rule 6: From two universal premises no particular conclusion may be drawn](#rule-6-from-two-universal-premises-no-particular-conclusion-may-be-drawn)
- [:star: Exposition of the Fifteen Valid Forms of the Categorical Syllogism](#star-exposition-of-the-fifteen-valid-forms-of-the-categorical-syllogism)
<!--toc:end-->

## Standard-Form Categorical Syllogisms

**Categorical Syllogisms** is defined as a **deductive argument** consisting of **three** categorical propositions that together
**contain exactly three terms**, **each** of which **occurs** in exactly **two** of the
constituent propositions.

- Standard-Form

  A Categorical Syllogisms is said to be `Standard-Form` when two things are
  true of it:

  1. its premises and its conclusion are all Standard-Form categorical syllogisms propositions(A,E,I or O).
  2. those propositions are arranged in a specified **standard order**.

### Terms of the Syllogisms: Major, Minor, and Middle

```tex
No heros are cowards.
Some soldiers are cowards.
Therefore some soldiers are not heros.

Major Term: hero
Minor Term: soldier
Middle Term: coward
Major Premise: No heros are cowards.
Minor Premise: Some soldiers are cowards.
```

| Term          | Parts                                                            |
| ------------- | ---------------------------------------------------------------- |
| Major Term    | The predicate term of the conclusion.                            |
| Minor Term    | The subject term of the conclusion.                              |
| Middle Term   | The term that appears in both premises but not in the conclusion |
| Major Premise | The premise containing the major term.                           |
| Minor Premise | The premise containing the minor term.                           |

**In a standard-form syllogism, the major premise is always stated first, the
minor premise second, and the conclusion last.**

### The mood of the Syllogism

**mood**: is determined by the types (A, E, I, O) of standard-form categorical
propositions it contains. For example, the mood of the syllogism below is called
**EIO**.

```tex
No heros are cowards. (E)
Some soldiers are cowards. (I)
Therefore some soldiers are not heros. (O)
```

### The figure of the Syllogism

The mood of a standard-form syllogism is not enough, by itself, to characterize
its logical form. Look at the two syllogisms shown below, they have the **same
mood AII** but the first is not valid. The difference is the **relative
positions of their middle terms**, and this is called **figure**.

$$
\begin{align*}
& \text{ All } P \text{ is } M. \\
& \text{ Some } S \text{ is } M. \\
\hline
& \therefore \text{ Some } S \text{ is } P.
\end{align*}
$$

$$
\begin{align*}
& \text{ All } M \text{ is } P. \\
& \text{ Some } M \text{ is } S. \\
\hline
& \therefore \text{ Some } S \text{ is } P.
\end{align*}
$$

- Syllogisms can have four -- and **only** four -- possible different figures.

- First Figure

$$
\begin{align*}
& M - P \\
& S - M \\
\hline
& \therefore S - P
\end{align*}
$$

- Second Figure

$$
\begin{align*}
& P - M \\
& S - M \\
\hline
& \therefore S - P
\end{align*}
$$

- Third Figure

$$
\begin{align*}
& M - P \\
& M - S \\
\hline
& \therefore S - P
\end{align*}
$$

- Fourth Figure

$$
\begin{align*}
& P - M \\
& M - S \\
\hline
& \therefore S - P
\end{align*}
$$

- **Any standard-form syllogisms is completely described when we specify its mood
  and its figure.**

- Summary

  There are $4 * 4 *4 = 64$ moods and 4 figures. So, syllogisms have $64 * 4 =
  256$ forms.

## The Formal Nature of Syllogistic Argument

Deductive Logic: aim to discriminate valid arguments from invalid ones;

Classic Logic: aim to discriminate valid syllogisms from invalid ones;

> It is
> reasonable to assume that the constituent propositions of a syllogism are all contingent—that
> is, that no one of those propositions is necessarily true, or necessarily false.

:star:**Under this assumption, the <u>validity and invalidity</u> of an syllogism depends
entirely on its <u>form</u>**.

Examples:

- AAA-1

$$
\begin{align*}
& \text{All M is P} \\
& \text{All S is M} \\
\hline
& \therefore \text{All S is P}
\end{align*}
$$

Any syllogism of the form **AAA-1** is valid, regardless of its subject
matter. We can substitute S, P and M to Athenians, humans and Greeks.

$$
\begin{align*}
& \text{All Greeks are humans} \\
& \text{All Athenians are Greeks} \\
\hline
& \therefore \text{All Athenians are humans}
\end{align*}
$$

---

- If **any syllogism is valid** in virtue of its form alone, any other syllogism
  having that **same form** will also be **valid**.

- If a syllogism is **invalid**, any other syllogism having that **same form** will also
  be **invalid**.

- Examples:

$$
\begin{align*}
& \text{All liberals(P) are proponents of national health insurance(M)} \\
& \text{Some members of the administration(S) are propositions of national health
insurance(M)} \\
\hline
& \therefore \text{Some members of the administration are liberals}
\end{align*}
$$

The best way to expose its fallacious character is to construct another
argument that has exactly the same form but whose invalidity is immediately
apparent.

$$
\begin{align*}
& \text{All rabbits(P) are very fast runners(M)} \\
& \text{Some horses(S) are very fast runners(M)} \\
\hline
& \therefore \text{Some horses are rabbits.}
\end{align*}
$$

## Venn Diagram Technique for Testing Syllogisms

The syllogism can be drawn as three overlapping circles.
![Venn-Diagram-Syllogisms](assets/logic/venn-diagram-syllogisms.jpg)

### Example: Venn Graph for AAA-1

$$
\begin{align*}
& \text{All M is P} \\
& \text{All S is M} \\
\hline
& \therefore \text{All S is P}
\end{align*}
$$

- All M is P and All S is M
<style>
    .image-container {
        display: flex;
    }

    .image-container img {
        margin-right: 10px;
    }
</style>

<div class="image-container">
    <img src="assets/logic/all-m-is-p.jpg" alt="All M is P">
    <img src="assets/logic/all-s-is-m.jpg" alt="All S is M">
</div>

- Both
  <div style="text-align: center;">
    <img src="assets/logic/both-AA.jpg" alt="All S is M">
      <p>Combine the two premises</p>
  </div>

This syllogism is valid if and only if the **two premises imply or entail the
conclusion** -- that is, if together they say what is said by the conclusion.

### Diagram the universal premise first

$$
\begin{align*}
& \text{All artists are egotists} \\
& \text{Some artists are paupers} \\
\hline
& \therefore \text{Some paupers are egotists}
\end{align*}
$$

  <div style="text-align: center;">
    <img src="assets/logic/universal-first.jpg">
  </div>

> Had we tried to diagram the particular premise first, before the region $S\bar PM$ was shaded
> out along with $\bar S \bar P M$ in diagramming the universal premise, we would not have known whether
> to insert an x in $SPM$ or in $S \bar P M$ or in both.

### :star: Put x at border

$$
\begin{align*}
& \text{All great scientists are college graduates} \\
& \text{Some professional athletes are college graduates} \\
\hline
& \therefore \text{Some professional athletes are great scientists}
\end{align*}
$$

  <div style="text-align: center;">
    <img src="assets/logic/where-x.jpg">
  </div>

> we may still be puzzled about where to put the x needed in order to diagram the particular
> premise. That premise is “Some professional athletes are college graduates,” so an x must be
> inserted somewhere in the overlapping part of the two circles labeled “Professional athletes”and “College graduates.” That overlapping part, however, contains two regions, SPM and
> SPM. In which of these should we put an x? The premises do not tell us, and if we make an
> arbitrary decision to place it in one rather than the other, we would be inserting more
> information into the diagram than the premises warrant—which would spoil the diagram’s use
> as a test for validity.

  <div style="text-align: center;">
    <img src="assets/logic/x-at-border.jpg">
  </div>

**Placing an x on the line that divides the overlapping region. This indicate
that there is something that belongs in one of them, but does not indicate which
one.**

### Technique Summary

1. Label the circles of a three-circle Venn diagram with the syllogism's three
   terms.
2. :star:Diagram both premises, diagramming the universal one first if there is one
   universal and one particular.
3. :star:In diagramming a particular proposition, to put an x on a line if the
   premises do not determine on which side of the line it should go.
4. Inspect the diagram to see whether the diagram of the premises contains a
   diagram of the conclusion.

### :star:Why Venn Diagram can tell the validity?

- It was shown there that **one legitimate test of the validity or invalidity of a syllogism is to establish the validity or
  invalidity of a different syllogism that has exactly the same form**.

- Example

$$
\begin{align*}
& \text{All successful people are people who are keenly interested in their work} \\
& \text{No people who are keenly interested in their work are people whose
attention is easily distracted when they are working} \\
\hline
& \therefore \text{No People whose attention is easily distracted when they are
working are successful}
\end{align*}
$$

  <div style="text-align: center;">
    <img src="assets/logic/why-valid.jpg">
  </div>

> How does this Venn Diagram tell us that the given syllogism is valid?

:star: We can construct a syllogism of the same form that involves objects
that are immediately present and directly available for our inspection.

Here is the new syllogism:

$$
\begin{align*}
& \text{All points with in the unshaded part of the circle labeled P are
points within the unshaded part of the circle labeled M.} \\
& \text{No points within the unshaded part of the circle labeled M are points
within the unshaded part of the circle labeled S.} \\
\hline
& \therefore \text{No points within the unshaded part of the circle labeled S
are points within the unshaded part of the circle labeled P}
\end{align*}
$$

## Syllogistic Rules and Syllogistic Fallacies

### Rule 1: Avoid Four Terms

A valid standard-form categorical syllogism **must contain exactly three terms**,
each of which is used in the **same sense** throughout the argument.

If more than three terms are involved, the syllogism is invalid. The fallacy
thus committed is called the **fallacy of four terms**.

### Rule 2: Distribute the middle term in at least one premise

A term is "distributed" in a proposition when the proposition refers to all
members of the class designated by that term. **If the middle term is not
distributed in at least one premise, the connection required by the conclusion
cannot be made.**

- Example

$$
\begin{align*}
& \text{All Russians were revolutionists} \\
& \text{All anarchists were revolutionists} \\
\hline
& \therefore \text{All anarchists were Russians}
\end{align*}
$$

> This syllogism is plainly invalid. Its mistake is that it asserts a connection between anarchists
> and Russians by relying on the links between each of those classes and the class of
> revolutionists—**but revolutionists is an undistributed term in both of the premises. The first
> premise does not refer to all revolutionists**, and neither does the second. “Revolutionists” is
> the middle term in this argument, and if the middle term is not distributed in at least one
> premise of a syllogism, that syllogism cannot be valid.

This is called the **fallacy of the undistributed middle.**

:star:We want to use middle term to link the minor and major term. Either the
subject or the predicate of the conclusion must be related to the **whole** of
the class designated by the middle term. If that is **not so**, it is possible
that **each of the terms in the conclusion may be connected to a different part**
of the **middle term**, and **not necessarily connected** with each other.

### :star:Rule 3: Any term distributed in the conclusion must be distributed in the premises.

- To refer to all members of a class is to say more about that class than is said when only some of its members are
  referred to.
- Therefore, when the conclusion of a syllogism distributes a term that was undistributed in the premises, it
  says more about that term than the premises did.
- But **a valid argument is one whose premises logically entail its
  conclusion**, and for that to be true the **conclusion must not assert any more than is asserted in the premises.**
- A term that is distributed in the conclusion but is not distributed in the premises is therefore a sure mark that the conclusion
  has gone beyond its premises and has reached too far.
- This is called the **fallacy of illicit process**.
- <h3>Example</h3>

  - Illicit process of the major term

    $$
    \begin{align*}
    & \text{All dogs are mammals(Not distributed)} \\
    & \text{No cats are dogs} \\
    \hline
    & \therefore \text{No cats are mammals(Distributed)}
    \end{align*}
    $$

  - Illicit process of the minor term

    $$
    \begin{align*}
    & \text{All traditionally religious people are fundamentalists} \\
    & \text{All traditionally religious people are opponents of abortion(Not distributed)} \\
    \hline
    & \therefore \text{All opponents of abortion(Distributed) are fundamentalists}
    \end{align*}
    $$

### Rule 4: Avoid two negative premises

- Any **negative proposition** (E or O) **denies class inclusion**; it asserts that some or **all of one class** is **excluded** from the
  **whole of the other class**.
- Two premises asserting such exclusion **cannot yield the linkage that the conclusion asserts**,
  and therefore cannot yield a valid argument.
- The mistake is named the **fallacy of exclusive premises**.
- <h3>Further Reflection</h3>

  - S is wholly or partially excluded from all or part of M
  - P is wholly or partially excluded from all or part of M
  - However, any one of these relations may very well be established no matter
    how S and P are related.

### Rule 5: If either premise is negative, the conclusion must be negative

- **If the conclusion is affirmative**—that is, if it asserts that one of the two classes, S or P , is wholly or partly contained
  in the other—**it can only be inferred from premises that assert the existence of a third class that contains the first
  and is itself contained in the second**.
- However, **class inclusion can be stated only by affirmative propositions.**
- :star:Therefore, **an affirmative conclusion can follow validly only from two affirmative premises.**

---

- The mistake here is called the **fallacy of drawing an affirmative conclusion from a negative premise.**
- This fallacy is uncommon, since is quite easy to tell

$$
\begin{align*}
& \text{No poets are accountants} \\
& \text{Some artists are poets} \\
\hline
& \therefore \text{Some artists are accountants}
\end{align*}
$$

### Rule 6: From two universal premises no particular conclusion may be drawn

> In the Boolean interpretation of categorical propositions, universal propositions (A and
> E) have no existential import, but particular propositions (I and O) do have such import. Wherever the Boolean
> interpretation is supposed, as in this book, a rule is needed that precludes passage from premises that have no
> existential import to a conclusion that does have such import.

- Because of the Boolean Interpretation, it will show a clear fallacy that if the premises
  of an argument do not assert the existence of anything at all, the conclusion
  inferred asserts the existence of something.
- This mistake is called **existential fallacy**.
- Example

$$
\begin{align*}
& \text{All household pets are domestic animals} \\
& \text{No unicorns(no existential import) are domestic animals} \\
\hline
& \therefore \text{Some unicorns(have existential import) are not household pets}
\end{align*}
$$

## :star: Exposition of the Fifteen Valid Forms of the Categorical Syllogism

- <h3>AAA-1  Barbara</h3>
- <h3>EAE-1  Celarent</h3>
- <h3>AII-1  Darii</h3>
- <h3>EIO-1  Ferio</h3>

---

- <h3>AEE-2  Camestres</h3>
- <h3>EAE-2  Cesare</h3>
- <h3>AOO-2  Baroko</h3>
- <h3>EIO-2  Festino</h3>

---

- <h3>AII-3  Datisi</h3>
- <h3>IAI-3  Disamis</h3>
- <h3>EIO-3  Ferison</h3>
- <h3>OAO-3  Bokardo</h3>

---

- <h3>AEE-4  Camenes</h3>
- <h3>IAI-4  Dimaris</h3>
- <h3>EIO-4  Fresison</h3>
