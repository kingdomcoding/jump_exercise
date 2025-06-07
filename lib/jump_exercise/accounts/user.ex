defmodule JumpExercise.Accounts.User do
  use Ash.Resource,
    otp_app: :jump_exercise,
    domain: JumpExercise.Accounts,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshAuthentication]

  authentication do
    add_ons do
      log_out_everywhere do
        apply_on_password_change? true
      end
    end

    tokens do
      enabled? true
      token_resource JumpExercise.Accounts.Token
      signing_secret JumpExercise.Secrets
      store_all_tokens? true
      require_token_presence_for_authentication? true
    end
  end

  policies do
    bypass(AshAuthentication.Checks.AshAuthenticationInteraction) do
      authorize_if(always())
    end

    policy(always()) do
      forbid_if(always())
    end
  end

  postgres do
    table "users"
    repo JumpExercise.Repo
  end

  attributes do
    uuid_primary_key(:id)
  end

  actions do
    defaults([:read])

    read :get_by_subject do
      description("Get a user by the subject claim in a JWT")
      argument(:subject, :string, allow_nil?: false)
      get?(true)
      prepare(AshAuthentication.Preparations.FilterBySubject)
    end
  end
end
