ExUnit.start()

File.ls!("test/support")
|> Enum.filter(fn file -> String.ends_with?(file, ".ex") end)
|> Enum.map(fn file -> Code.require_file("test/support/#{file}") end)

Ecto.Adapters.SQL.Sandbox.mode(Cipher.Repo, :manual)
