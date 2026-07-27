defmodule ExUnitAtlas.IntegrationTest do
  use ExUnit.Case, async: false

  @fixture Path.expand("fixtures/integration", __DIR__)
  @report Path.join(@fixture, "ex_unit_atlas_report/report.json")
  @html Path.join(@fixture, "ex_unit_atlas_report/index.html")

  setup do
    File.rm_rf!(Path.dirname(@report))
    on_exit(fn -> File.rm_rf!(Path.dirname(@report)) end)
    :ok
  end

  test "real ExUnit formatter associates interleaved async tests and writes valid JSON" do
    {output, status} = run_fixture("test/passing.exs")

    assert status == 0, output
    assert output =~ "3 tests, 0 failures"
    report = File.read!(@report)
    html = File.read!(@html)

    assert report =~ ~s("module": "AtlasIntegrationFixture.AsyncA")
    assert report =~ ~s("module": "AtlasIntegrationFixture.AsyncB")
    assert report =~ ~s("name": "A1")
    assert report =~ ~s("name": "A2")
    assert report =~ ~s("name": "B1")
    assert report =~ ~s("name": "B2")
    assert html =~ "AtlasIntegrationFixture.AsyncA"
    assert html =~ "A1"
    assert html =~ "B2"

    {_, 0} =
      System.cmd("python3", ["-c", "import json,sys; json.load(open(sys.argv[1]))", @report])
  end

  test "failed suite keeps non-zero exit status and still writes the report" do
    {output, status} = run_fixture("test/failing.exs")

    assert status != 0
    assert output =~ "Assertion with == failed"
    assert output =~ "test/failing.exs:7"

    report = File.read!(@report)
    html = File.read!(@html)
    assert report =~ ~s("status": "failed")
    assert report =~ ~s("name": "Expected business rule")
    assert report =~ "Assertion with == failed"
    assert report =~ "test/failing.exs:7"
    assert html =~ "Expected business rule"
    assert html =~ "Assertion with == failed"
    assert html =~ "test/failing.exs:7"

    {_, 0} =
      System.cmd("python3", ["-c", "import json,sys; json.load(open(sys.argv[1]))", @report])
  end

  test "empty suite writes an empty report" do
    {output, status} = run_fixture("test/empty.exs")
    assert status == 0, output

    report = File.read!(@report)
    html = File.read!(@html)
    assert report =~ ~s("total": 0)
    assert report =~ ~s("tests": [])
    assert html =~ "No tests were run."
  end

  test "normalizes step, outside-block and setup failures" do
    {output, status} = run_fixture("test/failure_modes.exs")
    assert status != 0
    assert output =~ "3 tests, 3 failures"

    report = File.read!(@report)
    html = File.read!(@html)
    assert report =~ "step boom"
    assert report =~ "outside boom"
    assert report =~ "setup boom"
    assert report =~ ~s("name": "Exploding operation")
    assert report =~ ~s("items": [])
    assert html =~ "step boom"
    assert html =~ "outside boom"
    assert html =~ "setup boom"

    {_, 0} =
      System.cmd("python3", ["-c", "import json,sys; json.load(open(sys.argv[1]))", @report])
  end

  defp run_fixture(file) do
    System.cmd("mix", ["test", file],
      cd: @fixture,
      env: [{"MIX_ENV", "test"}],
      stderr_to_stdout: true
    )
  end
end
