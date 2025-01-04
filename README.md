# Create
Graphic certation tool for Kreuzer interactive games

Here's an improved documentation for CREATE4, formatted as a user guide:

# CREATE4 User Guide

CREATE4 is a pixel art and game screen editor with special interaction points ("specials") for game development.

## Basic Controls

### Navigation
- **Numpad Keys (1-9)**: Move cursor in 8 directions
- **Arrow Keys**: Alternative movement controls
- **Mouse/Pen**: Direct cursor positioning

### Drawing Tools
- **5**: Toggle drawing mode on/off
- **Space/Enter**: Place pixel/element
- **[/]**: Decrease/Increase color
- **-**: Redraw border
- **+**: drop stamp
- **'**: Cycles each game r will display selected game pics, p will cycle selected game palettes
- **;**: displays color at cursor palette location
- **b**: Change brush color (prompts for number)
- **0**: Change cursor step size (1, 3, or 6 pixels)
- **i**: Pick color under cursor
- **f**: Toggle color replace mode
    - Use **t** to sample color to replace
    - Use **y** to sample replacement color
    - When active, replaces colors in a 5x5 area around cursor
- **l**: Draw line between two points (use z/x to set points)
- **o**: Select new color
- **c**: Toggle canvas clear
- **\***: Flood fill from cursor position with current color

### File Operations
- **s/S**: Save current work
- **r/R**: Load existing file
- **n**: Start new file
- **q**: Quit program

## Creating Special Interaction Points

1. Press **C** to enter special creation mode

2. For each special point, you'll be prompted to define:
   - **What must be set**: Variable flag (1-100) that must be active for special to work
   - **What can't be set**: Variable flag (1-100) that must NOT be active
   - **What gets set**: Variable flag (1-100) that will be activated
   - **What is displayed**: Message shown when special is activated
   - **What key pressed**: Cursor type needed to activate:
     - `l` = eye (look cursor)
     - `g` = arrow (get cursor)
     - `a` = hand (action cursor)
     - `u` = gun (use cursor)
   - **Extra info/Transfer**: Additional data or screen transition information

3. Placing Specials:
   - Press **Enter** then type special number to place
   - Use **t** to toggle "trail" mode (automatically places specials as you move)
   - Use **d** then type special number to display its message
   - Use **s** to save specials
   - Use **e** to exit create mode

### Screen Transitions
For the "Extra info/Transfer" field, use this format:
- `filename<direction>` where:
  - `filename` = destination screen (without .pic extension)
  - `<n>` = character walks north
  - `<s>` = character walks south
  - `<l>` = character walks left
  - `<r>` = character walks right

## Tips
- Messages cannot contain quotes (") or commas (,)
- Flag numbers must be between 1 and 100
- Use **d** to review special numbers and their messages
- Save frequently using **s**
- Exit create mode with **e**

## File Types
- `.pic`: Screen image data
- `.pal`: Palette data
- `.dat`: Special interaction data

This tool appears to be part of a larger game development system, where these special points define interactive elements in game screens.

# Understanding "Specials" in CREATE4

"Specials" are interactive points in the game screen that define how players can interact with the environment. They're essentially the building blocks of game logic and interactivity.

## Anatomy of a Special

Each special point has 6 key components:

```basic
1. CS(CQ)  - Can't Set: Condition that must NOT be true
2. bs(CQ)  - Must Set: Condition that must be true
3. st(CQ)  - Sets: What happens when activated
4. mess$(CQ) - Message: Text displayed when activated
5. ky$(CQ)  - Key: Type of interaction/cursor
6. df$(CQ)  - Extra Info: Additional data/screen transitions
```

## Types of Interactions (ky$)
```
l = Look cursor (eye icon)
g = Get/grab cursor (arrow)
a = Action cursor (hand)
u = Use cursor (gun/tool)
```

## Practical Example
Here's how a special might work in practice:

```
Special #1:
Can't Set: 5      (Won't work if flag 5 is set)
Must Set: 0       (No prerequisite)
Sets: 7           (Sets flag 7 when activated)
Message: "The door is locked"
Key: l            (Look cursor)
Extra: door1<n>   (Transitions to door1 screen, walking north)
```

This creates an interactive point where:
1. When the player looks at it (using eye cursor)
2. If flag 5 isn't set
3. They see "The door is locked"
4. Flag 7 gets set
5. Character walks north to screen "door1"

## Common Uses for Specials

1. **Doors and Transitions**
```basic
Message: "Door opens"
Key: u
Extra: hallway<n>  ' Goes to hallway screen, walking north
```

2. **Item Collection**
```basic
Message: "You found a key"
Key: g            ' Get cursor
Sets: 5           ' Sets flag 5 (has key)
```

3. **Locked Objects**
```basic
Can't Set: 5      ' Can't open without key
Message: "It's locked"
Key: u            ' Use cursor
```

4. **State Changes**
```basic
Must Set: 5       ' Must have key
Sets: 6           ' Sets "door unlocked" flag
Message: "You unlock the door"
Key: u
```

## Managing Specials

- Up to 30 specials can be defined per screen
- Each special is numbered (1-30)
- Specials are stored in `.dat` files alongside the screen image
- Use the **d** command to review placed specials
- Use **s** to save special definitions

## Tips for Using Specials

1. Plan your flag numbers carefully:
   - Keep track of what each flag means
   - Consider using ranges (1-10 for items, 11-20 for doors, etc.)

2. Test interactions:
   - Use the **d** command to verify special placement
   - Check that conditions work as expected

3. Common patterns:
   - Look before Use (place two specials in same spot)
   - Item requirements (Can't Set/Must Set combinations)
   - Sequential events (one special sets flag for another)

This system allows for creating complex adventure game-style interactions through a combination of conditions, messages, and screen transitions.

## Asset Structure

### File Organization
```
assets/
├── game1/
│   ├── room1.pic      # picture files
│   ├── room1.dat      # Special interaction data
│   ├── hallway.pic
│   └── hallway.dat
│
├── game2/
│   ├── room2.pic
│   ├── room2.dat
│   ├── hallway.pic
│   └── hallway.dat
│
├── game3/
│   ├── room3.DV      # picture files
│   ├── room3.DVT     # Special interaction data
│   ├── hallway.DV
│   └── hallway.DVT
│
modules/
│   ├── config.bas
│   ├── config.bi
│   ├── pal.bas
│   ├── pal.bi
│   └── create.bas
├── CFG.INI
└── CREATE5.BAS
```