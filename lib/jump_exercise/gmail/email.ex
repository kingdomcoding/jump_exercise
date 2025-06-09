defmodule JumpExercise.Gmail.Email do
  use Ash.Resource,
    otp_app: :jump_exercise,
    domain: JumpExercise.Gmail,
    extensions: [AshAi],
    data_layer: AshPostgres.DataLayer

  vectorize do
    strategy :after_action

    full_text do
      text fn record ->
        """
        Email details
        From: #{record.from}
        To: #{record.to}
        Subject: #{record.subject}
        Body: #{record.body}
        """
      end

      used_attributes [:from, :to, :subject, :body]
    end

    embedding_model JumpExercise.OpenAiEmbeddingModel
  end

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

    read :search do
      argument :query, :string, allow_nil?: false

      prepare before_action(fn query, context ->
        case JumpExercise.OpenAiEmbeddingModel.generate([query.arguments.query], []) do
          {:ok, [search_vector]} ->
            Ash.Query.filter(
              query,
              expr(vector_cosine_distance(full_text_vector, ^search_vector) < 0.5)
            )
            |> Ash.Query.sort(
              {calc(vector_cosine_distance(full_text_vector, ^search_vector),
                type: :float
              ), :asc}
            )
            |> Ash.Query.limit(10)

          {:error, error} ->
            {:error, error}
        end
      end)
    end
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
