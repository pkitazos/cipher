defmodule Cipher.Game.Choice do
  alias Cipher.Game.Choice

  defstruct [:kind, :name]

  # Canonical ordering for choices
  @kind_order [:shape, :colour, :pattern, :direction]
  @shape_order [:circle, :square, :star, :triangle]
  @colour_order [:red, :green, :blue, :yellow]
  @pattern_order [:vertical_stripes, :horizontal_stripes, :checkered, :dotted]
  @direction_order [:top, :bottom, :left, :right]

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

  def compare(%Choice{kind: kind1} = c1, %Choice{kind: kind2} = c2) do
    cond do
      kind1 != kind2 -> compare_kinds(kind1, kind2)
      true -> compare_names(kind1, c1.name, c2.name)
    end
  end

  defp compare_kinds(k1, k2) do
    pos1 = Enum.find_index(@kind_order, &(&1 == k1))
    pos2 = Enum.find_index(@kind_order, &(&1 == k2))
    pos1 <= pos2
  end

  defp compare_names(:shape, n1, n2), do: compare_in_list(@shape_order, n1, n2)
  defp compare_names(:colour, n1, n2), do: compare_in_list(@colour_order, n1, n2)
  defp compare_names(:pattern, n1, n2), do: compare_in_list(@pattern_order, n1, n2)
  defp compare_names(:direction, n1, n2), do: compare_in_list(@direction_order, n1, n2)

  defp compare_in_list(list, n1, n2) do
    pos1 = Enum.find_index(list, &(&1 == n1))
    pos2 = Enum.find_index(list, &(&1 == n2))
    pos1 <= pos2
  end
end

defimpl Inspect, for: Cipher.Game.Choice do
  alias Cipher.Game.Choice

  def inspect(choice, _opts) do
    symbol = Choice.show(choice)
    "#Choice<#{choice.kind}:#{choice.name} \"#{symbol}\">"
  end
end
