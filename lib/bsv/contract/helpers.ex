defmodule BSV.Contract.Helpers do
  @moduledoc """
  TODO
  """
  alias BSV.{Contract, OpCode, PrivKey, Sig, UTXO}

  # Iterrates over all opcodes
  # Defines a function to push the specified opcode onto the contract script
  Enum.each(OpCode.all(), fn {op, _} ->
    key = op
    |> Atom.to_string()
    |> String.downcase()
    |> String.to_atom()

    def unquote(key)(%Contract{} = contract) do
      Contract.script_push(contract, unquote(op))
    end
  end)

  @doc """
  TODO
  """
  def push(%Contract{} = contract, data) do
    Contract.script_push(contract, data)
  end

  @doc """
  TODO
  """
  def signature(
    %Contract{ctx: {tx, index}, opts: opts, subject: %UTXO{txout: txout}} = contract,
    %PrivKey{} = privkey
  ) do
    signature = Sig.sign(tx, index, txout, privkey, opts)
    Contract.script_push(contract, signature)
  end

  def signature(%Contract{ctx: nil} = contract, %PrivKey{} = _privkey),
    do: Contract.script_push(contract, <<0::568>>)

end
