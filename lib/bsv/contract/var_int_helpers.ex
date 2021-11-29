defmodule BSV.Contract.VarIntHelpers do
  @moduledoc """
  Helper module for working with `t:BSV.VarInt.t/0` in `BSV.Contract` modules.

  VarInts are commonly used in Bitcoin scripts to encode variable length bits of
  data. This module provides a number of functions for extracting the data from
  VarInts.
  """
  alias BSV.Contract
  import BSV.Contract.Helpers
  import BSV.Contract.OpCodeHelpers

  @doc """
  Assuming the top stack item is a VarInt encoded binary, the VarInt is
  extracted and placed on top of the stack as a ScriptNum.

  The original element is not removed.

  Use this function if you would like to to extract the VarInt number, yet leave
  the original data on the stack.
  """
  @spec get_varint(Contract.t()) :: Contract.t()
  def get_varint(%Contract{} = contract) do
    contract
    |> op_dup()
    |> varint_switch(&do_get_varint/2)
  end

  # Extract and decode the VarInt number
  defp do_get_varint(contract, 1) do
    contract
    |> op_nip()
    |> decode_uint(:little)
  end

  defp do_get_varint(contract, bytes) do
    contract
    |> op_drop()
    |> push(bytes)
    |> op_split()
    |> op_drop()
    |> decode_uint(:little)
  end

  @doc """
  Assuming the top stack item is a VarInt encoded binary, the VarInt encoded
  data is extracted and placed on top of the stack as a ScriptNum.

  The original element is removed and any remaining data is second on the stack.

  Use this function if the VarInt is part of a larger string of bytes and you
  would like to extract the data whilst retaining the remaining bytes.
  """
  @spec read_varint(Contract.t()) :: Contract.t()
  def read_varint(%Contract{} = contract),
    do: varint_switch(contract, &do_read_varint/2)

  # Extract the VarInt data and place on top
  defp do_read_varint(contract, 1) do
    contract
    |> decode_uint(:little)
    |> op_split()
    |> op_swap()
  end

  defp do_read_varint(contract, bytes) do
    contract
    |> op_drop()
    |> push(bytes)
    |> op_split()
    |> op_swap()
    |> decode_uint(:little)
    |> op_split()
    |> op_swap()
  end

  @doc """
  Assuming the top stack item is a VarInt encoded binary, the VarInt prefix
  is trimmed from the leading bytes and the encoded data is placed on top of the
  stack.

  The original element is removed.

  Use this function if the VarInt is **not** part of a larger string of bytes
  and you would like to cleanly trim the VarInt number from the leading bytes.
  """
  @spec trim_varint(Contract.t()) :: Contract.t()
  def trim_varint(%Contract{} = contract),
    do: varint_switch(contract, &do_trim_varint/2)

  # Trim varint from leading bytes
  defp do_trim_varint(contract, 1), do: op_drop(contract)

  defp do_trim_varint(contract, bytes) do
    contract
    |> op_drop()
    |> trim(bytes)
  end

  # Shared VarInt switch statement
  defp varint_switch(contract, handle_varint)
    when is_function(handle_varint)
  do
    contract
    |> op_1()
    |> op_split()
    |> op_swap()
    |> op_dup()
    |> push(<<253>>)
    |> op_equal()
    |> op_if(&handle_varint.(&1, 2), fn contract ->
      contract
      |> op_dup()
      |> push(<<254>>)
      |> op_equal()
      |> op_if(&handle_varint.(&1, 4), fn contract ->
        contract
        |> op_dup()
        |> push(<<255>>)
        |> op_equal()
        |> op_if(&handle_varint.(&1, 8), &handle_varint.(&1, 1))
      end)
    end)
  end

end
