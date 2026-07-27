defmodule ExUnitAtlas.Recorder do
  @moduledoc false
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, Keyword.put_new(opts, :name, __MODULE__))
  end

  def start_item(nil, _type, _name, _started_at), do: :ok

  def start_item(owner, type, name, started_at) do
    GenServer.call(__MODULE__, {:start, owner, type, name, started_at})
  end

  def finish_item(nil, _status, _duration_us, _error), do: :ok

  def finish_item(owner, status, duration_us, error) do
    GenServer.call(__MODULE__, {:finish, owner, status, duration_us, error})
  end

  def take(owner, test_error \\ nil), do: GenServer.call(__MODULE__, {:take, owner, test_error})
  def reset, do: GenServer.call(__MODULE__, :reset)
  def state, do: GenServer.call(__MODULE__, :state)

  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_call({:start, owner, type, name, started_at}, _from, state) do
    history = Map.get(state, owner, %{next_sequence: 0, items: [], open: nil})

    if history.open do
      {:reply, {:error, :nested}, state}
    else
      open = %{sequence: history.next_sequence, type: type, name: name, started_at: started_at}
      history = %{history | next_sequence: history.next_sequence + 1, open: open}
      {:reply, :ok, Map.put(state, owner, history)}
    end
  end

  def handle_call({:finish, owner, status, duration_us, error}, _from, state) do
    case Map.get(state, owner) do
      %{open: open} = history when not is_nil(open) ->
        item =
          open
          |> Map.drop([:started_at])
          |> Map.merge(%{status: status, duration_us: duration_us, error: error})

        history = %{history | items: [item | history.items], open: nil}
        {:reply, :ok, Map.put(state, owner, history)}

      _ ->
        {:reply, :ok, state}
    end
  end

  def handle_call({:take, owner, test_error}, _from, state) do
    {history, state} = Map.pop(state, owner, %{items: [], open: nil})

    items =
      case history.open do
        nil ->
          history.items

        open ->
          duration_us =
            System.monotonic_time()
            |> Kernel.-(open.started_at)
            |> System.convert_time_unit(:native, :microsecond)

          interrupted =
            open
            |> Map.drop([:started_at])
            |> Map.merge(%{status: :interrupted, duration_us: duration_us, error: test_error})

          [interrupted | history.items]
      end

    {:reply, Enum.sort_by(items, & &1.sequence), state}
  end

  def handle_call(:reset, _from, _state), do: {:reply, :ok, %{}}
  def handle_call(:state, _from, state), do: {:reply, state, state}
end
