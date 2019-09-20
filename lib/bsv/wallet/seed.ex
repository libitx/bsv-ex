defmodule BSV.Wallet.Seed do
  @moduledoc """
  Module for generating a BIP-39 seed, derived from a mnemonic phrase.
  """
  alias BSV.Crypto.Hash
  alias BSV.Util

  @rounds 2048


  @doc """
  Generates and returns a wallet seed derived from the given mnemonic phrase and
  optionally a passphrase.

  ## Options

  The accepted options are:

  * `:passphrase` - Optionally protect the seed with an additional passphrase
  * `:encoding` - Optionally encode the seed with either the `:base64` or `:hex` encoding scheme.

  ## Examples

      iex> BSV.Wallet.Mnemonic.from_entropy(BSV.Test.mnemonic_entropy)
      ...> |> BSV.Wallet.Seed.generate(encoding: :hex)
      "380823f725beb7846806d0b88590a0823ea81c0b88cd151f7295772bbe48bbffa9b0f131dce77c4a7168925d466270c12bc0073db917da9f2bb1f4ac59e9fa3b"

      iex> BSV.Wallet.Mnemonic.from_entropy(BSV.Test.mnemonic_entropy)
      ...> |> BSV.Wallet.Seed.generate(passphrase: "my wallet")
      ...> |> byte_size
      64
  """
  @spec generate(BSV.Wallet.Mnemonic.t, keyword) :: binary
  def generate(mnemonic, options \\ []) do
    passphrase = Keyword.get(options, :passphrase, "")
    encoding = Keyword.get(options, :encoding)

    <<"mnemonic", passphrase::binary, 1::integer-32>>
    |> Hash.hmac(:sha512, mnemonic)
    |> pbkdf2(mnemonic)
    |> Util.encode(encoding)
  end


  defp pbkdf2(hmac_block, mnemonic) do
    iterate(mnemonic, 1, hmac_block, hmac_block)
  end

  defp iterate(_mnemonic, round_num, _hmac_block, result)
    when round_num == @rounds,
    do: result

  defp iterate(mnemonic, round_num, hmac_block, result) do
    with next_block <- Hash.hmac(hmac_block, :sha512, mnemonic),
         result <- :crypto.exor(next_block, result),
         do: iterate(mnemonic, round_num + 1, next_block, result)
  end
end