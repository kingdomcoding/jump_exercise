defmodule JumpExercise.Accounts do
  use Ash.Domain,
    otp_app: :jump_exercise

  resources do
    resource(JumpExercise.Accounts.Token)
    resource(JumpExercise.Accounts.User)
    resource(JumpExercise.Accounts.UserIdentity)
    resource(JumpExercise.Accounts.ApiKey)
  end
end
