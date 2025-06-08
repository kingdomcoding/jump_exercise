defmodule JumpExerciseWeb.GmailController do
  use JumpExerciseWeb, :controller

  def fetch_gmail_emails(conn, _params) do
    access_token = get_access_token_for_user(conn)

    headers = [
      {"Authorization", "Bearer #{access_token}"},
      {"Accept", "application/json"}
    ]

    {:ok, %HTTPoison.Response{body: body, status_code: 200}} =
      HTTPoison.get("https://gmail.googleapis.com/gmail/v1/users/me/messages", headers)

    messages = Jason.decode!(body)["messages"] || []

    emails =
      Enum.map(messages |> Enum.take(1), fn %{"id" => id} ->
        {:ok, %HTTPoison.Response{body: msg_body, status_code: 200}} =
          HTTPoison.get(
            "https://gmail.googleapis.com/gmail/v1/users/me/messages/#{id}?format=full",
            headers
          )

        email = Jason.decode!(msg_body)
        decoded_email = decode_email_parts(email)

        %{
          thread_id: email["threadId"],
          from: get_header(decoded_email, "From"),
          to: get_header(decoded_email, "To"),
          subject: get_header(decoded_email, "Subject"),
          body: extract_body(decoded_email),
          labels: email["labelIds"] || [],
          snippet: email["snippet"] || "",
          raw: Jason.encode!(email)
        }
      end)

    json(conn, emails)
  end

  defp get_header(%{"payload" => %{"headers" => headers}}, name) do
    headers
    |> Enum.find(fn %{"name" => n} -> n == name end)
    |> case do
      %{"value" => value} -> value
      _ -> nil
    end
  end

  defp extract_body(%{"payload" => payload}) do
    extract_body_from_payload(payload)
  end

  defp extract_body_from_payload(%{"mimeType" => "text/plain", "body" => %{"data" => data}})
       when is_binary(data) do
    data
    |> String.replace("-", "+")
    |> String.replace("_", "/")
    |> Base.decode64!(ignore: :whitespace)
  end

  defp extract_body_from_payload(%{"parts" => parts}) when is_list(parts) do
    # Prefer text/plain, fallback to text/html
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

  defp decode_email_parts(%{"payload" => payload} = email) do
    Map.put(email, "payload", decode_payload(payload))
  end

  defp decode_email_parts(email), do: email

  defp decode_payload(%{"parts" => parts} = payload) do
    parts = Enum.map(parts, &decode_payload/1)

    payload
    |> decode_body_data()
    |> Map.put("parts", parts)
  end

  defp decode_payload(payload) do
    decode_body_data(payload)
  end

  defp decode_body_data(%{"body" => %{"data" => data} = body} = payload) do
    decoded =
      data
      |> String.replace("-", "+")
      |> String.replace("_", "/")
      |> Base.decode64!(ignore: :whitespace)

    body = Map.put(body, "data", decoded)
    Map.put(payload, "body", body)
  end

  defp decode_body_data(payload), do: payload

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
