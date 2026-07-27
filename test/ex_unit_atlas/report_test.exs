defmodule ExUnitAtlas.ReportTest do
  use ExUnit.Case, async: true
  use ExUnitAtlas

  alias ExUnitAtlas.Report

  describe "Report normalization" do
    test "normalizes, sorts and summarizes ExUnit tests" do
      test_results =
        step "Build passed and failed ExUnit results with Atlas items" do
          passed = %ExUnit.Test{
            module: Example.ZTest,
            name: :"test Sales succeeds",
            state: nil,
            time: 20,
            tags: %{file: "test/z_test.exs", line: 12, describe: "Sales", test_type: :test}
          }

          failure =
            {%RuntimeError{message: "boom"},
             [{Example.ATest, :run, 0, [file: ~c"test/a_test.exs", line: 9]}]}

          failed = %ExUnit.Test{
            module: Example.ATest,
            name: :"test fails",
            state: {:failed, [{:error, elem(failure, 0), elem(failure, 1)}]},
            time: 10,
            tags: %{file: "test/a_test.exs", line: 8, describe: nil, test_type: :test}
          }

          item = %{
            sequence: 0,
            type: :check,
            name: "Works ✓",
            status: :passed,
            duration_us: 2,
            error: nil
          }

          shown = %{
            sequence: 1,
            type: :show,
            name: "Created sale",
            value: "%{id: 42}",
            status: :passed,
            duration_us: 0,
            error: nil
          }

          [{passed, [item, shown]}, {failed, []}]
        end

      report =
        step "Normalize the ExUnit results into schema version 2" do
          Report.build(test_results, ~U[2026-07-21 10:00:00Z])
        end
        |> show("Normalized report summary")

      check "Schema, timestamp, summary, and ordering are deterministic" do
        assert report["schema_version"] == 2
        assert report["generated_at"] == "2026-07-21T10:00:00Z"

        assert report["summary"] == %{
                 "total" => 2,
                 "passed" => 1,
                 "failed" => 1,
                 "duration_us" => 30
               }

        assert Enum.map(report["tests"], & &1["module"]) == ["Example.ATest", "Example.ZTest"]
        assert Enum.at(report["tests"], 1)["name"] == "succeeds"
      end

      check "Steps and shown values retain their public shape" do
        assert get_in(report, ["tests", Access.at(1), "items", Access.at(0), "name"]) ==
                 "Works ✓"

        assert get_in(report, ["tests", Access.at(1), "items", Access.at(1), "value"]) ==
                 "%{id: 42}"

        refute get_in(report, ["tests", Access.at(1), "items", Access.at(0)])
               |> Map.has_key?("value")
      end

      check "ExUnit failures are normalized without serializing exception structs" do
        assert get_in(report, ["tests", Access.at(0), "error", Access.at(0), "message"]) ==
                 "boom"
      end
    end

    test "omits skipped and excluded tests" do
      states =
        step "Build skipped and excluded test states" do
          [{:skipped, "later"}, {:excluded, "tag"}]
        end
        |> show("States omitted from schema version 2")

      check "Neither skipped nor excluded tests enter the public report" do
        for state <- states do
          test = %ExUnit.Test{
            module: Example.Test,
            name: :"test ignored",
            state: state,
            tags: %{}
          }

          assert Report.build([{test, []}])["tests"] == []
        end
      end
    end
  end
end
