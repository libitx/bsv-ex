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
  Pushes the given data onto the script.
  """
  @spec push(Contract.t(), atom() | binary() | integer()) :: Contract.t()
  def push(%Contract{} = contract, data) do
    Contract.script_push(contract, data)
  end

  @doc """
  Pushes the given list of data onto the script in seperate pushes.
  """
  @spec push_all(Contract.t(), list(atom() | binary() | integer())) :: Contract.t()
  def push_all(%Contract{} = contract, []), do: contract
  def push_all(%Contract{} = contract, [data | rest]) do
    contract
    |> push(data)
    |> push_all(rest)
  end

  @doc """
  Signs the transaction [`context`](`t:BSV.Contract.ctx/0`) and pushes the
  signature onto the stack.

  If no context is available in the [`contract`](`t:BSV.Contract.t/0`), then
  71 bytes of zeros are pushed onto the stack instead.
  """
  @spec sig(Contract.t(), PrivKey.t()) :: Contract.t()
  def sig(
    %Contract{ctx: {tx, index}, opts: opts, subject: %UTXO{txout: txout}} = contract,
    %PrivKey{} = privkey
  ) do
    signature = Sig.sign(tx, index, txout, privkey, opts)
    Contract.script_push(contract, signature)
  end

  def sig(%Contract{ctx: nil} = contract, %PrivKey{} = _privkey),
    do: Contract.script_push(contract, <<0::568>>)

  @doc """
  TODO
  """
  @spec multi_sig(Contract.t(), list(PrivKey.t())) :: Contract.t()
  def multi_sig(ctx, []), do: ctx
  def multi_sig(ctx, [privkey | privkeys]) do
    ctx
    |> sig(privkey)
    |> multi_sig(privkeys)
  end

end
