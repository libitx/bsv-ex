defmodule BSV.Crypto.AES do
  @moduledoc """
  Functions for use with AES symmetric cryptography
  """
  alias BSV.Util

  @type cipher_mode :: atom()
  @cipher_modes [:cbc, :ctr, :gcm]
  @aad "BSV.Crypto.AES"


  @doc """
  Returns a list of supported cypher modes.
  """
  @spec cipher_modes() :: [cipher_mode]
  def cipher_modes, do: @cipher_modes


  @doc """
  Generate a random secret key.
  """
  def generate_secret do
    Util.random_bytes(32)
  end


  @doc """
  Encrypts the given data using the specified cipher mode with the given secret key.

  ## Examples

      BSV.Crypto.AES.encrypt("hello world", :gcm, BSV.Test.symetric_key)
      # returns binary << encrypted data >>

      iex> BSV.Crypto.AES.encrypt("hello world", :gcm, BSV.Test.symetric_key, iv: BSV.Test.iv12, aad: "MyAAD")
      <<50, 75, 191, 85, 4, 124, 185, 253, 212, 34, 64, 169, 95, 107, 218, 187, 235, 55, 176, 107, 70, 58, 27, 219, 127, 230, 238, 103, 160, 2, 228, 189, 104, 109, 9, 75, 62, 1, 42>>

      iex> BSV.Crypto.AES.encrypt("hello world", :gcm, BSV.Test.symetric_key, iv: BSV.Test.iv12, aad: "MyAAD", encode: :base64)
      "Mku/VQR8uf3UIkCpX2vau+s3sGtGOhvbf+buZ6AC5L1obQlLPgEq"

      iex> BSV.Crypto.AES.encrypt("hello world", :cbc, BSV.Test.symetric_key, iv: BSV.Test.iv16, encode: :base64)
      "quZoaDPv4OXNC5Ze2wmbCA=="

      iex> BSV.Crypto.AES.encrypt("hello world", :ctr, BSV.Test.symetric_key, iv: BSV.Test.iv16, encode: :hex)
      "cdf91fda732325cf96de03"
  """
  @spec encrypt(binary(), cipher_mode, binary(), keyword()) :: binary()
  def encrypt(data, mode, secret, options \\ [])

  def encrypt(data, :gcm, secret, options) do
    aad = Keyword.get(options, :aad, @aad)
    encoding = Keyword.get(options, :encode)
    iv = Keyword.get(options, :iv, Util.random_bytes(12))

    {ciphertext, tag} = :crypto.crypto_one_time_aead(:aes_256_gcm, secret, iv, data, aad, true)
    Util.encode(iv <> tag <> ciphertext, encoding)
  end

  def encrypt(data, :cbc, secret, options) do
    encoding = Keyword.get(options, :encode)
    padding = 16 - rem(byte_size(data), 16)
    iv = Keyword.get(options, :iv, Util.random_bytes(16))

    :crypto.crypto_one_time(:aes_256_cbc, secret, iv, data <> :binary.copy(<<padding>>, padding), true)
    |> Util.encode(encoding)
  end

  def encrypt(data, :ctr, secret, options) do
    encoding = Keyword.get(options, :encode)
    iv = Keyword.get(options, :iv, Util.random_bytes(16))

    :crypto.crypto_one_time(:aes_256_ctr, secret, iv, data, true)
    |> Util.encode(encoding)
  end


  @doc """
  Decrypts the given ciphertext using the specified cipher mode with the given secret key.

  ## Examples

      iex> "Mku/VQR8uf3UIkCpX2vau+s3sGtGOhvbf+buZ6AC5L1obQlLPgEq"
      ...> |> Base.decode64!
      ...> |> BSV.Crypto.AES.decrypt(:gcm, BSV.Test.symetric_key, iv: BSV.Test.iv12, aad: "MyAAD")
      "hello world"

      iex> "quZoaDPv4OXNC5Ze2wmbCA=="
      ...> |> Base.decode64!
      ...> |> BSV.Crypto.AES.decrypt(:cbc, BSV.Test.symetric_key, iv: BSV.Test.iv16, aad: "MyAAD")
      "hello world"

      iex> "cdf91fda732325cf96de03"
      ...> |> Base.decode16!(case: :lower)
      ...> |> BSV.Crypto.AES.decrypt(:ctr, BSV.Test.symetric_key, iv: BSV.Test.iv16, aad: "MyAAD")
      "hello world"
  """
  @spec decrypt(binary(), cipher_mode, binary(), keyword()) :: binary()
  def decrypt(ciphertext, mode, secret, options \\ [])

  def decrypt(ciphertext, :gcm, secret, options) do
    aad = Keyword.get(options, :aad, @aad)
    <<iv::binary-12, tag::binary-16, data::binary>> = ciphertext

    :crypto.crypto_one_time_aead(:aes_256_gcm, secret, iv, data, aad, tag, false)
  end

  def decrypt(ciphertext, :cbc, secret, options) do
    iv = Keyword.get(options, :iv)

    data = :crypto.crypto_one_time(:aes_256_cbc, secret, iv, ciphertext, false)
    padding = :binary.last(data)
    :binary.part(data, 0, byte_size(data) - padding)
  end

  def decrypt(ciphertext, :ctr, secret, options) do
    iv = Keyword.get(options, :iv)

    :crypto.crypto_one_time(:aes_256_ctr, secret, iv, ciphertext, false)
  end

  
end