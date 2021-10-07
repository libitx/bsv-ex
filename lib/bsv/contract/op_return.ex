defmodule BSV.Contract.OpReturn do
  @moduledoc """
  OP_RETURN outputs are frequently used for placing arbitrary data on-chain.

  As this is generally used for creating unspendable outputs, no unlocking
  script is defined on this contract.

  ## Lock parameters

  * `:data` - A single binary or list of binary values.

  ## Examples

      iex> contract = OpReturn.lock(0, %{data: "hello world"})
      iex> Contract.to_script(contract)
      %Script{chunks: [
        :OP_FALSE,
        :OP_RETURN,
        "hello world"
      ]}

      iex> contract = OpReturn.lock(0, %{data: ["hello", "world"]})
      iex> Contract.to_script(contract)
      %Script{chunks: [
        :OP_FALSE,
        :OP_RETURN,
        "hello",
        "world"
      ]}
  """
  use BSV.Contract

  @impl true
  def locking_script(ctx, %{data: data}) do
    ctx
    |> op_false
    |> op_return
    |> push_data(data)
  end

  # TODO
  defp push_data(ctx, data) when is_list(data),
    do: Enum.reduce(data, ctx, & push(&2, &1))

  defp push_data(ctx, data), do: push(ctx, data)

end
