defmodule Cipher.GamesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Cipher.Games` context.
  """

  @doc """
  Generate a game.
  """
  def game_fixture(attrs \\ %{}) do
    user = Cipher.AccountsFixtures.user_fixture()

    {:ok, game} =
      attrs
      |> Enum.into(%{
        difficulty: :normal,
        secret: [:circle, :red, :vertical_stripes, :top],
        status: :active,
        user_id: user.id
      })
      |> Cipher.Games.create_game()

    game
  end

  @doc """
  Generate a guess.
  """
  def guess_fixture(attrs \\ %{}) do
    game = game_fixture()

    {:ok, guess} =
      attrs
      |> Enum.into(%{
        choices: [:circle, :red, :vertical_stripes, :top],
        matches: 4,
        game_id: game.id
      })
      |> Cipher.Games.create_guess()

    guess
  end
end
