# TODO

## LiveView Frontend Development Plan

### Phase 1: Setup (COMPLETED)
- [x] Add dependencies (phoenix_live_view, phoenix_html, esbuild, tailwind)
- [x] Configure asset pipeline in config.exs and dev.exs
- [x] Create layouts (root.html.heex, app.html.heex)
- [x] Create core_components.ex
- [x] Update cipher_web.ex with live_view/live_component/html helpers
- [x] Enable LiveView socket in endpoint.ex
- [x] Add browser pipeline and route in router.ex
- [x] Create basic DifficultyLive module (was DifficultyLive)
- [x] Create GameLive module for `/game/:id` route

### Phase 2: Game Creation (COMPLETED)
- [x] Connect "Start Game" button to Cipher.Games.Server.start_game/0
- [x] Display actual game ID after creation
- [x] Add difficulty selection (easy/normal/hard)

### Phase 3: Display Game State (COMPLETED)
- [x] Show current guess slots (empty or filled)
- [x] Display guess history with match counts
- [x] Show game status (active/won)

### Phase 4: Category Selection & Guessing (IN PROGRESS)
- [x] Define choice data (shapes, colors, patterns, directions)
- [x] Build category selector component
- [x] Handle selection events and track current guess
- [x] Submit guess to Games.Server
- [x] **Handle win state UI feedback**
  - [x] Show congratulations message when game is won (via Flash)
  - [x] Disable guess submission after win (choice buttons disabled)
  - [x] Show "New Game" and "Level Up" buttons when won
- [ ] **Implement "New Game" functionality**
  - [x] Add "New Game" button (visible when not active)
  - [ ] Handle "new_game" event in GameLive (currently using href link)
        make this a button which abandons the current game, and then pushes the "/" route
  - [ ] Call `Games.Server.abandon_game/1` to clean up current game process
  - [x] Navigate to "/" (DifficultyLive)
- [x] **Implement "Level Up" functionality**
  - [x] Add "Level Up" button (only visible when game is won, not at max difficulty)
  - [x] Handle "level_up" event in GameLive
  - [x] Call `Games.level_up/1` to create new game at next difficulty
  - [x] Navigate to "/game/:new_game_id" using `push_navigate/2`
  - [ ] Show appropriate error if player hasn't won yet
  - [ ] Show appropriate message if already at max difficulty

### Phase 5: Polish & Styling
- [ ] Style the game board with Tailwind
- [ ] Add visual feedback and transitions
- [ ] Mobile-responsive design

---

## Backend Refactoring Tasks

### Game Lifecycle Management (PRIORITY)

#### [B1] Remove `reset_game/1` functionality
**Why:** Allows cheating (reset with same secret), unclear semantics, conflicts with database persistence model
- [x] Remove `reset_game/1` function from `Games.Server`
- [x] Remove `:reset` GenServer handler
- [x] Remove tests for `reset_game/1`
- [x] Remove API route `POST /api/games/:id/reset`
- [x] Remove controller action for reset

#### [B2] Implement `abandon_game/1` functionality
**Purpose:** Clean up game process when player starts a new game
- [x] Add `abandon_game/1` function to `Games.Server`
  - [x] Look up game process by ID
  - [x] Call `:mark_abandoned` handler to update status
  - [x] Stop the process gracefully with `GenServer.stop(pid, :normal)`
  - [x] Return `{:ok, abandoned_state}` for DB persistence
  - [x] Handle `:game_not_found` error case
- [x] Add `:mark_abandoned` GenServer handler
  - [x] Update state status to `:abandoned`
  - [x] Return updated state
- [ ] Add tests for `abandon_game/1`
  - [ ] Test successful abandonment
  - [ ] Test error when game not found
  - [ ] Test that process actually stops
  - [ ] Test that abandoned state can be retrieved before stop

#### [B3] Refactor `level_up/1` functionality
**Purpose:** Create new game at next difficulty, properly clean up old game
- [x] Update `level_up/1` implementation
  - [x] Look up current game process
  - [x] Get internal state (including secret for validation)
  - [x] **Verify game status is `:won`** (return error if not)
  - [x] Get next difficulty via `Game.next_difficulty/1`
  - [x] Start new game at next difficulty
  - [x] Mark old game as `:won` (already won, no need for separate status)
  - [x] Stop old game process
  - [x] Return `{:ok, new_game_id}`
  - [x] Handle error cases:
    - [x] Game not found
    - [x] Game not won yet (`:game_not_won` error)
    - [x] Already at max difficulty (`:max_difficulty` error)
- [ ] Update tests for `level_up/1`
  - [ ] Test successful level up from easy → normal
  - [ ] Test successful level up from normal → hard
  - [ ] Test error when trying to level up from hard
  - [ ] **Test error when game not won** (new test case)
  - [ ] Test that old process is stopped
  - [ ] Test that new game has correct difficulty
  - [ ] Test that new game has fresh secret (different from old)

#### [B4] Update Game Status Enum (SIMPLIFIED)
**Purpose:** Three statuses for clear terminal states
- [x] Update state initialization to use new status values
- [ ] Document status meanings:
  - `:active` - Currently being played
  - `:won` - Player guessed correctly (terminal state)
  - `:abandoned` - Player left game (timeout OR clicked "New Game")
- [ ] Update timeout handler to use `:abandoned` instead of `:expired`
- [ ] Remove references to `:completed` status (use `:won` instead)
- [ ] Update any status checks in code to handle new statuses
- [ ] Update tests to use new status values where applicable

#### [B5] Security: Filter secret at GenServer boundary
**Status:** Already implemented, verify completeness
- [x] `get_client_state/1` filters secret via `:client_state` handler
- [x] `get_internal_state/1` test-only function for tests
- [x] All production code uses `get_client_state/1`
- [x] All tests use `get_internal_state/1` where secret is needed
- [ ] Verify LiveView never receives secret
- [ ] Verify HTTP API responses never include secret

---

## Future: Database Persistence

### Database Schema Design

#### [DB1]
- [ ] Create `games` table migration
  - [x] `id` - UUID (matches GenServer game_id)
  - [x] `user_id` - Reference to users (future auth)
  - [x] `difficulty` - Enum (easy/normal/hard)
  - [x] `status` - Enum (active/won/expired/abandoned/completed)
  - [x] `secret` - Encrypted JSONB (for verification)
  - [x] `guesses` - JSONB array of guess history
  - [ ] `num_guesses` - Integer (for leaderboards)
  - [ ] `leveled_up_to` - UUID reference to next game in chain
  - [x] `timestamps` - inserted_at, updated_at

#### [DB2]
- [x] Create `Games` context module

#### [DB3]
- [ ] Implement persistence functions
  - [x] `get_game/1` - Retrieve by ID
  - [ ] `list_user_games/1` - Get user's game history
  - [ ] `leaderboard/1` - Top scores by difficulty

#### [DB4]
- [ ] Integrate persistence with lifecycle events
  - [ ] Persist on timeout (`:expired` status)
  - [ ] Persist on abandon (`:abandoned` status)
  - [ ] Persist on level up (`:completed` status)
  - [ ] Persist on win (`:won` status)

---

## Documentation Updates

#### [DOC1]
- [ ] Update Games.Server public API documentation
  - [x] Document `get_client_state/1` (filters secret)
  - [ ] Document `abandon_game/1` (new function)
  - [ ] Document updated `level_up/1` (new behavior)
  - [ ] Remove `reset_game/1` documentation
  - [ ] Remove `join_game/1` if it still exists

#### [DOC2]
- [ ] Update game status documentation with new enum values

#### [DOC3]
- [ ] Add section on "Game Lifecycle and Cleanup"
  - [ ] Explain when games are stopped vs timeout
  - [ ] Document the different terminal states
  - [ ] Explain the 1-hour timeout is a safety net, not primary cleanup

#### [DOC4]
- [ ] Update "Data Flow" section to reflect new patterns
  - [ ] Manual cleanup on "New Game"
  - [ ] Process termination on "Level Up"
  - [ ] Secret filtering at GenServer boundary

### API Documentation

#### [DOC5]
- [ ] Update OpenAPI/API docs (if they exist)

#### [DOC6]
- [ ] Remove reset endpoint from documentation

#### [DOC7]
- [ ] Document new error cases for level_up

---

## Technical Debt / Nice-to-Haves

#### [T1]
- [x] Add `last_matches` field to state (for returning in guess response)

#### [T2]
- [x] Change `guess/2` return type from `{:correct, n} | {:incorrect, n}` to `{:ok, state}`

#### [T3]
- [ ] Add proper logging for all lifecycle events (should be possible to see a game by filtering the logs by game id)

#### [T4]
- [ ] Add telemetry events for game lifecycle

#### [T5]
- [x] Consider adding game creation timestamp to state (exists in db)

#### [T6]
- [ ] Add proper validation for difficulty parameter in all functions
