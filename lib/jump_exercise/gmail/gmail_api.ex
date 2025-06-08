defmodule JumpExercise.Gmail.GmailApi do
  def send_email(user, to, subject, body) do
    access_token = get_access_token_for_user(user)

    headers = [
      {"Authorization", "Bearer #{access_token}"},
      {"Content-Type", "application/json"}
    ]

    from = get_header_from_user(user) || "me"

    raw_message =
      """
      From: #{from}
      To: #{to}
      Subject: #{subject}
      Content-Type: text/plain; charset="UTF-8"

      #{body}
      """
      |> :erlang.iolist_to_binary()
      |> Base.encode64()

    payload = Jason.encode!(%{raw: raw_message})

    url = "https://gmail.googleapis.com/gmail/v1/users/me/messages/send"

    case HTTPoison.post(url, payload, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: resp_body}} ->
        {:ok, Jason.decode!(resp_body)}

      {:ok, %HTTPoison.Response{status_code: code, body: resp_body}} ->
        {:error, code, Jason.decode!(resp_body)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def list_emails(user, _params) do
    access_token = get_access_token_for_user(user)

    headers = [
      {"Authorization", "Bearer #{access_token}"},
      {"Accept", "application/json"}
    ]

    {:ok, %HTTPoison.Response{body: body, status_code: 200}} =
      HTTPoison.get("https://gmail.googleapis.com/gmail/v1/users/me/messages", headers)

    messages = Jason.decode!(body)["messages"] || []

    emails =
      Enum.map(messages, fn %{"id" => id} ->
        {:ok, %HTTPoison.Response{body: msg_body, status_code: 200}} =
          HTTPoison.get(
            "https://gmail.googleapis.com/gmail/v1/users/me/messages/#{id}?format=full",
            headers
          )

        email = Jason.decode!(msg_body)

        %{
          thread_id: email["threadId"],
          from: get_header(email, "From"),
          to: get_header(email, "To"),
          subject: get_header(email, "Subject"),
          body: extract_body(email),
          labels: email["labelIds"] || [],
          snippet: email["snippet"] || "",
          raw: Jason.encode!(email)
        }
      end)

    emails
  end

  def get_email(user, id) do
    access_token = get_access_token_for_user(user)

    headers = [
      {"Authorization", "Bearer #{access_token}"},
      {"Accept", "application/json"}
    ]

    {:ok, %HTTPoison.Response{body: msg_body, status_code: 200}} =
      HTTPoison.get(
        "https://gmail.googleapis.com/gmail/v1/users/me/messages/#{id}?format=full",
        headers
      )

    email = Jason.decode!(msg_body)

    %{
      thread_id: email["threadId"],
      from: get_header(email, "From"),
      to: get_header(email, "To"),
      subject: get_header(email, "Subject"),
      body: extract_body(email),
      labels: email["labelIds"] || [],
      snippet: email["snippet"] || "",
      raw: Jason.encode!(email)
    }
  end

  defp get_header(%{"payload" => %{"headers" => headers}}, name) do
    headers
    |> Enum.find(fn %{"name" => n} -> n == name end)
    |> case do
      %{"value" => value} -> value
      _ -> nil
    end
  end

  defp extract_body(%{"payload" => payload}), do: extract_body_from_payload(payload)
  defp extract_body(_), do: ""

  defp extract_body_from_payload(%{"mimeType" => "text/plain", "body" => %{"data" => data}})
       when is_binary(data) do
    data
    |> String.replace("-", "+")
    |> String.replace("_", "/")
    |> Base.decode64!(ignore: :whitespace)
  end

  defp extract_body_from_payload(%{"parts" => parts}) when is_list(parts) do
    plain =
      Enum.find(parts, fn part -> part["mimeType"] == "text/plain" end)
      |> case do
        nil -> nil
        part -> extract_body_from_payload(part)
      end

    if plain do
      plain
    else
      html =
        Enum.find(parts, fn part -> part["mimeType"] == "text/html" end)
        |> case do
          nil -> nil
          part -> extract_body_from_payload(part)
        end

      html || ""
    end
  end

  defp extract_body_from_payload(_), do: ""

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

  defp get_header_from_user(%{email: email}), do: email
  defp get_header_from_user(_), do: nil
end
