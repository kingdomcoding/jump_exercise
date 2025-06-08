defmodule JumpExercise.Twitter do
  use Ash.Domain,
    otp_app: :jump_exercise,
    extensions: [AshAi]

  resources do
    resource(JumpExercise.Twitter.Tweet)
  end

  tools do
    tool :create_tweet, JumpExercise.Twitter.Tweet, :create
    tool :list_tweets, JumpExercise.Twitter.Tweet, :read
  end
end
