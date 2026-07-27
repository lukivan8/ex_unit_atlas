defmodule ExUnitAtlas.JSONTest do
  use ExUnit.Case, async: true
  use ExUnitAtlas

  alias ExUnitAtlas.JSON

  describe "Strict JSON encoding" do
    test "encodes supported values deterministically with escaping and Unicode" do
      value =
        step "Build a JSON-safe behavior tree" do
          %{
            "z" => [nil, true, false, 12],
            "a" => "Behavior map 🗺\n\"guarantees\"\\\u0001"
          }
        end
        |> show("JSON encoder input")

      encoded =
        step "Encode the behavior tree" do
          JSON.encode!(value)
        end

      check "Strings, Unicode, and control characters are escaped safely" do
        assert encoded =~ ~s("a": "Behavior map 🗺\\n\\\"guarantees\\\"\\\\\\u0001")
        assert encoded =~ ~s("z": [)
      end

      check "Object keys are deterministic regardless of map order" do
        assert :binary.match(encoded, ~s("a")) < :binary.match(encoded, ~s("z"))
      end
    end

    test "rejects unsupported values and non-string keys" do
      unsupported_values =
        step "Collect Elixir terms that cannot enter the public schema" do
          [:atom, self(), make_ref(), fn -> :ok end]
        end

      check "Atoms, PIDs, references, and functions are rejected" do
        for value <- unsupported_values do
          assert_raise ArgumentError, fn -> JSON.encode!(value) end
        end
      end

      check "Object keys must be strings" do
        assert_raise ArgumentError, ~r/keys must be strings/, fn ->
          JSON.encode!(%{atom: "value"})
        end
      end

      check "JSON strings must contain valid UTF-8" do
        assert_raise ArgumentError, ~r/valid UTF-8/, fn -> JSON.encode!(<<255>>) end
      end
    end

    test "writes atomically and replaces an existing report" do
      directory =
        step "Create an output directory with an existing report" do
          directory =
            Path.join(System.tmp_dir!(), "atlas-json-#{System.unique_integer([:positive])}")

          on_exit(fn -> File.rm_rf!(directory) end)
          File.mkdir_p!(directory)
          File.write!(Path.join(directory, "report.json"), "old")
          directory
        end

      destination =
        step "Replace the report through an atomic write" do
          JSON.write!(%{"ok" => true}, directory)
        end
        |> show("Written report path")

      check "The destination contains the new JSON document" do
        assert destination == Path.join(directory, "report.json")
        assert File.read!(destination) =~ ~s("ok": true)
      end

      check "No temporary report file remains" do
        assert Path.wildcard(Path.join(directory, ".report-*.tmp")) == []
      end
    end
  end
end
