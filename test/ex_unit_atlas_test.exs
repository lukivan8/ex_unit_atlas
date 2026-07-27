defmodule ExUnitAtlasTest do
  use ExUnit.Case, async: false
  use ExUnitAtlas

  setup do
    case ExUnitAtlas.Recorder.start_link() do
      {:ok, pid} ->
        on_exit(fn ->
          try do
            GenServer.stop(pid)
          catch
            :exit, _ -> :ok
          end
        end)

      {:error, {:already_started, _pid}} ->
        ExUnitAtlas.Recorder.reset()
    end

    :ok
  end

  test "step returns the original value", context do
    value =
      step "returns a tuple" do
        {:ok, %{answer: 42}}
      end

    assert value == {:ok, %{answer: 42}}
    [item] = ExUnitAtlas.Recorder.take({context.module, context.test})
    assert %{type: :step, name: "returns a tuple", status: :passed, sequence: 0} = item
    assert item.duration_us >= 0
  end

  test "check executes its block once", context do
    Process.put(:executions, 0)

    check "runs assertions" do
      Process.put(:executions, Process.get(:executions) + 1)
      assert 1 + 1 == 2
      refute false
    end

    assert Process.get(:executions) == 1

    assert [%{type: :check, status: :passed}] =
             ExUnitAtlas.Recorder.take({context.module, context.test})
  end

  test "records and reraises an error with its original stacktrace", context do
    assert_raise RuntimeError, "boom", fn ->
      step "explodes" do
        raise "boom"
      end
    end

    [item] = ExUnitAtlas.Recorder.take({context.module, context.test})
    assert item.status == :failed
    assert {:error, %RuntimeError{message: "boom"}, stacktrace} = item.error
    assert Enum.any?(stacktrace, fn {module, _, _, _} -> module == __MODULE__ end)
  end

  test "preserves throw and exit kinds", context do
    assert catch_throw(check("throws", do: throw(:value))) == :value
    assert catch_exit(step("exits", do: exit(:reason))) == :reason

    assert [
             %{error: {:throw, :value, _}},
             %{error: {:exit, :reason, _}}
           ] = ExUnitAtlas.Recorder.take({context.module, context.test})
  end

  test "rejects invalid and nested names" do
    assert_raise ArgumentError, ~r/must not be empty/, fn -> step("  ", do: :ok) end
    assert_raise ArgumentError, ~r/must be a string/, fn -> check(:atom, do: :ok) end

    assert_raise ArgumentError, ~r/nested/, fn ->
      step "outer" do
        check "inner" do
          assert true
        end
      end
    end
  end

  test "works as a no-op when recorder is unavailable" do
    pid = Process.whereis(ExUnitAtlas.Recorder)
    GenServer.stop(pid)
    assert step("still runs", do: :result) == :result
    assert_raise RuntimeError, "original", fn -> check("still fails", do: raise("original")) end
  end
end
