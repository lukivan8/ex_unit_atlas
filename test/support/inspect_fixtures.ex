defmodule ExUnitAtlas.Test.LongInspect do
  defstruct []
end

defimpl Inspect, for: ExUnitAtlas.Test.LongInspect do
  import Inspect.Algebra

  def inspect(_value, _opts), do: string(String.duplicate("x", 3_000))
end

defmodule ExUnitAtlas.Test.BrokenInspect do
  defstruct []
end

defimpl Inspect, for: ExUnitAtlas.Test.BrokenInspect do
  def inspect(_value, _opts), do: raise("custom inspect failed")
end
