defmodule JumpExercise.Gmail do
  use Ash.Domain,
    otp_app: :jump_exercise,
    extensions: [AshAi]

  resources do
    resource(JumpExercise.Gmail.Email)
    resource(JumpExercise.Gmail.Client)
  end

  tools do
    tool :send_email, JumpExercise.Gmail.Client, :send_email
    # tool :list_emails, JumpExercise.Gmail.Client, :list_emails
    # tool :get_email, JumpExercise.Gmail.Client, :get_email
    # tool :modify_labels, JumpExercise.Gmail.Client, :modify_labels
    # tool :delete_email, JumpExercise.Gmail.Client, :delete_email
  end
end
