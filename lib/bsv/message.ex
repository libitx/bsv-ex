defmodule BSV.Message do
  @moduledoc """
  The Message module provides functions for encrypting, decrypting, signing and
  verifying arbitrary messages using Bitcoin keys.

  Message encryption uses the Electrum-compatible BIE1 ECIES algorithm. Message
  signing uses the Bitcoin Signed Message algorithm. Both alorithms are broadly
  supported by popular BSV libraries in other languages.

  ## Encryption

  A sender encrypts the message using the recipient's PubKey. The recipient
  decrypts the message with their PrivKey.

      iex> msg = "Secret test message"
      iex> encrypted = Message.encrypt(msg, @bob_keypair.pubkey)
      iex> Message.decrypt(encrypted, @bob_keypair.privkey)
      {:ok, "Secret test message"}

  ## Signing

  A sender signs a message with their PrivKey. The recipient verifies the
  message using the sender's PubKey.

      iex> msg = "Secret test message"
      iex> sig = Message.sign(msg, @alice_keypair.privkey)
      iex> Message.verify(sig, msg, @alice_keypair.pubkey)
      true
  """
  alias BSV.{Address, Hash, KeyPair, PrivKey, PubKey, VarInt}
  import BSV.Util, only: [decode: 2, decode!: 2, encode: 2]

  @doc """
  Decrypts the given message with the private key.

  ## Options

  The accepted options are:

  * `:encoding` - Optionally decode the binary with either the `:base64` or `:hex` encoding scheme.
  """
  @spec decrypt(binary(), PrivKey.t(), keyword()) ::
    {:ok, binary()} |
    {:error, term()}
  def decrypt(data, %PrivKey{} = privkey, opts \\ []) do
    encoding = Keyword.get(opts, :encoding)
    encrypted = decode!(data, encoding)
    len = byte_size(encrypted) - 69

    <<
      "BIE1",                         # magic bytes
      ephemeral_pubkey::binary-33,    # ephermeral pubkey
      ciphertext::binary-size(len),   # ciphertext
      mac::binary-32                  # mac hash
    >> = encrypted

    <<d::big-256>> = privkey.d

    # Derive ECDH key and sha512 hash
    ecdh_point = ephemeral_pubkey
    |> PubKey.from_binary!()
    |> Map.get(:point)
    |> Curvy.Point.mul(d)
    key_hash = %PubKey{point: ecdh_point}
    |> PubKey.to_binary()
    |> Hash.sha512()

    # iv and enc_key used in AES, mac_key used in HMAC
    <<iv::binary-16, enc_key::binary-16, mac_key::binary-32>> = key_hash

    with ^mac <- Hash.sha256_hmac("BIE1" <> ephemeral_pubkey <> ciphertext, mac_key),
         msg when is_binary(msg) <- :crypto.crypto_one_time(:aes_128_cbc, enc_key, iv, ciphertext, false)
    do
      {:ok, pkcs7_unpad(msg)}
    end
  end

  @doc """
  Encrypts the given message with the public key.

  ## Options

  The accepted options are:

  * `:encoding` - Optionally encode the binary with either the `:base64` or `:hex` encoding scheme.
  """
  @spec encrypt(binary(), PubKey.t(), keyword()) :: binary()
  def encrypt(message, %PubKey{} = pubkey, opts \\ []) do
    encoding = Keyword.get(opts, :encoding)

    # Generate ephemeral keypair
    ephemeral_key = KeyPair.new()
    <<d::big-256>> = ephemeral_key.privkey.d

    # Derive ECDH key and sha512 hash
    ecdh_point = pubkey.point
    |> Curvy.Point.mul(d)
    key_hash = %PubKey{point: ecdh_point}
    |> PubKey.to_binary()
    |> Hash.sha512()

    # iv and enc_key used in AES, mac_key used in HMAC
    <<iv::binary-16, enc_key::binary-16, mac_key::binary-32>> = key_hash
    cyphertext = :crypto.crypto_one_time(:aes_128_cbc, enc_key, iv, pkcs7_pad(message), true)
    encrypted = "BIE1" <> PubKey.to_binary(ephemeral_key.pubkey) <> cyphertext
    mac = Hash.sha256_hmac(encrypted, mac_key)
    encode(encrypted <> mac, encoding)
  end

  @doc """
  Signs the given message with the PrivKey.

  By default signatures are returned `base64` encoded. Use the `encoding: :raw`
  option to return a raw binary signature.

  ## Options

  The accepted options are:

  * `:encoding` - Encode the binary with either the `:base64`, `:hex` or `:raw` encoding scheme.
  """
  @spec sign(binary(), PrivKey.t(), keyword()) :: binary()
  def sign(message, %PrivKey{} = privkey, opts \\ []) do
    opts = opts
    |> Keyword.put_new(:encoding, :base64)
    |> Keyword.merge([
      compact: true,
      compressed: privkey.compressed,
      hash: false
    ])

    message
    |> bsm_digest()
    |> Curvy.sign(privkey.d, opts)
  end

  @doc """
  Verifies the given signature against the given message using the PubKey.

  By default signatures are assumed to be `base64` encoded. Use the `:encoding`
  option to specify a different signature encoding.

  ## Options

  The accepted options are:

  * `:encoding` - Decode the signature with either the `:base64`, `:hex` or `:raw` encoding scheme.
  """
  @spec verify(binary(), binary(), PubKey.t() | Address.t(), keyword()) ::
    boolean() |
    {:error, term()}
  def verify(signature, message, pubkey_or_address, opts \\ []) do
    encoding = Keyword.get(opts, :encoding, :base64)

    with {:ok, sig} <- decode(signature, encoding) do
      case do_verify(sig, bsm_digest(message), pubkey_or_address) do
        res when is_boolean(res) -> res
        :error -> false
        error -> error
      end
    end
  end

  # Handles signature verification with address or pubkey
  def do_verify(sig, message, %Address{} = address) do
    with %Curvy.Key{} = key <- Curvy.recover_key(sig, message, hash: false),
         ^address <- Address.from_pubkey(%PubKey{point: key.point})
    do
      Curvy.verify(sig, message, key, hash: false)
    end
  end

  def do_verify(sig, message, %PubKey{} = pubkey) do
    Curvy.verify(sig, message, PubKey.to_binary(pubkey), hash: false)
  end

  # Prefixes the message with magic bytes and hashes
  defp bsm_digest(msg) do
    prefix = "Bitcoin Signed Message:\n"
    b1 = VarInt.encode(byte_size(prefix))
    b2 = VarInt.encode(byte_size(msg))

    Hash.sha256_sha256(<<b1::binary, prefix::binary, b2::binary, msg::binary>>)
  end

  # Pads the message using PKCS7
  defp pkcs7_pad(msg) do
    case rem(byte_size(msg), 16) do
      0 -> msg
      pad ->
        pad = 16 - pad
        msg <> :binary.copy(<<pad>>, pad)
    end
  end

  # Unpads the message using PKCS7
  defp pkcs7_unpad(msg) do
    case :binary.last(msg) do
      pad when 0 < pad and pad < 16 ->
        :binary.part(msg, 0, byte_size(msg) - pad)
      _ ->
        msg
    end
  end

end
