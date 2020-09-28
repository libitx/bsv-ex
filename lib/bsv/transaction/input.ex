defmodule BSV.Transaction.Input do
  @moduledoc """
  Module for parsing and serialising transaction inputs.
  """
  alias BSV.Script
  alias BSV.Transaction.Output
  alias BSV.Util
  alias BSV.Util.VarBin

  @max_sequence 0xFFFFFFFF
  @p2pkh_script_size 108

  defstruct output_txid: nil,
            output_index: nil,
            script: nil,
            sequence: @max_sequence,
            utxo: nil

  @typedoc "Transaction input"
  @type t :: %__MODULE__{
    output_txid: String.t,
    output_index: integer,
    script: binary,
    sequence: integer,
    utxo: Output.t
  }


  @doc """
  Parse the given binary into a transaction input. Returns a tuple containing
  the transaction input and the remaining binary data.

  ## Options

  The accepted options are:

  * `:encoding` - Optionally decode the binary with either the `:base64` or `:hex` encoding scheme.

  ## Examples

      BSV.Transaction.Input.parse(data)
      {%BSV.Trasaction.Input{}, ""}
  """
  @spec parse(binary, keyword) :: {__MODULE__.t, binary}
  def parse(data, options \\ []) do
    encoding = Keyword.get(options, :encoding)

    <<txid::bytes-32, index::little-32, data::binary>> = data
    |> Util.decode(encoding)
    {script, data} = VarBin.parse_bin(data)
    <<sequence::little-32, data::binary>> = data

    txid = txid |> Util.reverse_bin |> Util.encode(:hex)

    {struct(__MODULE__, [
      output_txid: txid,
      output_index: index,
      script: (if is_null(txid, index), do: Script.get_coinbase(script), else: Script.parse(script)),
      sequence: sequence
    ]), data}
  end


  @doc """
  Serialises the given transaction input struct into a binary.

  ## Options

  The accepted options are:

  * `:encode` - Optionally encode the returned binary with either the `:base64` or `:hex` encoding scheme.

  ## Examples

      BSV.Transaction.Input.serialize(input)
      <<binary>>
  """
  @spec serialize(__MODULE__.t, keyword) :: binary
  def serialize(%__MODULE__{} = input, options \\ []) do
    encoding = Keyword.get(options, :encoding)

    txid = input.output_txid
    |> Util.decode(:hex)
    |> Util.reverse_bin

    script = case input.script do
      %Script{} = s -> Script.serialize(s) |> VarBin.serialize_bin
      _ -> <<>>
    end

    <<
      txid::binary,
      input.output_index::little-32,
      script::binary,
      input.sequence::little-32
    >>
    |> Util.encode(encoding)
  end


  @doc """
  Returns the size of the given input. If the input has a script, it's actual
  size is calculated, otherwise a P2PKH input is estimated.
  """
  @spec get_size(__MODULE__.t) :: integer
  def get_size(%__MODULE__{script: script} = tx) do
    case script do
      nil -> 40 + @p2pkh_script_size
      %Script{chunks: []} -> 40 + @p2pkh_script_size
      _ -> serialize(tx) |> byte_size
    end
  end

  @doc """
  Gets whether this is a null input (coinbase transaction input).

  ## Examples

    iex> {%BSV.Transaction{inputs: [coinbase_input]}, ""} = BSV.Transaction.parse("01000000010000000000000000000000000000000000000000000000000000000000000000ffffffff0704ffff001d0104ffffffff0100f2052a0100000043410496b538e853519c726a2c91e61ec11600ae1390813a627c66fb8be7947be63c52da7589379515d4e0a604f8141781e62294721166bf621e73a82cbf2342c858eeac00000000", encoding: :hex)
    iex> BSV.Transaction.Input.is_null(coinbase_input)
    true

    iex> {%BSV.Transaction{inputs: [input]}, ""} = BSV.Transaction.parse("0100000001ae13d3386c0541b9f8528c7f215713e94c52279318090a95e39e5b123360ee48110000006a47304402206d0cf8f9ac8cadcb5061072ff28ca434620bbb0d442f9578d560e840a9cce90a022023aaae374be08838cb42cafd35459f140c6b440db45e6ecc007d9d5d95c89d504121036ce3ac90505e8ca49c0f43d5db1ebf67dc502d79518db2ab54e86947ab1c91fefeffffff01a0aae219020000001976a914ab1cad2d09eedfb15794cc01edc2141b7ccc587388ac77d50900", encoding: :hex)
    iex> BSV.Transaction.Input.is_null(input)
    false

  """
  @spec is_null(__MODULE__.t) :: boolean
  def is_null(%__MODULE__{output_txid: transaction, output_index: index}) do
    is_null(transaction, index)
  end

  @spec is_null(String.t(), non_neg_integer) :: boolean
  defp is_null(previous_transaction, previous_index) do
    previous_transaction == "0000000000000000000000000000000000000000000000000000000000000000" and previous_index == 0xFFFFFFFF
  end

end
