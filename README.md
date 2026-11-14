
# Untitled

A framework for card based games

## Structure

The framework is structured to abstract the logical and physical state of the game as much as possible.

- `main.gd` - Coordinates player actions, turns, and animations.
- `game_state.gd` - Manages the logical deck, hand, and discard piles.
- `game_view.gd` - Handles card instantiation, positioning, and animations.
- `input_manager.gd` - Handles player input

The game state should never interact with the physical scene. The main script enforces rules
on the player input, applies player input to the game state, and triggers the relevant physical state
changes

## Card System

- `card_data.gd` - Is the card Resource. New cards can be created by saving an instance of card data
into the [cards folder](/cards)
- `card_instance.gd` - Represents an individual card with a unique ID and mutable state.
- `card.gd` - The card scene which handles interactions with a card and rendering a card from data

## Art

Card artwork dimensions: 480x360.
