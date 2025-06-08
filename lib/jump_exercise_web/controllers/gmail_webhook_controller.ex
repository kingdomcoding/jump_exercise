defmodule JumpExerciseWeb.GmailWebhookController do
  use JumpExerciseWeb, :controller

  # Google will POST notifications here
  def notify(conn, %{"message" => message}) do
    # Decode the Pub/Sub message data (base64-encoded)
    with {:ok, decoded} <- Base.decode64(message["data"]),
         {:ok, data} <- Jason.decode(decoded) do
      user_email = data["emailAddress"]
      history_id = data["historyId"]

      if user_email && history_id do
        # Find user by email (replace with your actual user lookup)
        user = JumpExercise.Accounts.get_user_by_email(user_email)

        if user do
          emails = JumpExercise.Gmail.GmailApi.fetch_new_emails(user, history_id)
          IO.inspect(emails, label: "Fetched new emails")
        end
      end
    end

    send_resp(conn, 200, "ok")
  end

  # Google will GET this endpoint to verify it
  def notify(conn, _params) do
    send_resp(conn, 200, "ok")
  end
end
