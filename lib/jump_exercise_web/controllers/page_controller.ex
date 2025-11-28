defmodule JumpExerciseWeb.PageController do
  use JumpExerciseWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def redirect_to_chat(conn, _params) do
    redirect(conn, to: ~p"/chat")
  end
end
