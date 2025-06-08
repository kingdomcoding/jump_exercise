defmodule JumpExercise.Accounts.Secrets do
  use AshAuthentication.Secret

  # TODO: Add signing_secret

  def secret_for(
        [:authentication, :strategies, :google, :client_id],
        JumpExercise.Accounts.User,
        _opts,
        _context
      ),
      do: {:ok, System.get_env("GOOGLE_CLIENT_ID")}

  def secret_for(
        [:authentication, :strategies, :google, :redirect_uri],
        JumpExercise.Accounts.User,
        _opts,
        _context
      ),
      do: {:ok, System.get_env("GOOGLE_REDIRECT_URI")}

  def secret_for(
        [:authentication, :strategies, :google, :client_secret],
        JumpExercise.Accounts.User,
        _opts,
        _context
      ),
      do: {:ok, System.get_env("GOOGLE_CLIENT_SECRET")}

  def secret_for(
        [:authentication, :strategies, :google, :user_url],
        JumpExercise.Accounts.User,
        _opts,
        _context
      ),
      do: {:ok, System.get_env("GOOGLE_USER_URL")}

  def secret_for(
        [:authentication, :strategies, :google, :token_url],
        JumpExercise.Accounts.User,
        _opts,
        _context
      ),
      do: {:ok, System.get_env("GOOGLE_TOKEN_URL")}

  def secret_for(
        [:authentication, :strategies, :google, :authorize_url],
        JumpExercise.Accounts.User,
        _opts,
        _context
      ),
      do: {:ok, System.get_env("GOOGLE_AUTHORIZE_URL")}

  def secret_for(
        [:authentication, :strategies, :google, :base_url],
        JumpExercise.Accounts.User,
        _opts,
        _context
      ),
      do: {:ok, System.get_env("GOOGLE_BASE_URL")}
end
