defmodule Doom.Task do
  use Doom.Web, :model

  import Doom.Model.ParamsHelpers

  schema "tasks" do
    field :name, :string
    field :interval, :integer
    field :silent, :integer
    field :url, :string
    field :method, :string
    field :type, :string
    field :headers, :map
    field :params, :map
    field :expect, :map
    field :active, :boolean, default: true
    field :silence_at, Calecto.DateTimeUTC

    many_to_many :groups, Doom.Group, join_through: "tasks_groups", on_replace: :delete, on_delete: :delete_all
    timestamps
  end

  @required_fields ~w(name interval type url expect method)
  @optional_fields ~w(active params headers)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> cast_assoc(:groups)
    |> validate_length(:url, max: 150)
  end

  def save_changeset(model, params \\ %{}) do
    task_params = params |> process_json_params
    model |> changeset(task_params)
  end
end
