defmodule BSV.Crypto.AES do
  @moduledoc """
  Functions for use with AES symmetric cryptography.

  ## Examples

      iex> secret = BSV.Crypto.AES.generate_secret
      ...>
      ...> "hello world"
      ...> |> BSV.Crypto.AES.encrypt(:gcm, secret)
      ...> |> BSV.Crypto.AES.decrypt(:gcm, secret)
      "hello world"
  """
  alias BSV.Util

  @cipher_modes [:cbc, :ctr, :gcm]


  @doc """
  Returns a list of supported cypher modes.
  """
  @spec cipher_modes :: list
  def cipher_modes, do: @cipher_modes


  @doc """
  Generate a 256 bit random secret key.

  ## Examples

      iex> BSV.Crypto.AES.generate_secret
      ...> |> byte_size
      32
  """
  @spec generate_secret :: binary
  def generate_secret do
    Util.random_bytes(32)
  end


  @doc """
  Encrypts the given data using the specified cipher mode with the given secret
  key.

  ## Options

  The accepted cipher modes are:

  * `:gcm` - Galois/Counter Mode (GCM)
  * `:cbc` - Cipher Block Chaining (CBC)
  * `:ctr` - Counter (CTR)

  The accepted options are:

  * `:aad` - Provide your own Additional Authentication Data (only used in `:gcm` mode). If not provided, defaults to `"BSV.Crypto.AES"`.
  * `:encoding` - Optionally encode the returned cipher text with either the `:base64` or `:hex` encoding scheme.
  * `:iv` - Provide your own initialization vector. In `:cbc` and `:ctr` mode this is necessary as the same vector is needed to decrypt. In `:gcm` mode it is unnecessary as a random vector is generated and encoded in the returned cipher text.

  ## Examples

      iex> BSV.Crypto.AES.encrypt("hello world", :gcm, BSV.Test.symetric_key, iv: BSV.Test.iv12, aad: "MyAAD")
      <<50, 75, 191, 85, 4, 124, 185, 253, 212, 34, 64, 169, 160, 2, 228, 189, 104, 109, 9, 75, 62, 1, 42, 95, 107, 218, 187, 235, 55, 176, 107, 70, 58, 27, 219, 127, 230, 238, 103>>

      iex> BSV.Crypto.AES.encrypt("hello world", :gcm, BSV.Test.symetric_key, iv: BSV.Test.iv12, aad: "MyAAD", encoding: :base64)
      "Mku/VQR8uf3UIkCpoALkvWhtCUs+ASpfa9q76zewa0Y6G9t/5u5n"

      iex> BSV.Crypto.AES.encrypt("hello world", :cbc, BSV.Test.symetric_key, iv: BSV.Test.iv16, encoding: :base64)
      "quZoaDPv4OXNC5Ze2wmbCA=="

      iex> BSV.Crypto.AES.encrypt("hello world", :ctr, BSV.Test.symetric_key, iv: BSV.Test.iv16, encoding: :hex)
      "cdf91fda732325cf96de03"
  """
  @spec encrypt(binary, atom, binary, keyword) :: binary
  def encrypt(data, mode, secret, options \\ [])

  def encrypt(data, :gcm, secret, options) do
    aad = Keyword.get(options, :aad, "")
    encoding = Keyword.get(options, :encoding)
    iv = Keyword.get(options, :iv, Util.random_bytes(12))

    {ciphertext, tag} = :crypto.crypto_one_time_aead(:aes_256_gcm, secret, iv, data, aad, true)
    Util.encode(iv <> ciphertext <> tag, encoding)
  end

  def encrypt(data, :cbc, secret, options) do
    encoding = Keyword.get(options, :encoding)
    iv = Keyword.get(options, :iv, Util.random_bytes(16))
    mode = case byte_size(secret) do
      16 -> :aes_128_cbc
      _ -> :aes_256_cbc
    end
    padding = 16 - rem(byte_size(data), 16)
    
    :crypto.crypto_one_time(mode, secret, iv, data <> :binary.copy(<<padding>>, padding), true)
    |> Util.encode(encoding)
  end

  def encrypt(data, :ctr, secret, options) do
    encoding = Keyword.get(options, :encoding)
    iv = Keyword.get(options, :iv, Util.random_bytes(16))

    :crypto.crypto_one_time(:aes_256_ctr, secret, iv, data, true)
    |> Util.encode(encoding)
  end


  @doc """
  Decrypts the given ciphertext using the specified cipher mode with the given
  secret key.

  ## Options

  The accepted cipher modes are:

  * `:gcm` - Galois/Counter Mode (GCM)
  * `:cbc` - Cipher Block Chaining (CBC)
  * `:ctr` - Counter (CTR)

  The accepted options are:

  * `:aad` - If Additional Authentication Data was specified at encryption, it must be used here to successfully decrypt.
  * `:encoding` - Optionally decode the given cipher text with either the `:base64` or `:hex` encoding scheme.
  * `:iv` - If your own initialization vector was specified at encryption, it must be used here to successfully decrypt.

  ## Examples

      iex> "Mku/VQR8uf3UIkCpoALkvWhtCUs+ASpfa9q76zewa0Y6G9t/5u5n"
      ...> |> BSV.Crypto.AES.decrypt(:gcm, BSV.Test.symetric_key, iv: BSV.Test.iv12, encoding: :base64, aad: "MyAAD")
      "hello world"

      iex> "quZoaDPv4OXNC5Ze2wmbCA=="
      ...> |> BSV.Crypto.AES.decrypt(:cbc, BSV.Test.symetric_key, iv: BSV.Test.iv16, encoding: :base64)
      "hello world"

      iex> "cdf91fda732325cf96de03"
      ...> |> BSV.Crypto.AES.decrypt(:ctr, BSV.Test.symetric_key, iv: BSV.Test.iv16, encoding: :hex)
      "hello world"
  """
  @spec decrypt(binary, atom, binary, keyword) :: binary
  def decrypt(ciphertext, mode, secret, options \\ [])

  def decrypt(ciphertext, :gcm, secret, options) do
    encoding = Keyword.get(options, :encoding)
    aad = Keyword.get(options, :aad, "")
    ciphertext = Util.decode(ciphertext, encoding)
    len = byte_size(ciphertext) - 12 - 16
    <<iv::binary-12, data::binary-size(len), tag::binary-16>> = ciphertext

    :crypto.crypto_one_time_aead(:aes_256_gcm, secret, iv, data, aad, tag, false)
  end

  def decrypt(ciphertext, :cbc, secret, options) do
    encoding = Keyword.get(options, :encoding)
    iv = Keyword.get(options, :iv)
    mode = case byte_size(secret) do
      16 -> :aes_128_cbc
      _ -> :aes_256_cbc
    end
    ciphertext = Util.decode(ciphertext, encoding)

    data = :crypto.crypto_one_time(mode, secret, iv, ciphertext, false)
    padding = :binary.last(data)
    :binary.part(data, 0, byte_size(data) - padding)
  end

  def decrypt(ciphertext, :ctr, secret, options) do
    encoding = Keyword.get(options, :encoding)
    iv = Keyword.get(options, :iv)
    ciphertext = Util.decode(ciphertext, encoding)

    :crypto.crypto_one_time(:aes_256_ctr, secret, iv, ciphertext, false)
  end
  
end