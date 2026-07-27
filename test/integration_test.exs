defmodule ExUnitAtlas.IntegrationTest do
  use ExUnit.Case, async: false
  use ExUnitAtlas

  @fixture Path.expand("fixtures/integration", __DIR__)
  @report Path.join(@fixture, "ex_unit_atlas_report/report.json")
  @html Path.join(@fixture, "ex_unit_atlas_report/index.html")

  setup do
    File.rm_rf!(Path.dirname(@report))
    on_exit(fn -> File.rm_rf!(Path.dirname(@report)) end)
    :ok
  end

  describe "Real ExUnit formatter lifecycle" do
    test "associates interleaved async tests and writes both report formats" do
      {output, status} =
        step "Run a genuinely interleaved async fixture in a child ExUnit suite" do
          run_fixture("test/passing.exs")
        end

      status
      |> show("Child suite exit status")

      {report, html} =
        step "Read the JSON and HTML produced by the child formatter" do
          {File.read!(@report), File.read!(@html)}
        end

      check "The child suite passes while keeping the standard CLI formatter" do
        assert status == 0, output
        assert output =~ "3 tests, 0 failures"
      end

      check "Interleaved async tests retain independent ordered items" do
        assert report =~ ~s("module": "AtlasIntegrationFixture.AsyncA")
        assert report =~ ~s("module": "AtlasIntegrationFixture.AsyncB")
        assert report =~ ~s("name": "A1")
        assert report =~ ~s("name": "A2")
        assert report =~ ~s("name": "B1")
        assert report =~ ~s("name": "B2")
      end

      check "Shown data is present in JSON and HTML" do
        assert report =~ ~s("name": "A data")
        assert report =~ ~s("value": "%{owner: :a, stage: :prepared}")
        assert html =~ "AtlasIntegrationFixture.AsyncA"
        assert html =~ "A1"
        assert html =~ "B2"
        assert html =~ "A data"
        assert html =~ "%{owner: :a, stage: :prepared}"
      end

      check "The generated report parses as standard JSON" do
        assert_json_parses(@report)
      end
    end

    test "keeps a failed suite non-zero while still writing its report" do
      {output, status} =
        step "Run an assertion failure in a child ExUnit suite" do
          run_fixture("test/failing.exs")
        end

      status
      |> show("Failed child suite exit status")

      {report, html} =
        step "Read the reports left by the failed child suite" do
          {File.read!(@report), File.read!(@html)}
        end

      check "Atlas preserves ExUnit failure semantics and source location" do
        assert status != 0
        assert output =~ "Assertion with == failed"
        assert output =~ "test/failing.exs:7"
      end

      check "The failed item and diagnostic appear in both report formats" do
        assert report =~ ~s("status": "failed")
        assert report =~ ~s("name": "Expected business rule")
        assert report =~ "Assertion with == failed"
        assert report =~ "test/failing.exs:7"
        assert html =~ "Expected business rule"
        assert html =~ "Assertion with == failed"
        assert html =~ "test/failing.exs:7"
      end

      check "A report from a failed suite remains valid JSON" do
        assert_json_parses(@report)
      end
    end

    test "writes useful empty reports" do
      {output, status} =
        step "Run an empty child ExUnit suite" do
          run_fixture("test/empty.exs")
        end

      {report, html} =
        step "Read the empty suite reports" do
          {File.read!(@report), File.read!(@html)}
        end

      check "An empty suite succeeds and reports zero tests" do
        assert status == 0, output
        assert report =~ ~s("total": 0)
        assert report =~ ~s("tests": [])
        assert html =~ "No tests were run."
      end
    end

    test "normalizes failures inside steps, outside instrumentation, and setup" do
      {output, status} =
        step "Run three distinct child-suite failure modes" do
          run_fixture("test/failure_modes.exs")
        end

      {report, html} =
        step "Read reports containing all failure modes" do
          {File.read!(@report), File.read!(@html)}
        end

      check "Every failure mode remains visible to ExUnit and Atlas" do
        assert status != 0
        assert output =~ "3 tests, 3 failures"
        assert report =~ "step boom"
        assert report =~ "outside boom"
        assert report =~ "setup boom"
        assert report =~ ~s("name": "Exploding operation")
        assert report =~ ~s("items": [])
        assert html =~ "step boom"
        assert html =~ "outside boom"
        assert html =~ "setup boom"
      end

      check "The multi-failure report remains valid JSON" do
        assert_json_parses(@report)
      end
    end
  end

  defp run_fixture(file) do
    System.cmd("mix", ["test", file],
      cd: @fixture,
      env: [{"MIX_ENV", "test"}],
      stderr_to_stdout: true
    )
  end

  defp assert_json_parses(path) do
    assert {_, 0} =
             System.cmd("python3", ["-c", "import json,sys; json.load(open(sys.argv[1]))", path])
  end
end
