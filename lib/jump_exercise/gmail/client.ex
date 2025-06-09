defmodule JumpExercise.Gmail.Client do
  use Ash.Resource,
    otp_app: :jump_exercise,
    domain: JumpExercise.Gmail,
    data_layer: AshPostgres.DataLayer

  attributes do
    uuid_primary_key :id
    attribute :last_fetched_history_id, :string, allow_nil?: true
  end

  relationships do
    belongs_to :user, JumpExercise.Accounts.User, allow_nil?: false
  end

  actions do
    defaults [:read, :destroy]
    default_accept [:last_fetched_history_id]

    create :create do
      primary? true
      accept [:last_fetched_history_id]

      change fn changeset, context ->
        Ash.Changeset.manage_relationship(changeset, :user, context.actor, type: :append)
      end
    end

    update :update do
      primary? true
      accept [:last_fetched_history_id]
    end

    action :send_email, :map do
      argument :to, :string, allow_nil?: false
      argument :subject, :string, allow_nil?: false
      argument :body, :string, allow_nil?: false

      run fn input, %{actor: user} ->
        case JumpExercise.Gmail.GmailApi.send_email(user, input.arguments.to, input.arguments.subject, input.arguments.body) do
          {:ok, result} -> {:ok, result}
          {:error, reason} -> {:error, reason}
        end
      end
    end

    action :fetch_emails, {:array, :map} do
      description """
      Fetches emails from the Gmail API for the given user and stores them in the database.
      If this is the user's first fetch (no last_fetched_history_id), it retrieves historical emails.
      Otherwise, it fetches only new emails since the last fetched history ID.
      Each fetched email is persisted as a JumpExercise.Gmail.Email record.
      Returns the list of fetched emails.
      """

      run fn _, %{actor: user} ->
        result =
          case Ash.load(user, :client) do
          {:ok, %{client: %{last_fetched_history_id: nil}}} ->
            JumpExercise.Gmail.GmailApi.fetch_historical_emails(user)
          {:ok, %{client: %{last_fetched_history_id: _last_fetched_history_id}}} ->
            JumpExercise.Gmail.GmailApi.fetch_new_emails(user)
          end

        dbg(user)
        with {:ok, emails} <- result do
          :ok =
          Enum.each(emails, fn email ->
            JumpExercise.Gmail.Email.create!(%{
            thread_id: email.thread_id,
            from: email.from,
            to: email.to,
            subject: email.subject,
            body: email.body,
            labels: email.labels,
            snippet: email.snippet,
            raw: email.raw,
            user: user
            })
          end)
          {:ok, emails}
        end
      end
    end
  end

  code_interface do
    define :create
    define :update
    define :send_email, args: [:to, :subject, :body]
    define :fetch_emails
  end

  postgres do
    table "gmail_clients"
    repo JumpExercise.Repo
  end
end
