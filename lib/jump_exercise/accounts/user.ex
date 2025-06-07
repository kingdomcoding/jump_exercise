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

    strategies do
      oauth2 :google do
        client_id System.get_env("GOOGLE_CLIENT_ID")
        redirect_uri System.get_env("GOOGLE_REDIRECT_URI")
        client_secret System.get_env("GOOGLE_CLIENT_SECRET")
        user_url System.get_env("GOOGLE_USER_URL")
        token_url System.get_env("GOOGLE_TOKEN_URL")
        authorize_url System.get_env("GOOGLE_AUTHORIZE_URL")
        base_url System.get_env("GOOGLE_BASE_URL")
        authorization_params scope: "openid profile email"
      end
    end
  end

  actions do
    defaults [:read]

    create :register_with_google do
      argument :user_info, :map, allow_nil?: false
      argument :oauth_tokens, :map, allow_nil?: false
      upsert? true
      upsert_identity :unique_email

      change AshAuthentication.GenerateTokenChange
      change AshAuthentication.Strategy.OAuth2.IdentityChange

      change fn changeset, _ ->
        user_info = Ash.Changeset.get_argument(changeset, :user_info)
        Ash.Changeset.change_attribute(changeset, :email, Map.get(user_info, "email"))
      end

      # change set_attribute(:confirmed_at, DateTime.utc_now())

      change after_action(fn _changeset, user, _context -> {:ok, user} end)
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
