---
title: Meaningful Names
summary: how to give names when coding
authors:
  - GentleTomZerg
date:
  created: 2025-03-15
  updated: 2025-03-15
categories:
  - Software Engineering
tags:
  - clean code
---

## Meaningful Names

### Use Intention-Revealing Names

- fields

  ```java
  // BAD
  int d; // elapsed time in days

  // GOOD
  int elapsedTimeInDays;
  ```

- functions

  `implicity` of the code: the degree to which the context is not explicit in the
  code itself.

  ```java
  public List<int[]> getThem() {
    List<int[]> list1 = new ArrayList<int[]>();
    for (int[] x : theList)
    if (x[0] == 4)
      list1.add(x);
    return list1;
  }
  ```

  <!-- more -->

  ```java
  public List<Cell> getFlaggedCells() {
    List<Cell> flaggedCells = new ArrayList<Cell>();
    for (Cell cell : gameBoard)
    if (cell.isFlagged())
      flaggedCells.add(cell);
    return flaggedCells;
  }
  ```

### Avoid Disinformation

- Avoid names whose entrenched meanings vary from our intended meaning.

  eg: `hp`, `aix`, `sco` -> Unix platforms or variants

- Name for a group of things

  eg: `accountList` -> the data structure may not be a list. Better names:
  `accountGroup`, `bunchOfAccounts` Or `accounts`

- Name with small difference

  eg: `XYZControllerForEfficientHandlingOfStrings` and
  `XYZControllerForEfficientStorageOfStrings`

- Spelling similar concepts similarly is `information`; Using inconsistent
  spellings is `disinformation`

  eg: IDE will prompt all desired functions that can do replacment if we enter
  "replace"

- Lowercase l and Uppercase O

### Make Meaningful Distinctions

- Number-series naming `(a1, a2, a3)` -> noninformative
- Noise words -> redundant

  eg: Class `Product`, `ProductInfo`, `ProductData`

  eg: Class `Name`, `NameString`

  eg: Function `getActiveAccount()`, `getActiveAccounts()`, `getActiveAccountInfo()`

### Use Pronounceable Names

### Use Searchable Names

- `MAX_CLASSES_PER_STUDENT` is better than `7`
- single-letter names can **ONLY** be used as local variables inside short
  methods

### Avoid Encodings

#### Hungarian(匈牙利) Notation -> Old Naming fashions

- type is the prefix of the variable name: `chName`

#### Memeber Prefixes

- class field member prefix with `m_`, eg: `private String m_name`
- modern IDE has solved this through colorize members to make them distinct

#### Interfaces and Implementations

- `IShapeFactory` or `ShapeFactory`

  > I prefer to leave interfaces unadorned. The preceding I, so common in
  > today’s legacy wads, is a distraction at best and too much information at worst. I don’t
  > want my users knowing that I’m handing them an interface.

- Encode implementation, not interface

  Interface: `ShapeFactory`

  Concrete Class: `ShapeFactoryImp`

### Avoid Mental Mapping

Readers shouldn’t have to mentally translate your names into other names they already
know.

### Class Names

noun and noun phrase, no verb

### Method Names

have verb or verb phrase + predicates

**NOTE**: when facing with constructors overloaded, static factory methods with
names that describes the arguments is better.

```java
Complex fulcrumPoint = Complex.FromRealNumber(23.0); // Better
Complex fulcrumPoint = new Complex(23.0);
```

### Pick One Word per Concept

- `fetch`, `retrieve`, `get` -> stick to one!

### Don't Pun

Avoid using the same word for two purposes

- Use `add` for concatenating
- Use `insert` for puts a value into a collection

### Use Solution Domain Names

Use names that programmer will understand rather than terms from customers

### Use Problem Domain Names

When there is no programmer term for the names, use the name from the problem
domain.

### Add Meaningful Context

- Most names are not meaningful in and of themsevles.

- you need to place names in context for your reader by **enclosing them in
  well-named classes, functions, or namespaces.**

- When all else fails, then **preﬁxing the name** may be necessary as a last resort.

Example 1: Address Variables

```java
// Together seems to be the attributes of address
// What if we use state alone in a method?
String firstName;
String lastName;
String street;
String houseNumber;
String city;
String state;

// Solution 1: Prefix
String addrFirstName;
String addrLastName;

// Solution 2: Class
class Address {
  String firstName;
  ....
}
```

Example 2: Variables in Function

```java
// Variables with unclear context
// number, verb, pluralModifier must be infered from the code
private void printGuessStatistics(char candidate, int count) {
  String number;
  String verb;
  String pluralModifier;
  if (count == 0) {
    number = "no";
    verb = "are";
  pluralModifier = "s";
  } else if (count == 1) {
    number = "1";
    verb = "is";
    pluralModifier = "";
  } else {
    number = Integer.toString(count);
    verb = "are";
    pluralModifier = "s";
  }
  String guessMessage = String.format( "There %s %s %s%s", verb, number, candidate, pluralModifier);
  print(guessMessage);
}

// Variables have a context
public class GuessStatisticsMessage {
  private String number;
  private String verb;
  private String pluralModifier;
  public String make(char candidate, int count) {
  createPluralDependentMessageParts(count);
    return String.format( "There %s %s %s%s", verb, number, candidate, pluralModifier );
  }
  private void createPluralDependentMessageParts(int count) {
    if (count == 0) {
      thereAreNoLetters();
    } else if (count == 1) {
      thereIsOneLetter();
    } else {
      thereAreManyLetters(count);
    }
  }
  private void thereAreManyLetters(int count) {
    number = Integer.toString(count);
    verb = "are";
    pluralModifier = "s";
  }
  private void thereIsOneLetter() {
    number = "1";
    verb = "is";
    pluralModifier = "";
  }
  private void thereAreNoLetters() {
    number = "no";
    verb = "are";
    pluralModifier = "s";
  }
}
```

### Don't Add Gratuitous(无理由的) Context
