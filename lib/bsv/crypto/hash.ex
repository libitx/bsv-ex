defmodule BSV.Crypto.Hash do
  @moduledoc """
  A collection of one-way hashing functions
  """

  @type hash_algorithm :: atom()
  @type encoding :: :hex

  @doc """
  Returns a list of supported hash algorithms.
  """
  @hash_algorithms [:md5, :ripemd160, :sha, :sha224, :sha256, :sha384, :sha512]
  @spec hash_algorithms() :: [hash_algorithm]
  def hash_algorithms, do: @hash_algorithms


  @doc """
  Computes the specified hash type on the given data.

  ## Examples

      iex> BSV.Crypto.Hash.hash("hello world", :md5)
      <<94, 182, 59, 187, 224, 30, 238, 208, 147, 203, 34, 187, 143, 90, 205, 195>>

      iex> BSV.Crypto.Hash.hash("hello world", :md5, :hex)
      "5eb63bbbe01eeed093cb22bb8f5acdc3"
  """
  @spec hash(binary(), hash_algorithm) :: binary()
  def hash(data, algorithm), do: :crypto.hash(algorithm, data)
  @spec hash(binary(), hash_algorithm, encoding) :: binary()
  def hash(data, algorithm, :hex), do: hash(data, algorithm) |> Base.encode16(case: :lower)


  @doc """
  Computes the RIPEMD hash of a given input, outputting 160 bits.

  ## Examples

      iex> BSV.Crypto.Hash.ripemd160("hello world")
      <<152, 198, 21, 120, 76, 203, 95, 229, 147, 111, 188, 12, 190, 157, 253, 180, 8, 217, 47, 15>>

      iex> BSV.Crypto.Hash.ripemd160("hello world", :hex)
      "98c615784ccb5fe5936fbc0cbe9dfdb408d92f0f"
  """
  @spec ripemd160(binary()) :: <<_::160>>
  def ripemd160(data), do: hash(data, :ripemd160)
  @spec ripemd160(binary(), encoding) :: binary()
  def ripemd160(data, :hex), do: hash(data, :ripemd160, :hex)


  @doc """
  Computes the SHA-1 hash of a given input, outputting 160 bits.

  ## Examples

      iex> BSV.Crypto.Hash.sha1("hello world")
      <<42, 174, 108, 53, 201, 79, 207, 180, 21, 219, 233, 95, 64, 139, 156, 233, 30, 232, 70, 237>>

      iex> BSV.Crypto.Hash.sha1("hello world", :hex)
      "2aae6c35c94fcfb415dbe95f408b9ce91ee846ed"
  """
  @spec sha1(binary()) :: <<_::160>>
  def sha1(data), do: hash(data, :sha)
  @spec sha1(binary(), encoding) :: binary()
  def sha1(data, :hex), do: hash(data, :sha, :hex)


  @doc """
  Computes the SHA-2 of a given input, outputting 256 bits.

  ## Examples

      iex> BSV.Crypto.Hash.sha256("hello world")
      <<185, 77, 39, 185, 147, 77, 62, 8, 165, 46, 82, 215, 218, 125, 171, 250, 196, 132, 239, 227, 122, 83, 128, 238, 144, 136, 247, 172, 226, 239, 205, 233>>

      iex> BSV.Crypto.Hash.sha256("hello world", :hex)
      "b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9"
  """
  @spec sha256(binary()) :: <<_::256>>
  def sha256(data), do: hash(data, :sha256)
  @spec sha256(binary(), encoding) :: binary()
  def sha256(data, :hex), do: hash(data, :sha256, :hex)


  @doc """
  Computes the SHA-2 of a given input, outputting 512 bits.

  ## Examples

      BSV.Crypto.Hash.sha512("hello world")

      iex> BSV.Crypto.Hash.sha512("hello world", :hex)
      "309ecc489c12d6eb4cc40f50c902f2b4d0ed77ee511a7c7a9bcd3ca86d4cd86f989dd35bc5ff499670da34255b45b0cfd830e81f605dcf7dc5542e93ae9cd76f"
  """
  @spec sha512(binary()) :: <<_::512>>
  def sha512(data), do: hash(data, :sha512)
  @spec sha512(binary(), encoding) :: binary()
  def sha512(data, :hex), do: hash(data, :sha512, :hex)


  @doc """
  Computes a RIPEMD0160 hash of a SHA256 hash, outputting 160 bits. This is commonly used inside Bitcoin, particularly for Bitcoin addresses.

  ## Examples

      iex> BSV.Crypto.Hash.sha256ripemd160("hello world")
      <<215, 213, 238, 120, 36, 255, 147, 249, 76, 48, 85, 175, 147, 130, 200, 108, 104, 181, 202, 146>>

      iex> BSV.Crypto.Hash.sha256ripemd160("hello world", :hex)
      "d7d5ee7824ff93f94c3055af9382c86c68b5ca92"
  """
  @spec sha256ripemd160(binary()) :: <<_::160>>
  def sha256ripemd160(data), do: sha256(data) |> hash(:ripemd160)
  @spec sha256ripemd160(binary(), encoding) :: binary()
  def sha256ripemd160(data, :hex), do: sha256(data) |> hash(:ripemd160, :hex)


  @doc """
  Computes a double SHA256 hash. This hash function is commonly used inside Bitcoin, particularly for the hash of a block and the hash of a transaction.

  ## Examples

      iex> BSV.Crypto.Hash.sha256sha256("hello world")
      <<188, 98, 212, 184, 13, 158, 54, 218, 41, 193, 108, 93, 77, 159, 17, 115, 31, 54, 5, 44, 114, 64, 26, 118, 194, 60, 15, 181, 169, 183, 68, 35>>

      iex> BSV.Crypto.Hash.sha256sha256("hello world", :hex)
      "bc62d4b80d9e36da29c16c5d4d9f11731f36052c72401a76c23c0fb5a9b74423"
  """
  @spec sha256sha256(binary()) :: <<_::256>>
  def sha256sha256(data), do: sha256(data) |> hash(:sha256)
  @spec sha256sha256(binary(), encoding) :: binary()
  def sha256sha256(data, :hex), do: sha256(data) |> hash(:sha256, :hex)

end