defmodule BSV.Contract.Helpers do
  @moduledoc """
  Base helper module containing helper functions for use in `BSV.Contract`
  modules.

  Using `BSV.Contract.Helpers` will import itself and all related helper modules
  into your context.

      use BSV.Contract.Helpers

  Alternative, helper modules can be imported individually.

      import BSV.Contract.Helpers
      import BSV.Contract.OpCodeHelpers
      import BSV.Contract.VarIntHelpers
  """
  alias BSV.{Contract, PrivKey, Sig, UTXO}
  import BSV.Contract.OpCodeHelpers

  defmacro __using__(_) do
    quote do
      import BSV.Contract.Helpers
      import BSV.Contract.OpCodeHelpers
      import BSV.Contract.VarIntHelpers
    end
  end

  @doc """
  Assuming the top stack element is an unsigned integer, casts it to a
  `BSV.ScriptNum.t()` encoded number.
  """
  @spec decode_uint(Contract.t(), atom()) :: Contract.t()
  def decode_uint(contract, endianess \\ :little)
  def decode_uint(%Contract{} = contract, endianess)
    when endianess in [:le, :little]
  do
    contract
    |> push(<<0>>)
    |> op_cat()
    |> op_bin2num()
  end

  # TODO encode big endian decoding
  def decode_uint(%Contract{} = _contract, endianess)
    when endianess in [:be, :big],
    do: raise "Big endian decoding not implemented yet"

  @doc """
  Iterates over the given enumerable, invoking the `handle_each` function on
  each.

  ## Example

      contract
      |> each(["foo", "bar", "baz"], fn el, c ->
        c
        |> push(el)
        |> op_cat()
      end)
  """
  @spec each(
    Contract.t(),
    Enum.t(),
    (Enum.element(), Contract.t() -> Contract.t())
  ) :: Contract.t()
  def each(%Contract{} = contract, enum, handle_each)
    when is_function(handle_each),
    do: Enum.reduce(enum, contract, handle_each)

  @doc """
  Pushes the given data onto the script. If a list of data elements is given,
  each will be pushed to the script as seperate pushdata elements.
  """
  @spec push(
      Contract.t(),
      atom() | binary() | integer() |
      list(atom() | binary() | integer())
    ) ::Contract.t()
  def push(%Contract{} = contract, data) when is_list(data),
    do: each(contract, data, &push(&2, &1))

  def push(%Contract{} = contract, data),
    do: Contract.script_push(contract, data)

  @doc """
  Iterates the given number of times, invoking the `handle_each` function on
  each iteration.

  ## Example

      contract
      |> repeat(5, fn _i, c ->
        c
        |> op_5()
        |> op_add()
      end)
  """
  @spec repeat(
    Contract.t(),
    non_neg_integer(),
    (non_neg_integer(), Contract.t() -> Contract.t())
  ) :: Contract.t()
  def repeat(%Contract{} = contract, loops, handle_each)
    when is_integer(loops) and loops > 0
    and is_function(handle_each),
    do: Enum.reduce(0..loops-1, contract, handle_each)

  @doc """
  Reverses the top item on the stack.

  This helper function pushes op codes on to the script that will reverse a
  binary of the given length.
  """
  @spec reverse(Contract.t(), integer()) :: Contract.t()
  def reverse(%Contract{} = contract, length)
    when is_integer(length) and length > 1
  do
    contract
    |> repeat(length-1, fn _i, contract ->
      contract
      |> op_1()
      |> op_split()
    end)
    |> repeat(length-1, fn _i, contract ->
      contract
      |> op_swap()
      |> op_cat()
    end)
  end

  @doc """
  Signs the transaction [`context`](`t:BSV.Contract.ctx/0`) and pushes the
  signature onto the script.

  A list of private keys can be given, in which case each is used to sign and
  multiple signatures are added.

  If no context is available in the [`contract`](`t:BSV.Contract.t/0`), then
  71 bytes of zeros are pushed onto the script for each private key.
  """
  @spec sig(Contract.t(), PrivKey.t() | list(PrivKey.t())) :: Contract.t()
  def sig(%Contract{} = contract, privkey) when is_list(privkey),
    do: each(contract, privkey, &sig(&2, &1))

  def sig(
    %Contract{ctx: {tx, index}, opts: opts, subject: %UTXO{txout: txout}} = contract,
    %PrivKey{} = privkey
  ) do
    signature = Sig.sign(tx, index, txout, privkey, opts)
    Contract.script_push(contract, signature)
  end

  def sig(%Contract{ctx: nil} = contract, %PrivKey{} = _privkey),
    do: Contract.script_push(contract, <<0::568>>)

  @doc """
  Extracts the bytes from top item on the stack, starting on the given `start`
  index for `length` bytes. The stack item is replaced with the sliced value.

  Binaries are zero indexed. If `start` is a negative integer, then the start
  index is counted from the end.
  """
  @spec slice(Contract.t(), integer(), non_neg_integer()) :: Contract.t()
  def slice(%Contract{} = contract, start, length) when start < 0 do
    contract
    |> op_size()
    |> push(start * -1)
    |> op_sub()
    |> op_split()
    |> op_nip()
    |> slice(0, length)
  end

  def slice(%Contract{} = contract, start, length) when start > 0 do
    contract
    |> trim(start)
    |> slice(0, length)
  end

  def slice(%Contract{} = contract, 0, length) do
    contract
    |> push(length)
    |> op_split()
    |> op_drop()
  end

  @doc """
  Trims the given number of leading or trailing bytes from the top item on the
  stack. The stack item is replaced with the trimmed value.

  When the given `length` is a positive integer, leading bytes are trimmed. When
  a negative integer is given, trailing bytes are trimmed.
  """
  @spec trim(Contract.t(), integer()) :: Contract.t()
  def trim(%Contract{} = contract, length) when length > 0 do
    contract
    |> push(length)
    |> op_split()
    |> op_nip()
  end

  def trim(%Contract{} = contract, length) when length < 0 do
    contract
    |> op_size()
    |> push(length * -1)
    |> op_sub()
    |> op_split()
    |> op_drop()
  end

  def trim(%Contract{} = contract, 0), do: contract

end
