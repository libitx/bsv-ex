defmodule BSV.Contract.P2RPH do
  @moduledoc """
  Pay to R-Puzzle Hash contract.

  P2RPH scripts are used to lock Bitcoin to a hash puzzle based on the R value
  of an ECDSA signature. The Bitcoin can later be unlocked with knowledge of the
  corresponding K value used in that signature.

  The technique allows for the spending party to sign the unlocking script using
  any `t:BSV.KeyPair.t/0`.

  ## Examples

      iex> contract = P2RPH.lock(1000, %{r: <<0, 248, 31, 103, 64, 90, 206, 189, 241, 179, 82, 21, 21, 93, 182, 235, 240, 79, 251, 243, 151, 251, 106, 1, 172, 52, 67, 147, 228, 160, 37, 243, 37>>})
      iex> Contract.to_script(contract)
      %Script{chunks: [
        :OP_OVER,
        :OP_3,
        :OP_SPLIT,
        :OP_NIP,
        :OP_1,
        :OP_SPLIT,
        :OP_SWAP,
        :OP_SPLIT,
        :OP_DROP,
        :OP_HASH160,
        <<54, 64, 230, 57, 244, 115, 17, 120, 225, 185, 95, 98, 204, 108, 116, 34, 51, 156, 70, 82>>,
        :OP_EQUALVERIFY,
        :OP_TUCK,
        :OP_CHECKSIGVERIFY,
        :OP_CHECKSIG
      ]}

      iex> contract = P2RPH.unlock(%UTXO{}, %{keypair: @keypair, k: <<194, 223, 63, 16, 71, 231, 76, 36, 240, 165, 106, 139, 60, 110, 89, 72, 165, 137, 83, 102, 50, 141, 163, 159, 131, 133, 220, 164, 218, 224, 121, 81>>})
      iex> Contract.to_script(contract)
      %Script{chunks: [
        <<0::568>>, # signatures are zero'd out until the transaction context is attached
        <<0::568>>,
        <<3, 248, 31, 140, 139, 144, 245, 236, 6, 238, 66, 69, 234, 177, 102, 232, 175, 144, 63, 199, 58, 109, 215, 54, 54, 104, 126, 240, 39, 135, 10, 190, 57>>
      ]}
  """
  use BSV.Contract
  alias BSV.{Hash, PrivKey, PubKey, Sig, UTXO}
  alias Curvy.Point
  import Curvy.Util, only: [mod: 2]

  @crv Curvy.Curve.secp256k1()

  @impl true
  def locking_script(ctx, %{r: r}) when is_binary(r) do
    ctx
    |> op_over
    |> op_3
    |> op_split
    |> op_nip
    |> op_1
    |> op_split
    |> op_swap
    |> op_split
    |> op_drop
    |> op_hash160
    |> push(Hash.sha256_ripemd160(r))
    |> op_equalverify
    |> op_tuck
    |> op_checksigverify
    |> op_checksig
  end

  @impl true
  def unlocking_script(ctx, %{k: k, keypair: keypair})
    when is_binary(k) or is_integer(k)
  do
    ctx
    |> sig(keypair.privkey)
    |> sig_with_k(keypair.privkey, k)
    |> push(PubKey.to_binary(keypair.pubkey))
  end

  @doc """
  Generates a new random K value binary.
  """
  @spec generate_k() :: binary()
  def generate_k() do
    :crypto.generate_key(:ecdh, :secp256k1)
    |> elem(1)
  end

  @doc """
  Returns the corresponding R value of the given K value.
  """
  @spec get_r(binary()) :: binary()
  def get_r(<<k::big-256>>) do
    r = @crv[:G]
    |> Point.mul(k)
    |> Map.get(:x)
    |> mod(@crv[:n])

    case <<r::big-256>> do
      <<r0, _::binary>> = r when r0 > 127 ->
        <<0, r::binary>>
      r ->
        r
    end
  end

  # Signs the transaction context using the given K value
  defp sig_with_k(
    %Contract{ctx: {tx, vin}, opts: opts, subject: %UTXO{txout: txout}} = ctx,
    %PrivKey{d: privkey},
    k
  ) do
    sighash_type = Keyword.get(opts, :sighash_type, Sig.sighash_flag(:default))

    signature = tx
    |> Sig.sighash(vin, txout, sighash_type)
    |> Curvy.sign(privkey, hash: false, k: k)
    |> Kernel.<>(<<sighash_type>>)

    Contract.script_push(ctx, signature)
  end

  defp sig_with_k(ctx, %PrivKey{} = _privkey, _k),
    do: Contract.script_push(ctx, <<0::568>>)

end
