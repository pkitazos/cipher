# Phoenix Concepts

## LiveView Templates

### Inline vs External Templates

You can define templates in two ways:

**Inline** - using `render/1` with the `~H` sigil:
```elixir
def render(assigns) do
  ~H"""
  <div>Hello {@name}</div>
  """
end
```

**External file** - create a `.html.heex` file next to your LiveView:
```
lib/cipher_web/live/game_live.ex
lib/cipher_web/live/game_live.html.heex
```

When using an external file, remove the `render/1` function entirely. Phoenix finds it automatically by naming convention.

### Accessing Helper Functions in Templates

Any function defined in your LiveView module (public or private) is accessible in the template:

```elixir
# In game_live.ex
defp difficulty_class(current, target) do
  if current == target, do: "bg-green-700", else: "bg-zinc-700"
end
```

```heex
<%!-- In game_live.html.heex --%>
<.button class={["w-24", difficulty_class(@difficulty, :easy)]}>
  easy
</.button>
```

---

## Flash Messages

Flash messages are temporary notifications displayed to users after an action. They persist across a single redirect and then disappear automatically.

They're the server-side mechanism for toasts.

### Common use cases

- Success confirmations: "Game created successfully"
- Error notifications: "Invalid guess"
- Warnings: "Game will expire in 5 minutes"

### How to use in LiveView

Setting a flash message:

```elixir
def handle_event("start_game", _params, socket) do
  # ... create game logic ...
  {:noreply, socket |> put_flash(:info, "Game started!")}
end
```

Flash types:
- `:info` - general information (often styled blue/green)
- `:error` - error messages (often styled red)

### Rendering flash messages

In your layout or template:

```heex
<div :if={@flash[:info]} class="text-green-600">
  {@flash[:info]}
</div>
<div :if={@flash[:error]} class="text-red-600">
  {@flash[:error]}
</div>
```

Or use Phoenix's built-in `<.flash>` component if defined in CoreComponents.

---

## Security Headers

Security headers are HTTP response headers that instruct browsers to enable certain security protections. Phoenix adds these via the `:put_secure_browser_headers` plug in the router pipeline.

### Headers added by default

| Header                   | Value           | Purpose                                                                                      |
| ------------------------ | --------------- | -------------------------------------------------------------------------------------------- |
| `x-frame-options`        | `SAMEORIGIN`    | Prevents your site from being embedded in iframes on other domains (clickjacking protection) |
| `x-content-type-options` | `nosniff`       | Stops browsers from guessing content types, preventing MIME sniffing attacks                 |
| `x-xss-protection`       | `1; mode=block` | Enables browser's built-in XSS (cross-site scripting) filter                                 |

### Why they matter

These headers defend against common web attacks:

**Clickjacking**: An attacker embeds your site in an invisible iframe and tricks users into clicking hidden buttons. `x-frame-options: SAMEORIGIN` prevents this by blocking cross-origin iframe embedding.

**MIME sniffing**: Browsers sometimes ignore the `Content-Type` header and guess based on content. An attacker could upload a file that looks like HTML to execute scripts. `x-content-type-options: nosniff` forces browsers to trust the declared content type.

**XSS (Cross-Site Scripting)**: Malicious scripts injected into pages. While proper output encoding is the primary defense, `x-xss-protection` adds a browser-level backup filter.

### Customizing headers

You can add additional headers:

```elixir
plug :put_secure_browser_headers, %{"content-security-policy" => "default-src 'self'"}
```
