defmodule BSV.Contract.Helpers do
  @moduledoc """
  Collection of helpers functions for use in `BSV.Contract` modules.
  """
  alias BSV.{Contract, OpCode, PrivKey, Sig, UTXO}

  # Iterrates over all opcodes
  # Defines a function to push the specified opcode onto the contract script
  Enum.each(OpCode.all(), fn {op, _} ->
    key = op
    |> Atom.to_string()
    |> String.downcase()
    |> String.to_atom()

    @doc "Pushes `#{op}` onto the script."
    @spec unquote(key)(Contract.t()) :: Contract.t()
    def unquote(key)(%Contract{} = contract) do
      Contract.script_push(contract, unquote(op))
    end
  end)

  @doc """
  Pushes the given data onto the script. If a list of data elements is given,
  each will be pushed to the script as seperate pushdata elements.
  """
  @spec push(
      Contract.t(),
      atom() | binary() | integer() |
      list(atom() | binary() | integer())
    ) ::Contract.t()
  def push(%Contract{} = contract, []), do: contract
  def push(%Contract{} = contract, [data | rest]) do
    contract
    |> push(data)
    |> push(rest)
  end

  def push(%Contract{} = contract, data) do
    Contract.script_push(contract, data)
  end

  @doc """
  Reverses the top item on the stack.

  This helper function pushes op codes on to the script that will reverse a
  binary of the given length.
  """
  @spec reverse_bin(Contract.t(), integer()) :: Contract.t()
  def reverse_bin(%Contract{} = contract, length)
    when is_integer(length) and length > 1
  do
    loops = div(length-1, 16)
    bytes = rem(length-1, 16)

    rev_loops(contract, loops, bytes)
  end

  defp rev_loops(contract, 0, 0), do: contract

  defp rev_loops(contract, 0, bytes) do
    rev_bytes(contract, bytes)
  end

  defp rev_loops(contract, loops, bytes) do
    contract
    |> op_16()
    |> op_split()
    |> op_swap()
    |> rev_bytes(15)
    |> op_swap()
    |> rev_loops(loops-1, bytes)
    |> op_swap()
    |> op_cat()
  end

  defp rev_bytes(contract, 0), do: contract
  defp rev_bytes(contract, n) when n <= 16 do
    contract
    |> Contract.script_push(:"OP_#{n}")
    |> op_split()
    |> op_swap()
    |> rev_bytes(n-1)
    |> op_cat()
  end

  @doc """
  Signs the transaction [`context`](`t:BSV.Contract.ctx/0`) and pushes the
  signature onto the script.

  A list of private keys can be given, in which case each is used to sign and
  multiple signatures are added.

  If no context is available in the [`contract`](`t:BSV.Contract.t/0`), then
  71 bytes of zeros are pushed onto the script for each private key.
  """
  @spec sig(Contract.t(), PrivKey.t() | list(PrivKey.t())) :: Contract.t()
  def sig(%Contract{} = contract, []), do: contract
  def sig(%Contract{} = contract, [privkey | rest]) do
    contract
    |> sig(privkey)
    |> sig(rest)
  end

  def sig(
    %Contract{ctx: {tx, index}, opts: opts, subject: %UTXO{txout: txout}} = contract,
    %PrivKey{} = privkey
  ) do
    signature = Sig.sign(tx, index, txout, privkey, opts)
    Contract.script_push(contract, signature)
  end

  def sig(%Contract{ctx: nil} = contract, %PrivKey{} = _privkey),
    do: Contract.script_push(contract, <<0::568>>)

end
