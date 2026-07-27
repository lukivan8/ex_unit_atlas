ExUnit.start(formatters: [ExUnit.CLIFormatter, ExUnitAtlas.Formatter])

defmodule AtlasIntegrationFixture.Barrier do
  use Agent

  def start_link do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def arrive(label) do
    Agent.update(__MODULE__, &[{self(), label} | &1])
    wait_for_pair()
  end

  defp wait_for_pair do
    if Agent.get(__MODULE__, &(length(&1) >= 2)) do
      :ok
    else
      Process.sleep(2)
      wait_for_pair()
    end
  end
end

{:ok, _pid} = AtlasIntegrationFixture.Barrier.start_link()
