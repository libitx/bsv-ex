defmodule BSV.TxIn do
  @moduledoc """
  TODO
  """
  alias BSV.{OutPoint, Script, Serializable, VarInt}
  import BSV.Util, only: [decode: 2, encode: 2]

  @max_sequence 0xFFFFFFFF

  defstruct prev_output: %OutPoint{}, script: %Script{}, sequence: @max_sequence

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    prev_output: OutPoint.t(),
    script: Script.t(),
    sequence: integer()
  }

  @doc """
  TODO
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
  TODO
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
  TODO
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
           {:ok, script} <- Script.from_binary(script),
           <<sequence::little-32, rest::binary>> = data
      do
        {:ok, struct(txin, [
          prev_output: outpoint,
          script: script,
          sequence: sequence
        ]), rest}
      end
    end

    @impl true
    def serialize(%{prev_output: outpoint, script: script, sequence: sequence}) do
      outpoint_data = Serializable.serialize(outpoint)
      script_data = script
      |> Serializable.serialize()
      |> VarInt.encode_binary()

      <<
        outpoint_data::binary,
        script_data::binary,
        sequence::little-32
      >>
    end
  end

end
