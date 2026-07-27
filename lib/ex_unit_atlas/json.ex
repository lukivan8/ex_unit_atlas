defmodule ExUnitAtlas.JSON do
  @moduledoc false

  def encode!(value), do: [encode(value, 0), "\n"] |> IO.iodata_to_binary()

  def write!(value, output_dir \\ "ex_unit_atlas_report") do
    File.mkdir_p!(output_dir)
    destination = Path.join(output_dir, "report.json")
    temporary = Path.join(output_dir, ".report-#{System.unique_integer([:positive])}.tmp")

    try do
      File.write!(temporary, encode!(value), [:binary])
      File.rename!(temporary, destination)
      destination
    after
      File.rm(temporary)
    end
  end

  defp encode(nil, _depth), do: "null"
  defp encode(true, _depth), do: "true"
  defp encode(false, _depth), do: "false"
  defp encode(value, _depth) when is_integer(value), do: Integer.to_string(value)

  defp encode(value, _depth) when is_binary(value) do
    if String.valid?(value) do
      [?", escape(value), ?"]
    else
      raise ArgumentError, "JSON strings must contain valid UTF-8"
    end
  end

  defp encode([], _depth), do: "[]"

  defp encode(values, depth) when is_list(values) do
    inner =
      Enum.map_join(values, ",\n", fn value -> [indent(depth + 1), encode(value, depth + 1)] end)

    ["[\n", inner, "\n", indent(depth), "]"]
  end

  defp encode(map, depth) when is_map(map) do
    entries =
      map
      |> Enum.map(fn
        {key, value} when is_binary(key) ->
          {key, value}

        {key, _value} ->
          raise ArgumentError, "JSON object keys must be strings, got: #{inspect(key)}"
      end)
      |> Enum.sort_by(&elem(&1, 0))

    case entries do
      [] ->
        "{}"

      _ ->
        inner =
          Enum.map_join(entries, ",\n", fn {key, value} ->
            [indent(depth + 1), encode(key, depth + 1), ": ", encode(value, depth + 1)]
          end)

        ["{\n", inner, "\n", indent(depth), "}"]
    end
  end

  defp encode(value, _depth),
    do: raise(ArgumentError, "unsupported JSON value: #{inspect(value)}")

  defp indent(depth), do: String.duplicate("  ", depth)

  defp escape(value) do
    for <<codepoint::utf8 <- value>>, into: "" do
      case codepoint do
        ?" ->
          "\\\""

        ?\\ ->
          "\\\\"

        8 ->
          "\\b"

        12 ->
          "\\f"

        10 ->
          "\\n"

        13 ->
          "\\r"

        9 ->
          "\\t"

        control when control < 32 ->
          "\\u" <> String.pad_leading(Integer.to_string(control, 16), 4, "0")

        other ->
          <<other::utf8>>
      end
    end
  end
end
