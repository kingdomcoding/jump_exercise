defmodule JumpExercise.Accounts.UserIdentity do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication.UserIdentity],
    domain: JumpExercise.Accounts

  postgres do
    table "user_identities"
    repo JumpExercise.Repo
  end

  user_identity do
    user_resource JumpExercise.Accounts.User
  end
end
