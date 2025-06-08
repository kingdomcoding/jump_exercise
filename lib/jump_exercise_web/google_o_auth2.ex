defmodule JumpExerciseWeb.GoogleOAuth2 do
  alias HTTPoison.Response

  # TODO: Log more information about the request and response

  @google_token_url "https://accounts.google.com/o/oauth2/token"
  @google_user_info_url "https://www.googleapis.com/oauth2/v1/userinfo"

  def exchange_code_for_tokens(code) do
    params = %{
      "code" => code,
      "client_id" => System.get_env("GOOGLE_CLIENT_ID"),
      "client_secret" => System.get_env("GOOGLE_CLIENT_SECRET"),
      "redirect_uri" => System.get_env("GOOGLE_REDIRECT_URI"),
      "grant_type" => "authorization_code"
    }

    case HTTPoison.post(@google_token_url, URI.encode_query(params), headers()) do
      {:ok, %Response{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %Response{status_code: status_code, body: body}} when status_code != 200 ->
        {:error, "Failed to exchange code for tokens: #{body}"}

      {:error, reason} ->
        {:error, "Request failed: #{inspect(reason)}"}
    end
  end

  defp headers do
    [{"Content-Type", "application/x-www-form-urlencoded"}]
  end

  def fetch_user_info(oauth_tokens) do
    access_token = oauth_tokens["access_token"]

    case HTTPoison.get(@google_user_info_url, headers(access_token)) do
      {:ok, %Response{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %Response{status_code: status_code, body: body}} when status_code != 200 ->
        {:error, "Failed to fetch user info: #{body}"}

      {:error, reason} ->
        {:error, "Request failed: #{inspect(reason)}"}
    end
    |> dbg()
  end

  defp headers(access_token) do
    [{"Authorization", "Bearer #{access_token}"}]
  end
end
