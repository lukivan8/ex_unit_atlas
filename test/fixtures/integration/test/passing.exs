defmodule AtlasIntegrationFixture.AsyncA do
  use ExUnit.Case, async: true
  use ExUnitAtlas

  test "same name" do
    result =
      step "A1" do
        AtlasIntegrationFixture.Barrier.arrive(:a)
        %{owner: :a, stage: :prepared}
      end
      |> show("A data")

    assert result.owner == :a

    check "A2" do
      assert true
    end
  end
end

defmodule AtlasIntegrationFixture.AsyncB do
  use ExUnit.Case, async: true
  use ExUnitAtlas

  test "same name" do
    step "B1" do
      AtlasIntegrationFixture.Barrier.arrive(:b)
    end

    Process.sleep(5)

    check "B2" do
      assert true
    end
  end
end

defmodule AtlasIntegrationFixture.PlainTest do
  use ExUnit.Case, async: true

  test "works without instrumentation" do
    assert 2 + 2 == 4
  end
end
