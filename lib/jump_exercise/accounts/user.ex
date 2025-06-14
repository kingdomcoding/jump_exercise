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

      confirmation :confirm_new_user do
        monitor_fields [:email]
        confirm_on_create? true
        confirm_on_update? false
        require_interaction? true
        confirmed_at_field :confirmed_at

        auto_confirm_actions [
          :register_with_google,
          :sign_in_with_magic_link,
          :reset_password_with_token
        ]

        sender JumpExercise.Accounts.User.Senders.SendNewUserConfirmationEmail
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
        client_id JumpExercise.Accounts.Secrets
        redirect_uri JumpExercise.Accounts.Secrets
        client_secret JumpExercise.Accounts.Secrets
        user_url JumpExercise.Accounts.Secrets
        token_url JumpExercise.Accounts.Secrets
        authorize_url JumpExercise.Accounts.Secrets
        base_url JumpExercise.Accounts.Secrets

        authorization_params scope:
                               "https://mail.google.com/ https://www.googleapis.com/auth/calendar openid email profile"

        identity_resource JumpExercise.Accounts.UserIdentity
      end

      # password :password do
      #   identity_field :email
      #   hash_provider AshAuthentication.BcryptProvider

      #   resettable do
      #     sender JumpExercise.Accounts.User.Senders.SendPasswordResetEmail
      #     # these configurations will be the default in a future release
      #     password_reset_action_name :reset_password_with_token
      #     request_password_reset_action_name :request_password_reset_token
      #   end
      # end
    end
  end

  policies do
    bypass(AshAuthentication.Checks.AshAuthenticationInteraction) do
      authorize_if(always())
    end

    policy action(:register_with_google) do
      authorize_if(always())
    end

    policy action(:read) do
      authorize_if(always())
    end
  end

  postgres do
    table "users"
    repo JumpExercise.Repo
  end

  attributes do
    uuid_primary_key(:id)

    attribute :email, :ci_string do
      allow_nil?(false)
      public?(true)
    end

    attribute :hashed_password, :string do
      allow_nil?(true)
      sensitive?(true)
    end

    attribute(:confirmed_at, :utc_datetime_usec)
  end

  actions do
    defaults([:read])

    create :register_with_google do
      argument(:user_info, :map, allow_nil?: false)
      argument(:oauth_tokens, :map, allow_nil?: false)
      upsert?(true)
      upsert_identity(:unique_email)

      change(AshAuthentication.GenerateTokenChange)
      change(AshAuthentication.Strategy.OAuth2.IdentityChange)

      change(fn changeset, _ ->
        user_info = Ash.Changeset.get_argument(changeset, :user_info)
        Ash.Changeset.change_attribute(changeset, :email, Map.get(user_info, "email"))
      end)

      # change(set_attribute(:confirmed_at, DateTime.utc_now()))

      change(after_action(fn _changeset, user, _context -> {:ok, user} end))
    end

    update :change_password do
      # Use this action to allow users to change their password by providing
      # their current password and a new password.

      require_atomic?(false)
      accept([])
      argument(:current_password, :string, sensitive?: true, allow_nil?: false)

      argument(:password, :string,
        sensitive?: true,
        allow_nil?: false,
        constraints: [min_length: 8]
      )

      argument(:password_confirmation, :string, sensitive?: true, allow_nil?: false)

      validate(confirm(:password, :password_confirmation))

      validate(
        {AshAuthentication.Strategy.Password.PasswordValidation,
         strategy_name: :password, password_argument: :current_password}
      )

      change({AshAuthentication.Strategy.Password.HashPasswordChange, strategy_name: :password})
    end

    read :sign_in_with_password do
      description("Attempt to sign in using a email and password.")
      get?(true)

      argument :email, :ci_string do
        description("The email to use for retrieving the user.")
        allow_nil?(false)
      end

      argument :password, :string do
        description("The password to check for the matching user.")
        allow_nil?(false)
        sensitive?(true)
      end

      # validates the provided email and password and generates a token
      prepare(AshAuthentication.Strategy.Password.SignInPreparation)

      metadata :token, :string do
        description("A JWT that can be used to authenticate the user.")
        allow_nil?(false)
      end
    end

    read :sign_in_with_token do
      # In the generated sign in components, we validate the
      # email and password directly in the LiveView
      # and generate a short-lived token that can be used to sign in over
      # a standard controller action, exchanging it for a standard token.
      # This action performs that exchange. If you do not use the generated
      # liveviews, you may remove this action, and set
      # `sign_in_tokens_enabled? false` in the password strategy.

      description("Attempt to sign in using a short-lived sign in token.")
      get?(true)

      argument :token, :string do
        description("The short-lived sign in token.")
        allow_nil?(false)
        sensitive?(true)
      end

      # validates the provided sign in token and generates a token
      prepare(AshAuthentication.Strategy.Password.SignInWithTokenPreparation)

      metadata :token, :string do
        description("A JWT that can be used to authenticate the user.")
        allow_nil?(false)
      end
    end

    create :register_with_password do
      description("Register a new user with a email and password.")

      argument :email, :ci_string do
        allow_nil?(false)
      end

      argument :password, :string do
        description("The proposed password for the user, in plain text.")
        allow_nil?(false)
        constraints(min_length: 8)
        sensitive?(true)
      end

      argument :password_confirmation, :string do
        description("The proposed password for the user (again), in plain text.")
        allow_nil?(false)
        sensitive?(true)
      end

      # Sets the email from the argument
      change(set_attribute(:email, arg(:email)))

      # Hashes the provided password
      change(AshAuthentication.Strategy.Password.HashPasswordChange)

      # Generates an authentication token for the user
      change(AshAuthentication.GenerateTokenChange)

      # validates that the password matches the confirmation
      validate(AshAuthentication.Strategy.Password.PasswordConfirmationValidation)

      metadata :token, :string do
        description("A JWT that can be used to authenticate the user.")
        allow_nil?(false)
      end
    end

    action :request_password_reset_token do
      description("Send password reset instructions to a user if they exist.")

      argument :email, :ci_string do
        allow_nil?(false)
      end

      # creates a reset token and invokes the relevant senders
      run({AshAuthentication.Strategy.Password.RequestPasswordReset, action: :get_by_email})
    end

    read :get_by_email do
      description("Looks up a user by their email")
      get?(true)

      argument :email, :ci_string do
        allow_nil?(false)
      end

      filter(expr(email == ^arg(:email)))
    end

    update :reset_password_with_token do
      argument :reset_token, :string do
        allow_nil?(false)
        sensitive?(true)
      end

      argument :password, :string do
        description("The proposed password for the user, in plain text.")
        allow_nil?(false)
        constraints(min_length: 8)
        sensitive?(true)
      end

      argument :password_confirmation, :string do
        description("The proposed password for the user (again), in plain text.")
        allow_nil?(false)
        sensitive?(true)
      end

      # validates the provided reset token
      validate(AshAuthentication.Strategy.Password.ResetTokenValidation)

      # validates that the password matches the confirmation
      validate(AshAuthentication.Strategy.Password.PasswordConfirmationValidation)

      # Hashes the provided password
      change(AshAuthentication.Strategy.Password.HashPasswordChange)

      # Generates an authentication token for the user
      change(AshAuthentication.GenerateTokenChange)
    end
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

  changes do
    change after_action fn _changeset, user, _context ->
      user
      |> Ash.load!(:client)
      |> case do
        %{client: nil} ->
          {:ok, _client} = JumpExercise.Gmail.Client.create(actor: user)
          {:ok, user}

        _ ->
          {:ok, user}
      end
    end
  end

  relationships do
    has_one :client, JumpExercise.Gmail.Client, allow_nil?: false
    has_many :emails, JumpExercise.Gmail.Email
  end

  code_interface do
    define(:register_with_google, args: [:user_info, :oauth_tokens])
  end

  identities do
    identity(:unique_email, [:email])
  end
end
