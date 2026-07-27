defmodule ExUnitAtlas.HTMLTest do
  use ExUnit.Case, async: true

  alias ExUnitAtlas.HTML

  test "renders summary, tests, items and failures" do
    report = report_fixture()
    html = HTML.render(report)

    assert html =~ "<!doctype html>"
    assert html =~ ~s(<html lang="en">)
    assert html =~ "ExUnit Atlas"
    assert html =~ "Total:"
    assert html =~ "Technical details"
    assert html =~ "<h2>Sales</h2>"
    assert html =~ "Expected business rule"
    assert html =~ "Assertion failed"
    assert length(Regex.scan(~r/Assertion failed/, html)) == 1
    assert html =~ "test/example_test.exs:12"
    assert html =~ "1.5 ms"
  end

  test "escapes every user-controlled string" do
    report =
      report_fixture()
      |> put_in(["tests", Access.at(0), "name"], "<script>alert('test')</script>")
      |> put_in(["tests", Access.at(0), "items", Access.at(0), "name"], "<b>unsafe</b>")
      |> put_in(
        ["tests", Access.at(0), "items", Access.at(0), "error", "message"],
        "<img src=x>"
      )

    html = HTML.render(report)

    refute html =~ "<script>"
    refute html =~ "<b>unsafe</b>"
    refute html =~ "<img src=x>"
    assert html =~ "&lt;script&gt;"
    assert html =~ "&lt;b&gt;unsafe&lt;/b&gt;"
    assert html =~ "&lt;img src=x&gt;"
  end

  test "renders an empty suite and writes index.html atomically" do
    report = %{
      "generated_at" => "2026-07-27T10:00:00Z",
      "summary" => %{"total" => 0, "passed" => 0, "failed" => 0, "duration_us" => 0},
      "tests" => []
    }

    directory = Path.join(System.tmp_dir!(), "atlas-html-#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf!(directory) end)

    assert HTML.write!(report, directory) == Path.join(directory, "index.html")
    assert File.read!(Path.join(directory, "index.html")) =~ "No tests were run."
    assert Path.wildcard(Path.join(directory, ".index-*.tmp")) == []
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
            }
          ],
          "error" => [error]
        }
      ]
    }
  end
end
