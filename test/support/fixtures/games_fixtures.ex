defmodule Cipher.GamesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Cipher.Games` context.
  """

  @doc """
  Generate a game.
  """
  def game_fixture(attrs \\ %{}) do
    {:ok, game} =
      attrs
      |> Enum.into(%{
        difficulty: "some difficulty",
        secret: ["option1", "option2"],
        status: "some status"
      })
      |> Cipher.Games.create_game()

    game
  end

  @doc """
  Generate a guess.
  """
  def guess_fixture(attrs \\ %{}) do
    {:ok, guess} =
      attrs
      |> Enum.into(%{
        choices: ["option1", "option2"],
        matches: 42
      })
      |> Cipher.Games.create_guess()

    guess
  end
end
