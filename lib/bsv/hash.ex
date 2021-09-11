defmodule BSV.Hash do
  @moduledoc """
  A collection of one-way hashing functions used frequently throughout Bitcoin.

  All hashing functions accept the `:encoding` option which can be either
  `:base64` or `:hex`.
  """
  import BSV.Util, only: [encode: 2]

  @doc """
  Computes the RIPEMD hash of a given input, outputting 160 bits.

  ## Examples

      iex> BSV.Hash.ripemd160("hello world")
      <<152, 198, 21, 120, 76, 203, 95, 229, 147, 111, 188, 12, 190, 157, 253, 180, 8, 217, 47, 15>>

      iex> BSV.Hash.ripemd160("hello world", encoding: :hex)
      "98c615784ccb5fe5936fbc0cbe9dfdb408d92f0f"
  """
  @spec ripemd160(binary(), keyword()) :: binary()
  def ripemd160(data, opts \\ []) when is_binary(data),
    do: hash(data, :ripemd160, opts)

  @doc """
  Computes the SHA-1 hash of a given input, outputting 160 bits.

  ## Examples

      iex> BSV.Hash.sha1("hello world")
      <<42, 174, 108, 53, 201, 79, 207, 180, 21, 219, 233, 95, 64, 139, 156, 233, 30, 232, 70, 237>>

      iex> BSV.Hash.sha1("hello world", encoding: :hex)
      "2aae6c35c94fcfb415dbe95f408b9ce91ee846ed"
  """
  @spec sha1(binary(), keyword()) :: binary()
  def sha1(data, opts \\ []) when is_binary(data),
    do: hash(data, :sha, opts)

  @doc """
  Computes the HMAC of the of the given input using a secret key and the SHA-1
  algorithm.

  ## Examples

      iex> BSV.Hash.sha1_hmac("hello world", "test")
      <<90, 9, 227, 4, 243, 198, 13, 99, 63, 241, 103, 53, 236, 147, 30, 17, 22, 255, 33, 209>>

      iex> BSV.Hash.sha1_hmac("hello world", "test", encoding: :hex)
      "5a09e304f3c60d633ff16735ec931e1116ff21d1"
  """
  @spec sha1_hmac(binary(), binary(), keyword()) :: binary()
  def sha1_hmac(data, key, opts \\ [])
    when is_binary(data) and is_binary(key),
    do: hmac(data, key, :sha, opts)

  @doc """
  Computes the SHA-2 hash of a given input, outputting 256 bits.

  ## Examples

      iex> BSV.Hash.sha256("hello world")
      <<185, 77, 39, 185, 147, 77, 62, 8, 165, 46, 82, 215, 218, 125, 171, 250, 196, 132, 239, 227, 122, 83, 128, 238, 144, 136, 247, 172, 226, 239, 205, 233>>

      iex> BSV.Hash.sha256("hello world", encoding: :hex)
      "b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9"
  """
  @spec sha256(binary(), keyword()) :: binary()
  def sha256(data, opts \\ []) when is_binary(data),
    do: hash(data, :sha256, opts)

  @doc """
  Computes the HMAC of the of the given input using a secret key and the SHA-256
  algorithm.

  ## Examples

      iex> BSV.Hash.sha256_hmac("hello world", "test")
      <<209, 89, 110, 13, 66, 128, 242, 189, 45, 49, 28, 224, 129, 159, 35, 189, 224, 220, 131, 77, 130, 84, 185, 41, 36, 8, 141, 233, 76, 56, 217, 34>>

      iex> BSV.Hash.sha256_hmac("hello world", "test", encoding: :hex)
      "d1596e0d4280f2bd2d311ce0819f23bde0dc834d8254b92924088de94c38d922"
  """
  @spec sha256_hmac(binary(), binary(), keyword()) :: binary()
  def sha256_hmac(data, key, opts \\ [])
    when is_binary(data) and is_binary(key),
    do: hmac(data, key, :sha256, opts)

  @doc """
  Computes a RIPEMD hash of a SHA-256 hash, outputting 160 bits. This is
  commonly used inside Bitcoin, particularly for Bitcoin addresses.

  ## Examples

      iex> BSV.Hash.sha256_ripemd160("hello world")
      <<215, 213, 238, 120, 36, 255, 147, 249, 76, 48, 85, 175, 147, 130, 200, 108, 104, 181, 202, 146>>

      iex> BSV.Hash.sha256_ripemd160("hello world", encoding: :hex)
      "d7d5ee7824ff93f94c3055af9382c86c68b5ca92"
  """
  @spec sha256_ripemd160(binary(), keyword()) :: binary()
  def sha256_ripemd160(data, opts \\ []) when is_binary(data),
    do: sha256(data) |> ripemd160(opts)

  @doc """
  Computes a double SHA256 hash. This hash function is commonly used inside
  Bitcoin, particularly for the hash of a block and the hash of a transaction.

  ## Examples

      iex> BSV.Hash.sha256_sha256("hello world")
      <<188, 98, 212, 184, 13, 158, 54, 218, 41, 193, 108, 93, 77, 159, 17, 115, 31, 54, 5, 44, 114, 64, 26, 118, 194, 60, 15, 181, 169, 183, 68, 35>>

      iex> BSV.Hash.sha256_sha256("hello world", encoding: :hex)
      "bc62d4b80d9e36da29c16c5d4d9f11731f36052c72401a76c23c0fb5a9b74423"
  """
  @spec sha256_sha256(binary(), keyword()) :: binary()
  def sha256_sha256(data, opts \\ []) when is_binary(data),
    do: sha256(data) |> sha256(opts)

  @doc """
  Computes the SHA-2 hash of a given input, outputting 512 bits.

  ## Examples

      iex> BSV.Hash.sha512("hello world", encoding: :hex)
      "309ecc489c12d6eb4cc40f50c902f2b4d0ed77ee511a7c7a9bcd3ca86d4cd86f989dd35bc5ff499670da34255b45b0cfd830e81f605dcf7dc5542e93ae9cd76f"

      iex> BSV.Hash.sha512("hello world", encoding: :base64)
      "MJ7MSJwS1utMxA9QyQLytNDtd+5RGnx6m808qG1M2G+YndNbxf9JlnDaNCVbRbDP2DDoH2Bdz33FVC6TrpzXbw=="
  """
  @spec sha512(binary(), keyword()) :: binary()
  def sha512(data, opts \\ []) when is_binary(data),
    do: hash(data, :sha512, opts)

  @doc """
  Computes the HMAC of the of the given input using a secret key and the SHA-512
  algorithm.

  ## Examples

      iex> BSV.Hash.sha512_hmac("hello world", "test", encoding: :hex)
      "2536d175df94a4638110701d8a0e2cbe56e35f2dcfd167819148cd0f2c8780cb3d3df52b4aea8f929004dd07235ae802f4b5d160a2b8b82e8c2f066289de85a3"

      iex> BSV.Hash.sha512_hmac("hello world", "test", encoding: :base64)
      "JTbRdd+UpGOBEHAdig4svlbjXy3P0WeBkUjNDyyHgMs9PfUrSuqPkpAE3QcjWugC9LXRYKK4uC6MLwZiid6Fow=="
  """
  @spec sha512_hmac(binary(), binary(), keyword()) :: binary()
  def sha512_hmac(data, key, opts \\ [])
    when is_binary(data) and is_binary(key),
    do: hmac(data, key, :sha512, opts)

  # Computes the hash of the given binary using the specified algorithm
  defp hash(data, alg, opts) do
    encoding = Keyword.get(opts, :encoding)
    :crypto.hash(alg, data)
    |> encode(encoding)
  end

  # Computes the hmac of the given binary with the key, using the specified
  # algorithm
  defp hmac(data, key, alg, opts) do
    encoding = Keyword.get(opts, :encoding)
    :crypto.mac(:hmac, alg, key, data)
    |> encode(encoding)
  end

end
