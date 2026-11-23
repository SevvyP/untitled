# Untitled

A Slay the Spire clone

## Structure

Resources are separated into logical and visual states.

- `<type>_data.gd` - Represents a static, saveable resource. Cards, characters, enemies, etc. can be created and saved via these resource declarations
- `<type>_instance.gd` - Represents an instantiated resource in a run, handling addtional wrapper info like statuses applied during combat
- `<type>.gd` - Scripts attached to the <type> scene, which handle manipulation and presentation of the <type> visual on the screen

For the basic gameplay loop, a character and deck are passed into the main scene. 
The main scene then handles what scenes are displayed, changes to the deck, global state, etc.

## Ability system

Abilities are represented as an ordered array of actions. Actions are a tuple of Effect and Modifier.
Every possible action can be represented in this way:
	
- `ATTACK: 6` = do 6 damage
- `DRAW: 2` = draw 2 cards
- `ADD_MAX_HEALTH: -10` = lose 10 max health

Card abilities, enemy abilities, encounters, etc. can all be represented as a list of actions that are performed. 
Actions are associated to targeting types, ex.: CHOSEN_ENEMY, SELF, CHOSEN_ALLY, NONE. Players determine
targets when playing a card, enemies and encounter events need to have targeting behavior defined.

## Art

Card artwork dimensions: 480x360.
