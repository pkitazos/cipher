# TODO

## Frontend

- [ ] [F1] make the labels in the current guess area either fainter or tooltips
- [ ] [F2] test layout where categories are grouped horizontally rather than vertically
- [ ] [F3] Show appropriate message if already at max difficulty (level_up button/UI)
- [ ] [F4] 500 error page
- [ ] [F5] Add visual feedback and transitions (probably needs Alpine for nicer interactivity)
- [x] [F6] Account dropdown is too wide
- [x] [F7] player labels in "How to Play" section are not vertically aligned
- [ ] [F8] abandoned game should be marked as such somewhere in the header (currently just appears as readonly)
- [x] [F9] maybe some toasts are unnecessary
- [x] [F10] move theme toggle out of settings OR respect system settings
- [ ] [F11] the match number in history needs some kinda label

## Backend

### Tests

- [x] [B1] abandon_game/1: successful abandonment
- [x] [B2] abandon_game/1: error when game not found
- [x] [B3] abandon_game/1: process actually stops
- [x] [B4] abandon_game/1: abandoned state retrievable before stop
- [x] [B5] level_up/1: easy → normal
- [x] [B6] level_up/1: normal → hard
- [x] [B7] level_up/1: error at max difficulty (hard)
- [x] [B8] level_up/1: error when game not yet won
- [x] [B9] level_up/1: old process is stopped
- [x] [B10] level_up/1: new game has correct difficulty
- [x] [B11] level_up/1: new game has fresh secret

### Cleanup

- [x] [B12] Remove dead `status_class(:expired)` clause in `game_components.ex:57`

### Security

- [ ] [S1] Migrate game IDs from serial int custom IDs (Cipher.Games.Id)
- [x] [S2] Add ownership checks to all mutating game operations
- [x] [S3] Verify LiveView never receives the game secret
- [x] [S4] Verify HTTP API responses never include the game secret

## Database

- [ ] [DB1] Add `num_guesses` column to games table (for leaderboards)

## Docs

- [ ] [DOC1] Document `abandon_game/1` and updated `level_up/1` in `Games.Server`; remove stale `reset_game/1` and `join_game/1` references
- [ ] [DOC2] Update game status documentation (`:active` / `:won` / `:abandoned`)
- [ ] [DOC3] Add "Game Lifecycle and Cleanup" section (terminal states, timeout as safety net)
- [ ] [DOC4] Update "Data Flow" section (manual cleanup, process termination, secret filtering)
- [ ] [DOC7] Document new error cases for `level_up`

## Technical Debt

- [ ] [T3] Add lifecycle event logging (filterable by game id)
- [ ] [T4] Add telemetry events for game lifecycle
- [ ] [T6] Add proper validation for difficulty parameter in all functions
