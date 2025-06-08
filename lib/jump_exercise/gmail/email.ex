defmodule JumpExercise.Gmail.Email do
  use Ash.Resource,
    otp_app: :jump_exercise,
    domain: JumpExercise.Gmail,
    data_layer: Ash.DataLayer.Ets

  attributes do
    uuid_primary_key :id
    attribute :thread_id, :string
    attribute :from, :string
    attribute :to, :string
    attribute :subject, :string
    attribute :body, :string
    attribute :labels, {:array, :string}, default: []
    attribute :snippet, :string
    attribute :raw, :string
  end

  actions do
    defaults [:read, :destroy]
    default_accept [:thread_id, :from, :to, :subject, :body, :labels, :snippet, :raw]

    create :send_email do
      change fn changeset, _ ->
        # TODO: Implement Gmail API call to send email
        changeset
      end
    end

    read :list_emails do
      prepare fn query, _ ->
        # TODO: Implement Gmail API call to list/search emails
        query
      end
    end

    read :get_email do
      prepare fn query, _ ->
        # TODO: Implement Gmail API call to get a single email
        query
      end
    end

    update :modify_labels

    destroy :delete_email
  end
end
