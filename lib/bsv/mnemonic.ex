defmodule BSV.Mnemonic do
  @moduledoc """
  Module for generating and restoring mnemonic phrases, for the generation of
  deterministic keys. Implements BIP-39.

  A mnemonic phrase is a group of easy to remember words. The phrase can be
  converted to a binary seed, which in turn is used to generate deterministic
  keys.
  """
  alias BSV.Crypto.Hash
  alias BSV.Util

  @typedoc "Mnemonic phrase"
  @type t :: String.t

  @words :code.priv_dir(:bsv)
         |> Path.join("words.txt")
         |> File.stream!()
         |> Stream.map(&String.trim/1)
         |> Enum.to_list()

  @allowed_lengths [128, 160, 192, 224, 256]

  @rounds 2048

  
  @doc """
  Returns the mnemonic word list.
  """
  @spec words :: list
  def words, do: @words


  @doc """
  Returns a list of the allowed mnemonic entropy lengths.
  """
  @spec allowed_lengths :: list
  def allowed_lengths, do: @allowed_lengths


  @doc """
  Generates a new mnemonic phrase from the given entropy length (defaults to
  256 bits / 24 words). 

  ## Examples

      iex> BSV.Mnemonic.generate
      ...> |> String.split
      ...> |> length
      24

      iex> BSV.Mnemonic.generate(128)
      ...> |> String.split
      ...> |> length
      12
  """
  @spec generate(integer) :: __MODULE__.t
  def generate(entropy_length \\ List.last(@allowed_lengths))

  def generate(entropy_length)
    when not (entropy_length in @allowed_lengths),
    do: {:error, "Entropy length must be one of #{inspect(@allowed_lengths)}"}

  def generate(entropy_length) do
    div(entropy_length, 8)
    |> Util.random_bytes
    |> from_entropy
  end


  @doc """
  Returns a mnemonic phrase derived from the given binary.

  ## Examples

      iex> BSV.Test.mnemonic_entropy
      ...> |> BSV.Mnemonic.from_entropy
      "organ boring cushion feature wheat juice quality replace concert baby topic scrub"
  """
  @spec from_entropy(binary) :: __MODULE__.t
  def from_entropy(entropy) when is_binary(entropy) do
    <<entropy::bits, checksum(entropy)::bits>>
    |> mnemonic
  end


  @doc """
  Returns a binary derived from the given mnemonic phrase.

  ## Examples

      iex> "organ boring cushion feature wheat juice quality replace concert baby topic scrub"
      ...> |> BSV.Mnemonic.to_entropy
      <<156, 99, 60, 217, 170, 31, 158, 241, 171, 205, 182, 46, 162, 35, 148, 96>>
  """
  @spec to_entropy(__MODULE__.t) :: binary
  def to_entropy(mnemonic) do
    String.split(mnemonic)
    |> Enum.map(&word_index/1)
    |> entropy
  end


  @doc """
  Returns a wallet seed derived from the given mnemonic phrase and optionally a
  passphrase.

  ## Options

  The accepted options are:

  * `:passphrase` - Optionally protect the seed with an additional passphrase
  * `:encoding` - Optionally encode the seed with either the `:base64` or `:hex` encoding scheme.

  ## Examples

      iex> BSV.Mnemonic.from_entropy(BSV.Test.mnemonic_entropy)
      ...> |> BSV.Mnemonic.to_seed(encoding: :hex)
      "380823f725beb7846806d0b88590a0823ea81c0b88cd151f7295772bbe48bbffa9b0f131dce77c4a7168925d466270c12bc0073db917da9f2bb1f4ac59e9fa3b"

      iex> BSV.Mnemonic.from_entropy(BSV.Test.mnemonic_entropy)
      ...> |> BSV.Mnemonic.to_seed(passphrase: "my wallet")
      ...> |> byte_size
      64
  """
  @spec to_seed(__MODULE__.t, keyword) :: binary
  def to_seed(mnemonic, options \\ []) do
    passphrase = Keyword.get(options, :passphrase, "")
    encoding = Keyword.get(options, :encoding)

    <<"mnemonic", passphrase::binary, 1::integer-32>>
    |> Hash.hmac(:sha512, mnemonic)
    |> pbkdf2(mnemonic)
    |> Util.encode(encoding)
  end


  defp checksum(entropy) do
    with size <- bit_size(entropy) |> div(32),
         <<checksum::bits-size(size), _::bits>> <- Hash.sha256(entropy),
         do: checksum
  end

  defp mnemonic(entropy) do
    chunks = for <<chunk::11 <- entropy>>, do: Enum.at(words(), chunk)
    Enum.join(chunks, " ")
  end

  defp entropy(indices) do
    bytes = for i <- indices, into: <<>>, do: <<i::11>>
    with size = bit_size(bytes) |> Kernel.*(32) |> div(33),
         <<entropy::bits-size(size), _::bits>> <- bytes,
         do: entropy
  end

  defp word_index(word), do: Enum.find_index(words(), &(&1 == word))

  defp pbkdf2(hmac_block, mnemonic) do
    iterate(mnemonic, 1, hmac_block, hmac_block)
  end

  defp iterate(_mnemonic, round_num, _hmac_block, result)
    when round_num == @rounds,
    do: result

  defp iterate(mnemonic, round_num, hmac_block, result) do
    with next_block <- Hash.hmac(hmac_block, :sha512, mnemonic),
         result <- :crypto.exor(next_block, result),
         do: iterate(mnemonic, round_num + 1, next_block, result)
  end

end