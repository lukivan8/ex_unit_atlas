defmodule ExUnitAtlas.Formatter do
  @moduledoc """
  ExUnit formatter which writes the Atlas JSON and HTML reports.

  Register it alongside the standard CLI formatter in `test/test_helper.exs`:

      ExUnit.start(
        formatters: [
          ExUnit.CLIFormatter,
          ExUnitAtlas.Formatter
        ]
      )

  ExUnit owns this module's lifecycle; do not start it directly. Reports are
  written to `ex_unit_atlas_report/report.json` and
  `ex_unit_atlas_report/index.html`. The CLI formatter remains responsible for
  terminal output and the test process exit status.
  """
  use GenServer

  @impl true
  def init(_opts) do
    case ExUnitAtlas.Recorder.start_link() do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> ExUnitAtlas.Recorder.reset()
    end

    {:ok, %{tests: [], lifecycle: []}}
  end

  @impl true
  def handle_cast({:test_finished, %ExUnit.Test{} = test} = event, state) do
    items = ExUnitAtlas.Recorder.take({test.module, test.name}, test.state)

    {:noreply,
     %{
       state
       | tests: [{test, items} | state.tests],
         lifecycle: [event_name(event) | state.lifecycle]
     }}
  end

  def handle_cast({:suite_finished, _times} = event, state) do
    report = ExUnitAtlas.Report.build(state.tests)
    ExUnitAtlas.JSON.write!(report)
    ExUnitAtlas.HTML.write!(report)

    ExUnitAtlas.Recorder.reset()
    {:noreply, %{state | lifecycle: [event_name(event) | state.lifecycle]}}
  end

  def handle_cast(event, state) do
    {:noreply, %{state | lifecycle: [event_name(event) | state.lifecycle]}}
  end

  defp event_name({name, _}), do: name
end
