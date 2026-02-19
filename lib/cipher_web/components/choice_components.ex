defmodule CipherWeb.ChoiceComponents do
  use Phoenix.Component
  alias Cipher.Games.Choice

  attr :choice, Choice, required: true

  def icon(%{choice: %Choice{kind: :colour, name: name}} = assigns) do
    assigns = assign(assigns, :colour, name)
    swatch(assigns)
  end

  def icon(%{choice: %Choice{kind: :size, name: name}} = assigns) do
    assigns = assign(assigns, :size, name)
    size(assigns)
  end

  def icon(%{choice: %Choice{name: :square}} = assigns), do: square(assigns)
  def icon(%{choice: %Choice{name: :circle}} = assigns), do: circle(assigns)
  def icon(%{choice: %Choice{name: :triangle}} = assigns), do: triangle(assigns)
  def icon(%{choice: %Choice{name: :star}} = assigns), do: star(assigns)
  def icon(%{choice: %Choice{name: :vertical_stripes}} = assigns), do: vertical_stripes(assigns)

  def icon(%{choice: %Choice{name: :horizontal_stripes}} = assigns),
    do: horizontal_stripes(assigns)

  def icon(%{choice: %Choice{name: :checkered}} = assigns), do: checkered(assigns)
  def icon(%{choice: %Choice{name: :dotted}} = assigns), do: dotted(assigns)
  def icon(%{choice: %Choice{name: :top}} = assigns), do: top(assigns)
  def icon(%{choice: %Choice{name: :bottom}} = assigns), do: bottom(assigns)
  def icon(%{choice: %Choice{name: :left}} = assigns), do: left(assigns)
  def icon(%{choice: %Choice{name: :right}} = assigns), do: right(assigns)

  # shape
  defp square(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
      class="size-6"
    >
      <rect width="18" height="18" x="3" y="3" rx="2" />
    </svg>
    """
  end

  defp circle(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
      class="size-6"
    >
      <circle cx="12" cy="12" r="10" />
    </svg>
    """
  end

  defp triangle(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
      class="size-6"
    >
      <path d="M13.73 4a2 2 0 0 0-3.46 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z" />
    </svg>
    """
  end

  defp star(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
      class="size-6"
    >
      <path d="M11.525 2.295a.53.53 0 0 1 .95 0l2.31 4.679a2.123 2.123 0 0 0 1.595 1.16l5.166.756a.53.53 0 0 1 .294.904l-3.736 3.638a2.123 2.123 0 0 0-.611 1.878l.882 5.14a.53.53 0 0 1-.771.56l-4.618-2.428a2.122 2.122 0 0 0-1.973 0L6.396 21.01a.53.53 0 0 1-.77-.56l.881-5.139a2.122 2.122 0 0 0-.611-1.879L2.16 9.795a.53.53 0 0 1 .294-.906l5.165-.755a2.122 2.122 0 0 0 1.597-1.16z" />
    </svg>
    """
  end

  # colour
  attr :colour, :atom, required: true
  # :red | :green | :blue | :yellow

  defp swatch(assigns) do
    ~H"""
    <svg
      style={"fill: var(--choice-#{@colour}-stroke);"}
      viewBox="0 0 24 24"
      fill="currentColor"
      class="rounded-md size-6"
    >
      <rect width="24" height="24" rx="4" />
    </svg>
    """
  end

  # pattern
  defp vertical_stripes(assigns) do
    ~H"""
    <svg
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      className="text-foreground"
    >
      <rect x="4" y="2" width="4" height="20" fill="currentColor" />
      <rect x="10" y="2" width="4" height="20" fill="currentColor" />
      <rect x="16" y="2" width="4" height="20" fill="currentColor" />
    </svg>
    """
  end

  defp horizontal_stripes(assigns) do
    ~H"""
    <svg
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      className="text-foreground"
    >
      <rect x="2" y="4" width="20" height="4" fill="currentColor" />
      <rect x="2" y="10" width="20" height="4" fill="currentColor" />
      <rect x="2" y="16" width="20" height="4" fill="currentColor" />
    </svg>
    """
  end

  defp checkered(assigns) do
    ~H"""
    <svg
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      className="text-foreground"
    >
      <rect x="2" y="2" width="9" height="9" fill="currentColor" />
      <rect x="13" y="2" width="9" height="9" fill="currentColor" />
      <rect x="2" y="13" width="9" height="9" fill="currentColor" />
      <rect x="13" y="13" width="9" height="9" fill="currentColor" />
    </svg>
    """
  end

  defp dotted(assigns) do
    ~H"""
    <svg
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      className="text-foreground"
    >
      <circle cx="6" cy="6" r="2" fill="currentColor" />
      <circle cx="12" cy="6" r="2" fill="currentColor" />
      <circle cx="18" cy="6" r="2" fill="currentColor" />
      <circle cx="6" cy="12" r="2" fill="currentColor" />
      <circle cx="12" cy="12" r="2" fill="currentColor" />
      <circle cx="18" cy="12" r="2" fill="currentColor" />
      <circle cx="6" cy="18" r="2" fill="currentColor" />
      <circle cx="12" cy="18" r="2" fill="currentColor" />
      <circle cx="18" cy="18" r="2" fill="currentColor" />
    </svg>
    """
  end

  # direction
  defp top(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
      class="size-6"
    >
      <path d="M5 3h14" /><path d="m18 13-6-6-6 6" /><path d="M12 7v14" />
    </svg>
    """
  end

  defp bottom(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
      class="size-6"
    >
      <path d="M12 17V3" /><path d="m6 11 6 6 6-6" /><path d="M19 21H5" />
    </svg>
    """
  end

  defp left(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
      class="size-6"
    >
      <path d="M3 19V5" /><path d="m13 6-6 6 6 6" /><path d="M7 12h14" />
    </svg>
    """
  end

  defp right(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
      class="size-6"
    >
      <path d="M17 12H3" /><path d="m11 18 6-6-6-6" /><path d="M21 5v14" />
    </svg>
    """
  end

  # size
  attr :size, :atom, required: true

  defp size(assigns) do
    size =
      case assigns.size do
        :tiny -> "size-2"
        :small -> "size-3"
        :medium -> "size-4"
        :large -> "size-5"
      end

    assigns = assign(assigns, :size, size)

    ~H"""
    <svg
      class={["bg-foreground", @size]}
      viewBox="0 0 24 24"
      fill="currentColor"
    >
      <circle cx="12" cy="12" r="12" />
    </svg>
    """
  end

  # defp tiny(assigns) do
  #   ~H"""
  #   <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  #     <path
  #       d="M8 10.5V10C8 9.46957 8.21071 8.96086 8.58579 8.58579C8.96086 8.21071 9.46957 8 10 8H10.5"
  #       stroke="black"
  #       stroke-width="1.5"
  #       stroke-linecap="round"
  #       stroke-linejoin="round"
  #     />
  #     <path
  #       d="M13.5 8H14C14.5304 8 15.0391 8.21071 15.4142 8.58579C15.7893 8.96086 16 9.46957 16 10V10.5"
  #       stroke="black"
  #       stroke-width="1.5"
  #       stroke-linecap="round"
  #       stroke-linejoin="round"
  #     />
  #     <path
  #       d="M16 13.5V14C16 14.5304 15.7893 15.0391 15.4142 15.4142C15.0391 15.7893 14.5304 16 14 16H13.5"
  #       stroke="black"
  #       stroke-width="1.5"
  #       stroke-linecap="round"
  #       stroke-linejoin="round"
  #     />
  #     <path
  #       d="M10.5 16H10C9.46957 16 8.96086 15.7893 8.58579 15.4142C8.21071 15.0391 8 14.5304 8 14V13.5"
  #       stroke="black"
  #       stroke-width="1.5"
  #       stroke-linecap="round"
  #       stroke-linejoin="round"
  #     />
  #   </svg>
  #   """
  # end

  # defp small(assigns) do
  #   ~H"""
  #   <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  #     <path
  #       d="M6 9V8C6 7.46957 6.21071 6.96086 6.58579 6.58579C6.96086 6.21071 7.46957 6 8 6H9"
  #       stroke="black"
  #       stroke-width="2"
  #       stroke-linecap="round"
  #       stroke-linejoin="round"
  #     />
  #     <path
  #       d="M15 6H16C16.5304 6 17.0391 6.21071 17.4142 6.58579C17.7893 6.96086 18 7.46957 18 8V9"
  #       stroke="black"
  #       stroke-width="2"
  #       stroke-linecap="round"
  #       stroke-linejoin="round"
  #     />
  #     <path
  #       d="M18 15V16C18 16.5304 17.7893 17.0391 17.4142 17.4142C17.0391 17.7893 16.5304 18 16 18H15"
  #       stroke="black"
  #       stroke-width="2"
  #       stroke-linecap="round"
  #       stroke-linejoin="round"
  #     />
  #     <path
  #       d="M9 18H8C7.46957 18 6.96086 17.7893 6.58579 17.4142C6.21071 17.0391 6 16.5304 6 16V15"
  #       stroke="black"
  #       stroke-width="2"
  #       stroke-linecap="round"
  #       stroke-linejoin="round"
  #     />
  #   </svg>
  #   """
  # end

  # defp medium(assigns) do
  #   ~H"""
  #   <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  #     <path
  #       d="M3 8V5C3 4.46957 3.21071 3.96086 3.58579 3.58579C3.96086 3.21071 4.46957 3 5 3H8"
  #       stroke="black"
  #       stroke-width="2.1"
  #       stroke-linecap="round"
  #       stroke-linejoin="round"
  #     />
  #     <path
  #       d="M16 3H19C19.5304 3 20.0391 3.21071 20.4142 3.58579C20.7893 3.96086 21 4.46957 21 5V8"
  #       stroke="black"
  #       stroke-width="2.1"
  #       stroke-linecap="round"
  #       stroke-linejoin="round"
  #     />
  #     <path
  #       d="M21 16V19C21 19.5304 20.7893 20.0391 20.4142 20.4142C20.0391 20.7893 19.5304 21 19 21H16"
  #       stroke="black"
  #       stroke-width="2.1"
  #       stroke-linecap="round"
  #       stroke-linejoin="round"
  #     />
  #     <path
  #       d="M8 21H5C4.46957 21 3.96086 20.7893 3.58579 20.4142C3.21071 20.0391 3 19.5304 3 19V16"
  #       stroke="black"
  #       stroke-width="2.1"
  #       stroke-linecap="round"
  #       stroke-linejoin="round"
  #     />
  #   </svg>
  #   """
  # end

  # defp large(assigns) do
  #   ~H"""
  #   <svg
  #     width="24"
  #     height="24"
  #     viewBox="0 0 24 24"
  #     fill="none"
  #     xmlns="http://www.w3.org/2000/svg"
  #   >
  #     <path
  #       d="M8 23L3 23C2.46957 23 1.96086 22.7893 1.58579 22.4142C1.21071 22.0391 1 21.5304 1 21L1 16"
  #       stroke="black"
  #       stroke-width="2"
  #       stroke-linecap="round"
  #       stroke-linejoin="round"
  #     />
  #     <path
  #       d="M1 8V3C1 2.46957 1.21071 1.96086 1.58579 1.58579C1.96086 1.21071 2.46957 1 3 1H8"
  #       stroke="black"
  #       stroke-width="2"
  #       stroke-linecap="round"
  #       stroke-linejoin="round"
  #     />
  #     <path
  #       d="M16 1H21C21.5304 1 22.0391 1.21071 22.4142 1.58579C22.7893 1.96086 23 2.46957 23 3V8"
  #       stroke="black"
  #       stroke-width="2"
  #       stroke-linecap="round"
  #       stroke-linejoin="round"
  #     />
  #     <path
  #       d="M23 16V21C23 21.5305 22.7893 22.0392 22.4142 22.4142C22.0391 22.7893 21.5304 23 21 23H16"
  #       stroke="black"
  #       stroke-width="2"
  #       stroke-linecap="round"
  #       stroke-linejoin="round"
  #     />
  #   </svg>
  #   """
  # end
end
