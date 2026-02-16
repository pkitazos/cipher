import Config

config :cipher, CipherWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "Z3qmA3t2l72fltt5Ijl7mwrfmO4LAyWinc2OyjB4yVNIrViC+USMUzmB92iWytN/",
  watchers: []

config :cipher, Cipher.Repo,
  username: "cipher",
  password: "cipher",
  hostname: "localhost",
  database: "cipher_sandbox",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10,
  log: false

config :logger, :default_formatter, format: "[$level] $message\n"
config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime
