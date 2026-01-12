defmodule CipherWeb.GameControllerTest do
  use CipherWeb.ConnCase, async: true
  alias Cipher.Game

  describe "POST /api/games" do
    test "creates a new game and returns game_id with empty guesses", %{conn: conn} do
      conn = post(conn, ~p"/api/games")
      response = json_response(conn, 200)

      assert %{"id" => game_id, "history" => []} = response
      assert is_binary(game_id)
      assert String.length(game_id) == 36
    end

    test "created game can be joined", %{conn: conn} do
      conn = post(conn, ~p"/api/games")
      %{"id" => game_id} = json_response(conn, 200)

      {:ok, state} = Game.Server.join_game(game_id)
      assert state.id == game_id
    end

    test "each create generates a unique game_id", %{conn: conn} do
      conn1 = post(conn, ~p"/api/games")
      %{"id" => game_id_1} = json_response(conn1, 200)

      conn2 = post(conn, ~p"/api/games")
      %{"id" => game_id_2} = json_response(conn2, 200)

      assert game_id_1 != game_id_2
    end
  end

  describe "GET /api/games/:id" do
    test "returns game state for valid game_id", %{conn: conn} do
      conn_create = post(conn, ~p"/api/games")
      %{"id" => game_id} = json_response(conn_create, 200)

      conn_show = get(conn, ~p"/api/games/#{game_id}")
      response = json_response(conn_show, 200)

      assert %{"id" => ^game_id, "status" => "active", "history" => []} = response
    end

    test "returns 404 for non-existent game", %{conn: conn} do
      conn = get(conn, ~p"/api/games/non-existent-id")
      response = json_response(conn, 404)

      assert %{"error" => "Game not found"} = response
    end

    test "shows accumulated guesses after making guesses", %{conn: conn} do
      conn_create = post(conn, ~p"/api/games")
      %{"id" => game_id} = json_response(conn_create, 200)

      guess_data = %{
        guess: %{
          shape: "circle",
          colour: "red",
          pattern: "dotted",
          direction: "top"
        }
      }

      post(conn, ~p"/api/games/#{game_id}/guess", guess_data)

      conn_show = get(conn, ~p"/api/games/#{game_id}")
      response = json_response(conn_show, 200)

      assert %{"id" => ^game_id, "history" => guesses} = response
      assert length(guesses) == 1
    end
  end

  describe "POST /api/games/:id/guess" do
    setup %{conn: conn} do
      conn_create = post(conn, ~p"/api/games")
      %{"id" => game_id} = json_response(conn_create, 200)

      {:ok, state} = Game.Server.join_game(game_id)

      %{conn: conn, game_id: game_id, secret: state.secret}
    end

    test "returns correct result when guess matches secret", %{
      conn: conn,
      game_id: game_id,
      secret: secret
    } do
      secret_list = MapSet.to_list(secret)

      guess_data = %{
        guess: %{
          shape: Enum.find(secret_list, &(&1.kind == :shape)).name |> Atom.to_string(),
          colour: Enum.find(secret_list, &(&1.kind == :colour)).name |> Atom.to_string(),
          pattern: Enum.find(secret_list, &(&1.kind == :pattern)).name |> Atom.to_string(),
          direction: Enum.find(secret_list, &(&1.kind == :direction)).name |> Atom.to_string()
        }
      }

      conn = post(conn, ~p"/api/games/#{game_id}/guess", guess_data)
      response = json_response(conn, 200)

      assert %{"result" => "correct", "message" => "You won!"} = response
    end

    test "returns incorrect with matches count for partial match", %{conn: conn, game_id: game_id} do
      guess_data = %{
        guess: %{
          shape: "circle",
          colour: "red",
          pattern: "dotted",
          direction: "top"
        }
      }

      conn = post(conn, ~p"/api/games/#{game_id}/guess", guess_data)
      response = json_response(conn, 200)

      case response do
        %{"result" => "correct"} ->
          assert true

        %{"result" => "incorrect", "matches" => matches} ->
          assert is_integer(matches)
          assert matches >= 0 and matches <= 3
      end
    end

    test "returns 400 for invalid choice", %{conn: conn, game_id: game_id} do
      guess_data = %{
        guess: %{
          shape: "invalid_shape",
          colour: "red",
          pattern: "dotted",
          direction: "top"
        }
      }

      conn = post(conn, ~p"/api/games/#{game_id}/guess", guess_data)
      response = json_response(conn, 400)

      assert %{"error" => error} = response
      assert error =~ "Invalid"
    end

    test "returns 400 for missing field (nil value)", %{conn: conn, game_id: game_id} do
      guess_data = %{
        guess: %{
          shape: nil,
          colour: "red",
          pattern: "dotted",
          direction: "top"
        }
      }

      conn = post(conn, ~p"/api/games/#{game_id}/guess", guess_data)
      response = json_response(conn, 400)

      assert %{"error" => error} = response
      assert error =~ "Missing"
    end

    test "returns 400 for invalid format (non-string value)", %{conn: conn, game_id: game_id} do
      guess_data = %{
        guess: %{
          shape: 123,
          colour: "red",
          pattern: "dotted",
          direction: "top"
        }
      }

      conn = post(conn, ~p"/api/games/#{game_id}/guess", guess_data)
      response = json_response(conn, 400)

      assert %{"error" => error} = response
      assert error =~ "Invalid"
    end

    test "returns 404 for non-existent game", %{conn: conn} do
      guess_data = %{
        guess: %{
          shape: "circle",
          colour: "red",
          pattern: "dotted",
          direction: "top"
        }
      }

      conn = post(conn, ~p"/api/games/non-existent-id/guess", guess_data)
      response = json_response(conn, 404)

      assert %{"error" => "Game not found"} = response
    end

    test "multiple guesses are accumulated in game state", %{conn: conn, game_id: game_id} do
      guess_1 = %{guess: %{shape: "circle", colour: "red", pattern: "dotted", direction: "top"}}

      guess_2 = %{
        guess: %{shape: "square", colour: "blue", pattern: "checkered", direction: "left"}
      }

      post(conn, ~p"/api/games/#{game_id}/guess", guess_1)
      post(conn, ~p"/api/games/#{game_id}/guess", guess_2)

      conn_show = get(conn, ~p"/api/games/#{game_id}")
      response = json_response(conn_show, 200)

      assert %{"history" => guesses} = response
      assert length(guesses) == 2
    end

    test "status changes to won after correct guess", %{
      conn: conn,
      game_id: game_id,
      secret: secret
    } do
      secret_list = MapSet.to_list(secret)

      guess_data = %{
        guess: %{
          shape: Enum.find(secret_list, &(&1.kind == :shape)).name |> Atom.to_string(),
          colour: Enum.find(secret_list, &(&1.kind == :colour)).name |> Atom.to_string(),
          pattern: Enum.find(secret_list, &(&1.kind == :pattern)).name |> Atom.to_string(),
          direction: Enum.find(secret_list, &(&1.kind == :direction)).name |> Atom.to_string()
        }
      }

      conn_guess = post(conn, ~p"/api/games/#{game_id}/guess", guess_data)
      assert json_response(conn_guess, 200)

      conn_show = get(conn, ~p"/api/games/#{game_id}")
      response = json_response(conn_show, 200)

      assert %{"status" => "won"} = response
    end

    test "returns 409 conflict when guessing on won game", %{
      conn: conn,
      game_id: game_id,
      secret: secret
    } do
      secret_list = MapSet.to_list(secret)

      correct_guess = %{
        guess: %{
          shape: Enum.find(secret_list, &(&1.kind == :shape)).name |> Atom.to_string(),
          colour: Enum.find(secret_list, &(&1.kind == :colour)).name |> Atom.to_string(),
          pattern: Enum.find(secret_list, &(&1.kind == :pattern)).name |> Atom.to_string(),
          direction: Enum.find(secret_list, &(&1.kind == :direction)).name |> Atom.to_string()
        }
      }

      post(conn, ~p"/api/games/#{game_id}/guess", correct_guess)

      another_guess = %{
        guess: %{shape: "square", colour: "blue", pattern: "checkered", direction: "left"}
      }

      conn_blocked = post(conn, ~p"/api/games/#{game_id}/guess", another_guess)
      response = json_response(conn_blocked, 409)

      assert %{"error" => "Game already completed", "status" => "won"} = response
    end

    test "guess history includes match counts", %{conn: conn, game_id: game_id} do
      guess_1 = %{guess: %{shape: "circle", colour: "red", pattern: "dotted", direction: "top"}}

      guess_2 = %{
        guess: %{shape: "square", colour: "blue", pattern: "checkered", direction: "left"}
      }

      post(conn, ~p"/api/games/#{game_id}/guess", guess_1)
      post(conn, ~p"/api/games/#{game_id}/guess", guess_2)

      conn_show = get(conn, ~p"/api/games/#{game_id}")
      response = json_response(conn_show, 200)

      assert %{"history" => guesses} = response
      assert length(guesses) == 2

      Enum.each(guesses, fn guess ->
        assert Map.has_key?(guess, "matches")
        assert is_integer(guess["matches"])
        assert guess["matches"] >= 0 and guess["matches"] <= 4
      end)
    end
  end

  describe "POST /api/games/:id/reset" do
    test "resets game and returns new empty state", %{conn: conn} do
      conn_create = post(conn, ~p"/api/games")
      %{"id" => game_id} = json_response(conn_create, 200)

      guess = %{guess: %{shape: "circle", colour: "red", pattern: "dotted", direction: "top"}}
      post(conn, ~p"/api/games/#{game_id}/guess", guess)
      post(conn, ~p"/api/games/#{game_id}/guess", guess)

      conn_reset = post(conn, ~p"/api/games/#{game_id}/reset")
      response = json_response(conn_reset, 200)

      assert %{"id" => ^game_id, "status" => "active", "history" => []} = response
    end

    test "resets won game back to active", %{conn: conn} do
      conn_create = post(conn, ~p"/api/games")
      %{"id" => game_id} = json_response(conn_create, 200)

      {:ok, state} = Game.Server.join_game(game_id)
      secret_list = MapSet.to_list(state.secret)

      correct_guess = %{
        guess: %{
          shape: Enum.find(secret_list, &(&1.kind == :shape)).name |> Atom.to_string(),
          colour: Enum.find(secret_list, &(&1.kind == :colour)).name |> Atom.to_string(),
          pattern: Enum.find(secret_list, &(&1.kind == :pattern)).name |> Atom.to_string(),
          direction: Enum.find(secret_list, &(&1.kind == :direction)).name |> Atom.to_string()
        }
      }

      post(conn, ~p"/api/games/#{game_id}/guess", correct_guess)

      conn_reset = post(conn, ~p"/api/games/#{game_id}/reset")
      response = json_response(conn_reset, 200)

      assert %{"status" => "active", "history" => []} = response
    end

    test "returns 404 for non-existent game", %{conn: conn} do
      conn = post(conn, ~p"/api/games/non-existent-id/reset")
      response = json_response(conn, 404)

      assert %{"error" => "Game not found"} = response
    end

    test "can make guesses after reset", %{conn: conn} do
      conn_create = post(conn, ~p"/api/games")
      %{"id" => game_id} = json_response(conn_create, 200)

      post(conn, ~p"/api/games/#{game_id}/reset")

      guess = %{guess: %{shape: "circle", colour: "red", pattern: "dotted", direction: "top"}}
      conn_guess = post(conn, ~p"/api/games/#{game_id}/guess", guess)

      response = json_response(conn_guess, 200)
      assert Map.has_key?(response, "result")
    end
  end
end
