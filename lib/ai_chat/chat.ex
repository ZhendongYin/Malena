defmodule AiChat.Chat do
  @moduledoc """
  The Chat context.
  """

  import Ecto.Query, warn: false
  alias AiChat.Repo

  alias AiChat.Chat.Conversation
  alias AiChat.Chat.Message

  @doc """
  Returns the list of conversations for a user (excluding deleted ones).
  """
  def list_user_conversations(user_id) do
    Conversation
    |> where([c], c.user_id == ^user_id and is_nil(c.deleted_at))
    |> order_by([c], desc: c.updated_at)
    |> Repo.all()
  end

  @doc """
  Gets a single conversation (excluding deleted ones).
  """
  def get_conversation(id) do
    Conversation
    |> where([c], c.id == ^id and is_nil(c.deleted_at))
    |> Repo.one()
  end

  @doc """
  Creates a conversation.
  """
  def create_conversation(attrs \\ %{}) do
    %Conversation{}
    |> Conversation.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a conversation.
  """
  def update_conversation(%Conversation{} = conversation, attrs) do
    conversation
    |> Conversation.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Soft deletes a conversation by setting deleted_at timestamp.
  """
  def delete_conversation(%Conversation{} = conversation) do
    conversation
    |> Conversation.changeset(%{deleted_at: DateTime.utc_now()})
    |> Repo.update()
  end

  def delete_conversation(id) when is_binary(id) or is_integer(id) do
    case get_conversation(id) do
      nil -> {:error, :not_found}
      conversation -> delete_conversation(conversation)
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking conversation changes.
  """
  def change_conversation(%Conversation{} = conversation, attrs \\ %{}) do
    Conversation.changeset(conversation, attrs)
  end

  @doc """
  Returns the list of messages for a conversation.
  """
  def list_conversation_messages(conversation_id) do
    Message
    |> where([m], m.conversation_id == ^conversation_id)
    |> order_by([m], asc: m.inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single message.
  """
  def get_message(id), do: Repo.get(Message, id)

  @doc """
  Creates a message.
  """
  def create_message(attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a message.
  """
  def update_message(%Message{} = message, attrs) do
    message
    |> Message.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a message.
  """
  def delete_message(%Message{} = message) do
    Repo.delete(message)
  end

  @doc """
  Deletes all messages for a given conversation id.

  Returns {count, nil} like Repo.delete_all/2.
  """
  def delete_messages_for_conversation(conversation_id) do
    Message
    |> where([m], m.conversation_id == ^conversation_id)
    |> Repo.delete_all()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking message changes.
  """
  def change_message(%Message{} = message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end
end
