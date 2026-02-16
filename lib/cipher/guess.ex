defmodule Cipher.Guess do
  @moduledoc """
  The pure domain entity representing a player's guess.
  Decoupled from the database schema.
  """
  alias Cipher.Games.Choice

  defstruct [:game_id, :matches, :choices]

  @type t :: %__MODULE__{
          game_id: integer(),
          choices: MapSet.t(Choice.t()),
          matches: integer()
        }

  @doc """
  Converts a DB Schema (%Cipher.Games.Guess{}) into a Domain DTO.
  Inflates the list of atoms ([:red, :circle]) back into full Choice structs.
  """
  def new(db_guess) do
    %__MODULE__{
      game_id: db_guess.game_id,
      matches: db_guess.matches,
      choices: inflate_choices(db_guess.choices)
    }
  end

  defp inflate_choices(atom_list) when is_list(atom_list) do
    atom_list
    |> Enum.map(&Choice.from_name/1)
    |> MapSet.new()
  end
end
