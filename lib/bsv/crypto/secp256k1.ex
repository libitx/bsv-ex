defmodule BSV.Crypto.Secp256k1 do
  @moduledoc """
  Wrapper module for common secp256k1 functions.integer()

  By default uses the pure Elixir [Curvy](https://hexdocs.pm/curvy) library. If
  the optional `:libsecp256k1` dependency is installed then that is used instead.
  """

  @env_test_curvy System.get_env("TEST_CURVY")
  @use_libsep256k1 Code.ensure_loaded?(:libsecp256k1) and is_nil(@env_test_curvy)


  @doc """
  Adds the two elliptic curve points together.
  """
  @spec pubkey_add(binary, binary) :: binary
  def pubkey_add(<<pubkey::binary-size(33)>>, other) when @use_libsep256k1 do
    with {:ok, result} <- :libsecp256k1.ec_pubkey_decompress(pubkey) do
      pubkey_add(result, other)
    end
  end

  def pubkey_add(pubkey, other) when @use_libsep256k1 do
    with {:ok, result} <- :libsecp256k1.ec_pubkey_tweak_add(pubkey, other) do
      result
    end
  end

  def pubkey_add(pubkey, other) do
    pubkey
    |> Curvy.Key.from_pubkey()
    |> Map.get(:point)
    |> Curvy.Point.add(Curvy.Key.from_pubkey(other))
    |> Curvy.Key.from_point()
    |> Curvy.Key.to_pubkey()
  end


  @doc """
  Multiplies the elliptic curve point by the given scalar.
  """
  @spec pubkey_mul(binary, binary) :: binary
  def pubkey_mul(<<pubkey::binary-size(33)>>, other) when @use_libsep256k1 do
    with {:ok, result} <- :libsecp256k1.ec_pubkey_decompress(pubkey) do
      pubkey_mul(result, other)
    end
  end

  def pubkey_mul(pubkey, other) when @use_libsep256k1 do
    with {:ok, result} <- :libsecp256k1.ec_pubkey_tweak_mul(pubkey, other) do
      BSV.Crypto.ECDSA.PublicKey.compress(result)
    end
  end

  def pubkey_mul(pubkey, <<other::big-size(256)>>) do
    pubkey
    |> Curvy.Key.from_pubkey()
    |> Map.get(:point)
    |> Curvy.Point.mul(other)
    |> Curvy.Key.from_point()
    |> Curvy.Key.to_pubkey()
  end


  @doc """
  Recovers the public jey from the given compact signature.
  """
  @spec recover_key(binary, binary, keyword) :: binary
  def recover_key(sig, message, opts \\ [])

  def recover_key(<<prefix::integer, sig::binary>>, message, _opts) when @use_libsep256k1 do
    {comp, comp_opt} = if prefix > 30, do: {true, :compressed}, else: {false, :uncompressed}
    case :libsecp256k1.ecdsa_recover_compact(message, sig, comp_opt, prefix - sig_prefix(comp)) do
      {:ok, recovered_key} -> recovered_key
      error -> error
    end
  end

  def recover_key(sig, message, opts) do
    with %Curvy.Key{} = key <- Curvy.recover_key(sig, message, Keyword.put(opts, :hash, false)) do
      Curvy.Key.to_pubkey(key)
    end
  end


  @doc """
  Signs the given message hash with the private key.
  """
  @spec sign(binary, binary, keyword) :: binary
  def sign(msghash, privkey, opts \\ [])

  def sign(msghash, privkey, opts) when @use_libsep256k1 do
    compressed = Keyword.get(opts, :compressed, true)
    case Keyword.get(opts, :compact) do
      true -> :libsecp256k1.ecdsa_sign_compact(msghash, privkey, :default, <<>>)
      _ -> :libsecp256k1.ecdsa_sign(msghash, privkey, :default, <<>>)
    end
    |> case do
      {:ok, signature, recovery} ->
        <<sig_prefix(compressed) + recovery, signature::binary>>
      {:ok, signature} ->
        signature
      error ->
        error
    end
  end

  def sign(msghash, privkey, opts),
    do: Curvy.sign(msghash, privkey, Keyword.put(opts, :hash, false))

  defp sig_prefix(true), do: 31
  defp sig_prefix(false), do: 27


  @doc """
  Verifies the given signature with the message hash and public key.
  """
  @spec verify(binary, binary, binary, keyword) :: boolean
  def verify(sig, msghash, pubkey, opts \\ [])

  def verify(<<_::integer, sig::binary>>, msghash, pubkey, _opts)
    when @use_libsep256k1 and byte_size(sig) == 64
  do
    :libsecp256k1.ecdsa_verify_compact(msghash, sig, pubkey)
    |> atom_to_bool()
  end

  def verify(sig, msghash, pubkey, _opts) when @use_libsep256k1 do
    :libsecp256k1.ecdsa_verify(msghash, sig, pubkey)
    |> atom_to_bool()
  end

  def verify(sig, msghash, pubkey, opts),
    do: Curvy.verify(sig, msghash, pubkey, Keyword.put(opts, :hash, false))


  # Converts :libsecp256k1 atom response to boolean
  defp atom_to_bool(:ok), do: true
  defp atom_to_bool(:error), do: false

end
