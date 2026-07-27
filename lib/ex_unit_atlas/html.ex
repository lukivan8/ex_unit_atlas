defmodule ExUnitAtlas.HTML do
  @moduledoc false

  @template """
  <!doctype html>
  <html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>ExUnit Atlas</title>
    <style>
      body {
        max-width: 800px;
        margin: 40px auto;
        padding: 0 20px;
        color: #222;
        background: #fff;
        font: 16px/1.5 -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      }
      h1 { margin-bottom: 4px; }
      h2 { margin: 32px 0 8px; }
      .meta, .summary, .type, details { color: #666; }
      .summary { margin: 20px 0 32px; }
      .scenarios { padding-left: 24px; }
      .scenario { margin: 8px 0 16px; }
      .scenario-title { font-weight: 600; }
      .items { list-style: none; margin: 6px 0 0; padding-left: 20px; }
      .item { margin: 3px 0; }
      .mark { display: inline-block; width: 20px; font-weight: 700; }
      .passed { color: #16803a; }
      .failed { color: #c62828; }
      .type { display: inline-block; width: 70px; font-size: 12px; text-transform: uppercase; }
      details { margin: 10px 0 0 24px; font-size: 13px; }
      .error { margin: 8px 0; padding: 8px 12px; border-left: 3px solid #c62828; background: #fff5f5; }
      pre { margin-bottom: 0; white-space: pre-wrap; font-size: 12px; }
    </style>
  </head>
  <body>
    <header>
      <h1>ExUnit Atlas</h1>
      <p class="meta">Generated <%= h.(report["generated_at"]) %></p>
    </header>

    <p class="summary">
      Total: <strong><%= report["summary"]["total"] %></strong> ·
      Passed: <strong class="passed"><%= report["summary"]["passed"] %></strong> ·
      Failed: <strong class="failed"><%= report["summary"]["failed"] %></strong> ·
      Duration: <strong><%= duration.(report["summary"]["duration_us"]) %></strong>
    </p>

    <main>
      <%= if report["tests"] == [] do %>
        <p class="empty">No tests were run.</p>
      <% end %>

      <%= for group <- groups do %>
        <section class="group">
          <h2><%= h.(group.title) %></h2>
          <ul class="scenarios">
            <%= for test <- group.tests do %>
              <li class="scenario">
                <span class="mark <%= test["status"] %>" aria-label="<%= status_label.(test["status"]) %>"><%= status_mark.(test["status"]) %></span>
                <span class="scenario-title"><%= h.(test["name"]) %></span>

                <%= if test["items"] != [] do %>
                  <ul class="items">
                    <%= for item <- test["items"] do %>
                      <li class="item">
                        <span class="mark <%= item["status"] %>"><%= status_mark.(item["status"]) %></span>
                        <span class="type"><%= type_label.(item["type"]) %></span>
                        <span><%= h.(item["name"]) %></span>
                        <%= for error <- errors.(item["error"]) do %>
                          <%= error_block.(error) %>
                        <% end %>
                      </li>
                    <% end %>
                  </ul>
                <% end %>

                <%= for error <- test_errors.(test) do %>
                  <%= error_block.(error) %>
                <% end %>

              </li>
            <% end %>
          </ul>
          <details class="technical">
            <summary>Technical details</summary>
            <ul>
              <%= for test <- group.tests do %>
                <li><%= h.(test["name"]) %> · <%= h.(test["module"]) %> · <%= h.(test["file"]) %>:<%= test["line"] %> · <%= duration.(test["duration_us"]) %></li>
              <% end %>
            </ul>
          </details>
        </section>
      <% end %>
    </main>
  </body>
  </html>
  """

  def render(report) do
    EEx.eval_string(@template,
      report: report,
      groups: group_tests(report["tests"]),
      h: &escape/1,
      duration: &format_duration/1,
      errors: &errors/1,
      test_errors: &test_errors/1,
      error_block: &render_error/1,
      status_mark: &status_mark/1,
      status_label: &status_label/1,
      type_label: &type_label/1
    )
  end

  def write!(report, output_dir \\ "ex_unit_atlas_report") do
    File.mkdir_p!(output_dir)
    destination = Path.join(output_dir, "index.html")
    temporary = Path.join(output_dir, ".index-#{System.unique_integer([:positive])}.tmp")

    try do
      File.write!(temporary, render(report), [:binary])
      File.rename!(temporary, destination)
      destination
    after
      File.rm(temporary)
    end
  end

  defp errors(nil), do: []
  defp errors(error) when is_map(error), do: [error]
  defp errors(errors) when is_list(errors), do: errors

  defp test_errors(test) do
    if Enum.any?(test["items"], &(&1["error"] != nil)) do
      []
    else
      errors(test["error"])
    end
  end

  defp group_tests(tests) do
    tests
    |> Enum.group_by(&{&1["file"], &1["module"], &1["describe"]})
    |> Enum.map(fn {_key, grouped_tests} ->
      grouped_tests = Enum.sort_by(grouped_tests, & &1["line"])
      first = hd(grouped_tests)

      %{
        title: first["describe"] || first["module"],
        tests: grouped_tests,
        file: first["file"],
        module: first["module"],
        first_line: first["line"]
      }
    end)
    |> Enum.sort_by(&{&1.file, &1.first_line, &1.module, &1.title})
  end

  defp status_mark("passed"), do: "✓"
  defp status_mark(_status), do: "✕"
  defp status_label("passed"), do: "Passed"
  defp status_label(_status), do: "Failed"
  defp type_label("step"), do: "step"
  defp type_label("check"), do: "check"
  defp type_label(type), do: escape(type)

  defp render_error(error) do
    stacktrace =
      error["stacktrace"]
      |> Enum.map_join("\n", &escape/1)

    """
    <div class="error">
      <strong>#{escape(error["kind"])}: #{escape(error["message"])}</strong>
      <pre>#{stacktrace}</pre>
    </div>
    """
  end

  defp format_duration(duration_us) when duration_us < 1_000, do: "#{duration_us} μs"
  defp format_duration(duration_us), do: "#{Float.round(duration_us / 1_000, 2)} ms"

  defp escape(value) do
    value
    |> to_string()
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&#39;")
  end
end
