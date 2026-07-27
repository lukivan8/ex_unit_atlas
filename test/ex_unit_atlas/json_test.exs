defmodule ExUnitAtlas.JSONTest do
  use ExUnit.Case, async: true

  alias ExUnitAtlas.JSON

  test "encodes supported values deterministically with escaping and Unicode" do
    value = %{
      "z" => [nil, true, false, 12],
      "a" => "Behavior map 🗺\n\"guarantees\"\\\u0001"
    }

    encoded = JSON.encode!(value)
    assert encoded =~ ~s("a": "Behavior map 🗺\\n\\\"guarantees\\\"\\\\\\u0001")
    assert encoded =~ ~s("z": [)
    assert :binary.match(encoded, ~s("a")) < :binary.match(encoded, ~s("z"))
  end

  test "rejects unsupported values and non-string keys" do
    for value <- [:atom, self(), make_ref(), fn -> :ok end] do
      assert_raise ArgumentError, fn -> JSON.encode!(value) end
    end

    assert_raise ArgumentError, ~r/keys must be strings/, fn -> JSON.encode!(%{atom: "value"}) end
    assert_raise ArgumentError, ~r/valid UTF-8/, fn -> JSON.encode!(<<255>>) end
  end

  test "writes atomically and replaces an existing report" do
    directory = Path.join(System.tmp_dir!(), "atlas-json-#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf!(directory) end)
    File.mkdir_p!(directory)
    File.write!(Path.join(directory, "report.json"), "old")

    assert JSON.write!(%{"ok" => true}, directory) == Path.join(directory, "report.json")
    assert File.read!(Path.join(directory, "report.json")) =~ ~s("ok": true)
    refute Path.wildcard(Path.join(directory, ".report-*.tmp")) != []
  end
end
