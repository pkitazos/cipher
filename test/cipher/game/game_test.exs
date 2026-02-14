defmodule Cipher.GameTest do
  use ExUnit.Case, async: true

  alias Cipher.Games.Logic, as: GameLogic
  alias Cipher.Games.Choice

  describe "initialise_secret/0" do
    test "returns a MapSet with 4 choices" do
      secret = GameLogic.initialise_secret()
      assert MapSet.size(secret) == 4
    end

    test "contains one choice of each kind" do
      secret = GameLogic.initialise_secret()
      choices_list = MapSet.to_list(secret)

      kinds = Enum.map(choices_list, & &1.kind)
      assert :shape in kinds
      assert :colour in kinds
      assert :pattern in kinds
      assert :direction in kinds
    end

    test "generates different secrets on multiple calls" do
      secrets = Enum.map(1..10, fn _ -> GameLogic.initialise_secret() end)
      unique_secrets = Enum.uniq(secrets)

      # we should get at least 2 different secrets in 10 tries
      # (technically could fail, but probability is extremely low)
      assert length(unique_secrets) > 1
    end
  end

  describe "convert_guess!/1" do
    test "converts valid guess map to MapSet with 4 choices" do
      guess = %{
        shape: "circle",
        colour: "red",
        pattern: "vertical_stripes",
        direction: "top"
      }

      result = GameLogic.convert_guess!(guess)

      assert MapSet.size(result) == 4

      choices_list = MapSet.to_list(result)
      assert Enum.any?(choices_list, &(&1.name == :circle))
      assert Enum.any?(choices_list, &(&1.name == :red))
      assert Enum.any?(choices_list, &(&1.name == :vertical_stripes))
      assert Enum.any?(choices_list, &(&1.name == :top))
    end

    test "raises error for invalid shape" do
      guess = %{shape: "invalid", colour: "red", pattern: "dotted", direction: "top"}
      assert_raise KeyError, fn -> GameLogic.convert_guess!(guess) end
    end

    test "raises error for invalid colour" do
      guess = %{shape: "circle", colour: "invalid", pattern: "dotted", direction: "top"}
      assert_raise KeyError, fn -> GameLogic.convert_guess!(guess) end
    end

    test "raises error for invalid pattern" do
      guess = %{shape: "circle", colour: "red", pattern: "invalid", direction: "top"}
      assert_raise KeyError, fn -> GameLogic.convert_guess!(guess) end
    end

    test "raises error for invalid direction" do
      guess = %{shape: "circle", colour: "red", pattern: "dotted", direction: "invalid"}
      assert_raise KeyError, fn -> GameLogic.convert_guess!(guess) end
    end
  end

  describe "convert_guess/1" do
    test "returns {:ok, mapset} for valid guess" do
      guess = %{
        shape: "circle",
        colour: "red",
        pattern: "vertical_stripes",
        direction: "top"
      }

      assert {:ok, result} = GameLogic.convert_guess(guess)
      assert MapSet.size(result) == 4
    end

    test "returns error tuple with invalid_choice for invalid shape" do
      guess = %{shape: "invalid", colour: "red", pattern: "dotted", direction: "top"}
      assert {:error, {:invalid_choice, :shape, "invalid"}} = GameLogic.convert_guess(guess)
    end

    test "returns error tuple with invalid_choice for invalid colour" do
      guess = %{shape: "circle", colour: "invalid", pattern: "dotted", direction: "top"}
      assert {:error, {:invalid_choice, :colour, "invalid"}} = GameLogic.convert_guess(guess)
    end

    test "returns error tuple with invalid_choice for invalid pattern" do
      guess = %{shape: "circle", colour: "red", pattern: "invalid", direction: "top"}
      assert {:error, {:invalid_choice, :pattern, "invalid"}} = GameLogic.convert_guess(guess)
    end

    test "returns error tuple with invalid_choice for invalid direction" do
      guess = %{shape: "circle", colour: "red", pattern: "dotted", direction: "invalid"}
      assert {:error, {:invalid_choice, :direction, "invalid"}} = GameLogic.convert_guess(guess)
    end

    test "returns error tuple with missing_field for nil shape" do
      guess = %{shape: nil, colour: "red", pattern: "dotted", direction: "top"}
      assert {:error, {:missing_field, :shape}} = GameLogic.convert_guess(guess)
    end

    test "returns error tuple with missing_field for nil colour" do
      guess = %{shape: "circle", colour: nil, pattern: "dotted", direction: "top"}
      assert {:error, {:missing_field, :colour}} = GameLogic.convert_guess(guess)
    end

    test "returns error tuple with missing_field for nil pattern" do
      guess = %{shape: "circle", colour: "red", pattern: nil, direction: "top"}
      assert {:error, {:missing_field, :pattern}} = GameLogic.convert_guess(guess)
    end

    test "returns error tuple with missing_field for nil direction" do
      guess = %{shape: "circle", colour: "red", pattern: "dotted", direction: nil}
      assert {:error, {:missing_field, :direction}} = GameLogic.convert_guess(guess)
    end

    test "returns error tuple with invalid_format for non-string shape" do
      guess = %{shape: 123, colour: "red", pattern: "dotted", direction: "top"}
      assert {:error, {:invalid_format, :shape}} = GameLogic.convert_guess(guess)
    end

    test "returns error tuple with invalid_format for non-string colour" do
      guess = %{shape: "circle", colour: :red, pattern: "dotted", direction: "top"}
      assert {:error, {:invalid_format, :colour}} = GameLogic.convert_guess(guess)
    end

    test "returns error tuple with invalid_format for non-string pattern" do
      guess = %{shape: "circle", colour: "red", pattern: :dotted, direction: "top"}
      assert {:error, {:invalid_format, :pattern}} = GameLogic.convert_guess(guess)
    end

    test "returns error tuple with invalid_format for non-string direction" do
      guess = %{shape: "circle", colour: "red", pattern: "dotted", direction: 123}
      assert {:error, {:invalid_format, :direction}} = GameLogic.convert_guess(guess)
    end
  end

  describe "convert_guess_from_choices/2" do
    test "returns {:ok, mapset} for valid choice map" do
      circle = %Choice{kind: :shape, name: :circle}
      red = %Choice{kind: :colour, name: :red}
      vertical = %Choice{kind: :pattern, name: :vertical_stripes}
      top = %Choice{kind: :direction, name: :top}

      guess_map = %{
        shape: circle,
        colour: red,
        pattern: vertical,
        direction: top
      }

      assert {:ok, result} = GameLogic.convert_guess_from_choices(guess_map, :normal)
      assert MapSet.size(result) == 4
      assert MapSet.member?(result, circle)
      assert MapSet.member?(result, red)
      assert MapSet.member?(result, vertical)
      assert MapSet.member?(result, top)
    end

    test "returns error for missing field" do
      circle = %Choice{kind: :shape, name: :circle}
      red = %Choice{kind: :colour, name: :red}

      incomplete_guess = %{
        shape: circle,
        colour: red
        # missing pattern and direction
      }

      assert {:error, {:missing_field, :pattern}} =
               GameLogic.convert_guess_from_choices(incomplete_guess, :normal)
    end

    test "works with easy difficulty (3 fields)" do
      circle = %Choice{kind: :shape, name: :circle}
      red = %Choice{kind: :colour, name: :red}
      vertical = %Choice{kind: :pattern, name: :vertical_stripes}

      guess_map = %{
        shape: circle,
        colour: red,
        pattern: vertical
      }

      assert {:ok, result} = GameLogic.convert_guess_from_choices(guess_map, :easy)
      assert MapSet.size(result) == 3
    end

    test "works with hard difficulty (5 fields)" do
      circle = %Choice{kind: :shape, name: :circle}
      red = %Choice{kind: :colour, name: :red}
      vertical = %Choice{kind: :pattern, name: :vertical_stripes}
      top = %Choice{kind: :direction, name: :top}
      small = %Choice{kind: :size, name: :small}

      guess_map = %{
        shape: circle,
        colour: red,
        pattern: vertical,
        direction: top,
        size: small
      }

      assert {:ok, result} = GameLogic.convert_guess_from_choices(guess_map, :hard)
      assert MapSet.size(result) == 5
    end
  end

  describe "calculate_matches/2" do
    test "returns 4 when all choices match" do
      secret =
        MapSet.new([
          %Choice{kind: :shape, name: :circle},
          %Choice{kind: :colour, name: :red},
          %Choice{kind: :pattern, name: :vertical_stripes},
          %Choice{kind: :direction, name: :top}
        ])

      guess =
        MapSet.new([
          %Choice{kind: :shape, name: :circle},
          %Choice{kind: :colour, name: :red},
          %Choice{kind: :pattern, name: :vertical_stripes},
          %Choice{kind: :direction, name: :top}
        ])

      assert GameLogic.calculate_matches(guess, secret) == 4
    end

    test "returns 0 when no choices match" do
      secret =
        MapSet.new([
          %Choice{kind: :shape, name: :circle},
          %Choice{kind: :colour, name: :red},
          %Choice{kind: :pattern, name: :vertical_stripes},
          %Choice{kind: :direction, name: :top}
        ])

      guess =
        MapSet.new([
          %Choice{kind: :shape, name: :square},
          %Choice{kind: :colour, name: :green},
          %Choice{kind: :pattern, name: :horizontal_stripes},
          %Choice{kind: :direction, name: :bottom}
        ])

      assert GameLogic.calculate_matches(guess, secret) == 0
    end

    test "returns 1 when only one choice matches" do
      secret =
        MapSet.new([
          %Choice{kind: :shape, name: :circle},
          %Choice{kind: :colour, name: :red},
          %Choice{kind: :pattern, name: :vertical_stripes},
          %Choice{kind: :direction, name: :top}
        ])

      guess =
        MapSet.new([
          %Choice{kind: :shape, name: :circle},
          %Choice{kind: :colour, name: :green},
          %Choice{kind: :pattern, name: :horizontal_stripes},
          %Choice{kind: :direction, name: :bottom}
        ])

      assert GameLogic.calculate_matches(guess, secret) == 1
    end

    test "returns 2 when two choices match" do
      secret =
        MapSet.new([
          %Choice{kind: :shape, name: :circle},
          %Choice{kind: :colour, name: :red},
          %Choice{kind: :pattern, name: :vertical_stripes},
          %Choice{kind: :direction, name: :top}
        ])

      guess =
        MapSet.new([
          %Choice{kind: :shape, name: :circle},
          %Choice{kind: :colour, name: :red},
          %Choice{kind: :pattern, name: :horizontal_stripes},
          %Choice{kind: :direction, name: :bottom}
        ])

      assert GameLogic.calculate_matches(guess, secret) == 2
    end

    test "returns 3 when three choices match" do
      secret =
        MapSet.new([
          %Choice{kind: :shape, name: :circle},
          %Choice{kind: :colour, name: :red},
          %Choice{kind: :pattern, name: :vertical_stripes},
          %Choice{kind: :direction, name: :top}
        ])

      guess =
        MapSet.new([
          %Choice{kind: :shape, name: :circle},
          %Choice{kind: :colour, name: :red},
          %Choice{kind: :pattern, name: :vertical_stripes},
          %Choice{kind: :direction, name: :bottom}
        ])

      assert GameLogic.calculate_matches(guess, secret) == 3
    end

    test "works end-to-end" do
      secret =
        MapSet.new([
          %Choice{kind: :shape, name: :circle},
          %Choice{kind: :colour, name: :red},
          %Choice{kind: :pattern, name: :vertical_stripes},
          %Choice{kind: :direction, name: :top}
        ])

      guess_data = %{
        shape: "circle",
        colour: "red",
        pattern: "vertical_stripes",
        direction: "top"
      }

      {:ok, guess} = GameLogic.convert_guess(guess_data)
      assert GameLogic.calculate_matches(guess, secret) == 4
    end
  end

  describe "difficulty levels" do
    test "easy difficulty generates secret with 3 choices (no direction)" do
      secret = GameLogic.initialise_secret(:easy)
      assert MapSet.size(secret) == 3

      choices_list = MapSet.to_list(secret)
      kinds = Enum.map(choices_list, & &1.kind)

      assert :shape in kinds
      assert :colour in kinds
      assert :pattern in kinds
      refute :direction in kinds
      refute :size in kinds
    end

    test "normal difficulty generates secret with 4 choices (default)" do
      secret = GameLogic.initialise_secret(:normal)
      assert MapSet.size(secret) == 4

      choices_list = MapSet.to_list(secret)
      kinds = Enum.map(choices_list, & &1.kind)

      assert :shape in kinds
      assert :colour in kinds
      assert :pattern in kinds
      assert :direction in kinds
      refute :size in kinds
    end

    test "hard difficulty generates secret with 5 choices (adds size)" do
      secret = GameLogic.initialise_secret(:hard)
      assert MapSet.size(secret) == 5

      choices_list = MapSet.to_list(secret)
      kinds = Enum.map(choices_list, & &1.kind)

      assert :shape in kinds
      assert :colour in kinds
      assert :pattern in kinds
      assert :direction in kinds
      assert :size in kinds
    end

    test "convert_guess handles easy difficulty (3 fields)" do
      guess_data = %{
        shape: "circle",
        colour: "red",
        pattern: "vertical_stripes",
        direction: nil,
        size: nil
      }

      assert {:ok, guess} = GameLogic.convert_guess(guess_data, :easy)
      assert MapSet.size(guess) == 3

      choices_list = MapSet.to_list(guess)
      kinds = Enum.map(choices_list, & &1.kind)

      assert :shape in kinds
      assert :colour in kinds
      assert :pattern in kinds
      refute :direction in kinds
    end

    test "convert_guess handles hard difficulty (5 fields)" do
      guess_data = %{
        shape: "circle",
        colour: "red",
        pattern: "vertical_stripes",
        direction: "top",
        size: "medium"
      }

      assert {:ok, guess} = GameLogic.convert_guess(guess_data, :hard)
      assert MapSet.size(guess) == 5

      choices_list = MapSet.to_list(guess)
      kinds = Enum.map(choices_list, & &1.kind)

      assert :shape in kinds
      assert :colour in kinds
      assert :pattern in kinds
      assert :direction in kinds
      assert :size in kinds
    end

    test "convert_guess validates size field correctly" do
      valid_guess = %{
        shape: "circle",
        colour: "red",
        pattern: "vertical_stripes",
        direction: "top",
        size: "tiny"
      }

      assert {:ok, _} = GameLogic.convert_guess(valid_guess, :hard)

      invalid_guess = %{
        shape: "circle",
        colour: "red",
        pattern: "vertical_stripes",
        direction: "top",
        size: "invalid"
      }

      assert {:error, {:invalid_choice, :size, "invalid"}} =
               GameLogic.convert_guess(invalid_guess, :hard)
    end

    test "calculate_matches works for easy difficulty" do
      secret =
        MapSet.new([
          %Choice{kind: :shape, name: :circle},
          %Choice{kind: :colour, name: :red},
          %Choice{kind: :pattern, name: :vertical_stripes}
        ])

      guess =
        MapSet.new([
          %Choice{kind: :shape, name: :circle},
          %Choice{kind: :colour, name: :red},
          %Choice{kind: :pattern, name: :vertical_stripes}
        ])

      assert GameLogic.calculate_matches(guess, secret) == 3
    end

    test "calculate_matches works for hard difficulty" do
      secret =
        MapSet.new([
          %Choice{kind: :shape, name: :circle},
          %Choice{kind: :colour, name: :red},
          %Choice{kind: :pattern, name: :vertical_stripes},
          %Choice{kind: :direction, name: :top},
          %Choice{kind: :size, name: :medium}
        ])

      guess =
        MapSet.new([
          %Choice{kind: :shape, name: :circle},
          %Choice{kind: :colour, name: :red},
          %Choice{kind: :pattern, name: :vertical_stripes},
          %Choice{kind: :direction, name: :top},
          %Choice{kind: :size, name: :medium}
        ])

      assert GameLogic.calculate_matches(guess, secret) == 5
    end

    test "next_difficulty returns normal for easy" do
      assert {:ok, :normal} = GameLogic.next_difficulty(:easy)
    end

    test "next_difficulty returns hard for normal" do
      assert {:ok, :hard} = GameLogic.next_difficulty(:normal)
    end

    test "next_difficulty returns error for hard" do
      assert {:error, :max_difficulty} = GameLogic.next_difficulty(:hard)
    end

    test "next_difficulty returns error for invalid difficulty" do
      assert {:error, :invalid_difficulty} = GameLogic.next_difficulty(:invalid)
    end
  end
end
