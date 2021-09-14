defmodule BSV.Mnemonic do
  @moduledoc """
  TODO
  """
  alias BSV.Hash
  import BSV.Util, only: [encode: 2, rand_bytes: 1]

  @typedoc "TODO"
  @type t() :: String.t()

  @typedoc "TODO"
  @type entropy_length() :: 128 | 160 | 192 | 224 | 256

  @lang Application.get_env(:bsv, :lang, "en")

  @wordlist :code.priv_dir(:bsv)
            |> Path.join("bip39/#{ @lang }.txt")
            |> File.stream!()
            |> Stream.map(&String.trim/1)
            |> Enum.to_list()

  @allowed_lengths [128, 160, 192, 224, 256]

  @rounds 2048

  @doc """
  TODO
  """
  @spec wordlist() :: list()
  def wordlist(), do: @wordlist

  @doc """
  TODO
  """
  @spec new(entropy_length()) :: t()
  def new(entropy_bits \\ 128) when entropy_bits in @allowed_lengths do
    entropy_bits
    |> div(8)
    |> rand_bytes()
    |> from_entropy()
  end

  @doc """
  TODO
  """
  @spec from_entropy(binary()) :: t()
  def from_entropy(entropy)
    when is_binary(entropy) and bit_size(entropy) in @allowed_lengths,
    do: mnemonic(<<entropy::bits, checksum(entropy)::bits>>)

  @doc """
  TODO
  """
  @spec to_entropy(t()) :: binary()
  def to_entropy(mnemonic) when is_binary(mnemonic) do
    String.split(mnemonic)
    |> Enum.map(&word_index/1)
    |> entropy()
  end

  @doc """
  TODO
  """
  def to_seed(mnemonic, opts \\ []) when is_binary(mnemonic) do
    passphrase = Keyword.get(opts, :passphrase, "")
    encoding = Keyword.get(opts, :encoding)

    <<"mnemonic", passphrase::binary, 1::integer-32>>
    |> Hash.sha512_hmac(mnemonic)
    |> pbkdf2(mnemonic)
    |> encode(encoding)
  end

  # TODO
  defp checksum(entropy) do
    size = div(bit_size(entropy), 32)
    <<checksum::bits-size(size), _::bits>> = Hash.sha256(entropy)
    checksum
  end

  # TODO
  defp mnemonic(entropy) do
    chunks = for <<chunk::11 <- entropy>>, do: Enum.at(wordlist(), chunk)
    Enum.join(chunks, " ")
  end

  # TODO
  defp entropy(indices) do
    bytes = for i <- indices, into: <<>>, do: <<i::11>>
    size = div(bit_size(bytes) * 32, 33)
    <<entropy::bits-size(size), _::bits>> = bytes
    entropy
  end

  # TODO
  defp word_index(word),
    do: Enum.find_index(wordlist(), &(&1 == word))

  # TODO
  defp pbkdf2(hmac_block, mnemonic),
    do: iterate(mnemonic, 1, hmac_block, hmac_block)

  # TODO
  defp iterate(_mnemonic, round_num, _hmac_block, result)
    when round_num == @rounds,
    do: result

  # TODO
  defp iterate(mnemonic, round_num, hmac_block, result) do
    next_block = Hash.sha512_hmac(hmac_block, mnemonic)
    result = :crypto.exor(next_block, result)
    iterate(mnemonic, round_num + 1, next_block, result)
  end

end
