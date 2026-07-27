defmodule ExUnitAtlas.RecorderTest do
  use ExUnit.Case, async: false
  use ExUnitAtlas

  alias ExUnitAtlas.Recorder

  setup do
    case Recorder.start_link() do
      {:ok, pid} ->
        Process.unlink(pid)

      {:error, {:already_started, _pid}} ->
        :ok
    end

    :ok
  end

  describe "Async-safe event recording" do
    test "isolates and orders interleaved owners repeatedly" do
      result =
        for iteration <- 1..50 do
          owner_a = {Module.concat(["A#{iteration}"]), :"test same name"}
          owner_b = {Module.concat(["B#{iteration}"]), :"test same name"}
          parent = self()

          tasks =
            for {owner, prefix} <- [{owner_a, "A"}, {owner_b, "B"}] do
              Task.async(fn ->
                Recorder.start_item(owner, :step, "#{prefix}1", System.monotonic_time())
                send(parent, {:started, iteration, prefix})

                receive do
                  :continue -> :ok
                end

                Recorder.finish_item(owner, :passed, 1, nil)
                Recorder.start_item(owner, :check, "#{prefix}2", System.monotonic_time())
                Recorder.finish_item(owner, :passed, 1, nil)
              end)
            end

          assert_receive {:started, ^iteration, _}
          assert_receive {:started, ^iteration, _}
          Enum.each(tasks, &send(&1.pid, :continue))
          Task.await_many(tasks)

          names_a = Enum.map(Recorder.take(owner_a), & &1.name)
          names_b = Enum.map(Recorder.take(owner_b), & &1.name)
          state_empty? = Recorder.state() == %{}

          assert names_a == ["A1", "A2"]
          assert names_b == ["B1", "B2"]
          assert state_empty?

          %{a: names_a, b: names_b, state_empty?: state_empty?}
        end

      %{iterations: length(result), final_iteration: List.last(result)}
      |> show("Concurrent recorder stress result")

      check "Fifty interleaved pairs keep independent, ordered histories" do
        assert length(result) == 50
        assert Enum.all?(result, &(&1.a == ["A1", "A2"]))
        assert Enum.all?(result, &(&1.b == ["B1", "B2"]))
        assert Enum.all?(result, & &1.state_empty?)
      end
    end

    test "finalizes an open item as interrupted and clears it" do
      owner = {__MODULE__, :"test interrupted"}
      Recorder.start_item(owner, :step, "open", System.monotonic_time())

      items = Recorder.take(owner, :test_failed)
      state_empty? = Recorder.state() == %{}

      items
      |> Enum.map(&Map.take(&1, [:name, :status, :error]))
      |> show("Finalized interrupted item")

      check "A test failure closes its open item and releases recorder state" do
        assert [%{name: "open", status: :interrupted, error: :test_failed}] = items
        assert state_empty?
      end
    end

    test "orders show items with steps and checks" do
      owner = {__MODULE__, :"test data flow"}

      Recorder.start_item(owner, :step, "Create sale", System.monotonic_time())
      Recorder.finish_item(owner, :passed, 10, nil)
      Recorder.record_show(owner, "Created sale", "%{id: 42}")
      Recorder.start_item(owner, :check, "Sale is completed", System.monotonic_time())
      Recorder.finish_item(owner, :passed, 5, nil)

      items = Recorder.take(owner)
      ordered_items = Enum.map(items, &{&1.sequence, &1.type, &1.name})

      ordered_items
      |> show("Recorded data-flow order")

      check "Steps, shown data, and checks share one stable sequence" do
        assert ordered_items == [
                 {0, :step, "Create sale"},
                 {1, :show, "Created sale"},
                 {2, :check, "Sale is completed"}
               ]

        assert Enum.at(items, 1).value == "%{id: 42}"
      end
    end
  end
end
