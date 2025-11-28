defmodule JumpExercise.Chat.MessageNotEmpty do
  @impl true
  def supports(_opts), do: [Ash.Changeset]

  @impl true
  def validate(changeset, _opts, _context) do
    value = Ash.Changeset.get_attribute(changeset, :text)

    if is_nil(value) || Regex.match?(value, ~r/\S/) == false do
      {:error, field: :text, message: "Message cannot be empty"}
    else
      :ok
    end
  end
end
