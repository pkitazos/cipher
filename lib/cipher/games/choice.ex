defmodule Cipher.Games.Choice do
  alias Cipher.Games.Choice

  @type kind :: :shape | :colour | :pattern | :direction | :size
  @type shape_name :: :circle | :square | :star | :triangle
  @type colour_name :: :red | :green | :blue | :yellow
  @type pattern_name :: :vertical_stripes | :horizontal_stripes | :checkered | :dotted
  @type direction_name :: :top | :bottom | :left | :right
  @type size_name :: :tiny | :small | :medium | :large
  @type name :: shape_name() | colour_name() | pattern_name() | direction_name() | size_name()

  @type t :: %__MODULE__{
          kind: kind(),
          name: name()
        }

  defstruct [:kind, :name]

  # Canonical ordering for choices
  @kind_order [:shape, :colour, :pattern, :direction, :size]
  @shape_order [:circle, :square, :star, :triangle]
  @colour_order [:red, :green, :blue, :yellow]
  @pattern_order [:vertical_stripes, :horizontal_stripes, :checkered, :dotted]
  @direction_order [:top, :bottom, :left, :right]
  @size_order [:tiny, :small, :medium, :large]

  @valid_kinds [:shape, :colour, :pattern, :direction, :size]
  @valid_names @shape_order ++ @colour_order ++ @pattern_order ++ @direction_order ++ @size_order

  def values do
    @shape_order ++ @colour_order ++ @pattern_order ++ @direction_order ++ @size_order
  end

  @spec options(kind()) :: [atom()]
  def options(:shape), do: @shape_order
  def options(:colour), do: @colour_order
  def options(:pattern), do: @pattern_order
  def options(:direction), do: @direction_order
  def options(:size), do: @size_order

  @spec from_name(atom()) :: t()
  def from_name(name) when name in @shape_order, do: %__MODULE__{kind: :shape, name: name}
  def from_name(name) when name in @colour_order, do: %__MODULE__{kind: :colour, name: name}
  def from_name(name) when name in @pattern_order, do: %__MODULE__{kind: :pattern, name: name}
  def from_name(name) when name in @direction_order, do: %__MODULE__{kind: :direction, name: name}
  def from_name(name) when name in @size_order, do: %__MODULE__{kind: :size, name: name}

  def from_name(name), do: raise("Unknown choice name: #{inspect(name)}")

  @doc """
  Safely converts a string kind (e.g. "colour") to its atom.
  """
  @spec kind_from_string(String.t()) :: {:ok, kind()} | :error

  for kind_atom <- @valid_kinds do
    kind_str = Atom.to_string(kind_atom)

    def kind_from_string(unquote(kind_str)), do: {:ok, unquote(kind_atom)}
  end

  def kind_from_string(_), do: :error

  @doc """
  Safely converts a string to a Choice struct.
  Generated at compile-time: No try/rescue, no atom exhaustion risk.
  """
  @spec from_string(String.t()) :: {:ok, t()} | :error

  # Freak compile-time function generation.
  # Loop through the list and generate a function head for each valid string.
  for atom_name <- @valid_names do
    str_name = Atom.to_string(atom_name)

    def from_string(unquote(str_name)) do
      {:ok, from_name(unquote(atom_name))}
    end
  end

  def from_string(_), do: :error

  @spec show(t()) :: String.t()
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
  def show(%Choice{name: :tiny}), do: "·"
  def show(%Choice{name: :small}), do: "•"
  def show(%Choice{name: :medium}), do: "●"
  def show(%Choice{name: :large}), do: "◉"

  @spec guess_to_map(MapSet.t(t())) :: %{kind() => name()}
  def guess_to_map(guess_mapset) do
    guess_mapset
    |> MapSet.to_list()
    |> Enum.map(fn choice -> {choice.kind, choice.name} end)
    |> Enum.into(%{})
  end

  @spec compare(t(), t()) :: boolean()
  def compare(%Choice{kind: kind1} = c1, %Choice{kind: kind2} = c2) do
    cond do
      kind1 != kind2 -> compare_kinds(kind1, kind2)
      true -> compare_names(kind1, c1.name, c2.name)
    end
  end

  @spec compare_kinds(kind(), kind()) :: boolean()
  defp compare_kinds(k1, k2) do
    pos1 = Enum.find_index(@kind_order, &(&1 == k1))
    pos2 = Enum.find_index(@kind_order, &(&1 == k2))
    pos1 <= pos2
  end

  @spec compare_names(kind(), name(), name()) :: boolean()
  defp compare_names(:shape, n1, n2), do: compare_in_list(@shape_order, n1, n2)
  defp compare_names(:colour, n1, n2), do: compare_in_list(@colour_order, n1, n2)
  defp compare_names(:pattern, n1, n2), do: compare_in_list(@pattern_order, n1, n2)
  defp compare_names(:direction, n1, n2), do: compare_in_list(@direction_order, n1, n2)
  defp compare_names(:size, n1, n2), do: compare_in_list(@size_order, n1, n2)

  @spec compare_in_list([atom()], atom(), atom()) :: boolean()
  defp compare_in_list(list, n1, n2) do
    pos1 = Enum.find_index(list, &(&1 == n1))
    pos2 = Enum.find_index(list, &(&1 == n2))
    pos1 <= pos2
  end
end

defimpl Inspect, for: Cipher.Games.Choice do
  alias Cipher.Games.Choice

  def inspect(choice, _opts) do
    symbol = Choice.show(choice)
    "#Choice<#{choice.kind}:#{choice.name} \"#{symbol}\">"
  end
end
