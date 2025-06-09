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
    tool :get_emails, JumpExercise.Gmail.Email, :read
    tool :get_email, JumpExercise.Gmail.Email, :get
  end
end
