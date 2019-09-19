defmodule BSV.Wallet.Seed do
  @moduledoc """
  Module for generating a wallet seed, derived from a mnemonic phrase.
  """
  alias BSV.Crypto.Hash
  alias BSV.Util

  @rounds 2048


  @doc """
  Generates and returns a wallet seed derived from the given mnemonic phrase and
  optionally a passphrase.

  ## Options

  The accepted options are:

  * `passphrase` - Optionally protect the seed with an additional passphrase
  * `:encoding` - Optionally encode the seed with either the `:base64` or `:hex` encoding scheme.

  ## Examples

      iex> BSV.Wallet.Mnemonic.from_entropy(BSV.Test.mnemonic_entropy)
      ...> |> BSV.Wallet.Seed.generate(encoding: :hex)
      "8d3055be45aab3196051d5c852ceb370bbb8f79ed1325ff6e8693f42f762700e"

      iex> BSV.Wallet.Mnemonic.from_entropy(BSV.Test.mnemonic_entropy)
      ...> |> BSV.Wallet.Seed.generate(passphrase: "my wallet")
      <<241, 168, 252, 93, 207, 145, 185, 105, 100, 8, 190, 118, 195, 150, 233, 35, 34, 8, 94, 182, 3, 244, 161, 8, 33, 147, 124, 67, 82, 209, 187, 23>>
  """
  @spec generate(BSV.Wallet.Mnemonic.t, keyword) :: binary
  def generate(mnemonic, options \\ []) do
    passphrase = Keyword.get(options, :passphrase, "")
    encoding = Keyword.get(options, :encoding)

    Hash.hmac(mnemonic, :sha512, <<"mnemonic", passphrase::binary, 1::integer-32>>)
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
    with next_block <- Hash.hmac(mnemonic, :sha512, hmac_block),
         result <- :crypto.exor(next_block, result),
         do: iterate(mnemonic, round_num + 1, next_block, result)
  end
end