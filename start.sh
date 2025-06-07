# Setup database
mix ecto.setup

# Make server file executable
chmod a+x _build/prod/rel/jump_exercise/bin/server

# Start server
_build/prod/rel/jump_exercise/bin/server
