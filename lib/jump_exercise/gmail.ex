defmodule JumpExercise.Gmail do
  use Ash.Domain,
    otp_app: :jump_exercise,
    extensions: [AshAi]

  resources do
    resource(JumpExercise.Gmail.Email)
  end

  tools do
    tool :send_email, JumpExercise.Gmail.Email, :send_email
    tool :list_emails, JumpExercise.Gmail.Email, :list_emails
    tool :get_email, JumpExercise.Gmail.Email, :get_email
    tool :modify_labels, JumpExercise.Gmail.Email, :modify_labels
    tool :delete_email, JumpExercise.Gmail.Email, :delete_email
  end
end
