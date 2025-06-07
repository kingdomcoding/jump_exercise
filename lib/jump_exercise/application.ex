defmodule JumpExercise.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      JumpExerciseWeb.Telemetry,
      JumpExercise.Repo,
      {DNSCluster, query: Application.get_env(:jump_exercise, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: JumpExercise.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: JumpExercise.Finch},
      # Start a worker by calling: JumpExercise.Worker.start_link(arg)
      # {JumpExercise.Worker, arg},
      # Start to serve requests, typically the last entry
      JumpExerciseWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: JumpExercise.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    JumpExerciseWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
