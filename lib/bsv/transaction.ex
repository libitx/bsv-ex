defmodule BSV.Transaction do
  @moduledoc """
  Module for the construction, parsing and serialization of Bitcoin transactions.
  """
  alias BSV.Crypto.Hash
  alias BSV.Address
  alias BSV.Script
  alias BSV.Transaction.{Input, Output}
  alias BSV.Util
  alias BSV.Util.VarBin

  defstruct version: 1, inputs: [], outputs: [], lock_time: 0

  @typedoc "Bitcoin Transaction"
  @type t :: %__MODULE__{
    version: integer,
    inputs: list,
    outputs: list,
    lock_time: integer
  }

  
  @doc """
  Parse the given binary into a transaction. Returns a tuple containing the
  transaction input and the remaining binary data.

  ## Options

  The accepted options are:

  * `:encoding` - Optionally decode the binary with either the `:base64` or `:hex` encoding scheme.

  ## Examples

      BSV.Transaction.parse(data)
      {%BSV.Trasaction{}, ""}
  """
  @spec parse(binary, keyword) :: {__MODULE__.t, binary}
  def parse(data, options \\ []) do
    encoding = Keyword.get(options, :encoding)

    <<version::little-32, data::binary>> = data |> Util.decode(encoding)
    {inputs, data} = data |> VarBin.parse_items(&Input.parse/1)
    {outputs, data} = data |> VarBin.parse_items(&Output.parse/1)
    <<lock_time::little-32, data::binary>> = data

    {struct(__MODULE__, [
      version: version,
      inputs: inputs,
      outputs: outputs,
      lock_time: lock_time
    ]), data}
  end


  @doc """
  Serialises the given transaction into a binary.

  ## Options

  The accepted options are:

  * `:encode` - Optionally encode the returned binary with either the `:base64` or `:hex` encoding scheme.

  ## Examples

      BSV.Transaction.Input.serialize(input)
      <<binary>>
  """
  @spec serialize(__MODULE__.t, keyword) :: binary
  def serialize(%__MODULE__{} = tx, options \\ []) do
    encoding = Keyword.get(options, :encoding)

    inputs = tx.inputs |> VarBin.serialize_items(&Input.serialize/1)
    outputs = tx.outputs |> VarBin.serialize_items(&Output.serialize/1)
    <<
      tx.version::little-32,
      inputs::binary,
      outputs::binary,
      tx.lock_time::little-32
    >>
    |> Util.encode(encoding)
  end


  @doc """
  Returns the given transaction's txid, which is a double SHA-256 hash of the
  transaction, reversed.
  """
  @spec get_txid(__MODULE__.t) :: String.t
  def get_txid(%__MODULE__{} = tx) do
    serialize(tx)
    |> Hash.sha256_sha256
    |> Util.reverse_bin
    |> Util.encode(:hex)
  end


  @doc """
  TODOC

  ## Examples

      iex> tx = %BSV.Transaction{}
      ...> |> BSV.Transaction.add_input(%BSV.Transaction.Input{})
      iex> length(tx.inputs) == 1
      true
  """
  @spec add_input(__MODULE__.t, Input.t) :: __MODULE__.t
  def add_input(%__MODULE__{} = tx, %Input{} = input) do
    inputs = Enum.concat(tx.inputs, [input])
    Map.put(tx, :inputs, inputs)
  end


  @doc """
  TODOC

  ## Examples

      iex> tx = %BSV.Transaction{}
      ...> |> BSV.Transaction.add_output(%BSV.Transaction.Output{})
      iex> length(tx.outputs) == 1
      true
  """
  @spec add_output(__MODULE__.t, Output.t) :: __MODULE__.t
  def add_output(%__MODULE__{} = tx, %Output{} = output) do
    outputs = Enum.concat(tx.outputs, [output])
    Map.put(tx, :outputs, outputs)
  end


  @doc """
  TODOC
  """
  @spec spend_from(__MODULE__.t, Input.t | list) :: __MODULE__.t
  def spend_from(tx, %Input{} = input) do
    case Enum.member?(tx.inputs, input) do
      true -> tx
      false -> add_input(tx, input)
    end
  end

  def spend_from(tx, inputs) when is_list(inputs) do
    Enum.each(inputs, &(spend_from(tx, &1)))
  end


  @doc """
  TODOC

  ## Examples

      iex> tx = %BSV.Transaction{}
      ...> |> BSV.Transaction.spend_to("15KgnG69mTbtkx73vNDNUdrWuDhnmfCxsf", 1000)
      iex> length(tx.outputs) == 1
      true
  """
  @spec spend_to(%__MODULE__{}, Address.t | binary, integer) :: __MODULE__.t
  def spend_to(tx, address, satoshis) do
    output = struct(Output, [
      satoshis: satoshis,
      script: Script.build_public_key_hash_out(address)
    ])
    add_output(tx, output)
  end
end