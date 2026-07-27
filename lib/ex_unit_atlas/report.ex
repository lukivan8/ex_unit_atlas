defmodule ExUnitAtlas.Report do
  @moduledoc false

  def build(test_results, generated_at \\ DateTime.utc_now()) do
    tests =
      test_results
      |> Enum.map(&normalize_test/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.sort_by(fn test ->
        {test["file"], test["module"], test["describe"] || "", test["line"], test["name"]}
      end)

    passed = Enum.count(tests, &(&1["status"] == "passed"))

    %{
      "schema_version" => 1,
      "generated_at" => generated_at |> DateTime.truncate(:second) |> DateTime.to_iso8601(),
      "summary" => %{
        "total" => length(tests),
        "passed" => passed,
        "failed" => length(tests) - passed,
        "duration_us" => Enum.sum(Enum.map(tests, & &1["duration_us"]))
      },
      "tests" => tests
    }
  end

  def normalize_error(nil), do: nil
  def normalize_error({:failed, failures}), do: Enum.map(failures, &normalize_failure/1)
  def normalize_error(errors) when is_list(errors), do: Enum.map(errors, &normalize_failure/1)

  def normalize_error({kind, reason, stacktrace}),
    do: normalize_failure({kind, reason, stacktrace})

  defp normalize_test({%ExUnit.Test{state: {status, _}}, _items})
       when status in [:excluded, :skipped],
       do: nil

  defp normalize_test({%ExUnit.Test{} = test, items}) do
    tags = test.tags
    describe = tags[:describe]

    %{
      "module" => inspect(test.module),
      "file" => normalize_file(tags[:file]),
      "line" => tags[:line] || 0,
      "describe" => if(describe, do: to_string(describe), else: nil),
      "name" => clean_name(test.name, tags[:test_type] || :test, describe),
      "status" => if(is_nil(test.state), do: "passed", else: "failed"),
      "duration_us" => test.time || 0,
      "items" => Enum.map(items, &normalize_item/1),
      "error" => normalize_state(test.state)
    }
  end

  defp clean_name(name, test_type, describe) do
    name = name |> to_string() |> String.replace_prefix("#{test_type} ", "")
    if describe, do: String.replace_prefix(name, "#{describe} ", ""), else: name
  end

  defp normalize_file(nil), do: ""
  defp normalize_file(file), do: file |> to_string() |> Path.relative_to_cwd()

  defp normalize_item(item) do
    %{
      "type" => Atom.to_string(item.type),
      "name" => item.name,
      "status" => Atom.to_string(item.status),
      "duration_us" => item.duration_us,
      "error" => normalize_error(item.error)
    }
  end

  defp normalize_state(nil), do: nil
  defp normalize_state({:failed, failures}), do: Enum.map(failures, &normalize_failure/1)

  defp normalize_state({_status, reason}) do
    [%{"kind" => "error", "message" => inspect(reason), "stacktrace" => []}]
  end

  defp normalize_failure({kind, reason, stacktrace}) do
    %{
      "kind" => Atom.to_string(kind),
      "message" => failure_message(kind, reason),
      "stacktrace" => Enum.map(stacktrace, &Exception.format_stacktrace_entry/1)
    }
  end

  defp failure_message(:error, reason) do
    :error
    |> Exception.normalize(reason, [])
    |> Exception.message()
  rescue
    _ -> inspect(reason)
  end

  defp failure_message(:exit, reason), do: Exception.format_exit(reason)
  defp failure_message(:throw, reason), do: inspect(reason)
  defp failure_message(_kind, reason), do: inspect(reason)
end
