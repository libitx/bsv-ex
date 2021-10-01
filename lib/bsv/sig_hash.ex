defmodule BSV.SigHash do
  @moduledoc """
  TODO
  """
  use Bitwise
  alias BSV.{Hash, OutPoint, Script, Tx, TxIn, TxOut, VarInt}

  @typedoc "TODO"
  @type t() :: <<_::256>>

  @typedoc "TODO"
  @type preimage() :: binary()

  @typedoc "TODO"
  @type sighash_type() :: integer()

  @sighash_all 0x01
  @sighash_none 0x02
  @sighash_single 0x03
  @sighash_forkid 0x40
  @sighash_anyonecanpay 0x80

  @default_sighash @sighash_all ||| @sighash_forkid

  defguard sighash_all?(sighash_type)
    when (sighash_type &&& 31) == @sighash_all

  defguard sighash_none?(sighash_type)
    when (sighash_type &&& 31) == @sighash_none

  defguard sighash_single?(sighash_type)
    when (sighash_type &&& 31) == @sighash_single

  defguard sighash_forkid?(sighash_type)
    when (sighash_type &&& @sighash_forkid) != 0

  defguard sighash_anyone_can_pay?(sighash_type)
    when (sighash_type &&& @sighash_anyonecanpay) != 0

  @doc """
  TODO
  """
  @spec preimage(Tx.t(), TxIn.t(), TxOut.t(), sighash_type()) :: preimage()
  def preimage(tx, input, utxo, sighash_type \\ @default_sighash)

  def preimage(%Tx{inputs: inputs} = tx, %TxIn{} = input, %TxOut{} = utxo, sighash_type)
    when sighash_forkid?(sighash_type)
    #and input in inputs
  do
    # Input prevouts/nSequence
    prevouts_hash = hash_prevouts(tx.inputs, sighash_type)
    sequence_hash = hash_sequence(tx.inputs, sighash_type)

    # outpoint (32-byte hash + 4-byte little endian)
    outpoint = OutPoint.to_binary(input.prev_out)

    # subscript
    subscript = utxo.script
    |> Script.to_binary()
    |> VarInt.encode_binary()

    # Outputs (none/one/all, depending on flags)
    txin_index = Enum.find_index(inputs, & &1 == input)
    outputs_hash = hash_outputs(tx.outputs, txin_index, sighash_type)

    <<
      tx.version::little-32,
      prevouts_hash::binary,
      sequence_hash::binary,
      outpoint::binary,
      subscript::binary,
      utxo.satoshis::little-64,
      input.sequence::little-32,
      outputs_hash::binary,
      tx.lock_time::little-32,
      (sighash_type >>> 0)::little-32
    >>
  end

  def preimage(%Tx{} = _tx, %TxIn{} = _input, %TxOut{} = _utxo, _sighash_type),
    do: raise "Legacy Sighash algorithm not implemented yet."

  @doc """
  TODO
  """
  @spec sighash(Tx.t(), TxIn.t(), TxOut.t(), sighash_type()) :: t()
  def sighash(%Tx{} = tx, %TxIn{} = input, %TxOut{} = utxo, sighash_type \\ @default_sighash) do
    tx
    |> preimage(input, utxo, sighash_type)
    |> Hash.sha256_sha256()
  end

  # TODO
  defp hash_prevouts(_inputs, sighash_type)
    when sighash_anyone_can_pay?(sighash_type),
    do: <<0::256>>

  defp hash_prevouts(inputs, _sighash_type) do
    inputs
    |> Enum.reduce(<<>>, & &2 <> OutPoint.to_binary(&1.prev_out))
    |> Hash.sha256_sha256()
  end

  # TODO
  defp hash_sequence(_inputs, sighash_type)
    when sighash_anyone_can_pay?(sighash_type)
    or sighash_single?(sighash_type)
    or sighash_none?(sighash_type),
    do: <<0::256>>

  defp hash_sequence(inputs, _sighash_type) do
    inputs
    |> Enum.reduce(<<>>, & &2 <> <<&1.sequence::little-32>>)
    |> Hash.sha256_sha256()
  end

  # TODO
  defp hash_outputs(outputs, txin_index, sighash_type)
    when sighash_single?(sighash_type)
    and txin_index < length(outputs)
  do
    outputs
    |> Enum.at(txin_index)
    |> TxOut.to_binary()
    |> Hash.sha256_sha256()
  end

  defp hash_outputs(outputs, _index, sighash_type)
    when not sighash_none?(sighash_type)
  do
    outputs
    |> Enum.reduce(<<>>, & &2 <> TxOut.to_binary(&1))
    |> Hash.sha256_sha256()
  end

  defp hash_outputs(_outputs, _index, _sighash_type),
    do: :binary.copy(<<0>>, 32)

end
