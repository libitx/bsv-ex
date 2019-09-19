defmodule BSV.Mnemonic do
  @moduledoc """
  Module for generating and restoring mnemonic phrases, implementing BIP-39.
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
  @spec generate(integer) :: BSV.Mnemonic.t
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
  @spec from_entropy(binary) :: BSV.Mnemonic.t
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
  @spec to_entropy(BSV.Mnemonic.t) :: binary
  def to_entropy(mnemonic) do
    String.split(mnemonic)
    |> Enum.map(&word_index/1)
    |> entropy
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

end