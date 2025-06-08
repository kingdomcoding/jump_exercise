defmodule JumpExerciseWeb.GmailController do
  use JumpExerciseWeb, :controller

  def fetch_gmail_emails(conn, _params) do
    # Implement this to retrieve the user's token
    access_token = get_access_token_for_user(conn)

    headers = [
      {"Authorization", "Bearer #{access_token}"},
      {"Accept", "application/json"}
    ]

    # List messages
    {:ok, %HTTPoison.Response{body: body, status_code: 200}} =
      HTTPoison.get("https://gmail.googleapis.com/gmail/v1/users/me/messages", headers)

    messages = Jason.decode!(body)["messages"] || []

    # Fetch the first email's details as an example
    emails =
      Enum.map(messages |> Enum.take(5), fn %{"id" => id} ->
        {:ok, %HTTPoison.Response{body: msg_body, status_code: 200}} =
          HTTPoison.get("https://gmail.googleapis.com/gmail/v1/users/me/messages/#{id}", headers)

        Jason.decode!(msg_body)
      end)

    json(conn, emails)

    # json(conn, %{})
  end

  defp get_access_token_for_user(conn) do
    case conn.assigns[:current_user] do
      nil ->
        nil

      user ->
        {:ok, user} = Ash.load(user, :identities)

        user
        |> then(fn %{identities: identities} ->
          identities
          |> Enum.find(fn identity -> identity.strategy == "google" end)
        end)
        |> then(fn identity ->
          identity && identity.access_token
        end)
    end
  end
end
