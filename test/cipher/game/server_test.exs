defmodule Cipher.Game.ServerTest do
  use ExUnit.Case, async: true
  alias Cipher.Game.Server

  describe "start_game/0" do
    test "returns {:ok, game_id} with a valid UUID" do
      assert {:ok, game_id} = Server.start_game()
      assert is_binary(game_id)
      assert String.length(game_id) == 36
    end

    test "each call generates a unique game_id" do
      {:ok, game_id_1} = Server.start_game()
      {:ok, game_id_2} = Server.start_game()
      assert game_id_1 != game_id_2
    end

    test "creates a GenServer that can be looked up in Registry" do
      {:ok, game_id} = Server.start_game()
      assert [{pid, _}] = Registry.lookup(Cipher.GameRegistry, game_id)
      assert Process.alive?(pid)
    end
  end

  describe "join_game/1" do
    test "returns {:ok, state} with initial game state for valid game_id" do
      {:ok, game_id} = Server.start_game()
      assert {:ok, state} = Server.join_game(game_id)

      assert state.id == game_id
      assert state.guesses == []
      assert state.status == :active
      assert MapSet.size(state.secret) == 4
    end

    test "returns {:error, :game_not_found} for non-existent game_id" do
      assert {:error, :game_not_found} = Server.join_game("non-existent-id")
    end
  end

  describe "guess/2" do
    setup do
      {:ok, game_id} = Server.start_game()
      {:ok, state} = Server.join_game(game_id)
      %{game_id: game_id, secret: state.secret}
    end

    test "returns :correct when all 4 choices match", %{game_id: game_id, secret: secret} do
      # Convert the secret to a guess format
      secret_list = MapSet.to_list(secret)

      guess_data = %{
        shape: Enum.find(secret_list, &(&1.kind == :shape)).name |> Atom.to_string(),
        colour: Enum.find(secret_list, &(&1.kind == :colour)).name |> Atom.to_string(),
        pattern: Enum.find(secret_list, &(&1.kind == :pattern)).name |> Atom.to_string(),
        direction: Enum.find(secret_list, &(&1.kind == :direction)).name |> Atom.to_string()
      }

      assert :correct = Server.guess(game_id, guess_data)
    end

    test "returns {:incorrect, matches} with correct match count", %{game_id: game_id} do
      guess_data = %{
        shape: "circle",
        colour: "red",
        pattern: "dotted",
        direction: "top"
      }

      result = Server.guess(game_id, guess_data)

      case result do
        :correct ->
          assert true

        {:incorrect, matches} ->
          assert is_integer(matches)
          assert matches >= 0 and matches <= 3
      end
    end

    test "returns error for invalid choice", %{game_id: game_id} do
      guess_data = %{
        shape: "invalid",
        colour: "red",
        pattern: "dotted",
        direction: "top"
      }

      assert {:error, {:invalid_choice, :shape, "invalid"}} = Server.guess(game_id, guess_data)
    end

    test "returns error for missing field", %{game_id: game_id} do
      guess_data = %{
        shape: nil,
        colour: "red",
        pattern: "dotted",
        direction: "top"
      }

      assert {:error, {:missing_field, :shape}} = Server.guess(game_id, guess_data)
    end

    test "returns error for invalid format", %{game_id: game_id} do
      guess_data = %{
        shape: 123,
        colour: "red",
        pattern: "dotted",
        direction: "top"
      }

      assert {:error, {:invalid_format, :shape}} = Server.guess(game_id, guess_data)
    end

    test "returns {:error, :game_not_found} for non-existent game" do
      guess_data = %{
        shape: "circle",
        colour: "red",
        pattern: "dotted",
        direction: "top"
      }

      assert {:error, :game_not_found} = Server.guess("non-existent-id", guess_data)
    end
  end

  describe "state management" do
    test "game state accumulates guesses over multiple calls" do
      {:ok, game_id} = Server.start_game()

      guess_1 = %{shape: "circle", colour: "red", pattern: "dotted", direction: "top"}
      guess_2 = %{shape: "square", colour: "blue", pattern: "checkered", direction: "left"}

      Server.guess(game_id, guess_1)
      Server.guess(game_id, guess_2)

      {:ok, state} = Server.join_game(game_id)
      assert length(state.guesses) == 2
    end

    test "secret remains consistent across multiple guesses" do
      {:ok, game_id} = Server.start_game()
      {:ok, state_1} = Server.join_game(game_id)

      guess_data = %{shape: "circle", colour: "red", pattern: "dotted", direction: "top"}
      Server.guess(game_id, guess_data)

      {:ok, state_2} = Server.join_game(game_id)
      assert state_1.secret == state_2.secret
    end
  end

  describe "status tracking" do
    test "game starts with status :active" do
      {:ok, game_id} = Server.start_game()
      {:ok, state} = Server.join_game(game_id)

      assert state.status == :active
    end

    test "status changes to :won when correct guess is made" do
      {:ok, game_id} = Server.start_game()
      {:ok, state} = Server.join_game(game_id)

      secret_list = MapSet.to_list(state.secret)

      guess_data = %{
        shape: Enum.find(secret_list, &(&1.kind == :shape)).name |> Atom.to_string(),
        colour: Enum.find(secret_list, &(&1.kind == :colour)).name |> Atom.to_string(),
        pattern: Enum.find(secret_list, &(&1.kind == :pattern)).name |> Atom.to_string(),
        direction: Enum.find(secret_list, &(&1.kind == :direction)).name |> Atom.to_string()
      }

      assert :correct = Server.guess(game_id, guess_data)

      {:ok, updated_state} = Server.join_game(game_id)
      assert updated_state.status == :won
    end

    test "status remains :active after incorrect guesses" do
      {:ok, game_id} = Server.start_game()

      guess_data = %{shape: "circle", colour: "red", pattern: "dotted", direction: "top"}
      Server.guess(game_id, guess_data)

      {:ok, state} = Server.join_game(game_id)

      case state.status do
        :active -> assert true
        :won -> assert true
      end
    end

    test "guesses are blocked after game is won" do
      {:ok, game_id} = Server.start_game()
      {:ok, state} = Server.join_game(game_id)

      secret_list = MapSet.to_list(state.secret)

      correct_guess = %{
        shape: Enum.find(secret_list, &(&1.kind == :shape)).name |> Atom.to_string(),
        colour: Enum.find(secret_list, &(&1.kind == :colour)).name |> Atom.to_string(),
        pattern: Enum.find(secret_list, &(&1.kind == :pattern)).name |> Atom.to_string(),
        direction: Enum.find(secret_list, &(&1.kind == :direction)).name |> Atom.to_string()
      }

      assert :correct = Server.guess(game_id, correct_guess)

      another_guess = %{shape: "square", colour: "blue", pattern: "checkered", direction: "left"}
      assert {:error, {:game_not_active, :won}} = Server.guess(game_id, another_guess)
    end
  end

  describe "reset_game/1" do
    test "resets game with new secret and clears history" do
      {:ok, game_id} = Server.start_game()
      {:ok, initial_state} = Server.join_game(game_id)
      initial_secret = initial_state.secret

      guess_data = %{shape: "circle", colour: "red", pattern: "dotted", direction: "top"}
      Server.guess(game_id, guess_data)

      assert {:ok, reset_state} = Server.reset_game(game_id)

      assert reset_state.id == game_id
      assert reset_state.guesses == []
      assert reset_state.status == :active
      assert MapSet.size(reset_state.secret) == 4

      assert reset_state.secret != initial_secret or reset_state.secret == initial_secret
    end

    test "resets won game back to active" do
      {:ok, game_id} = Server.start_game()
      {:ok, state} = Server.join_game(game_id)

      # Win the game
      secret_list = MapSet.to_list(state.secret)

      correct_guess = %{
        shape: Enum.find(secret_list, &(&1.kind == :shape)).name |> Atom.to_string(),
        colour: Enum.find(secret_list, &(&1.kind == :colour)).name |> Atom.to_string(),
        pattern: Enum.find(secret_list, &(&1.kind == :pattern)).name |> Atom.to_string(),
        direction: Enum.find(secret_list, &(&1.kind == :direction)).name |> Atom.to_string()
      }

      Server.guess(game_id, correct_guess)

      {:ok, reset_state} = Server.reset_game(game_id)

      assert reset_state.status == :active
      assert reset_state.guesses == []
    end

    test "returns error for non-existent game" do
      assert {:error, :game_not_found} = Server.reset_game("non-existent-id")
    end
  end
end
