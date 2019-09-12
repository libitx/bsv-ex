defmodule BSV.Crypto.Hash do
  @moduledoc """
  A collection of one-way hashing functions.
  """
  alias BSV.Util

  @hash_algorithms [:md5, :ripemd160, :sha, :sha224, :sha256, :sha384, :sha512]


  @doc """
  Returns a list of supported hash algorithms.
  """
  @spec hash_algorithms :: list
  def hash_algorithms, do: @hash_algorithms


  @doc """
  Computes a hash of the given data, using the specified hash algorithm.

  ## Options

  The accepted hash algorithms are:

  * `:md5` - MD5 message-digest algorithm (128 bit)
  * `:ripemd160` - RIPE Message Digest algorithm (160 bit)
  * `:sha` - Secure Hash Algorithm 1 (SHA-1) (160 bit)
  * `:sha224` - Secure Hash Algorithm 2 (SHA-2) (224 bit)
  * `:sha256` - Secure Hash Algorithm 2 (SHA-2) (256 bit)
  * `:sha384` - Secure Hash Algorithm 2 (SHA-2) (384 bit)
  * `:sha512` - Secure Hash Algorithm 2 (SHA-2) (512 bit)

  The accepted options are:

  * `:encode` - Optionally encode the returned hash with either the `:base64` or `:hex` encoding scheme.

  ## Examples

      iex> BSV.Crypto.Hash.hash("hello world", :sha256)
      <<185, 77, 39, 185, 147, 77, 62, 8, 165, 46, 82, 215, 218, 125, 171, 250, 196, 132, 239, 227, 122, 83, 128, 238, 144, 136, 247, 172, 226, 239, 205, 233>>

      iex> BSV.Crypto.Hash.hash("hello world", :sha256, encode: :hex)
      "b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9"

      iex> BSV.Crypto.Hash.hash("hello world", :sha256, encode: :base64)
      "uU0nuZNNPgilLlLX2n2r+sSE7+N6U4DukIj3rOLvzek="
  """
  @spec hash(binary, atom, keyword) :: binary
  def hash(data, algorithm, options \\ []) do
    encoding = Keyword.get(options, :encode)
    :crypto.hash(algorithm, data)
    |> Util.encode(encoding)
  end


  @doc """
  Computes the RIPEMD hash of a given input, outputting 160 bits.

  See `BSV.Crypto.Hash.hash/3` for the accepted options.

  ## Examples

      iex> BSV.Crypto.Hash.ripemd160("hello world")
      <<152, 198, 21, 120, 76, 203, 95, 229, 147, 111, 188, 12, 190, 157, 253, 180, 8, 217, 47, 15>>

      iex> BSV.Crypto.Hash.ripemd160("hello world", encode: :hex)
      "98c615784ccb5fe5936fbc0cbe9dfdb408d92f0f"
  """
  @spec ripemd160(binary, keyword) :: binary
  def ripemd160(data, options \\ []), do: hash(data, :ripemd160, options)


  @doc """
  Computes the SHA-1 hash of a given input, outputting 160 bits.

  See `BSV.Crypto.Hash.hash/3` for the accepted options.

  ## Examples

      iex> BSV.Crypto.Hash.sha1("hello world")
      <<42, 174, 108, 53, 201, 79, 207, 180, 21, 219, 233, 95, 64, 139, 156, 233, 30, 232, 70, 237>>

      iex> BSV.Crypto.Hash.sha1("hello world", encode: :hex)
      "2aae6c35c94fcfb415dbe95f408b9ce91ee846ed"
  """
  @spec sha1(binary, keyword) :: binary
  def sha1(data, options \\ []), do: hash(data, :sha, options)


  @doc """
  Computes the SHA-2 hash of a given input, outputting 256 bits.

  See `BSV.Crypto.Hash.hash/3` for the accepted options.

  ## Examples

      iex> BSV.Crypto.Hash.sha256("hello world")
      <<185, 77, 39, 185, 147, 77, 62, 8, 165, 46, 82, 215, 218, 125, 171, 250, 196, 132, 239, 227, 122, 83, 128, 238, 144, 136, 247, 172, 226, 239, 205, 233>>

      iex> BSV.Crypto.Hash.sha256("hello world", encode: :hex)
      "b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9"
  """
  @spec sha256(binary, keyword) :: binary
  def sha256(data, options \\ []), do: hash(data, :sha256, options)


  @doc """
  Computes the SHA-2 hash of a given input, outputting 512 bits.

  See `BSV.Crypto.Hash.hash/3` for the accepted options.

  ## Examples

      iex> BSV.Crypto.Hash.sha512("hello world", encode: :hex)
      "309ecc489c12d6eb4cc40f50c902f2b4d0ed77ee511a7c7a9bcd3ca86d4cd86f989dd35bc5ff499670da34255b45b0cfd830e81f605dcf7dc5542e93ae9cd76f"

      iex> BSV.Crypto.Hash.sha512("hello world", encode: :base64)
      "MJ7MSJwS1utMxA9QyQLytNDtd+5RGnx6m808qG1M2G+YndNbxf9JlnDaNCVbRbDP2DDoH2Bdz33FVC6TrpzXbw=="
  """
  @spec sha512(binary, keyword) :: binary
  def sha512(data, options \\ []), do: hash(data, :sha512, options)


  @doc """
  Computes a RIPEMD0160 hash of a SHA256 hash, outputting 160 bits. This is
  commonly used inside Bitcoin, particularly for Bitcoin addresses.

  See `BSV.Crypto.Hash.hash/3` for the accepted options.

  ## Examples

      iex> BSV.Crypto.Hash.sha256_ripemd160("hello world")
      <<215, 213, 238, 120, 36, 255, 147, 249, 76, 48, 85, 175, 147, 130, 200, 108, 104, 181, 202, 146>>

      iex> BSV.Crypto.Hash.sha256_ripemd160("hello world", encode: :hex)
      "d7d5ee7824ff93f94c3055af9382c86c68b5ca92"
  """
  @spec sha256_ripemd160(binary, keyword) :: binary
  def sha256_ripemd160(data, options \\ []), do: sha256(data) |> hash(:ripemd160, options)


  @doc """
  Computes a double SHA256 hash. This hash function is commonly used inside
  Bitcoin, particularly for the hash of a block and the hash of a transaction.

  See `BSV.Crypto.Hash.hash/3` for the accepted options.

  ## Examples

      iex> BSV.Crypto.Hash.sha256_sha256("hello world")
      <<188, 98, 212, 184, 13, 158, 54, 218, 41, 193, 108, 93, 77, 159, 17, 115, 31, 54, 5, 44, 114, 64, 26, 118, 194, 60, 15, 181, 169, 183, 68, 35>>

      iex> BSV.Crypto.Hash.sha256_sha256("hello world", encode: :hex)
      "bc62d4b80d9e36da29c16c5d4d9f11731f36052c72401a76c23c0fb5a9b74423"
  """
  @spec sha256_sha256(binary, keyword) :: binary
  def sha256_sha256(data, options \\ []), do: sha256(data) |> hash(:sha256, options)

end