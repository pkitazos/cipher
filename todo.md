# todo

## LiveView Frontend Development Plan

### Phase 1: Setup (COMPLETED)
- [x] Add dependencies (phoenix_live_view, phoenix_html, esbuild, tailwind)
- [x] Configure asset pipeline in config.exs and dev.exs
- [x] Create layouts (root.html.heex, app.html.heex)
- [x] Create core_components.ex
- [x] Update cipher_web.ex with live_view/live_component/html helpers
- [x] Enable LiveView socket in endpoint.ex
- [x] Add browser pipeline and route in router.ex
- [x] Create basic GameLive module

### Phase 2: Game Creation (IN PROGRESS)
- [x] Connect "Start Game" button to Cipher.Game.Server.start_game/0
- [x] Display actual game ID after creation
- [x] Add difficulty selection (easy/normal/hard)

### Phase 3: Display Game State
- [x] Show current guess slots (empty or filled)
- [x] Display guess history with match counts
- [x] Show game status (active/won)

### Phase 4: Category Selection & Guessing
- [x] Define choice data (shapes, colors, patterns, directions)
- [x] Build category selector component
- [x] Handle selection events and track current guess
- [x] Submit guess to Game.Server
- [ ] Handle win state, reset, and level-up

### Phase 5: Polish & Styling
- [ ] Style the game board with Tailwind
- [ ] Add visual feedback and transitions
- [ ] Mobile-responsive design
