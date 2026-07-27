defmodule ExUnitAtlas.DogfoodTest do
  use ExUnit.Case, async: true
  use ExUnitAtlas

  describe "Public instrumentation API" do
    test "follows an order through a multi-stage data flow" do
      order =
        step "Create an order with two line items" do
          %{items: [%{price: 2_000}, %{price: 2_200}], total: 4_200, discount: 0}
        end
        |> show("Order before discount")

      discounted_order =
        step "Apply a ten percent discount" do
          discount = div(order.total, 10)
          %{order | total: order.total - discount, discount: discount}
        end
        |> show("Order after discount")

      check "The discount is recorded explicitly" do
        assert discounted_order.discount == 420
      end

      check "The final total includes the discount" do
        assert discounted_order.total == 3_780
      end

      check "The README example stays aligned with the executable scenario" do
        readme = File.read!("README.md")

        for label <- [
              "Create an order with two line items",
              "Order before discount",
              "Apply a ten percent discount",
              "Order after discount",
              "The final total includes the discount"
            ] do
          assert readme =~ label
        end
      end
    end
  end
end
