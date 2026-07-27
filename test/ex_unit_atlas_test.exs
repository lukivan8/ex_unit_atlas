defmodule ExUnitAtlasTest do
  use ExUnit.Case, async: false
  use ExUnitAtlas

  setup do
    case ExUnitAtlas.Recorder.start_link() do
      {:ok, pid} ->
        Process.unlink(pid)

      {:error, {:already_started, _pid}} ->
        :ok
    end

    :ok
  end

  describe "Public instrumentation semantics" do
    test "step returns the original value", context do
      value =
        step "Return a compound Elixir value unchanged" do
          {:ok, %{answer: 42}}
        end

      [item] = ExUnitAtlas.Recorder.take({context.module, context.test})

      item
      |> Map.take([:type, :name, :status, :sequence])
      |> show("Recorded step")

      check "A step preserves its exact result and records timing metadata" do
        assert value == {:ok, %{answer: 42}}
        assert %{type: :step, status: :passed, sequence: 0} = item
        assert item.duration_us >= 0
      end
    end

    test "check executes its block once", context do
      Process.put(:executions, 0)

      check "Run multiple ordinary ExUnit assertions" do
        Process.put(:executions, Process.get(:executions) + 1)
        assert 1 + 1 == 2
        refute false
      end

      executions = Process.get(:executions)
      items = ExUnitAtlas.Recorder.take({context.module, context.test})

      executions
      |> show("Check block execution count")

      check "A check executes once and keeps ordinary assertions intact" do
        assert executions == 1
        assert [%{type: :check, status: :passed}] = items
      end
    end

    test "show records a bounded preview and returns the exact value", context do
      value = {:ok, %{id: 42, status: :completed}}
      returned_value = show(value, "Created sale")
      [item] = ExUnitAtlas.Recorder.take({context.module, context.test})

      check "Shown data is observational and JSON-safe" do
        assert returned_value === value

        assert %{
                 type: :show,
                 name: "Created sale",
                 value: "{:ok, %{id: 42, status: :completed}}",
                 status: :passed,
                 duration_us: 0,
                 error: nil
               } = item
      end
    end

    test "show limits large previews", context do
      value = %ExUnitAtlas.Test.LongInspect{}
      returned_value = show(value, "Large list")
      [item] = ExUnitAtlas.Recorder.take({context.module, context.test})

      %{preview_length: String.length(item.value), truncated?: String.ends_with?(item.value, "…")}
      |> show("Bounded preview")

      check "Large values are truncated without changing the original term" do
        assert returned_value === value
        assert item.type == :show
        assert String.length(item.value) == 2_001
        assert String.ends_with?(item.value, "…")
      end
    end

    test "a broken Inspect implementation does not fail the test", context do
      value = %ExUnitAtlas.Test.BrokenInspect{}
      returned_value = show(value, "Custom value")
      [item] = ExUnitAtlas.Recorder.take({context.module, context.test})

      item.value
      |> show("Safe fallback preview")

      check "A custom Inspect failure cannot break user tests" do
        assert returned_value === value
        assert item.value == "#Inspect.Error<preview unavailable>"
      end
    end
  end

  describe "Failure preservation and validation" do
    test "records and reraises an error with its original stacktrace", context do
      assert_raise RuntimeError, "boom", fn ->
        step "Run code that raises a RuntimeError" do
          raise "boom"
        end
      end

      [item] = ExUnitAtlas.Recorder.take({context.module, context.test})
      {:error, error, stacktrace} = item.error

      %{
        status: item.status,
        kind: :error,
        message: Exception.message(error),
        user_frame_preserved?:
          Enum.any?(stacktrace, fn {module, _, _, _} -> module == __MODULE__ end)
      }
      |> show("Captured RuntimeError")

      check "Runtime errors keep their type, message, and user stack frame" do
        assert item.status == :failed
        assert %RuntimeError{message: "boom"} = error
        assert Enum.any?(stacktrace, fn {module, _, _, _} -> module == __MODULE__ end)
      end
    end

    test "preserves throw and exit kinds", context do
      thrown = catch_throw(check("Throw a value", do: throw(:value)))
      exited = catch_exit(step("Exit with a reason", do: exit(:reason)))
      items = ExUnitAtlas.Recorder.take({context.module, context.test})

      %{throw: thrown, exit: exited}
      |> show("Recovered non-error failure kinds")

      check "Throw and exit retain their original kinds and reasons" do
        assert thrown == :value
        assert exited == :reason

        assert [
                 %{error: {:throw, :value, _}},
                 %{error: {:exit, :reason, _}}
               ] = items
      end
    end

    test "rejects invalid and nested names", context do
      assert_raise ArgumentError, ~r/must not be empty/, fn -> step("  ", do: :ok) end
      assert_raise ArgumentError, ~r/must be a string/, fn -> check(:atom, do: :ok) end
      assert_raise ArgumentError, ~r/must not be empty/, fn -> show(:value, " ") end

      assert_raise ArgumentError, ~r/nested/, fn ->
        step "Outer step" do
          check "Nested check" do
            assert true
          end
        end
      end

      assert_raise ArgumentError, ~r/nested/, fn ->
        step "Outer step" do
          show(:value, "Nested shown data")
        end
      end

      rejected_items = ExUnitAtlas.Recorder.take({context.module, context.test})

      rejected_items
      |> Enum.map(&Map.take(&1, [:type, :name, :status]))
      |> show("Rejected nested items")

      check "Names must be non-empty strings and instrumentation remains linear" do
        assert Enum.count(rejected_items, &(&1.status == :failed)) == 2
        assert Enum.all?(rejected_items, &(&1.name == "Outer step"))
      end
    end

    test "works as a no-op when recorder is unavailable" do
      pid = Process.whereis(ExUnitAtlas.Recorder)
      GenServer.stop(pid)

      step_result = step("Still runs", do: :result)
      show_result = show({:still, :runs}, "Still returns")

      error =
        assert_raise RuntimeError, "original", fn ->
          check("Still fails", do: raise("original"))
        end

      {:ok, recorder_pid} = ExUnitAtlas.Recorder.start_link()
      Process.unlink(recorder_pid)

      check "Recorder outages never mask values or original failures" do
        assert step_result == :result
        assert show_result == {:still, :runs}
        assert error.message == "original"
      end
    end
  end
end
