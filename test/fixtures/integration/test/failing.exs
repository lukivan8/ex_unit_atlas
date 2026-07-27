defmodule AtlasIntegrationFixture.FailingTest do
  use ExUnit.Case, async: true
  use ExUnitAtlas

  test "keeps assertion failure semantics" do
    check "Expected business rule" do
      assert 1 == 2
    end
  end
end
