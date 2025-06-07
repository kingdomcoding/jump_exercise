defmodule JumpExercise.Repo do
  use Ecto.Repo,
    otp_app: :jump_exercise,
    adapter: Ecto.Adapters.Postgres
end
