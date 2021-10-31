defmodule BSV.Contract do
  @moduledoc """
  A behaviour module for implementing Bitcoin transaction contracts.

  A Bitcoin transaction contains two sides: inputs and outputs.

  Transaction outputs are script puzzles, called "locking scripts" (sometimes
  also known as a "ScriptPubKey") which lock a number of satoshis. Transaction
  inputs are contain an "unlocking script" (or the "ScriptSig") and unlock the
  satoshis contained in the previous transaction's outputs.

  Therefore, each locking script is unlocked by a corresponding unlocking script.

  The `BSV.Contract` module provides a way to define a locking script and
  unlocking script in a plain Elixir function. Because it is *just Elixir*, it
  is trivial to add helper functions and macros to reduce boilerplate and create
  more complex contract types and scripts.

  ## Defining a contract

  The following module implements a Pay to Public Key Hash contract.
  Implementing a contract is just a case of defining `c:locking_script/2` and
  `c:unlocking_script/2`.

      defmodule P2PKH do
        @moduledoc "Pay to Public Key Hash contract."
        use BSV.Contract

        @impl true
        def locking_script(ctx, %{address: address}) do
          ctx
          |> op_dup
          |> op_hash160
          |> push(address.pubkey_hash)
          |> op_equalverify
          |> op_checksig
        end

        @impl true
        def unlocking_script(ctx, %{keypair: keypair}) do
          ctx
          |> signature(keypair.privkey)
          |> push(BSV.PubKey.to_binary(keypair.pubkey))
        end
      end

  ## Locking a contract

  A contract locking script is initiated by calling `lock/2` on the contract
  module, passing the number of satoshis and a map of parameters expected by
  `c:locking_script/2` defined in the contract.

      # Initiate the contract locking script
      contract = P2PKH.lock(10_000, %{address: Address.from_pubkey(bob_pubkey)})

      script = Contract.to_script(contract) # returns the locking script
      txout = Contract.to_txout(contract)   # returns the full txout

  ## Unlocking a contract

  To unlock and spend the contract, a `t:BSV.UTXO.t/0` is passed to `unlock/2`
  with the parameters expected by `c:unlocking_script/2` defined in the contract.

      # Initiate the contract unlocking script
      contract = P2PKH.unlock(utxo, %{keypair: keypair})

  Optionally the current transaction [`context`](`t:BSV.Contract.ctx/0`) can be
  given to the [`contract`](`t:BSV.Contract.t/0`). This allows the correct
  [`sighash`](`t:BSV.Sig.sighash/0`) to be calculated for any signatures.

      # Pass the current transaction ctx
      contract = Contract.put_ctx(contract, {tx, vin})

      # returns the signed txin
      txout = Contract.to_txin(contract)

  ## Building transactions

  The `BSV.Contract` behaviour is taken advantage of in the `BSV.TxBuilder`
  module, resulting in transaction building semantics that are easy to grasp and
  pleasing to work with.

      builder = %TxBuilder{
        inputs: [
          P2PKH.unlock(utxo, %{keypair: keypair})
        ],
        outputs: [
          P2PKH.lock(10_000, %{address: address})
        ]
      }

      # Returns a fully signed transaction
      TxBuilder.to_tx(builder)

  For more information, refer to `BSV.TxBuilder`.
  """
  alias BSV.{Script, Tx, TxBuilder, TxIn, TxOut, UTXO, VM}

  defstruct ctx: nil, mfa: nil, opts: [], subject: nil, script: %Script{}

  @typedoc "BSV Contract struct"
  @type t() :: %__MODULE__{
    ctx: ctx() | nil,
    mfa: {module(), atom(), list()},
    opts: keyword(),
    subject: non_neg_integer() | UTXO.t(),
    script: Script.t()
  }

  @typedoc """
  Transaction context.

  A tuple containing a `t:BSV.Tx.t/0` and [`vin`](`t:non_neg_integer/0`). When
  attached to a contract, the he correct [`sighash`](`t:BSV.Sig.sighash/0`) to
  be calculated for any signatures.
  """
  @type ctx() :: {Tx.t(), non_neg_integer()}

  defmacro __using__(_) do
    quote do
      alias BSV.Contract
      import Contract.Helpers

      @behaviour Contract

      @doc """
      Returns a locking script contract with the given parameters.
      """
      @spec lock(non_neg_integer(), map(), keyword()) :: Contract.t()
      def lock(satoshis, %{} = params, opts \\ []) do
        struct(Contract, [
          mfa: {__MODULE__, :locking_script, [params]},
          opts: opts,
          subject: satoshis
        ])
      end

      @doc """
      Returns an unlocking script contract with the given parameters.
      """
      @spec unlock(UTXO.t(), map(), keyword()) :: Contract.t()
      def unlock(%UTXO{} = utxo, %{} = params, opts \\ []) do
        struct(Contract, [
          mfa: {__MODULE__, :unlocking_script, [params]},
          opts: opts,
          subject: utxo
        ])
      end
    end
  end

  @doc """
  Callback executed to generate the contract locking script.

  Is passed the [`contract`](`t:BSV.Contract.t/0`) and a map of parameters. It
  must return the updated [`contract`](`t:BSV.Contract.t/0`).
  """
  @callback locking_script(t(), map()) :: t()

  @doc """
  Callback executed to generate the contract unlocking script.

  Is passed the [`contract`](`t:BSV.Contract.t/0`) and a map of parameters. It
  must return the updated [`contract`](`t:BSV.Contract.t/0`).
  """
  @callback unlocking_script(t(), map()) :: t()

  @optional_callbacks unlocking_script: 2

  @doc """
  Puts the given [`transaction context`](`t:BSV.Contract.ctx/0`) (tx and vin)
  onto the contract.

  When the transaction context is attached, the contract can generate valid
  signatures. If it is not attached, all signatures will be 71 bytes of zeros.
  """
  @spec put_ctx(t(), ctx()) :: t()
  def put_ctx(%__MODULE__{} = contract, {%Tx{} = tx, vin}) when is_integer(vin),
    do: Map.put(contract, :ctx, {tx, vin})

  @doc """
  Appends the given value onto the end of the contract script.
  """
  @spec script_push(t(), atom() | integer() | binary()) :: t()
  def script_push(%__MODULE__{} = contract, val),
    do: update_in(contract.script, & Script.push(&1, val))

  @doc """
  Returns the size (in bytes) of the contract script.
  """
  @spec script_size(t()) :: non_neg_integer()
  def script_size(%__MODULE__{} = contract) do
    contract
    |> to_script()
    |> Script.to_binary()
    |> byte_size()
  end

  @doc """
  Compiles the contract and returns the script.
  """
  @spec to_script(t()) :: Script.t()
  def to_script(%__MODULE__{mfa: {mod, fun, args}} = contract) do
    %{script: script} = apply(mod, fun, [contract | args])
    script
  end

  @doc """
  Compiles the unlocking contract and returns the `t:BSV.TxIn.t/0`.
  """
  @spec to_txin(t()) :: TxIn.t()
  def to_txin(%__MODULE__{subject: %UTXO{outpoint: outpoint}} = contract) do
    sequence = Keyword.get(contract.opts, :sequence, 0xFFFFFFFF)
    script = to_script(contract)
    struct(TxIn, prevout: outpoint, script: script, sequence: sequence)
  end

  @doc """
  Compiles the locking contract and returns the `t:BSV.TxIn.t/0`.
  """
  @spec to_txout(t()) :: TxOut.t()
  def to_txout(%__MODULE__{subject: satoshis} = contract)
    when is_integer(satoshis)
  do
    script = to_script(contract)
    struct(TxOut, satoshis: satoshis, script: script)
  end

  @doc """
  Simulates the contract with the given locking and unlocking parameters.

  Internally this works by creating a fake transaction containing the locking
  script, and then attempts to spend that UTXO in a second fake transaction.
  The entire script is concatenated and passed to `VM.eval/2`.

  ## Example

      iex> alias BSV.Contract.P2PKH
      iex> keypair = BSV.KeyPair.new()
      iex> lock_params = %{address: BSV.Address.from_pubkey(keypair.pubkey)}
      iex> unlock_params = %{keypair: keypair}
      iex>
      iex> {:ok, vm} = Contract.simulate(P2PKH, lock_params, unlock_params)
      iex> BSV.VM.valid?(vm)
      true
  """
  @spec simulate(module(), map(), map()) :: {:ok, VM.t()} | {:error, VM.t()}
  def simulate(mod, %{} = lock_params, %{} = unlock_params) when is_atom(mod) do
    %Tx{outputs: [txout]} = lock_tx = TxBuilder.to_tx(%TxBuilder{
      outputs: [apply(mod, :lock, [1000, lock_params])]
    })

    utxo = UTXO.from_tx(lock_tx, 0)

    %Tx{inputs: [txin]} = tx = TxBuilder.to_tx(%TxBuilder{
      inputs: [apply(mod, :unlock, [utxo, unlock_params])]
    })

    VM.eval(%VM{ctx: {tx, 0, txout}}, txin.script.chunks ++ txout.script.chunks)
  end

end
