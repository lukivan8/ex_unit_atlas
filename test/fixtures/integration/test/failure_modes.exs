defmodule AtlasIntegrationFixture.StepExceptionTest do
  use ExUnit.Case, async: true
  use ExUnitAtlas

  test "exception inside step" do
    step "Exploding operation" do
      raise "step boom"
    end
  end
end

defmodule AtlasIntegrationFixture.OutsideFailureTest do
  use ExUnit.Case, async: true
  use ExUnitAtlas

  test "failure outside instrumentation" do
    raise "outside boom"
  end
end

defmodule AtlasIntegrationFixture.SetupFailureTest do
  use ExUnit.Case, async: true
  use ExUnitAtlas

  setup do
    raise "setup boom"
  end

  test "failure in setup" do
    flunk("test body must not run")
  end
end
