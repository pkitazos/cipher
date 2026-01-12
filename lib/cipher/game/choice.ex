defmodule Cipher.Game.Choice do
  alias Cipher.Game.Choice

  defstruct [:kind, :name, :_ord, :_kind_ord]

  def show(%Choice{name: :circle}), do: "O"
  def show(%Choice{name: :square}), do: "[]"
  def show(%Choice{name: :star}), do: "*"
  def show(%Choice{name: :triangle}), do: "Δ"
  def show(%Choice{name: :red}), do: "R"
  def show(%Choice{name: :green}), do: "G"
  def show(%Choice{name: :blue}), do: "B"
  def show(%Choice{name: :yellow}), do: "Y"
  def show(%Choice{name: :vertical_stripes}), do: "||"
  def show(%Choice{name: :horizontal_stripes}), do: "="
  def show(%Choice{name: :checkered}), do: "#"
  def show(%Choice{name: :dotted}), do: "::"
  def show(%Choice{name: :top}), do: "^"
  def show(%Choice{name: :bottom}), do: "v"
  def show(%Choice{name: :left}), do: "<"
  def show(%Choice{name: :right}), do: ">"

  def guess_to_map(guess_mapset) do
    guess_list = MapSet.to_list(guess_mapset)

    %{
      shape: Enum.find(guess_list, &(&1.kind == :shape)).name,
      colour: Enum.find(guess_list, &(&1.kind == :colour)).name,
      pattern: Enum.find(guess_list, &(&1.kind == :pattern)).name,
      direction: Enum.find(guess_list, &(&1.kind == :direction)).name
    }
  end
end
