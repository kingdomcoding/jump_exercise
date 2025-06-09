defmodule JumpExercise.Gmail.Client do
  use Ash.Resource,
    otp_app: :jump_exercise,
    domain: JumpExercise.Gmail,
    data_layer: Ash.DataLayer.Ets
    # TODO: Use a more persistent data layer like AshPostgres

  attributes do
    uuid_primary_key :id
    attribute :last_fetched_history_id, :string, allow_nil?: true
  end

  relationships do
    belongs_to :user, JumpExercise.Accounts.User, allow_nil?: false
  end

  actions do
    defaults [:read, :destroy, create: :*]
    default_accept [:last_fetched_history_id]

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

    action :update_email_records, {:array, :map} do
      run fn _, %{actor: user} ->
        result =
          case Ash.load(user, :client) do
            {:ok, %{client: %{last_fetched_history_id: nil}}} ->
              JumpExercise.Gmail.GmailApi.fetch_historical_emails(user)
            {:ok, %{client: %{last_fetched_history_id: _last_fetched_history_id}}} ->
              JumpExercise.Gmail.GmailApi.fetch_new_emails(user)
          end

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
                raw: email.raw
              }, actor: user)
            end)
          {:ok, emails}
        end
      end
    end

    # action :list_emails, {:array, :map} do

    # end

    # action :get_email, :map do
    #   argument :email_id, :string, allow_nil?: false

    #   run fn %{email_id: email_id}, _ ->
    #     case JumpExercise.Gmail.GmailApi.get_email(email_id) do
    #       {:ok, email} -> {:ok, email}
    #       {:error, reason} -> {:error, reason}
    #     end
    #   end
    # end

    # action :modify_labels, :map do

    # end

    # action :delete_email, :map do

    # end
  end

  code_interface do
    define :update
    define :send_email, args: [:to, :subject, :body]
    define :update_email_records
  end

end
