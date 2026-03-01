# TODO

## Frontend

- [ ] make the labels in the current guess area either fainter or tooltips
- [ ] test layout where categories are grouped horizontally rather than vertically
- [ ] Show appropriate message if already at max difficulty (level_up button/UI)
- [ ] 500 error page
- [ ] Add visual feedback and transitions (probably needs Alpine for nicer interactivity)
- [ ] Account dropdown is too wide
- [ ] player labels in "How to Play" section are not vertically aligned

## Backend

### Tests

- [ ] abandon_game/1: successful abandonment
- [ ] abandon_game/1: error when game not found
- [ ] abandon_game/1: process actually stops
- [ ] abandon_game/1: abandoned state retrievable before stop
- [ ] level_up/1: easy → normal
- [ ] level_up/1: normal → hard
- [ ] level_up/1: error at max difficulty (hard)
- [ ] level_up/1: error when game not yet won
- [ ] level_up/1: old process is stopped
- [ ] level_up/1: new game has correct difficulty
- [ ] level_up/1: new game has fresh secret

### Cleanup

- [ ] Remove dead `status_class(:expired)` clause in `game_components.ex:57`
- [ ] Update tests to use current status values (`:won` / `:active` / `:abandoned`)

### Security

- [ ] Verify LiveView never receives the game secret
- [ ] Verify HTTP API responses never include the game secret

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
