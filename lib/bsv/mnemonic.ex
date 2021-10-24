defmodule BSV.Mnemonic do
  @moduledoc """
  A Mnemonic is a string of words representing a large randomly generated
  number, making it easier for humans to store.

  The words are converted to a `t:BSV.Mnemonic.seed/0` which are used to
  create a new `t:BSV.ExtKey.t/0`.

  This module implemented [BIP-39](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki).
  """
  alias BSV.Hash
  import BSV.Util, only: [encode: 2, rand_bytes: 1]

  @typedoc "Mnemonic phrase"
  @type t() :: String.t()

  @typedoc "Entropy length"
  @type entropy_length() :: 128 | 160 | 192 | 224 | 256

  @typedoc "Mnemomic seed"
  @type seed() :: <<_::512>>

  @lang Application.get_env(:bsv, :lang, "en")

  @wordlist :code.priv_dir(:bsv)
            |> Path.join("bip39/#{ @lang }.txt")
            |> File.stream!()
            |> Stream.map(&String.trim/1)
            |> Enum.to_list()

  @allowed_lengths [128, 160, 192, 224, 256]

  @rounds 2048

  @doc """
  Generates and returns a new random `t:BSV.Mnemonic.t/0` of the specified
  `t:BSV.Mnemonic.entropy_length/0`.
  """
  @spec new(entropy_length()) :: t()
  def new(entropy_bits \\ 128) when entropy_bits in @allowed_lengths do
    entropy_bits
    |> div(8)
    |> rand_bytes()
    |> from_entropy()
  end

  @doc """
  Generates and returns a new `t:BSV.Mnemonic.t/0` using the given binary.

  The binary entropy must be of a valid `t:BSV.Mnemonic.entropy_length/0`.
  """
  @spec from_entropy(binary()) :: t()
  def from_entropy(entropy)
    when is_binary(entropy) and bit_size(entropy) in @allowed_lengths,
    do: mnemonic(<<entropy::bits, checksum(entropy)::bits>>)

  @doc """
  Returns the entropy from the given `t:BSV.Mnemonic.t/0`.
  """
  @spec to_entropy(t()) :: binary()
  def to_entropy(mnemonic) when is_binary(mnemonic) do
    String.split(mnemonic)
    |> Enum.map(&word_index/1)
    |> entropy()
  end

  @doc """
  Converts the given `t:BSV.Mnemonic.t/0` into a `t:BSV.Mnemonic.seed/0` used
  to create an extended master key.

  Optionally a passphrase (sometimes known as the 13th or 25th word) can be
  added to the mnemonic to modify the returned seed.

  ## Options

  The accepted options are:

  * `:encoding` - Optionally encode the seed with either the `:base64` or `:hex` encoding scheme.
  * `:passphrase` - Optionally secure the seed with an additional passphrase.

  ## Examples

      iex> Mnemonic.to_seed("six clarify that goddess door gain stick gentle vault bread taxi champion", encoding: :hex)
      "23c406db4d7f9abd318746e4edcc06290973f65cd9eb610d28f5260bdbdf907bace3de7f968d83622c4871fd99777b61611bae18046bc2dbb415f7f1799a43e0"

      iex> Mnemonic.to_seed("six clarify that goddess door gain stick gentle vault bread taxi champion", passphrase: "testing", encoding: :hex)
      "266f2ea4cd63fd190c3f46b35e6a7da63691c8dc2aa9e57fd362674555c5339f2839e54da6530c547653e263978726a775a16209c3cf80ac23cc2594bebd2301"
  """
  @spec to_seed(t(), keyword()) :: seed()
  def to_seed(mnemonic, opts \\ []) when is_binary(mnemonic) do
    passphrase = Keyword.get(opts, :passphrase, "")
    encoding = Keyword.get(opts, :encoding)

    <<"mnemonic", passphrase::binary, 1::integer-32>>
    |> Hash.sha512_hmac(mnemonic)
    |> pbkdf2(mnemonic)
    |> encode(encoding)
  end

  @doc false
  @spec wordlist() :: list()
  def wordlist(), do: @wordlist

  # Add a checksum to the entropy
  defp checksum(entropy) do
    size = div(bit_size(entropy), 32)
    <<checksum::bits-size(size), _::bits>> = Hash.sha256(entropy)
    checksum
  end

  # Convert the entropy into a mnemonic phrase
  defp mnemonic(entropy) do
    chunks = for <<chunk::11 <- entropy>>, do: Enum.at(wordlist(), chunk)
    Enum.join(chunks, " ")
  end

  # Convert the wordlist indices into entropy
  defp entropy(indices) do
    bytes = for i <- indices, into: <<>>, do: <<i::11>>
    size = div(bit_size(bytes) * 32, 33)
    <<entropy::bits-size(size), _::bits>> = bytes
    entropy
  end

  # Return the index of the given word
  defp word_index(word),
    do: Enum.find_index(wordlist(), &(&1 == word))

  # PBKDF2 function
  defp pbkdf2(hmac_block, mnemonic),
    do: iterate(mnemonic, 1, hmac_block, hmac_block)

  # PBKDF2 iterate function
  defp iterate(_mnemonic, round_num, _hmac_block, result)
    when round_num == @rounds,
    do: result

  defp iterate(mnemonic, round_num, hmac_block, result) do
    next_block = Hash.sha512_hmac(hmac_block, mnemonic)
    result = :crypto.exor(next_block, result)
    iterate(mnemonic, round_num + 1, next_block, result)
  end

end
