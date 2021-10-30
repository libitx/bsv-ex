defmodule BSV.TxIn do
  @moduledoc """
  A TxIn is a data structure representing a single input in a `t:BSV.Tx.t/0`.

  A TxIn consists of the `t:BSV.OutPoint.t/0` of the output which is being
  spent, a Script known as the unlocking script, and a sequence number.

  A TxIn spends a previous output by concatenation the unlocking script with the
  locking script in the order:

		  unlocking_script <> locking_script

  The entire script is evaluated and if it returns a truthy value, the output is
  unlocked and spent.

  When the sequence value is less that `0xFFFFFFFF` and that transaction
  locktime is set in the future, that transaction is considered non-final and
  will not be mined in a block. This mechanism can be used to build payment
  channels.
  """
  alias BSV.{OutPoint, Script, Serializable, VarInt}
  import BSV.Util, only: [decode: 2, encode: 2]

  @max_sequence 0xFFFFFFFF

  defstruct prevout: %OutPoint{}, script: %Script{}, sequence: @max_sequence

  @typedoc "TxIn struct"
  @type t() :: %__MODULE__{
    prevout: OutPoint.t(),
    script: Script.t(),
    sequence: non_neg_integer()
  }

  @doc """
  Returns true if the given `t:BSV.TxIn.t/0` is a coinbase input (the first
  input in a block, containing the miner block reward).
  """
  @spec coinbase?(t()) :: boolean()
  def coinbase?(%__MODULE__{prevout: outpoint}), do: OutPoint.is_null?(outpoint)

  @doc """
  Parses the given binary into a `t:BSV.TxIn.t/0`.

  Returns the result in an `:ok` / `:error` tuple pair.

  ## Options

  The accepted options are:

  * `:encoding` - Optionally decode the binary with either the `:base64` or `:hex` encoding scheme.
  """
  @spec from_binary(binary(), keyword()) :: {:ok, t()} | {:error, term()}
  def from_binary(data, opts \\ []) when is_binary(data) do
    encoding = Keyword.get(opts, :encoding)

    with {:ok, data} <- decode(data, encoding),
         {:ok, txin, _rest} <- Serializable.parse(%__MODULE__{}, data)
    do
      {:ok, txin}
    end
  end

  @doc """
  Parses the given binary into a `t:BSV.TxIn.t/0`.

  As `from_binary/2` but returns the result or raises an exception.
  """
  @spec from_binary!(binary(), keyword()) :: t()
  def from_binary!(data, opts \\ []) when is_binary(data) do
    case from_binary(data, opts) do
      {:ok, txin} ->
        txin

      {:error, error} ->
        raise BSV.DecodeError, error
    end
  end

  @doc """
  Returns the number of bytes of the given `t:BSV.TxIn.t/0`.
  """
  @spec size(t()) :: non_neg_integer()
  def size(%__MODULE__{} = txin),
    do: to_binary(txin) |> byte_size()

  @doc """
  Serialises the given `t:BSV.TxIn.t/0` into a binary.

  ## Options

  The accepted options are:

  * `:encoding` - Optionally encode the binary with either the `:base64` or `:hex` encoding scheme.
  """
  @spec to_binary(t()) :: binary()
  def to_binary(%__MODULE__{} = txin, opts \\ []) do
    encoding = Keyword.get(opts, :encoding)

    txin
    |> Serializable.serialize()
    |> encode(encoding)
  end


  defimpl Serializable do
    @impl true
    def parse(txin, data) do
      with {:ok, outpoint, data} <- Serializable.parse(%OutPoint{}, data),
           {:ok, script, data} <- VarInt.parse_data(data),
           <<sequence::little-32, rest::binary>> = data
      do
        script = case OutPoint.is_null?(outpoint) do
          false -> Script.from_binary!(script)
          true -> %Script{coinbase: script}
        end

        {:ok, struct(txin, [
          prevout: outpoint,
          script: script,
          sequence: sequence
        ]), rest}
      end
    end

    @impl true
    def serialize(%{prevout: outpoint, script: script, sequence: sequence}) do
      outpoint_data = Serializable.serialize(outpoint)
      script_data = script
      |> Script.to_binary()
      |> VarInt.encode_binary()

      <<
        outpoint_data::binary,
        script_data::binary,
        sequence::little-32
      >>
    end
  end

end
