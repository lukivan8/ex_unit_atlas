defmodule ExUnitAtlas.RecorderTest do
  use ExUnit.Case, async: false

  alias ExUnitAtlas.Recorder

  setup do
    case Recorder.start_link() do
      {:ok, pid} ->
        on_exit(fn ->
          try do
            GenServer.stop(pid)
          catch
            :exit, _ -> :ok
          end
        end)

      {:error, {:already_started, _pid}} ->
        Recorder.reset()
    end

    :ok
  end

  test "isolates and orders interleaved owners repeatedly" do
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

      assert Enum.map(Recorder.take(owner_a), & &1.name) == ["A1", "A2"]
      assert Enum.map(Recorder.take(owner_b), & &1.name) == ["B1", "B2"]
      assert Recorder.state() == %{}
    end
  end

  test "finalizes an open item as interrupted and clears it" do
    owner = {__MODULE__, :"test interrupted"}
    Recorder.start_item(owner, :step, "open", System.monotonic_time())

    assert [%{name: "open", status: :interrupted, error: :test_failed}] =
             Recorder.take(owner, :test_failed)

    assert Recorder.state() == %{}
  end
end
