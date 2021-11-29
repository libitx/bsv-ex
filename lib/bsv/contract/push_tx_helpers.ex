defmodule BSV.Contract.PushTxHelpers do
  @moduledoc """
  Helper module for implementing the technique known as `OP_PUSH_TX` in
  `BSV.Contract` modules.

  `OP_PUSH_TX` is a technique that enables true "smart contracts" to be deployed
  on Bitcoin. The technique can be defined as:

    * Push the transaction preimage into an unlocking script
    * In the locking script we can verify it is the correct preimage by using
      Script to create a signature and verifying it with `OP_CHECKSIG`
    * From there we can extract any data from the preimage and use it in our
      smart contracts.

  The technique allows for storing and tracking state across Bitcoin
  transactions, defining spending conditions in locking scripts, and much more.

  ## Usage

  To use these helpers, import this module into your contract module.

      defmodule MyContract do
        use BSV.Contract
        import BSV.Contract.PushTxHelpers

        def locking_script(ctx, _params) do
          check_tx(ctx)
        end

        def unlocking_script(ctx, _params) do
          push_tx(ctx)
        end
      end
  """
  alias BSV.{Contract, Sig, UTXO}
  use Contract.Helpers

  @order_prefix Base.decode16!("414136d08c5ed2bf3ba048afe6dcaebafe", case: :mixed)
  @pubkey_a Base.decode16!("023635954789a02e39fb7e54440b6f528d53efd65635ddad7f3c4085f97fdbdc48", case: :mixed)
  @pubkey_b Base.decode16!("038ff83d8cf12121491609c4939dc11c4aa35503508fe432dc5a5c1905608b9218", case: :mixed)
  @pubkey_opt Base.decode16!("02b405d7f0322a89d0f9f3a98e6f938fdc1c969a8d1382a2bf66a71ae74a1e83b0", case: :mixed)
  @sig_prefix Base.decode16!("3044022079be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f817980220", case: :mixed)
  @sighash_flag 0x41

  @doc """
  Assuming the top stack item is a Tx Preimage, gets the tx version number and
  places it on the stack on top of the preimage.
  """
  @spec get_version(Contract.t()) :: Contract.t()
  def get_version(%Contract{} = contract) do
    contract
    |> op_dup()
    |> slice(0, 4)
    |> decode_uint(:little)
  end

  @doc """
  Assuming the top stack item is a Tx Preimage, gets the 32 byte prevouts hash
  and places it on the stack on top of the preimage.
  """
  @spec get_prevouts_hash(Contract.t()) :: Contract.t()
  def get_prevouts_hash(%Contract{} = contract) do
    contract
    |> op_dup()
    |> slice(4, 32)
  end

  @doc """
  Assuming the top stack item is a Tx Preimage, gets the 32 byte sequence hash
  and places it on the stack on top of the preimage.
  """
  @spec get_sequence_hash(Contract.t()) :: Contract.t()
  def get_sequence_hash(%Contract{} = contract) do
    contract
    |> op_dup()
    |> slice(36, 32)
  end

  @doc """
  Assuming the top stack item is a Tx Preimage, gets the 36 byte outpoint and
  places it on the stack on top of the preimage.
  """
  @spec get_outpoint(Contract.t()) :: Contract.t()
  def get_outpoint(%Contract{} = contract) do
    contract
    |> op_dup()
    |> slice(68, 36)
  end

  @doc """
  Assuming the top stack item is a Tx Preimage, gets the locking script and
  places it on the stack on top of the preimage.

  State can be placed in the locking script and so this becomes an invaluable
  method for extracting and using that state.
  """
  @spec get_script(Contract.t()) :: Contract.t()
  def get_script(%Contract{} = contract) do
    contract
    |> op_dup()
    |> trim(104)
    |> trim(-52)
    |> trim_varint()
  end

  @doc """
  Assuming the top stack item is a Tx Preimage, gets the input satoshis number
  and places it on the stack on top of the preimage.
  """
  @spec get_satoshis(Contract.t()) :: Contract.t()
  def get_satoshis(%Contract{} = contract) do
    contract
    |> op_dup()
    |> slice(-52, 8)
    |> decode_uint(:little)
  end

  @doc """
  Assuming the top stack item is a Tx Preimage, gets the input sequence number
  and places it on the stack on top of the preimage.
  """
  @spec get_sequence(Contract.t()) :: Contract.t()
  def get_sequence(%Contract{} = contract) do
    contract
    |> op_dup()
    |> slice(-44, 4)
    |> decode_uint(:little)
  end

  @doc """
  Assuming the top stack item is a Tx Preimage, gets the 32 byte outputs hash
  and places it on the stack on top of the preimage.
  """
  @spec get_outputs_hash(Contract.t()) :: Contract.t()
  def get_outputs_hash(%Contract{} = contract) do
    contract
    |> op_dup()
    |> slice(-40, 32)
  end

  @doc """
  Assuming the top stack item is a Tx Preimage, gets the tx locktime number and
  places it on the stack on top of the preimage.
  """
  @spec get_lock_time(Contract.t()) :: Contract.t()
  def get_lock_time(%Contract{} = contract) do
    contract
    |> op_dup()
    |> slice(-8, 4)
    |> decode_uint(:little)
  end

  @doc """
  Assuming the top stack item is a Tx Preimage, gets the preimage sighash type
  and places it on the stack on top of the preimage.
  """
  @spec get_sighash_type(Contract.t()) :: Contract.t()
  def get_sighash_type(%Contract{} = contract) do
    contract
    |> op_dup()
    |> slice(-4, 4)
    |> decode_uint(:little)
  end

  @doc """
  Pushes the corrent Tx Preimage onto the stack. If no context is available in
  the [`contract`](`t:BSV.Contract.t/0`) or if this is called in a locking
  script, then 181 bytes of zeros are pushed onto the script instead.
  """
  @spec push_tx(Contract.t()) :: Contract.t()
  def push_tx(%Contract{ctx: {tx, vin}, subject: %UTXO{txout: txout}} = contract) do
    preimage = Sig.preimage(tx, vin, txout, @sighash_flag)
    push(contract, preimage)
  end

  def push_tx(%Contract{} = contract),
    do: push(contract, <<0::1448>>)

  @doc """
  Assuming the top stack item is a Tx Preimage, creates and verifies a signature
  with `OP_CHECKSIG`.

  The Tx Preimage is removed from the stack and replaced with the result from
  `OP_CHECKSIG`.
  """
  @spec check_tx(Contract.t()) :: Contract.t()
  def check_tx(%Contract{} = contract) do
    contract
    |> op_hash256()
    |> prepare_sighash()
    |> push_order()
    |> div_order()
    |> sighash_msb_is_0_or_255()
    |> op_if(
      fn contract ->
        contract
        |> op_2()
        |> op_pick()
        |> op_add()
      end,
      &op_1add/1
    )
    |> sighash_mod_gt_order()
    |> op_if(&op_sub/1, &op_nip/1)
    |> push_sig()
    |> op_swap()
    |> op_if(&push(&1, @pubkey_a), &push(&1, @pubkey_b))
    |> op_checksig()
  end

  @doc """
  As `check_tx/1` but verifies the signature with `OP_CHECKSIGVERIFY`.
  """
  @spec check_tx!(Contract.t()) :: Contract.t()
  def check_tx!(%Contract{} = contract) do
    contract = check_tx(contract)
    update_in(contract.script.chunks, & List.replace_at(&1, -1, :OP_CHECKSIGVERIFY))
  end

  # Prepares the sighash and MSB
  defp prepare_sighash(contract) do
    contract
    |> reverse(32)
    |> push(<<0x1F>>)
    |> op_split()
    |> op_tuck()
    |> op_cat()
    |> decode_uint(:little)
  end

  # Pushes the secp256k1 order onto the stack
  defp push_order(contract) do
    contract
    |> push(@order_prefix)
    |> push(<<0>>)
    |> op_15()
    |> op_num2bin()
    |> op_invert()
    |> op_cat()
    |> push(<<0>>)
    |> op_cat()
  end

  # Divides the order by 2
  defp div_order(contract) do
    contract
    |> op_dup()
    |> op_2()
    |> op_div()
  end

  # Is the sighash MSB 0x00 or 0xFF
  defp sighash_msb_is_0_or_255(contract) do
    contract
    |> op_rot()
    |> op_3()
    |> op_roll()
    |> op_dup()
    |> push(<<255>>)
    |> op_equal()
    |> op_swap()
    |> push(<<0>>)
    |> op_equal()
    |> op_boolor()
    |> op_tuck()
  end

  # Is the sighash mod greater than the secp256k1 order
  defp sighash_mod_gt_order(contract) do
    contract
    |> op_3()
    |> op_roll()
    |> op_tuck()
    |> op_mod()
    |> op_dup()
    |> op_4()
    |> op_roll()
    |> op_greaterthan()
  end

  # Constructs and pushes the signature onto the stack
  defp push_sig(contract) do
    contract
    |> push(@sig_prefix)
    |> op_swap()
    |> reverse(32)
    |> op_cat()
    |> push(@sighash_flag)
    |> op_cat()
  end

  @doc """
  Assuming the top stack item is a Tx Preimage, creates and verifies a signature
  with `OP_CHECKSIG`.

  This uses the [optimal OP_PUSH_TX approach](https://xiaohuiliu.medium.com/optimal-op-push-tx-ded54990c76f)
  which compiles to 87 bytes (compared to 438 as per `check_tx/1`).

  However, due to the [Low-S Constraint](https://bitcoin.stackexchange.com/questions/85946/low-s-value-in-bitcoin-signature)
  the most significant byte of the sighash must be less than a theshold of `0x7E`.
  There is a roughly 50% chance the signature being invalid. Therefore, when
  using this technique it is necessary to check the preimage and if necessary
  keep maleating the transaction until it is valid.
  """
  @spec check_tx_opt(Contract.t()) :: Contract.t()
  def check_tx_opt(%Contract{} = contract) do
    contract
    |> op_hash256()
    |> add_1_to_hash()
    |> push_sig_opt()
    |> push(@pubkey_opt)
    |> op_checksig()
  end

  @doc """
  As `check_tx_opt/1` but verifies the signature with `OP_CHECKSIGVERIFY`.
  """
  @spec check_tx_opt!(Contract.t()) :: Contract.t()
  def check_tx_opt!(%Contract{} = contract) do
    contract = check_tx_opt(contract)
    update_in(contract.script.chunks, & List.replace_at(&1, -1, :OP_CHECKSIGVERIFY))
  end

  # Adds 1 to the sighash MSB
  defp add_1_to_hash(contract) do
    contract
    |> op_1()
    |> op_split()
    |> op_swap()
    |> op_bin2num()
    |> op_1add()
    |> op_swap()
    |> op_cat()
  end

  # Constructs and pushes the signature onto the stack (optimal version)
  defp push_sig_opt(contract) do
    contract
    |> push(@sig_prefix)
    |> op_swap()
    |> op_cat()
    |> push(@sighash_flag)
    |> op_cat()
  end

end
