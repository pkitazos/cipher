defmodule Cipher.GamesTest do
  use Cipher.DataCase

  alias Cipher.Games

  describe "games" do
    alias Cipher.Games.Game

    import Cipher.GamesFixtures

    @invalid_attrs %{status: nil, difficulty: nil, secret: nil}

    test "list_games/0 returns all games" do
      game = game_fixture()
      assert Games.list_games() == [game]
    end

    test "get_game!/1 returns the game with given id" do
      game = game_fixture()
      assert Games.get_game!(game.id) == game
    end

    test "create_game/1 with valid data creates a game" do
      valid_attrs = %{
        status: :active,
        difficulty: :normal,
        secret: [:circle, :red, :vertical_stripes, :top]
      }

      assert {:ok, %Game{} = game} = Games.create_game(valid_attrs)
      assert game.status == :active
      assert game.difficulty == :normal
      assert game.secret == [:circle, :red, :vertical_stripes, :top]
    end

    test "create_game/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Games.create_game(@invalid_attrs)
    end

    test "update_game/2 with valid data updates the game" do
      game = game_fixture()

      update_attrs = %{
        status: :won,
        difficulty: :hard,
        secret: [:circle, :red, :vertical_stripes, :top, :tiny]
      }

      assert {:ok, %Game{} = game} = Games.update_game(game, update_attrs)
      assert game.status == :won
      assert game.difficulty == :hard
      assert game.secret == [:circle, :red, :vertical_stripes, :top, :tiny]
    end

    test "update_game/2 with invalid data returns error changeset" do
      game = game_fixture()
      assert {:error, %Ecto.Changeset{}} = Games.update_game(game, @invalid_attrs)
      assert game == Games.get_game!(game.id)
    end

    test "delete_game/1 deletes the game" do
      game = game_fixture()
      assert {:ok, %Game{}} = Games.delete_game(game)
      assert_raise Ecto.NoResultsError, fn -> Games.get_game!(game.id) end
    end

    test "change_game/1 returns a game changeset" do
      game = game_fixture()
      assert %Ecto.Changeset{} = Games.change_game(game)
    end
  end

  describe "guesses" do
    alias Cipher.Games.Guess

    import Cipher.GamesFixtures

    @invalid_attrs %{matches: nil, choices: nil}

    test "list_guesses/0 returns all guesses" do
      guess = guess_fixture()
      assert Games.list_guesses() == [guess]
    end

    test "get_guess!/1 returns the guess with given id" do
      guess = guess_fixture()
      assert Games.get_guess!(guess.id) == guess
    end

    test "create_guess/1 with valid data creates a guess" do
      game = game_fixture()

      valid_attrs = %{
        game_id: game.id,
        matches: 3,
        choices: [:circle, :red, :vertical_stripes, :top]
      }

      assert {:ok, %Guess{} = guess} = Games.create_guess(valid_attrs)
      assert guess.matches == 3
      assert guess.choices == [:circle, :red, :vertical_stripes, :top]
    end

    test "create_guess/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Games.create_guess(@invalid_attrs)
    end

    test "update_guess/2 with valid data updates the guess" do
      guess = guess_fixture()
      update_attrs = %{matches: 2, choices: [:circle, :red, :vertical_stripes, :top]}

      assert {:ok, %Guess{} = guess} = Games.update_guess(guess, update_attrs)
      assert guess.matches == 2
      assert guess.choices == [:circle, :red, :vertical_stripes, :top]
    end

    test "update_guess/2 with invalid data returns error changeset" do
      guess = guess_fixture()
      assert {:error, %Ecto.Changeset{}} = Games.update_guess(guess, @invalid_attrs)
      assert guess == Games.get_guess!(guess.id)
    end

    test "delete_guess/1 deletes the guess" do
      guess = guess_fixture()
      assert {:ok, %Guess{}} = Games.delete_guess(guess)
      assert_raise Ecto.NoResultsError, fn -> Games.get_guess!(guess.id) end
    end

    test "change_guess/1 returns a guess changeset" do
      guess = guess_fixture()
      assert %Ecto.Changeset{} = Games.change_guess(guess)
    end
  end
end
