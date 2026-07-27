defmodule ExUnitAtlas do
  @moduledoc """
  Adds named behavior steps, checks, and data previews to regular ExUnit tests.

  Use this module after `use ExUnit.Case` (or a project-specific case
  template):

      defmodule Shop.SaleTest do
        use ExUnit.Case, async: true
        use ExUnitAtlas

        test "cash sales are fiscalized" do
          sale =
            step "Create a cash sale" do
              %{payment_type: :cash}
            end
            |> show("Created sale")

          check "The sale is eligible for fiscalization" do
            assert sale.payment_type == :cash
          end
        end
      end

  `step/2`, `check/2`, and `show/2` preserve the values flowing through the
  test. Add `ExUnitAtlas.Formatter` alongside the standard ExUnit CLI formatter
  to generate the report.
  """

  @owner_key {__MODULE__, :owner}
  @open_item_key {__MODULE__, :open_item}
  @show_preview_characters 2_000

  defmacro __using__(_opts) do
    quote do
      import ExUnitAtlas, only: [step: 2, check: 2, show: 2]

      setup context do
        ExUnitAtlas.__register_test__(context)
        :ok
      end
    end
  end

  @doc """
  Runs and records a named scenario step.

  The block is executed exactly once and its value is returned unchanged.
  Errors, exits and throws are re-raised with their original reason and
  stacktrace. The name must be a non-empty string. Nested items are not
  supported.
  """
  defmacro step(name, do: block), do: item_quote(:step, name, block)

  @doc """
  Runs and records a named human-readable assertion block.

  A check can contain one or more regular ExUnit assertions. Atlas does not
  inspect or replace them, and preserves their normal failures. The name must
  be a non-empty string. Nested items are not supported.
  """
  defmacro check(name, do: block), do: item_quote(:check, name, block)

  @doc """
  Records a bounded preview of `value` and returns the original value.

  `show/2` is pipe-friendly:

      sale
      |> show("Sale after creation")
      |> persist_sale()

  The preview uses `inspect/2` with bounded collection and string limits, then
  truncates the final representation to 2,000 characters. Atlas records only
  that string representation, never the original term.

  Values may contain credentials, personal data, or other secrets. Use
  `show/2` only for data that is safe to store in local and CI report
  artifacts.

  The label must be a non-empty string. `show/2` cannot be called from inside
  an open `step` or `check`; place it after the block, typically through a
  pipeline.
  """
  @spec show(value, String.t()) :: value when value: term()
  def show(value, label) do
    validate_name!(label)
    ensure_not_nested!()

    if Process.whereis(ExUnitAtlas.Recorder) do
      owner = Process.get(@owner_key)
      preview = inspect_preview(value)
      record(fn -> ExUnitAtlas.Recorder.record_show(owner, label, preview) end)
    end

    value
  end

  @doc false
  def __register_test__(%{module: module, test: test}) do
    Process.put(@owner_key, {module, test})
    :ok
  end

  @doc false
  def __begin_item__(type, name) when type in [:step, :check] do
    validate_name!(name)
    ensure_not_nested!()

    owner = Process.get(@owner_key)
    started_at = System.monotonic_time()
    Process.put(@open_item_key, true)
    record(fn -> ExUnitAtlas.Recorder.start_item(owner, type, name, started_at) end)
    {owner, started_at}
  end

  @doc false
  def __pass_item__({owner, started_at}) do
    record(fn -> ExUnitAtlas.Recorder.finish_item(owner, :passed, elapsed_us(started_at), nil) end)

    :ok
  end

  @doc false
  def __fail_item__({owner, started_at}, kind, reason, stacktrace) do
    record(fn ->
      ExUnitAtlas.Recorder.finish_item(
        owner,
        :failed,
        elapsed_us(started_at),
        {kind, reason, stacktrace}
      )
    end)

    :ok
  end

  @doc false
  def __end_item__ do
    Process.delete(@open_item_key)
    :ok
  end

  defp validate_name!(name) when is_binary(name) do
    if String.trim(name) == "",
      do: raise(ArgumentError, "step/check/show name must not be empty")
  end

  defp validate_name!(name) do
    raise ArgumentError, "step/check/show name must be a string, got: #{inspect(name)}"
  end

  defp ensure_not_nested! do
    if Process.get(@open_item_key) do
      raise ArgumentError, "nested ExUnit Atlas step/check/show items are not supported"
    end
  end

  defp inspect_preview(value) do
    preview = inspect(value, pretty: true, width: 80, limit: 20, printable_limit: 500)

    if String.starts_with?(preview, "#Inspect.Error<") do
      "#Inspect.Error<preview unavailable>"
    else
      truncate_preview(preview)
    end
  rescue
    _error -> "#Inspect.Error<preview unavailable>"
  catch
    _kind, _reason -> "#Inspect.Error<preview unavailable>"
  end

  defp truncate_preview(preview) do
    if String.length(preview) > @show_preview_characters do
      String.slice(preview, 0, @show_preview_characters) <> "…"
    else
      preview
    end
  end

  defp elapsed_us(started_at) do
    System.monotonic_time()
    |> Kernel.-(started_at)
    |> System.convert_time_unit(:native, :microsecond)
  end

  defp record(fun) do
    if Process.whereis(ExUnitAtlas.Recorder) do
      try do
        fun.()
      catch
        :exit, _ -> :ok
      end
    else
      :ok
    end
  end

  defp item_quote(type, name, block) do
    quote do
      atlas_item = ExUnitAtlas.__begin_item__(unquote(type), unquote(name))

      try do
        atlas_result = unquote(block)
        ExUnitAtlas.__pass_item__(atlas_item)
        atlas_result
      catch
        atlas_kind, atlas_reason ->
          atlas_stacktrace = __STACKTRACE__
          ExUnitAtlas.__fail_item__(atlas_item, atlas_kind, atlas_reason, atlas_stacktrace)
          :erlang.raise(atlas_kind, atlas_reason, atlas_stacktrace)
      after
        ExUnitAtlas.__end_item__()
      end
    end
  end
end
