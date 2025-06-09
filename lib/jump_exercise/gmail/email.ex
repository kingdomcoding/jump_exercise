defmodule JumpExercise.Gmail.Email do
  use Ash.Resource,
    otp_app: :jump_exercise,
    domain: JumpExercise.Gmail,
    # TODO: Change this to postgres
    data_layer: AshPostgres.DataLayer

  attributes do
    uuid_primary_key(:id)
    attribute(:thread_id, :string)
    attribute(:from, :string)
    attribute(:to, :string)
    attribute(:subject, :string)
    attribute(:body, :string)
    attribute(:labels, {:array, :string}, default: [])
    attribute(:snippet, :string)
    attribute(:raw, :string)
  end

  changes do
    change fn changeset, context ->
      Ash.Changeset.manage_relationship(changeset, :user, context.actor, type: :append_and_remove)
    end
  end

  actions do
    defaults([:create, :read, :update, :destroy])
    default_accept([:thread_id, :from, :to, :subject, :body, :labels, :snippet, :raw])
  end

  relationships do
    belongs_to :user, JumpExercise.Accounts.User, allow_nil?: false
  end

  code_interface do
    define :create
  end

  postgres do
    table "gmail_emails"
    repo JumpExercise.Repo
  end
end
