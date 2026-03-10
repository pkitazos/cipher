# TODO

## Frontend

- [x] [F1] game sharing
- [ ] [F4] 500 error page
- [ ] [F5] Add visual feedback and transitions (probably needs Alpine for nicer interactivity)
- [x] [F6] Account dropdown is too wide
- [x] [F7] player labels in "How to Play" section are not vertically aligned
- [x] [F8] abandoned game should be marked as such somewhere in the game header (currently just appears as readonly)
- [x] [F9] maybe some toasts are unnecessary
- [x] [F10] move theme toggle out of settings OR respect system settings
- [x] [F11] the match number in history needs some kinda label

## Backend

- [ ] [B1] separate out daily challenge (with guess limit?) + archive / free play

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
