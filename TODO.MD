# TODO List

## Features

### UNDO System
- [ ] Implement array to store previous screen states
- [ ] Add memory management for undo buffer
- [ ] Create UNDO key handler
- [ ] Consider limiting undo steps to preserve memory

### Small Fonts
- [ ] Create/load small font bitmap data
- [ ] Implement small font print function
  - [ ] Handle character spacing
  - [ ] Support different text colors
  - [ ] Allow position specification
  - [ ] Consider transparency option

### Dark Vision Frame Loader
- [ ] Scan file for animation frame markers
- [ ] Create frame index system
- [ ] Store frame positions in array/table
- [ ] Implement quick frame access function

## Bugs

### Screen Text Area Management
- [ ] Create screen area snapshot function
  - [ ] Allocate buffer for bottom screen area
  - [ ] Implement GET for text area
- [ ] Implement text area restore function
  - [ ] Add PUT to restore saved area
- [ ] Add handlers for:
  - [ ] Pre-text display save
  - [ ] Post-key press restore
  - [ ] Clean text area coverage

### Spacebar put xor color not selected color
- [ ] Add spacebar put xor color not selected color
