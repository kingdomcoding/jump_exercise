defmodule JumpExerciseWeb.GmailController do
  use JumpExerciseWeb, :controller

  def send_email(conn, _params) do
    case JumpExercise.Gmail.Client.send_email("demo@example.com", "Subject", "Body", actor: conn.assigns[:current_user]) do
      {:ok, result} ->
        json(conn, %{status: "sent", result: result})

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{status: "error", reason: reason})
    end
  end

  def update_email_records(conn, _params) do
    case JumpExercise.Gmail.Client.update_email_records(actor: conn.assigns[:current_user]) do
      {:ok, emails} ->
        json(conn, %{status: "updated", emails: emails})

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{status: "error", reason: reason})
    end
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
