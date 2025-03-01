# HIGHEST PRIESTESS

## How to create your poker hand

Highest Priestess uses a custom markup language to define poker hands and all their properties. I tried my best to make this language as simple and comprehensible as possible.
"The poker hand" refers to the poker hand you're creating.

## Example of a poker hand

This section shows an example of what you need to write to create a poker hand and how. I suggest looking at this example, and reading further sections only if you have any doubts or want more information.

```
> Lines that start with a greater than sign are ignored

> These properties are MANDATORY
Name = My Poker Hand
Desc = {
    A Pair of 7s plus two Club cards,
    with suits and ranks overlapping or not
}
Base Chips = 35
Base Mult = 4
Level Chips = 15
Level Mult = 2
> If your poker hand doesn't want exact ranks or suits, search for variable ranks and suits in Rank Patterns and Suit Patterns sections
> If you're searching for more complex patterns in general, go to Hand Evaluation section (I suggest searching for keywords)
Eval = {
    > No suit or ranks overlapping
    (7 of *, 7 of *, * of Clubs, * of Clubs),
    > Only one card has overlapping suit and rank
    (7 of *, 7 of Clubs, * of Clubs),
    > Both cards have overlapping suit and rank
    (7 of Clubs, 7 of Clubs),
}
Author = TamerSoup625

> The following properties are OPTIONAL
> I suggest adding these ones however
Example = 7 of Hearts, 7 of Clubs, Jack of Clubs
Joker Mult = 10
Joker Chips = 80
Joker XMult = 2
> Go to Hand Ordering section for explanation
Order Offset = 1
> If you're not feeling creative, you can omit these
Planet Name = Kepler-22 b
Joker Mult Name = Jolly Joker
Joker Chips Name = Sly Joker
Joker XMult Name = The Duo
> Add something like this if you want to create additional composite hands
> Go to Composite Hands section for more similar properties
Flush Name = My Flush Poker Hand
Flush Base Chips = 350
Flush Base Mult = 40
Flush Level Chips = 150
Flush Level Mult = 20
Flush Planet Name = WASP-12 b
Flush Example = 4 of Clubs, 6 of Clubs, 7 of Clubs, 7 of Clubs, 10 of Clubs
```

## List of Poker Hand Properties

This is the list of all properties of a poker hand. Some properties are always mandatory, some are optional, and some are *grouped*, meaning if you define a property of a group, you have to define all properties of the group. Some properties have alternate names.

### Required Poker Hand Properties

- `Name`: The name of your poker hand. This shows, for example, when you select in-game cards that make up the poker hand.
- `Desc` or `Description`: The description of your poker hand. This is the text that appears in-game when you hover on the poker hand in the "Session Info" tab.
- `Base Chips`: The Chips this poker hand gives by itself when at level 1.
- `Base Mult`: The Mult this poker hand gives by itself when at level 1.
- `Level Chips`: The Chips this poker hand gains when leveled up (ex. by a Planet).
- `Level Mult`: The Mult this poker hand gains when leveled up (ex. by a Planet).
- `Eval` or `Evaluation`: Defines when a set of cards is considered to contain the poker hand. Go to Hand Evaluation section to know more about this property.
- `Author`: The name you want to be mentioned with in-game. This will appear when hovering on your poker hand in the "Session Info" tab.

### Optional Poker Hand Properties

- `Example`: A list of cards showing an example of how this poker hand can be played. The format is similar to card patterns, but it only accepts exact ranks, exact suits, `Wilds` suit, or exactly a Stone Card. Shows on card if omitted.
```
Example = Ace of Spades, Stone, 7 of Wilds
```
- `Order Offset`: See Hand Ordering section.
- `Planet Name`: The name given to this poker hand's corresponding Planet Card. Defaults to "`Name` Planet".
- `Joker Mult`: If this property is defined, a Joker which adds `Joker Mult` Mult if played hand contains the poker hand (similar to Jolly Joker, Zany Joker, Mad Joker, Crazy Joker, and Droll Joker) will be added along with the poker hand. Unlike other similar Jokers, this one will only show if you've discovered the poker hand if it was set to be hidden.
- `Joker Chips`: If this property is defined, a Joker which adds `Joker Chips` Chips if played hand contains the poker hand (similar to Sly Joker, Wily Joker, Clever Joker, Devious Joker, and Crafty Joker) will be added along with the poker hand. Unlike other similar Jokers, this one will only show if you've discovered the poker hand if it was set to be hidden.
- `Joker XMult`: If this property is defined, a Joker which multiplies Mult by `Joker XMult` if played hand contains the poker hand (similar to The Duo, The Trio, The Family, The Order, and The Tribe) will be added along with the poker hand. Unlike other similar Jokers, this one will only show if you've discovered the poker hand if it was set to be hidden, and also has no unlock condition.
- `Joker Mult Name`: If you defined `Joker Mult`, sets the name of the Joker created by `Joker Mult`. Defaults to "`Name` Joker".
- `Joker Chips Name`: If you defined `Joker Chips`, sets the name of the Joker created by `Joker Chips`. Defaults to "`Name` Jester".
- `Joker XMult Name`: If you defined `Joker XMult`, sets the name of the Joker created by `Joker XMult`. Defaults to "The `Name`".
- `Credits Name`: How the poker hand will be named in the credits. Used for long hand names.

- `Chance`: If added, the poker hand has only a 1 in `Chance` probability to be considered (affected by `G.GAME.probabilities.normal`)
- `Rank Sum`: If added, the poker hand must have the sum of the cards' ranks to be equal to `Rank Sum`. Jack, Queen, and King count as 10, and Ace as 1.
- `Composite Only`: If added, the non-composite variant of the poker hand won't be added (see Composite Hands section). No support for Jokers.
- `All Enhanced`: If added, all cards must have the specified enhancement for the poker hand to be considered.
- `Same Enhancement`: If added, all cards must have the same enhancement for the poker hand to be considered. Never counts with unenhanced cards.
- `Different Enhancement`: If added, each card must have a different enhancement for the poker hand to be considered. Never counts with unenhanced cards.
- `Card Count`: If added, the poker hand must have this exact number of cards.
- `All Editioned`: If added, all cards must have the specified edition for the poker hand to be considered.
- `Exact Enhancements`: If added, cards that make up this poker hand must have the listed enhancements, one for each.
```
Exact Enhancements = Steel, Gold, Steel, Gold, Steel
```
- `Money Min`: If added, you must have atleast the specified amount of money.
- `Money Max`: If added, you must have at most the specified amount of money.
- `All Sealed`: If added, all cards must have the specified seal color for the poker hand to be considered.
```
All Sealed = Red
```
- `Same Edition`: If added, all cards must have the same edition for the poker hand to be considered. Never counts with base cards.
- `Same Seal`: If added, all cards must have the same seal for the poker hand to be considered. Never counts with unsealed cards.
- `Unmodified`: If added, all cards must have no enhancement, edition, or seal.
- `Card Count Min`: If added, the poker hand must have at least this number of cards.
- `Card Count Max`: If added, the poker hand must have at most this number of cards.
- `All Debuffed`: If added, all cards must be debuffed.
- `Everything is Stone`: If added, all cards played and held in hand must be Stone Cards.
- `All In`: If added, all cards in hand must be played.
- `All Face`: If added, all cards must be face cards. This is more optimized than using options.
- `Two Pair in Hand`: If added, a Two Pair must be held in hand.
- `Nostalgic`: Used by the "Nostalgia" hand. If added, all cards must match the rank and suits of the first 5-card hand that was played this run. Does not count if you haven't played a 5-card hand this run.
- `RNG`: Used by the "RNG" hand. If added, all cards must match the rank and suits of a set of 5 cards randomly-generated at the start of the run.
- `Joker Texture ID`: Used internally. If added, Jokers created for the poker hand have custom art.
- `Planet Texture ID`: Used internally. If added, planets created for the poker hand have custom art.
- `Deja Vu`: Used internally. This is basically the condition for Deja Vu hand.

### Grouped Poker Hand Properties

- `Flush Name`: See Composite Hands section.
- `Flush Base Chips`: See Composite Hands section.
- `Flush Base Mult`: See Composite Hands section.
- `Flush Level Chips`: See Composite Hands section.
- `Flush Level Mult`: See Composite Hands section.
- `Flush Planet Name`: See Composite Hands section.
- `Flush Example`: See Composite Hands section.
- `Straight Name`: See Composite Hands section.
- `Straight Base Chips`: See Composite Hands section.
- `Straight Base Mult`: See Composite Hands section.
- `Straight Level Chips`: See Composite Hands section.
- `Straight Level Mult`: See Composite Hands section.
- `Straight Planet Name`: See Composite Hands section.
- `Straight Example`: See Composite Hands section.
- `House Name`: See Composite Hands section.
- `House Base Chips`: See Composite Hands section.
- `House Base Mult`: See Composite Hands section.
- `House Level Chips`: See Composite Hands section.
- `House Level Mult`: See Composite Hands section.
- `House Planet Name`: See Composite Hands section.
- `House Example`: See Composite Hands section.

## Markup Syntax

A poker hand is made up of many properties. To define a property, write the name of the property, followed by an equal sign, and then its value. The equal sign can have whitespace around it. Property names are case-insensitive, but has significant spaces.

```
> These lines define the same property with the same value
Base Mult = 4
base mult=4
BASE MULT  =  4
```

Some properties require multiline text. For these properties, follow the equal sign with brackets. Whitespace is trimmed.

```
> This works fine
Desc = {

    A Pair of 7s plus two Club cards,
    with suits and ranks overlapping or not

}
```

Any line that starts with any whitespace and a greater than sign (`>`) are considered to be comments and will be ignored by the parser.

```
> This line does nothing, that line won't set the Name property.
> Name = Nope!
```

## Hand Evaluation

The meat of your poker hand is the `Eval` property, defining when your poker hand is considered to be played and what cards will score when it's played. `Eval` requires multiline text and a markup syntax specific for it.

`Eval` is made up of one or more *hand patterns*, each of which is made up of some *card patterns* and can also have *options*.

All text inside `Eval` is case-insensitive.

### Hand Patterns

Hand patterns are enclosed in parenthesis and indicate one of the possible ways you can create the poker hand.

```
> Only matches two 7 of Clubs
Eval = {
    (7 of Clubs, 7 of Clubs)
}
> Example with multiple hand patterns (Wraparound straight)
Eval = {
    (King of *, Ace of *, 2 of *, 3 of *, 4 of *),
    (Queen of *, King of *, Ace of *, 2 of *, 3 of *),
    (Jack of *, Queen of *, King of *, Ace of *, 2 of *),
}
```

The first matching hand pattern will indicate what cards will score. Consider this when using multiple hand patterns.

```
> With this Eval, Clubs will never score because the second hand pattern will never match
Eval = {
    (* of Hearts, * of Diamonds),
    (* of Hearts, * of Diamonds, * of Clubs),
}
> Most of the time, you will have to place the hand pattern that requires most cards first
Eval = {
    (* of Hearts, * of Diamonds, * of Clubs),
    (* of Hearts, * of Diamonds),
}
```

### Card Patterns

A card pattern represent one of the cards that make up an hand pattern, one of the cards you must have to play the poker hand.

Most card patterns have the *rank pattern* (see Rank Patterns section), which is the rank(s) the card has to match, followed by `of`, then the *suit pattern* (see Suit Patterns section), which is the suit(s) the card has to match.

A card pattern can be only `stone` to match exactly a Stone Card.

```
> Cryptid's Bulwark (5 Stone Cards)
Eval = {
    (Stone, Stone, Stone, Stone, Stone),
}
```

A card pattern can be preceded by `nonscoring` or `unscoring`, in which case it will not count in scoring when played (it's still required for the poker hand).

```
> Two Hearts and one Club
> The Heart cards will not score, only the Club will
Eval = {
    (nonscoring * of Hearts, * of Clubs, nonscoring * of Hearts),
}
```

A card pattern can be preceded by `X` immediately followed by a number to make it score multiple times. This is referred to as "multiscoring" and is different than retriggering (cards that score twice and are retriggered trigger 4 times in total!)

```
> Two Hearts and one Club
> The Heart cards will score twice, the Club four times
Eval = {
    (X2 * of Hearts, X4 * of Clubs, X2 * of Hearts),
}
```

A playing card can't match multiple card patterns but, for getting the scoring cards, a card pattern can match multiple playing cards.

```
> Playing an Ace of Spades does not satisfy this pattern
> Playing multiple Aces and multiple Spades satisfies this pattern, in which case all Aces and all Spades will count in scoring when played
Eval = {
    (Ace of *, * of Spades),
}
```

### Rank Patterns

This is the list of all possible rank patterns. If both the rank pattern and suit pattern match, the whole card pattern matches.

- `2`, `3`, `4`, `5`, `6`, `7`, `8`, `9`, `10`, `Jack`, `Queen`, `King`, or `Ace`: Matches an *exact* rank.
- `*`: Matches *any* rank.
- A single letter `A`-`Z`: Matches a *variable* rank. Same letters corresponds to the same rank, and different letters correspond to different ranks.
```
> Matches a Full House
> A Five of a Kind will NOT match this pattern
Eval = {
    (A of *, A of *, A of *, B of *, B of *)
}
```
If you want to allow different letters to correspond to the same rank, see the `nonunique` option in the Pattern Options section.
- A single letter `A`-`Z` immediately followed by a plus sign and a number (ex. `a+3`): Matches a *variable* rank plus an offset. The offset works similarly to straights, with Aces that can both be the rank before 2 and the rank after King.
```
> Matches a Straight
Eval = {
    (A of *, A+1 of *, A+2 of *, A+3 of *, A+4 of *)
}
```
Numbers cannot be negative, and there must be atleast one associated variable rank without offset. Do note this is not an actual limitation on what patterns you can make.
```
> Two cards of the same rank X, one of rank X-1, and one of rank X+1
> Here X = A+1
Eval = {
    (A+1 of *, A+1 of *, A of *, A+2 of *)
}
```
For matching face cards, see the `face` option in the Pattern Options section.

### Suit Patterns

This is the list of all possible suit patterns. If both the rank pattern and suit pattern match, the whole card pattern matches.

- `Spades`, `Hearts`, `Clubs`, or `Diamonds`: Matches if the card counts as this suit. You do not need to check for wild cards.
- `Wilds`: Matches a *Wild* Card, regardless of the base suit.
- `*`: Matches *any* suit.
- A single letter `A`-`Z`: Matches a *variable* suit. Same letters corresponds to the same suit, and different letters correspond to different suits.
```
> Matches three cards of the same suit and two cards of another suit
> A Flush will NOT match this pattern
Eval = {
    (* of A, * of A, * of A, * of B, * of B)
}
```
If you want to allow different letters to correspond to the same suit, see the `nonunique` option in the Pattern Options section.

### Pattern Options

Pattern options are placed inside an hand pattern, and after card patterns and a semicolon. They can limit the possible ranks and suits a variable rank or suit can match for, or allow them to be non-unique.

Options target directly variable ranks/suits. A set of options for a variable is indicated by the variable name, followed by an equal sign, and then the variable's properties inside square parenteses.

```
> Any card with a prime number as rank, and Spades or Clubs as suit
Eval = {
    (A of B; A = [2, 3, 5, 7], B = [Spades, Clubs])
}
```

This is the list of properties for variable ranks. All properties except `nonunique` limit the ranks a variable rank can match for, and if none of these are satisfied, the variable rank won't match.

- `2`, `3`, `4`, `5`, `6`, `7`, `8`, `9`, `10`, `Jack`, `Queen`, `King`, or `Ace`: Variable can be one of these ranks.
- `face`: Variable can be a *face* card, or any rank if you have Pareidolia.
```
> A face card, or a 5
Eval = {
    (A of *; A = [face, 5])
}
```
- `nonface`: Variable can be a *non-face* card. This option has no effect if you have Pareidolia.
```
> A non-face card, or a Jack
Eval = {
    (A of *; A = [nonface, Jack])
}
> If you have Pareidolia, this will never match
Eval = {
    (A of *; A = [nonface])
}
```
- `nonunique`: Unlike the above properties, this one allows the associated variable rank to have the same rank of another variable rank. This is particurarly useful with the above other properties.
```
> 3 face cards. Pairs will also count
Eval = {
    (A of *, B of *, C of *; A = [face, nonunique], B = [face, nonunique], C = [face, nonunique])
}
```

This is the list of properties for variable suits. All properties except `nonunique` limit the suits a variable suit can match for, and if none of these are satisfied, the variable suit won't match.

- `Spades`, `Hearts`, `Clubs`, or `Diamonds`: Variable can be one of these suits.
- `Wilds`: Variable can be a *Wild* Card, regardless of the base suit.
- `nonunique`: Unlike the above properties, this one allows the associated variable rank to have the same rank of another variable rank. This is particurarly useful with the above other properties.
```
> 3 cards with Spade or Club suit
Eval = {
    (A of *, B of *, C of *; A = [Spades, Clubs, nonunique], B = [Spades, Clubs, nonunique], C = [Spades, Clubs, nonunique])
}
```

## Composite Hands

When you've created your custom poker hand, you can also create composite poker hands, which are poker hands made up of your poker hand plus another vanilla hand.

Within the definition of the poker hand, you can also create these composite hands:

- The poker hand + a Flush
- The poker hand + a Straight
- The poker hand + a Full House (referred to as House)

To define a composite hand, you have to define its corresponding Name, Base Chips, Base Mult, Level Chips, and Level Mult. You can also define its Planet Name and Example.

This is the list of composite hand properties:

- `Flush Name`: Similar to `Name`, but for Flush composite hand.
- `Flush Base Chips`: Similar to `Base Chips`, but for Flush composite hand.
- `Flush Base Mult`: Similar to `Base Mult`, but for Flush composite hand.
- `Flush Level Chips`: Similar to `Level Chips`, but for Flush composite hand.
- `Flush Level Mult`: Similar to `Level Mult`, but for Flush composite hand.
- `Flush Planet Name`: Similar to `Planet Name`, but for Flush composite hand.
- `Flush Example`: Similar to `Example`, but for Flush composite hand.
- `Straight Name`: Similar to `Name`, but for Straight composite hand.
- `Straight Base Chips`: Similar to `Base Chips`, but for Straight composite hand.
- `Straight Base Mult`: Similar to `Base Mult`, but for Straight composite hand.
- `Straight Level Chips`: Similar to `Level Chips`, but for Straight composite hand.
- `Straight Level Mult`: Similar to `Level Mult`, but for Straight composite hand.
- `Straight Planet Name`: Similar to `Planet Name`, but for Straight composite hand.
- `Straight Example`: Similar to `Example`, but for Straight composite hand.
- `House Name`: Similar to `Name`, but for Full House composite hand.
- `House Base Chips`: Similar to `Base Chips`, but for Full House composite hand.
- `House Base Mult`: Similar to `Base Mult`, but for Full House composite hand.
- `House Level Chips`: Similar to `Level Chips`, but for Full House composite hand.
- `House Level Mult`: Similar to `Level Mult`, but for Full House composite hand.
- `House Planet Name`: Similar to `Planet Name`, but for Full House composite hand.
- `House Example`: Similar to `Example`, but for Full House composite hand.

## Hand Ordering

In-game, poker hands have an order, shown in the Session Info tab from top to bottom. If an hand contains multiple poker hands, the game considers the played hand to be the earliest one, setting the starting Chips and Mult of the played poker hand.

For custom poker hands, the order is picked by the product between `Base Chips` and `Base Mult`. Your poker hand will be before hands that have a lower product of `Base Chips` and `Base Mult`, and after hands that have an higher product of it.

The `Order Offset` property gives more control on poker hands' order. If this property is defined, when calculating hand order, `Order Offset` will be added to the product of `Base Chips` and `Base Mult`.

A positive `Order Offset` effectively allows your poker hand to be before poker hands with an higher product of `Base Chips` and `Base Mult`, while a negative `Order Offset` allows the poker hand to be after poker hands with an higher product of `Base Chips` and `Base Mult`. All vanilla poker hands have an Order Offset of 0.

```
> If played hand contains a Pair and a 2, Wee Hand will take priority.
Name = Wee Hand
Base Chips = 2
Base Mult = 2
Order Offset = 20
Eval = {
    (2 of *)
}
> [...]
```

```
> To play an hand that contains this poker hand, you can play one card of each suit
> But to play exactly this poker hand, your hand mustn't contain a Pair or a Straight
Name = Cluster Spectrum
Base Chips = 35
Base Mult = 4
Order Offset = -130
Eval = {
    (* of Spades, * of Hearts, * of Clubs, * of Diamonds)
}
> [...]
```