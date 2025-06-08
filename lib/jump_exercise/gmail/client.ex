defmodule JumpExercise.Gmail.Client do
  use Ash.Resource,
    otp_app: :jump_exercise,
    domain: JumpExercise.Gmail

  actions do
    action :send_email, :map do

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
end
