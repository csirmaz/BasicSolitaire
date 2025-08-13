BasicSolitaire
==============

Classic Solitaire with autoplay written a long time ago in QBasic

![screenshot](https://www.postminart.com/cdn/solit.gif)

I uploaded this old project as it contains an algorithm to play classic solitaire
that might be interesting, although the code is a bit messy.

Download the compiled version
[here](https://www.epcsirmaz.co.uk/binary/solit.exe) -
you can use [DosBox](http://www.dosbox.com/) to run it.

# DOCUMENTATION

## Contents

* 1. Rules of Classic Solitaire
* 2. Playing Solitaire with the Program
   * 2.1. Initialization
   * 2.2. Functions
   * 2.3. The table
        * 2.3.1. Possible cards & How to insert cards from the deck or from 'out'
        * 2.3.2. Cards that can be moved out & How to move out a card
        * 2.3.3. Cards that can be moved now & How to move a card
        * 2.3.4. Cards that can be made movable
   * 2.4. Further moves: inserting Kings from the deck & revealing a card
   * 2.5. Command line arguments
* 3. Technical Info
   * 3.1. System requirements
   * 3.2. Data files
   * 3.3. Game numbers


## 1. Rules of Classic Solitaire

At the beginning of each game, 28 cards are dealt on the table
in 7 columns, face down, except for the lowermost cards, which are placed face
up. The number of cards in each column equals the number of the column, so
there is one card in the first, are two cards in the second column, etc. The
rest of the cards are left in the deck.

During a game of classic solitaire, you can make the following moves:

* a. Revealing a card. If there is no card under a card placed face down, you
have the option of flipping it over and use it afterwards to form ordered
columns.

* b. Moving cards out. There are four places on the table marked 'out'. Aces
can be immediately moved there; any other card can be moved out if and only
if the card of the next smaller value of the matching colour has been already
moved out. That is, you can move cards out in the following order: A-2-3-4-
5-6-7-8-9-10-J-Q-K. The topmost cards moved out can be taken back to the
table.

* c. Moving a card or an ordered column. A card placed face up can be moved to
under another card also placed face up if the card moved is of the next
smaller value and of the opposite colour (that is, you can place black cards
below red ones and red cards below black ones). For example, you can put
Hearts 3 under Spades 4. Also, you can move Kings to empty columns.

   Moreover, with this method, you may move entire columns of cards placed face
up, that is, which are ordered according to the above rules. In this case,
the value and the colour of the topmost card determines whether the move is
legal.

   Kings and columns starting with kings can be moved to empty columns.

* d. Inserting a card from the deck. You can insert a card from the deck to
under a face-up card according to the above described rules. For example, if
Hearts J is the lowermost card in a column, then you may put Club 10 from the
deck under it. Also, you can place Kings from the deck on the top of empty
columns.

* e. Inserting a card previously moved out. The topmost cards on the four 'out'
positions can be moved to under a card placed face up on the table, according
to the described rules.

The goal is to reveal all the cards, or (which is an equivalent task), to
move all cards out.

## 2. Playing Solitaire with the Program

### 2.1. Initialization

If you run the program for the first time, it will ask for your preferred
language. Choose English (press '1' and then ENTER).

If you deal a table for the first time, the program will notify you about
a missing file storing the next game number. By default, choose the first
option (press '1' and ENTER), or follow instructions on-screen.

### 2.2. Functions

When the program starts, no game has been dealt yet on the table. Both
dealing a new table and loading a previous one are among the various
functions of the program, which are listed below.

All functions can be activated by the keyboard.

Name  |       Key  |     Description
--- | --- | ---
Quit   |     ESC  |     Press ESC to leave the game.
Deal   |     D   |      Press 'd' to deal the next table. In the bottom right corner of the screen, the program prints out the number of the current game. This number can be used to reload the game later. Cards are dealt in a totally random method, unlike, it seems, the way the Windows solitaire program deals the table.
Load game |  L |        Press 'l' to load a previous table. Simply give the game number and press ENTER.
Undo      |  U  |       Press 'u' to take back the last move unless it was revealing a face-down card. Only the last move can be taken back this way.
Restart   |  R  |       Press 'r' the restart the current game.
Mark game |  M  |       In order to keep track of solvable/unsolvable games, the program has the option of marking the current game as Solved, Hopeless or TryAgain by pressing key 'm'. The program will create a directory named 'SOLUTION' and will create a null-length file for each game. The name of the file is determined as follows: the first eight characters denote the game number, the extension marks whether it is solved (SLD), hopeless (HLS) or TryAgain (TRY). Marking a game again will overwrite the previous mark. The program also places a '0README.TXT' in the directory describing its function and the extensions.
Show hidden cards |       S |        Pressing 's' will show/hide the cards placed face down. This option is useful when you need to decide which card to reveal and you want to know desperately whether the actual game can be solved at all. Naturally, according to the originial rules of classic solitaire, this is cheating, as is Restart.
Autoplay   | A,W  |     There is a strategy programmed into the game which can solve some of the games. Pressing 'w' will make the program do one move according to its strategy, while pressing 'a' will make it follow its strategy as far as it can. When it stops, the game requires your intervention to be solved, or it's stuck.
Colour cards according to parity |      P |        This option is intended to make life easier: pressing 'p' will make the program colour the cards in a way that red cards are placed on red ones and black cards on black ones. Practically, it means that cards A,3,5,7,9, J,K are displayed using the opposite colour. Pressing 'p' again will deactivate this feature.

### 2.3. The table

Once a game has started, the program places many marks on the table to make
playing solitaire easier. (Note that solving a game can be hard enough even
with these helpers.) Many of the following notations are explained briefly
on the right side of the screen.

#### 2.3.1. Possible cards & How to insert a card from the deck or from 'out'

Under actual cards (printed with white or cyan background), there might
be other cards listed of descending value, with green background. These
cards, at the moment, are in the deck or 'out', but can be inserted under
the lowermost card in the noted order. If there are two symbols printed
to the left of a number, then both cards are available.

To insert such a card, click on the symbol (colour) of the desired card
with the left button of the mouse. Only the topmost possible-card can be
inserted in a given column.

#### 2.3.2. Cards that can be moved out & How to move out a card

Cards which can be moved 'out' have a cyan background both on the table
and in the deck. Click with the right button of the mouse on a card to
move it out.

The topmost cards 'out' are also noted in the deck, with green background.

#### 2.3.3. Cards that can be moved now & How to move a card

There might be arrows to the right of face-up cards. If such an arrow is
white or bright green, then the card (and other cards under it) in question
can be moved somewhere else. Simply click on the card to move it. If there
are more than one places where the card might go, then select from the marked
possibilities by clicking on one of them.

The colour of the arrow depends on whether the card is the topmost one or not.
If yes, the arrow is bright green in order to call attention to the
possibility of making a card revealable or creating an empty column.
Otherwise, the arrow is white.

#### 2.3.4. Cards that can be made movable

If the arrow next to a card is black, then the card can be made movable
by inserting some cards from the deck or from 'out'. Imagine, for example,
that you have Hearts 5 as the lowermost card in a column, under which the
possibilities Spades 4 and Diamond 3 are listed. Now the card Spades 2 is
marked with a black arrow because if you insert Spades 4 and Diamond 3 from
the deck under Hearts 5, then it can be moved there.

### 2.4. Further moves: inserting Kings from the deck & revealing a card

Many of the possible actions (activating functions, moving, inserting, moving
out cards) have been described in the previous two sections. All that is left
to call attention to is that although inserting cards from the deck is
primarily done by clicking on possibilities, this is not the case when
inserting Kings to empty columns from the deck. In these cases, click on the
King to be inserted in the deck.

Face-down cards with no cards under them are automatically turned over.

### 2.5. Command-line arguments

The program tries to load a game if the appropriate game number is given
as its command line argument.

## 3. Technical Info

### 3.1. System requirements

The program is MS-DOS compatible and requires mouse.

### 3.2. Data files

The program creates the following files in the working directory:

Name | Function
--- | ---
LANGUAGE.SOL |  Stores the chosen language. Delete the file to make the program ask for the desired language again.
TABLE.SOL    |  Stores the absolute number of the next game.
SOLUTION\    |  A directory storing solvability info about the games. See the 'Mark game' function above. Created only if this function is used.

### 3.3. Game numbers

The game numbers are generated by multiplying the absolute number of the
game (always increased by 1) by 1000 and adding a 3-digit-long checksum
of the cards on the table. If the checksum does not match when loading a
game, the program notifies the user and tries to fall back on the closest
table, that is, continues using the present table anyway.
