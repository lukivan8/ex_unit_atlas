defmodule ExUnitAtlas.HTMLTest do
  use ExUnit.Case, async: true
  use ExUnitAtlas

  alias ExUnitAtlas.HTML

  describe "Static HTML reporting" do
    test "renders summary, tests, items and failures" do
      report =
        step "Build a failed report containing a check and shown data" do
          report_fixture()
        end
        |> show("HTML report input")

      html =
        step "Render the normalized report as standalone HTML" do
          HTML.render(report)
        end

      check "The document exposes behavior before technical metadata" do
        assert html =~ "<!doctype html>"
        assert html =~ ~s(<html lang="en">)
        assert html =~ "ExUnit Atlas"
        assert html =~ "Total:"
        assert html =~ "Technical details"
        assert html =~ "<h2>Sales</h2>"
        assert html =~ "Expected business rule"
        assert html =~ "Sale after creation"
      end

      check "Shown values, failures, source locations, and duration remain visible" do
        assert html =~ "%{id: 42, note: &quot;&lt;safe&gt;&quot;}"
        assert html =~ "Assertion failed"
        assert length(Regex.scan(~r/Assertion failed/, html)) == 1
        assert html =~ "test/example_test.exs:12"
        assert html =~ "1.5 ms"
      end
    end

    test "escapes every user-controlled string" do
      report =
        step "Inject HTML payloads into every public text position" do
          report_fixture()
          |> put_in(["tests", Access.at(0), "name"], "<script>alert('test')</script>")
          |> put_in(["tests", Access.at(0), "items", Access.at(0), "name"], "<b>unsafe</b>")
          |> put_in(
            ["tests", Access.at(0), "items", Access.at(1), "value"],
            "<script>data</script>"
          )
          |> put_in(
            ["tests", Access.at(0), "items", Access.at(0), "error", "message"],
            "<img src=x>"
          )
        end

      html =
        step "Render the report containing hostile strings" do
          HTML.render(report)
        end

      check "No user-controlled string is interpreted as HTML" do
        refute html =~ "<script>"
        refute html =~ "<b>unsafe</b>"
        refute html =~ "<img src=x>"
        refute html =~ "<script>data</script>"
      end

      check "Every hostile string remains readable in escaped form" do
        assert html =~ "&lt;script&gt;"
        assert html =~ "&lt;b&gt;unsafe&lt;/b&gt;"
        assert html =~ "&lt;img src=x&gt;"
        assert html =~ "&lt;script&gt;data&lt;/script&gt;"
      end
    end

    test "renders an empty suite and writes index.html atomically" do
      report =
        step "Build an empty suite report" do
          %{
            "generated_at" => "2026-07-27T10:00:00Z",
            "summary" => %{"total" => 0, "passed" => 0, "failed" => 0, "duration_us" => 0},
            "tests" => []
          }
        end

      directory =
        step "Allocate a temporary HTML output directory" do
          directory =
            Path.join(System.tmp_dir!(), "atlas-html-#{System.unique_integer([:positive])}")

          on_exit(fn -> File.rm_rf!(directory) end)
          directory
        end

      destination =
        step "Write index.html through a temporary file and rename" do
          HTML.write!(report, directory)
        end
        |> show("Written HTML report path")

      check "An empty suite still produces a readable report" do
        assert destination == Path.join(directory, "index.html")
        assert File.read!(destination) =~ "No tests were run."
      end

      check "No temporary HTML file remains" do
        assert Path.wildcard(Path.join(directory, ".index-*.tmp")) == []
      end
    end
  end

  defp report_fixture do
    error = %{
      "kind" => "error",
      "message" => "Assertion failed",
      "stacktrace" => ["test/example_test.exs:12: (test)"]
    }

    %{
      "generated_at" => "2026-07-27T10:00:00Z",
      "summary" => %{"total" => 1, "passed" => 0, "failed" => 1, "duration_us" => 1_500},
      "tests" => [
        %{
          "module" => "ExampleTest",
          "file" => "test/example_test.exs",
          "line" => 8,
          "describe" => "Sales",
          "name" => "failed scenario",
          "status" => "failed",
          "duration_us" => 1_500,
          "items" => [
            %{
              "type" => "check",
              "name" => "Expected business rule",
              "status" => "failed",
              "duration_us" => 25,
              "error" => error
            },
            %{
              "type" => "show",
              "name" => "Sale after creation",
              "value" => ~s(%{id: 42, note: "<safe>"}),
              "status" => "passed",
              "duration_us" => 0,
              "error" => nil
            }
          ],
          "error" => [error]
        }
      ]
    }
  end
end
