defmodule JumpExercise.GmailApi do
  def list_emails(user, _params) do
    access_token = get_access_token_for_user(user)

    headers = [
      {"Authorization", "Bearer #{access_token}"},
      {"Accept", "application/json"}
    ]

    {:ok, %HTTPoison.Response{body: body, status_code: 200}} =
      HTTPoison.get("https://gmail.googleapis.com/gmail/v1/users/me/messages", headers)

    messages = Jason.decode!(body)["messages"] || []

    Enum.map(messages |> Enum.take(5), fn %{"id" => id} ->
      {:ok, %HTTPoison.Response{body: msg_body, status_code: 200}} =
        HTTPoison.get("https://gmail.googleapis.com/gmail/v1/users/me/messages/#{id}", headers)

      Jason.decode!(msg_body)
    end)
  end

  def get_email(user, id) do
    access_token = get_access_token_for_user(user)

    headers = [
      {"Authorization", "Bearer #{access_token}"},
      {"Accept", "application/json"}
    ]

    url = "https://gmail.googleapis.com/gmail/v1/users/me/messages/#{id}"

    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        {:ok, Jason.decode!(body)}

      error ->
        error
    end
  end

  def create_email(user, email_params) do
    access_token = get_access_token_for_user(user)

    headers = [
      {"Authorization", "Bearer #{access_token}"},
      {"Content-Type", "application/json"}
    ]

    url = "https://gmail.googleapis.com/gmail/v1/users/me/messages/send"
    body = Jason.encode!(email_params)

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        {:ok, Jason.decode!(body)}

      error ->
        error
    end
  end

  def update_email_labels(user, id, label_ids) do
    access_token = get_access_token_for_user(user)

    headers = [
      {"Authorization", "Bearer #{access_token}"},
      {"Content-Type", "application/json"}
    ]

    url = "https://gmail.googleapis.com/gmail/v1/users/me/messages/#{id}/modify"
    body = Jason.encode!(%{addLabelIds: label_ids})

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        {:ok, Jason.decode!(body)}

      error ->
        error
    end
  end

  def delete_email(user, id) do
    access_token = get_access_token_for_user(user)

    headers = [
      {"Authorization", "Bearer #{access_token}"},
      {"Accept", "application/json"}
    ]

    url = "https://gmail.googleapis.com/gmail/v1/users/me/messages/#{id}"

    case HTTPoison.delete(url, headers) do
      {:ok, %HTTPoison.Response{status_code: 204}} ->
        :ok

      error ->
        error
    end
  end

  defp get_access_token_for_user(nil), do: nil

  defp get_access_token_for_user(user) do
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
