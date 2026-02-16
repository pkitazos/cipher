alias Cipher.Accounts
alias Cipher.Games

# Custom logger

defmodule Log do
  def info(msg), do: IO.puts([IO.ANSI.blue(), "[info] ", IO.ANSI.reset(), msg])
  def success(msg), do: IO.puts([IO.ANSI.green(), "[ok] ", IO.ANSI.reset(), msg])
  def warn(msg), do: IO.puts([IO.ANSI.yellow(), "[warning] ", IO.ANSI.reset(), msg])
  def error(msg), do: IO.puts([IO.ANSI.red(), "[error] ", IO.ANSI.reset(), msg])

  def section(title) do
    IO.puts([
      "\n",
      IO.ANSI.cyan(),
      IO.ANSI.bright(),
      "=== #{title} ===",
      IO.ANSI.reset()
    ])
  end
end

# Helpers

# A helper to "cheat" by looking at the game's secret target
# and converting it into the map format the Context expects: %{kind_atom => %Choice{}}
cheat_engine = fn game ->
  game.secret
  |> Enum.into(%{}, fn choice -> {choice.kind, choice} end)
end

# A helper to generate a deliberately WRONG guess (always picks the first option of each category)
# This ensures we don't accidentally win on the first try.
dummy_guesser = fn difficulty ->
  Cipher.Games.Logic.get_active_categories(difficulty)
  |> Enum.map(fn category ->
    # Pick the first available option for this category (e.g., :circle, :red)
    choice = Cipher.Games.Logic.get_choices_for_category(category) |> List.first()
    {category, choice}
  end)
  |> Enum.into(%{})
end

Log.section("\n--- 1. Seeding Users ---")

{:ok, alice} =
  Accounts.create_user(%{
    email: "alice@example.com",
    username: "alice_winner",
    provider: "google"
  })

Log.success("Created Alice (alice@example.com)")

{:ok, bob} =
  Accounts.create_user(%{
    email: "bob@example.com",
    username: "bob_builder",
    provider: "google"
  })

Log.success("Created Bob (bob@example.com)")

Log.section("\n--- 2. Scenario A: The Completed Game (Easy) ---")

# 1. Start Game
{:ok, game_won} = Games.start_new_game(alice, :easy)

# 2. Cheat: Read the secret from the struct and submit it
winning_guess = cheat_engine.(game_won)
{:ok, _result} = Games.make_guess(game_won.id, winning_guess)

Log.info("Game #{game_won.id} created and won immediately.")

Log.section("\n--- 3. Scenario B: The 'In Progress' Game (Normal) ---")

# 1. Start Game (Normal has 4 dimensions: shape, colour, pattern, direction)
{:ok, game_active} = Games.start_new_game(alice, :normal)

# 2. Make a wrong guess to populate history
wrong_guess = dummy_guesser.(:normal)
{:ok, _result} = Games.make_guess(game_active.id, wrong_guess)

Log.info("Game #{game_active.id} created with 1 incorrect guess.")

Log.section("\n--- 4. Scenario C: The Hard Mode (Fresh) ---")

# 1. Just start it, don't play it.
{:ok, game_hard} = Games.start_new_game(bob, :hard)

Log.info("Game #{game_hard.id} (Hard) created for Bob. No guesses yet.")

Log.section("\n--- 5. Verification ---")

# Quick check of the leaderboard
top_scores = Games.leaderboard(:easy)
IO.inspect(length(top_scores), label: "Leaderboard Entries")

IO.puts("\nPlayground Ready!")
