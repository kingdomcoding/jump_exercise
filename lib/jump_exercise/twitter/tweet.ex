defmodule JumpExercise.Twitter.Tweet do
  use Ash.Resource,
    otp_app: :jump_exercise,
    domain: JumpExercise.Twitter,
    data_layer: Ash.DataLayer.Ets

  attributes do
    uuid_primary_key :id
    attribute :message, :string, allow_nil?: false
  end

  actions do
    defaults [:read, :create, :update, :destroy]
    default_accept [:message]
  end
end
