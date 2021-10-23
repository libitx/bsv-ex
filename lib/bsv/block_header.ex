defmodule BSV.BlockHeader do
  @moduledoc """
  A block header is an 80 byte packet of information providing a summary of the
  `t:BSV.Block/0`.

  Contained within the block header is a Merkle root - the result of hashing all
  of the transactions contained in the block into a tree-like structure known as
  a Merkle tree. Given a transaction and `t:BSV.MerkleProof.t/0`, we can verify
  the transaction is contained in a block without downloading the entire block.
  """
  alias BSV.{Block, Serializable}
  import BSV.Util, only: [decode: 2, encode: 2]

  defstruct [:version, :prev_hash, :merkle_root, :time, :bits, :nonce]

  @typedoc "Block header struct"
  @type t() :: %__MODULE__{
    version: non_neg_integer(),
    prev_hash: <<_::256>>,
    merkle_root: Block.merkle_root(),
    time: non_neg_integer(),
    bits: non_neg_integer(),
    nonce: non_neg_integer()
  }

  @doc """
  Parses the given binary into a `t:BSV.BlockHeader.t/0`.

  Returns the result in an `:ok` / `:error` tuple pair.

  ## Options

  The accepted options are:

  * `:encoding` - Optionally decode the binary with either the `:base64` or `:hex` encoding scheme.
  """
  @spec from_binary(binary(), keyword()) :: {:ok, t()} | {:error, term()}
  def from_binary(data, opts \\ []) when is_binary(data) do
    encoding = Keyword.get(opts, :encoding)

    with {:ok, data} <- decode(data, encoding),
         {:ok, header, _rest} <- Serializable.parse(%__MODULE__{}, data)
    do
      {:ok, header}
    end
  end

  @doc """
  Parses the given binary into a `t:BSV.BlockHeader.t/0`.

  As `from_binary/2` but returns the result or raises an exception.
  """
  @spec from_binary!(binary(), keyword()) :: t()
  def from_binary!(data, opts \\ []) when is_binary(data) do
    case from_binary(data, opts) do
      {:ok, header} ->
        header

      {:error, error} ->
        raise BSV.DecodeError, error
    end
  end

  @doc """
  Serialises the given `t:BSV.BlockHeader.t/0` into a binary.

  ## Options

  The accepted options are:

  * `:encoding` - Optionally encode the binary with either the `:base64` or `:hex` encoding scheme.
  """
  @spec to_binary(t()) :: binary()
  def to_binary(%__MODULE__{} = header, opts \\ []) do
    encoding = Keyword.get(opts, :encoding)

    header
    |> Serializable.serialize()
    |> encode(encoding)
  end


  defimpl Serializable do
    @impl true
    def parse(header, data) do
      with <<
            version::little-32,
            prev_hash::binary-size(32),
            merkle_root::binary-size(32),
            time::little-32,
            bits::little-32,
            nonce::little-32,
            rest::binary
          >> <- data
      do
        {:ok, struct(header, [
          version: version,
          prev_hash: prev_hash,
          merkle_root: merkle_root,
          time: time,
          bits: bits,
          nonce: nonce
        ]), rest}
      else
        _data ->
          {:error, :invalid_header}
      end
    end

    @impl true
    def serialize(%{
      version: version,
      prev_hash: prev_hash,
      merkle_root: merkle_root,
      time: time,
      bits: bits,
      nonce: nonce
    }) do
      <<
        version::little-32,
        prev_hash::binary,
        merkle_root::binary,
        time::little-32,
        bits::little-32,
        nonce::little-32
      >>
    end
  end

end
