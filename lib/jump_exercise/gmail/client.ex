defmodule JumpExercise.Gmail.Client do
  use Ash.Resource,
    otp_app: :jump_exercise,
    domain: JumpExercise.Gmail,
    data_layer: Ash.DataLayer.Ets
    # TODO: Use a more persistent data layer like AshPostgres

  attributes do
    uuid_primary_key :id
    attribute :history_id, :string, allow_nil?: true
  end

  relationships do
    belongs_to :user, JumpExercise.Accounts.User
  end

  actions do
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

    action :fetch_new_emails, :map do
      run fn _, %{actor: user} ->
        case JumpExercise.Gmail.GmailApi.fetch_new_emails(user) do
          {:ok, emails} -> {:ok, emails}
          {:error, reason} -> {:error, reason}
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
    define :send_email, args: [:to, :subject, :body]
    define :fetch_new_emails
  end

end
