import Config

# Force using SSL in production. This also sets the "strict-security-transport" header,
# known as HSTS. If you have a health check endpoint, you may want to exclude it below.
# Note `:force_ssl` is required to be set at compile-time.
# We're disabling force_ssl, because we know our app sits behind a proxy anyway
# Ideally we just tell our proxy to include the `:x_forwarded_proto` header,
# but not sure how to do that yet
# config :cipher, CipherWeb.Endpoint,
#   force_ssl: [rewrite_on: [:x_forwarded_proto]],
#   exclude: [
#     # paths: ["/health"],
#     hosts: ["localhost", "127.0.0.1"]
#   ]

# Do not print debug messages in production
config :logger, level: :info

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
