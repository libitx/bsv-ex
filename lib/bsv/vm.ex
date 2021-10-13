defmodule BSV.VM do
  @moduledoc """
  Pure Elixir Bitcoin Script VM.
  """
  use Bitwise
  alias BSV.{PubKey, Script, ScriptNum, Sig, Tx, TxOut, Util}

  @default_opts %{}

  defstruct ctx: nil,
            stack: [],
            alt_stack: [],
            if_stack: [],
            op_return: [],
            opts: @default_opts,
            error: nil

  @typedoc "TODO"
  @type t :: %__MODULE__{
    ctx: ctx() | nil,
    stack: list(),
    alt_stack: list(),
    if_stack: list(),
    op_return: list(),
    opts: map(),
    error: nil | String.t
  }

  @typedoc "TODO"
  @type ctx() :: {Tx.t(), non_neg_integer(), TxOut.t()}

  @doc """
  Initiates a new VM struct
  """
  @spec init(keyword()) :: t()
  def init(opts) do
    %__MODULE__{opts: Enum.into(opts, @default_opts)}
  end

  @doc """
  Evaluates the given script and returns a VM state.
  """
  @spec eval(t(), Script.t() | list()) :: {:ok, t()} | {:error, t()}
  def eval(%__MODULE__{} = vm, %Script{chunks: chunks}),
    do: eval(vm, chunks)

  def eval(%__MODULE__{error: error} = vm, _chunks)
    when not is_nil(error),
    do: {:error, vm}

  def eval(%__MODULE__{op_return: op_return} = vm, _chunks)
    when length(op_return) > 0,
    do: {:ok, vm}

  def eval(%__MODULE__{} = vm, []),
    do: {:ok, vm}

  def eval(%__MODULE__{if_stack: [{:IF, false} | _]} = vm, [op | rest])
    when op != :OP_ELSE and op != :OP_ENDIF,
    do: eval(vm, rest)

  def eval(%__MODULE__{if_stack: [{:ELSE, false} | _]} = vm, [op | rest])
    when op != :OP_ENDIF,
    do: eval(vm, rest)

  def eval(%__MODULE__{} = vm, [chunk | rest]) do
    vm = case chunk do
      data when is_binary(data) or is_number(data) -> op_pushdata(vm, data)

      # 1. Constants
      :OP_FALSE -> op_pushdata(vm, 0)
      :OP_0 -> op_pushdata(vm, 0)
      :OP_1NEGATE -> op_pushdata(vm, -1)
      :OP_TRUE -> op_pushdata(vm, 1)
      :OP_1 -> op_pushdata(vm, 1)
      :OP_2 -> op_pushdata(vm, 2)
      :OP_3 -> op_pushdata(vm, 3)
      :OP_4 -> op_pushdata(vm, 4)
      :OP_5 -> op_pushdata(vm, 5)
      :OP_6 -> op_pushdata(vm, 6)
      :OP_7 -> op_pushdata(vm, 7)
      :OP_8 -> op_pushdata(vm, 8)
      :OP_9 -> op_pushdata(vm, 9)
      :OP_10 -> op_pushdata(vm, 10)
      :OP_11 -> op_pushdata(vm, 11)
      :OP_12 -> op_pushdata(vm, 12)
      :OP_13 -> op_pushdata(vm, 13)
      :OP_14 -> op_pushdata(vm, 14)
      :OP_15 -> op_pushdata(vm, 15)
      :OP_16 -> op_pushdata(vm, 16)

      # 2. Control
      :OP_NOP -> op_nop(vm)
      :OP_VER -> op_ver(vm)
      :OP_IF -> op_if(vm)
      :OP_NOTIF -> op_notif(vm)
      :OP_VERIF -> op_verif(vm)
      :OP_VERNOTIF -> op_vernotif(vm)
      :OP_ELSE -> op_else(vm)
      :OP_ENDIF -> op_endif(vm)
      :OP_VERIFY -> op_verify(vm)
      :OP_RETURN -> op_return(vm, rest)

      # 3. Stack
      :OP_TOALTSTACK -> op_toaltstack(vm)
      :OP_FROMALTSTACK -> op_fromaltstack(vm)
      :OP_2DROP -> op_2drop(vm)
      :OP_2DUP -> op_2dup(vm)
      :OP_3DUP -> op_3dup(vm)
      :OP_2OVER -> op_2over(vm)
      :OP_2ROT -> op_2rot(vm)
      :OP_2SWAP -> op_2swap(vm)
      :OP_IFDUP -> op_ifdup(vm)
      :OP_DEPTH -> op_depth(vm)
      :OP_DROP -> op_drop(vm)
      :OP_DUP -> op_dup(vm)
      :OP_NIP -> op_nip(vm)
      :OP_OVER -> op_over(vm)
      :OP_PICK -> op_pick(vm)
      :OP_ROLL -> op_roll(vm)
      :OP_ROT -> op_rot(vm)
      :OP_SWAP -> op_swap(vm)
      :OP_TUCK -> op_tuck(vm)

      # 4. Data manipulation
      :OP_CAT -> op_cat(vm)
      :OP_SPLIT -> op_split(vm)
      :OP_NUM2BIN -> op_num2bin(vm)
      :OP_BIN2NUM -> op_bin2num(vm)
      :OP_SIZE -> op_size(vm)

      # 5. Bitwise logic
      :OP_INVERT -> op_invert(vm)
      :OP_AND -> op_and(vm)
      :OP_OR -> op_or(vm)
      :OP_XOR -> op_xor(vm)
      :OP_EQUAL -> op_equal(vm)
      :OP_EQUALVERIFY -> op_equalverify(vm)

      # 6. Arithmetic
      :OP_1ADD -> op_1add(vm)
      :OP_1SUB -> op_1sub(vm)
      :OP_2MUL -> op_2mul(vm)
      :OP_2DIV -> op_2div(vm)
      :OP_NEGATE -> op_negate(vm)
      :OP_ABS -> op_abs(vm)
      :OP_NOT -> op_not(vm)
      :OP_0NOTEQUAL -> op_0notequal(vm)
      :OP_ADD -> op_add(vm)
      :OP_SUB -> op_sub(vm)
      :OP_MUL -> op_mul(vm)
      :OP_DIV -> op_div(vm)
      :OP_MOD -> op_mod(vm)
      :OP_LSHIFT -> op_lshift(vm)
      :OP_RSHIFT -> op_rshift(vm)
      :OP_BOOLAND -> op_booland(vm)
      :OP_BOOLOR -> op_boolor(vm)
      :OP_NUMEQUAL -> op_numequal(vm)
      :OP_NUMEQUALVERIFY -> op_numequalverify(vm)
      :OP_NUMNOTEQUAL -> op_numnotequal(vm)
      :OP_LESSTHAN -> op_lessthan(vm)
      :OP_GREATERTHAN -> op_greaterthan(vm)
      :OP_LESSTHANOREQUAL -> op_lessthanorequal(vm)
      :OP_GREATERTHANOREQUAL -> op_greaterthanorequal(vm)
      :OP_MIN -> op_min(vm)
      :OP_MAX -> op_max(vm)
      :OP_WITHIN -> op_within(vm)

      # 7. Cryptography
      :OP_RIPEMD160 -> op_ripemd160(vm)
      :OP_SHA1 -> op_sha1(vm)
      :OP_SHA256 -> op_sha256(vm)
      :OP_HASH160 -> op_hash160(vm)
      :OP_HASH256 -> op_hash256(vm)
      :OP_CODESEPARATOR -> op_nop(vm)
      :OP_CHECKSIG -> op_checksig(vm)
      :OP_CHECKSIGVERIFY -> op_checksigverify(vm)
      :OP_CHECKMULTISIG -> op_checkmultisig(vm)
      :OP_CHECKMULTISIGVERIFY -> op_checkmultisigverify(vm)

      # Nops and reserved words
      :OP_NOP1 -> op_nop(vm)
      :OP_NOP2 -> op_nop(vm)
      :OP_NOP3 -> op_nop(vm)
      :OP_NOP4 -> op_nop(vm)
      :OP_NOP5 -> op_nop(vm)
      :OP_NOP6 -> op_nop(vm)
      :OP_NOP7 -> op_nop(vm)
      :OP_NOP8 -> op_nop(vm)
      :OP_NOP9 -> op_nop(vm)
      :OP_NOP10 -> op_nop(vm)
      :OP_RESERVED -> op_reserved(vm)
      :OP_RESERVED1 -> op_reserved(vm)
      :OP_RESERVED2 -> op_reserved(vm)
    end

    eval(vm, rest)
  end

  def eval(%__MODULE__{} = vm, chunk) when is_atom(chunk) or is_binary(chunk),
    do: eval(vm, [chunk])

  @doc """
  As `eval/2` but returns the VM struct or raises an error.
  """
  @spec eval!(t(), Script.t() | list()) :: t()
  def eval!(vm, script) do
    case eval(vm, script) do
      {:ok, vm} ->
        vm
      {:error, %__MODULE__{:error => error}} ->
        raise error
    end
  end

  @doc """
  Generic pushdata. Pushes any given binary or integer to the stack.
  """
  @spec op_pushdata(t(), binary() | number()) :: t()
  def op_pushdata(vm, data) when is_binary(data),
    do: update_in(vm.stack, & [data | &1])

  def op_pushdata(vm, data) when is_number(data),
    do: op_pushdata(vm, ScriptNum.encode(data))

  @doc """
  No op. Does nothing and returns the vm.
  """
  @spec op_nop(t()) :: t()
  def op_nop(%__MODULE__{} = vm), do: vm

  @doc """
  Puts the version of the protocol under which this transaction will be
  evaluated onto the stack. **DISABLED**
  """
  @spec op_ver(t()) :: t()
  def op_ver(%__MODULE__{} = vm), do: err(vm, "OP_VER disabled")

  @doc """
  Removes the top of the stack. If the top value is truthy, statements between
  OP_IF and OP_ELSE are executed. Otherwise statements between OP_ELSE and
  OP_ENDIF are executed.
  """
  @spec op_if(t()) :: t()
  def op_if(%__MODULE__{stack: []} = vm), do: err(vm, "OP_IF stack empty")
  def op_if(%__MODULE__{stack: [top | _stack]} = vm) do
    vm
    |> op_drop()
    |> Map.update(:if_stack, [], & [{:IF, true?(top)} | &1])
  end

  @doc """
  Removes the top of the stack. If the top value is false, statements between
  OP_NOTIF and OP_ELSE are executed. Otherwise statements between OP_ELSE and
  OP_ENDIF are executed.
  """
  @spec op_notif(t()) :: t()
  def op_notif(%__MODULE__{stack: []} = vm), do: err(vm, "OP_NOTIF stack empty")
  def op_notif(%__MODULE__{stack: [top | _stack]} = vm) do
    vm
    |> op_drop()
    |> Map.update(:if_stack, [], & [{:IF, !true?(top)} | &1])
  end

  @doc """
  Removes the top of the stack. If the top value is equal to the version of the
  protocol under which the transaction is evaluated, statements between OP_IF
  and OP_ELSE are executed. Otherwise statements between OP_ELSE and OP_ENDIF
  are executed. **DISABLED**
  """
  @spec op_verif(t()) :: t()
  def op_verif(%__MODULE__{} = vm), do: err(vm, "OP_VERIF disabled")

  @doc """
  Removes the top of the stack. If the top value is not equal to the version of
  the protocol under which the transaction is evaluated, statements between
  OP_IF and OP_ELSE are executed. Otherwise statements between OP_ELSE and
  OP_ENDIF are executed. **DISABLED**
  """
  @spec op_vernotif(t()) :: t()
  def op_vernotif(%__MODULE__{} = vm), do: err(vm, "OP_VERNOTIF disabled")

  @doc """
  If the preceding OP_IF or OP_NOTIF was not executed, the the following
  statements are executed. If the preceding OP_IF or OP_NOTIF was executed, the
  following statements are not.
  """
  @spec op_else(t()) :: t()
  def op_else(%__MODULE__{if_stack: []} = vm),
    do: err(vm, "OP_ELSE used outside of IF block")

  def op_else(%__MODULE__{if_stack: [{_, bool} | if_stack]} = vm),
    do: put_in(vm.if_stack, [{:ELSE, !bool} | if_stack])

  @doc """
  Ends the current IF/ELSE block. All blocks must end or the script is
  **invalid**.
  """
  @spec op_endif(t()) :: t()
  def op_endif(%__MODULE__{if_stack: []} = vm),
    do: err(vm, "OP_ENDIF used outside of IF block")

  def op_endif(%__MODULE__{if_stack: [_ | if_stack]} = vm),
    do: put_in(vm.if_stack, if_stack)

  @doc """
  Mmarks the script as **invalid** unless the stack is truthy. Removes the top
  of the stack.
  """
  @spec op_verify(t()) :: t()
  def op_verify(%__MODULE__{stack: []} = vm),
    do: err(vm, "OP_VERIFY stack empty")

  def op_verify(%__MODULE__{stack: [top | stack]} = vm) do
    case true?(top) do
      true -> put_in(vm.stack, stack)
      false -> err(vm, "OP_VERIFY failed")
    end
  end

  @doc """
  Returns the vm and no further statements are evaluated.
  """
  @spec op_return(t, list) :: t()
  def op_return(%__MODULE__{} = vm, chunks),
    do: put_in(vm.op_return, chunks)

  @doc """
  Removes the top of the stack and puts it into the alt stack.
  """
  @spec op_toaltstack(t()) :: t()
  def op_toaltstack(%__MODULE__{stack: []} = vm),
    do: err(vm, "OP_TOALTSTACK stack empty")

  def op_toaltstack(%__MODULE__{stack: [top | stack]} = vm) do
    vm
    |> Map.update(:alt_stack, [], & [top | &1])
    |> Map.put(:stack, stack)
  end

  @doc """
  Removes the top of the alt stack and puts it into the stack.
  """
  @spec op_fromaltstack(t()) :: t()
  def op_fromaltstack(%__MODULE__{alt_stack: []} = vm),
    do: err(vm, "OP_FROMALTSTACK alt stack empty")

  def op_fromaltstack(%__MODULE__{alt_stack: [top | stack]} = vm) do
    vm
    |> Map.update(:stack, [], & [top | &1])
    |> Map.put(:alt_stack, stack)
  end

  @doc """
  Removes the top two items from the stack.
  """
  @spec op_2drop(t()) :: t()
  def op_2drop(%__MODULE__{stack: stack} = vm)
    when length(stack) < 2,
    do: err(vm, "OP_2DROP invalid stack length")

  def op_2drop(%__MODULE__{stack: [_, _ | stack]} = vm),
    do: put_in(vm.stack, stack)

  @doc """
  Duplicates the top two items on the stack.
  """
  @spec op_2dup(t()) :: t()
  def op_2dup(%__MODULE__{stack: stack} = vm)
    when length(stack) < 2,
    do: err(vm, "OP_2DUP invalid stack length")

  def op_2dup(%__MODULE__{stack: [a, b | _]} = vm),
    do: update_in(vm.stack, & [a, b | &1])

  @doc """
  Duplicates the top three items on the stack.
  """
  @spec op_3dup(t()) :: t()
  def op_3dup(%__MODULE__{stack: stack} = vm)
    when length(stack) < 3,
    do: err(vm, "OP_3DUP invalid stack length")

  def op_3dup(%__MODULE__{stack: [a, b, c | _]} = vm),
    do: update_in(vm.stack, & [a, b, c | &1])

  @doc """
  Copies two items two spaces back to the top of the stack.
  """
  @spec op_2over(t()) :: t()
  def op_2over(%__MODULE__{stack: stack} = vm)
    when length(stack) < 4,
    do: err(vm, "OP_2OVER invalid stack length")

  def op_2over(%__MODULE__{stack: [_a, _b, c, d | _]} = vm),
    do: update_in(vm.stack, & [c, d | &1])

  @doc """
  Moves the 5th and 6th items to top of stack.
  """
  @spec op_2rot(t()) :: t()
  def op_2rot(%__MODULE__{stack: stack} = vm)
    when length(stack) < 6,
    do: err(vm, "OP_2ROT invalid stack length")

  def op_2rot(%__MODULE__{stack: [a, b, c, d, e, f | stack]} = vm),
    do: put_in(vm.stack, [e, f, a, b, c, d | stack])

  @doc """
  Swaps the top two pairs of items.
  """
  @spec op_2swap(t()) :: t()
  def op_2swap(%__MODULE__{stack: stack} = vm)
    when length(stack) < 4,
    do: err(vm, "OP_2SWAP invalid stack length")

  def op_2swap(%__MODULE__{stack: [a, b, c, d | stack]} = vm),
    do: put_in(vm.stack, [c, d, a, b | stack])

  @doc """
  Duplicates the top stack item if it is truthy.
  """
  @spec op_ifdup(t()) :: t()
  def op_ifdup(%__MODULE__{stack: []} = vm), do: err(vm, "OP_IFDUP stack empty")
  def op_ifdup(%__MODULE__{stack: [top | _]} = vm) do
    if true?(top), do: update_in(vm.stack, & [top | &1]), else: vm
  end

  @doc """
  Counts the stack lenth and puts the result on the top of the stack.
  """
  @spec op_depth(t()) :: t()
  def op_depth(%__MODULE__{stack: stack} = vm) do
    val = length(stack) |> ScriptNum.encode()
    put_in(vm.stack, [val | stack])
  end

  @doc """
  Removes the top item from the stack.
  """
  @spec op_drop(t()) :: t()
  def op_drop(%__MODULE__{stack: []} = vm), do: err(vm, "OP_DROP stack empty")
  def op_drop(%__MODULE__{stack: [_ | stack]} = vm), do: put_in(vm.stack, stack)

  @doc """
  Duplicates the top item on the stack.
  """
  @spec op_dup(t()) :: t()
  def op_dup(%__MODULE__{stack: []} = vm), do: err(vm, "OP_DUP stack empty")
  def op_dup(%__MODULE__{stack: [top | _]} = vm),
    do: update_in(vm.stack, & [top | &1])

  @doc """
  Removes the second to top item from the stack.
  """
  @spec op_nip(t()) :: t()
  def op_nip(%__MODULE__{stack: stack} = vm)
    when length(stack) < 2,
    do: err(vm, "OP_NIP invalid stack length")

  def op_nip(%__MODULE__{} = vm),
    do: update_in(vm.stack, & List.delete_at(&1, 1))

  @doc """
  Copies the second to top stack item to the top.
  """
  @spec op_over(t()) :: t()
  def op_over(%__MODULE__{stack: stack} = vm)
    when length(stack) < 2,
    do: err(vm, "OP_OVER invalid stack length")

  def op_over(%__MODULE__{stack: [_a, b | _]} = vm),
    do: update_in(vm.stack, & [b | &1])

  @doc """
  Removes the top stack item and uses it as an index length, then copies the nth
  item on the stack to the top.
  """
  @spec op_pick(t()) :: t()
  def op_pick(%__MODULE__{stack: []} = vm), do: err(vm, "OP_PICK stack empty")
  def op_pick(%__MODULE__{stack: [top | stack]} = vm) do
    i = ScriptNum.decode(top)
    case Enum.at(stack, i) do
      nil -> err(vm, "OP_PICK invalid stack length")
      val -> put_in(vm.stack, [val | stack])
    end
  end

  @doc """
  Removes the top stack item and uses it as an index length, then moves the nth
  item on the stack to the top.
  """
  @spec op_roll(t()) :: t()
  def op_roll(%__MODULE__{stack: []} = vm), do: err(vm, "OP_ROLL stack empty")
  def op_roll(%__MODULE__{stack: [top | stack]} = vm) do
    i = ScriptNum.decode(top)
    case List.pop_at(stack, i) do
      {nil, _} -> err(vm, "OP_ROLL invalid stack length")
      {val, stack} -> put_in(vm.stack, [val | stack])
    end
  end

  @doc """
  Rotates the top three items on the stack, effictively moving the 3rd item to
  the top of the stack.
  """
  @spec op_rot(t()) :: t()
  def op_rot(%__MODULE__{stack: stack} = vm)
    when length(stack) < 3,
    do: err(vm, "OP_ROT invalid stack length")

  def op_rot(%__MODULE__{stack: [a, b, c | stack]} = vm),
    do: put_in(vm.stack, [c, a, b | stack])

  @doc """
  Rotates the top two items on the stack, effectively moving the 2nd item to the
  top of the stack.
  """
  @spec op_swap(t()) :: t()
  def op_swap(%__MODULE__{stack: stack} = vm)
    when length(stack) < 2,
    do: err(vm, "OP_SWAP invalid stack length")

  def op_swap(%__MODULE__{stack: [a, b | stack]} = vm),
    do: put_in(vm.stack, [b, a | stack])

  @doc """
  Copies the top item on the stack and inserts it before the second to top item.
  """
  @spec op_tuck(t()) :: t()
  def op_tuck(%__MODULE__{stack: stack} = vm)
    when length(stack) < 2,
    do: err(vm, "OP_TUCK invalid stack length")

  def op_tuck(%__MODULE__{stack: [top | _]} = vm),
    do: update_in(vm.stack, & List.insert_at(&1, 2, top))

  @doc """
  Concatenates the top two stack items into one binary.
  """
  @spec op_cat(t()) :: t()
  def op_cat(%__MODULE__{stack: stack} = vm)
    when length(stack) < 2,
    do: err(vm, "OP_CAT invalid stack length")

  def op_cat(%__MODULE__{stack: [a, b | stack]} = vm),
    do: put_in(vm.stack, [b <> a | stack])

  @doc """
  Splits the second from top stack item by the index given in the top stack
  item.
  """
  @spec op_split(t()) :: t()
  def op_split(%__MODULE__{stack: stack} = vm)
    when length(stack) < 2,
    do: err(vm, "OP_SPLIT invalid stack length")

  def op_split(%__MODULE__{stack: [top, val | stack]} = vm) do
    i = ScriptNum.decode(top)
    <<a::binary-size(i), b::binary>> = val
    put_in(vm.stack, [b, a | stack])
  end

  @doc """
  Converts the second from top stack item into a binary of the length given in
  the top stack item.
  """
  @spec op_num2bin(t()) :: t()
  def op_num2bin(%__MODULE__{stack: stack} = vm)
    when length(stack) < 2,
    do: err(vm, "OP_NUM2BIN invalid stack length")

  def op_num2bin(%__MODULE__{stack: [top, bin | stack]} = vm) do
    with pad when pad >= 0 <- ScriptNum.decode(top) - byte_size(bin) do
      <<first, rest::binary>> = Util.reverse_bin(bin)
      <<_, rest::binary>> = :binary.copy(<<0>>, pad) <> <<first &&& 127, rest::binary>>
      val = Util.reverse_bin(<<first &&& 128, rest::binary>>)
      put_in(vm.stack, [val | stack])
    else
      _ ->
        err(vm, "OP_NUM2BIN invalid length")
    end
  end

  @doc """
  Converts the binary value into a numeric value.
  """
  @spec op_bin2num(t()) :: t()
  def op_bin2num(%__MODULE__{stack: []} = vm),
    do: err(vm, "OP_BIN2NUM stack empty")

  def op_bin2num(%__MODULE__{stack: [top | stack]} = vm) do
    val = ScriptNum.decode(top)
    put_in(vm.stack, [ScriptNum.encode(val) | stack])
  end

  @doc """
  Pushes the byte length of the top element of the stack, without popping it.
  """
  @spec op_size(t()) :: t()
  def op_size(%__MODULE__{stack: []} = vm), do: err(vm, "OP_SIZE stack empty")
  def op_size(%__MODULE__{stack: [top | _] = stack} = vm) do
    val = byte_size(top) |> ScriptNum.encode()
    put_in(vm.stack, [val | stack])
  end

  @doc """
  Flips all bits on the top element of the stack.
  """
  @spec op_invert(t()) :: t()
  def op_invert(%__MODULE__{stack: []} = vm), do: err(vm, "OP_INVERT stack empty")
  def op_invert(%__MODULE__{stack: [top | stack]} = vm) do
    val = top
    |> :binary.bin_to_list()
    |> Enum.map(& bxor(&1, 255))
    |> :binary.list_to_bin()
    put_in(vm.stack, [val | stack])
  end

  @doc """
  Calculates the bitwise AND of the top two elements of the stack. Both elements
  must be the same length.
  """
  @spec op_and(t()) :: t()
  def op_and(%__MODULE__{stack: stack} = vm)
    when length(stack) < 2,
    do: err(vm, "OP_AND invalid stack length")

  def op_and(%__MODULE__{stack: [a, b | stack]} = vm)
    when is_binary(a) and is_binary(b)
    and byte_size(a) == byte_size(b)
  do
    val = [:binary.bin_to_list(b), :binary.bin_to_list(a)]
    |> List.zip()
    |> Enum.map(fn {b, a} -> b &&& a end)
    |> :binary.list_to_bin()
    put_in(vm.stack, [val | stack])
  end

  def op_and(%__MODULE__{} = vm),
    do: err(vm, "OP_AND invalid binary lengths")

  @doc """
  Calculates the bitwise OR of the top two elements of the stack. Both elements
  must be the same length.
  """
  @spec op_or(t()) :: t()
  def op_or(%__MODULE__{stack: stack} = vm)
    when length(stack) < 2,
    do: err(vm, "OP_OR invalid stack length")

  def op_or(%__MODULE__{stack: [a, b | stack]} = vm)
    when is_binary(a) and is_binary(b)
    and byte_size(a) == byte_size(b)
  do
    val = [:binary.bin_to_list(b), :binary.bin_to_list(a)]
    |> List.zip()
    |> Enum.map(fn {b, a} -> b ||| a end)
    |> :binary.list_to_bin()
    put_in(vm.stack, [val | stack])
  end

  def op_or(%__MODULE__{} = vm),
    do: err(vm, "OP_OR invalid binary lengths")

  @doc """
  Calculates the bitwise XOR of the top two elements of the stack. Both elements
  must be the same length.
  """
  @spec op_xor(t()) :: t()
  def op_xor(%__MODULE__{stack: stack} = vm)
    when length(stack) < 2,
    do: err(vm, "OP_XOR invalid stack length")

  def op_xor(%__MODULE__{stack: [a, b | stack]} = vm)
    when is_binary(a) and is_binary(b)
    and byte_size(a) == byte_size(b)
  do
    val = [:binary.bin_to_list(b), :binary.bin_to_list(a)]
    |> List.zip()
    |> Enum.map(fn {b, a} -> bxor(b, a) end)
    |> :binary.list_to_bin()
    put_in(vm.stack, [val | stack])
  end

  def op_xor(%__MODULE__{} = vm),
    do: err(vm, "OP_XOR invalid binary lengths")

  @doc """
  Compares the equality of the top two stack items and replaces them with the
  boolean result.
  """
  @spec op_equal(t()) :: t()
  def op_equal(%__MODULE__{stack: stack} = vm)
    when length(stack) < 2,
    do: err(vm, "OP_EQUAL invalid stack length")

  def op_equal(%__MODULE__{opts: %{simulate: true}, stack: [_a, _b | stack]} = vm),
    do: put_in(vm.stack, [ScriptNum.encode(1) | stack])

  def op_equal(%__MODULE__{stack: [a, b | stack]} = vm)
    when a == b,
    do: put_in(vm.stack, [ScriptNum.encode(1) | stack])

  def op_equal(%__MODULE__{stack: [_a, _b | stack]} = vm),
    do: put_in(vm.stack, [ScriptNum.encode(0) | stack])

  @doc """
  Runs `op_equal/1` and `op_verify/1`.
  """
  @spec op_equalverify(t()) :: t()
  def op_equalverify(%__MODULE__{} = vm), do: vm |> op_equal |> op_verify

  @doc """
  Adds 1 onto the top stack element.
  """
  @spec op_1add(t()) :: t()
  def op_1add(%__MODULE__{stack: []} = vm), do: err(vm, "OP_1ADD stack empty")
  def op_1add(%__MODULE__{stack: [top | stack]} = vm) do
    val = ScriptNum.decode(top) + 1
    put_in(vm.stack, [ScriptNum.encode(val) | stack])
  end

  @doc """
  Subtracks 1 from the top stack element.
  """
  @spec op_1sub(t()) :: t()
  def op_1sub(%__MODULE__{stack: []} = vm), do: err(vm, "OP_1SUB stack empty")
  def op_1sub(%__MODULE__{stack: [top | stack]} = vm) do
    val = ScriptNum.decode(top) - 1
    put_in(vm.stack, [ScriptNum.encode(val) | stack])
  end

  @doc """
  Multiplies the top stack element by 2. **DISABLED**
  """
  @spec op_2mul(t()) :: t()
  def op_2mul(%__MODULE__{} = vm), do: err(vm, "OP_2MUL disabled")

  @doc """
  Divides the top stack element by 2. **DISABLED**
  """
  @spec op_2div(t()) :: t()
  def op_2div(%__MODULE__{} = vm), do: err(vm, "OP_2DIV disabled")

  @doc """
  Negates the numeric value of the top stack element.
  """
  @spec op_negate(t()) :: t()
  def op_negate(%__MODULE__{stack: []} = vm), do: err(vm, "OP_NEGATE stack empty")
  def op_negate(%__MODULE__{stack: [top | stack]} = vm) do
    val = ScriptNum.decode(top) * -1
    put_in(vm.stack, [ScriptNum.encode(val) | stack])
  end

  @doc """
  Makes positive the numeric value of the top stack element.
  """
  @spec op_abs(t()) :: t()
  def op_abs(%__MODULE__{stack: []} = vm), do: err(vm, "OP_ABS stack empty")
  def op_abs(%__MODULE__{stack: [top | stack]} = vm) do
    val = ScriptNum.decode(top) |> abs()
    put_in(vm.stack, [ScriptNum.encode(val) | stack])
  end

  @doc """
  If the top stack element is false it is made true. Otherwise it is made false.
  """
  @spec op_not(t()) :: t()
  def op_not(%__MODULE__{stack: []} = vm), do: err(vm, "OP_NOT stack empty")
  def op_not(%__MODULE__{stack: [top | stack]} = vm) do
    val = if true?(top), do: 0, else: 1
    put_in(vm.stack, [ScriptNum.encode(val) | stack])
  end

  @doc """
  If the top stack element is not false it is made true. Otherwise it is made
  false.
  """
  @spec op_0notequal(t()) :: t()
  def op_0notequal(%__MODULE__{stack: []} = vm),
    do: err(vm, "OP_0NOTEQUAL stack empty")

  def op_0notequal(%__MODULE__{stack: [top | stack]} = vm) do
    val = if ScriptNum.decode(top) == 0, do: 0, else: 1
    put_in(vm.stack, [ScriptNum.encode(val) | stack])
  end

  @doc """
  The top two stack elements are added and replaced on the stack with the
  result.
  """
  @spec op_add(t()) :: t()
  def op_add(%__MODULE__{stack: stack} = vm)
    when length(stack) < 2,
    do: err(vm, "OP_ADD invalid stack length")

  def op_add(%__MODULE__{stack: [a, b | stack]} = vm) do
    val = ScriptNum.decode(b) + ScriptNum.decode(a)
    put_in(vm.stack, [ScriptNum.encode(val) | stack])
  end

  @doc """
  The top stack element is subtracted from the second, and both are replaced on
  the stack with the result.
  """
  @spec op_sub(t()) :: t()
  def op_sub(%__MODULE__{stack: stack} = vm)
    when length(stack) < 2,
    do: err(vm, "OP_SUB invalid stack length")

  def op_sub(%__MODULE__{stack: [a, b | stack]} = vm) do
    val = ScriptNum.decode(b) - ScriptNum.decode(a)
    put_in(vm.stack, [ScriptNum.encode(val) | stack])
  end

  @doc """
  The top two stack elements are multiplied and replaced on the stack with the
  result.
  """
  @spec op_mul(t()) :: t()
  def op_mul(%__MODULE__{stack: stack} = vm)
    when length(stack) < 2,
    do: err(vm, "OP_MUL invalid stack length")

  def op_mul(%__MODULE__{stack: [a, b | stack]} = vm) do
    val = ScriptNum.decode(b) * ScriptNum.decode(a)
    put_in(vm.stack, [ScriptNum.encode(val) | stack])
  end

  @doc """
  The top stack element is divided from the second, and both are replaced on
  the stack with the result.
  """
  @spec op_div(t()) :: t()
  def op_div(%__MODULE__{stack: stack} = vm)
    when length(stack) < 2,
    do: err(vm, "OP_DIV invalid stack length")

  def op_div(%__MODULE__{stack: [a, b | stack]} = vm) do
    val = div(ScriptNum.decode(b), ScriptNum.decode(a))
    put_in(vm.stack, [ScriptNum.encode(val) | stack])
  end

  @doc """
  The top stack element is divided from the second, and both are replaced on
  the stack with the remainder.
  """
  @spec op_mod(t()) :: t()
  def op_mod(%__MODULE__{stack: stack} = vm)
    when length(stack) < 2,
    do: err(vm, "OP_MOD invalid stack length")

  def op_mod(%__MODULE__{stack: [a, b | stack]} = vm) do
    val = rem(ScriptNum.decode(b), ScriptNum.decode(a))
    put_in(vm.stack, [ScriptNum.encode(val) | stack])
  end

  @doc """
  The second from top element numeric value is bitshifted to the left by the
  number of bits in the top element numeric value. Both elements are replaced
  on the stack with the result.
  """
  @spec op_lshift(t()) :: t()
  def op_lshift(%__MODULE__{stack: stack} = vm)
    when length(stack) < 2,
    do: err(vm, "OP_LSHIFT invalid stack length")

  def op_lshift(%__MODULE__{stack: [top, bin | stack]} = vm) do
    case ScriptNum.decode(top) do
      len when len < 0 ->
        err(vm, "OP_LSHIFT invalid shift length")
      len ->
        res = bin
        |> :binary.decode_unsigned()
        |> bsl(len)
        |> :binary.encode_unsigned()
        res = case byte_size(res) - byte_size(bin) do
          diff when diff > 0 ->
            :binary.part(res, diff, byte_size(bin))
          diff ->
            :binary.copy(<<0>>, diff * -1) <> res
        end
        put_in(vm.stack, [res | stack])
    end
  end

  @doc """
  The second from top element numeric value is bitshifted to the right by the
  number of bits in the top element numeric value. Both elements are replaced
  on the stack with the result.
  """
  @spec op_rshift(t()) :: t()
  def op_rshift(%__MODULE__{stack: stack} = vm)
    when length(stack) < 2,
    do: err(vm, "OP_RSHIFT invalid stack length")

  def op_rshift(%__MODULE__{stack: [top, bin | stack]} = vm) do
    case ScriptNum.decode(top) do
      len when len < 0 ->
        err(vm, "OP_RSHIFT invalid shift length")
      len ->
        res = bin
        |> :binary.decode_unsigned()
        |> bsr(len)
        |> :binary.encode_unsigned()
        res = case byte_size(res) - byte_size(bin) do
          diff when diff > 0 ->
            :binary.part(res, diff, byte_size(bin))
          diff ->
            :binary.copy(<<0>>, diff * -1) <> res
        end
        put_in(vm.stack, [res | stack])
    end
  end

  @doc """
  Checks the top two stack elements are both truthy and replaces them with the
  boolean result.
  """
  @spec op_booland(t()) :: t()
  def op_booland(%__MODULE__{stack: stack} = vm)
    when length(stack) < 2,
    do: err(vm, "OP_BOOLAND invalid stack length")

  def op_booland(%__MODULE__{stack: [a, b | stack]} = vm) do
    res = if true?(a) and true?(b), do: 1, else: 0
    put_in(vm.stack, [ScriptNum.encode(res) | stack])
  end

  @doc """
  Checks if either of the top two stack elements are truthy and replaces them
  with the boolean result.
  """
  @spec op_boolor(t()) :: t()
  def op_boolor(%__MODULE__{stack: stack} = vm)
    when length(stack) < 2,
    do: err(vm, "OP_BOOLOR invalid stack length")

  def op_boolor(%__MODULE__{stack: [a, b | stack]} = vm) do
    res = if true?(a) or true?(b), do: 1, else: 0
    put_in(vm.stack, [ScriptNum.encode(res) | stack])
  end

  @doc """
  Compares the equality of the numeric value of the top two stack items and
  replaces them with the boolean result.
  """
  @spec op_numequal(t()) :: t()
  def op_numequal(%__MODULE__{stack: stack} = vm)
    when length(stack) < 2,
    do: err(vm, "OP_NUMEQUAL invalid stack length")

  def op_numequal(%__MODULE__{opts: %{simulate: true}, stack: [_a, _b | stack]} = vm),
    do: put_in(vm.stack, [ScriptNum.encode(1) | stack])

  def op_numequal(%__MODULE__{stack: [a, b | stack]} = vm) do
    res = if ScriptNum.decode(a) == ScriptNum.decode(b), do: 1, else: 0
    put_in(vm.stack, [ScriptNum.encode(res) | stack])
  end

  @doc """
  Runs `op_numequal/1` and `op_verify/1`.
  """
  @spec op_numequalverify(t()) :: t()
  def op_numequalverify(%__MODULE__{} = vm), do: vm |> op_numequal |> op_verify

  @doc """
  Checks the numeric value of the top two stack items are not equal and replaces
  them with the boolean result.
  """
  @spec op_numnotequal(t()) :: t()
  def op_numnotequal(%__MODULE__{stack: stack} = vm)
    when length(stack) < 2,
    do: err(vm, "OP_NUMNOTEQUAL invalid stack length")

  def op_numnotequal(%__MODULE__{stack: [a, b | stack]} = vm) do
    res = if ScriptNum.decode(a) != ScriptNum.decode(b), do: 1, else: 0
    put_in(vm.stack, [ScriptNum.encode(res) | stack])
  end

  @doc """
  Compares numeric value of the top two stack elements, and both are replaced on
  the stack with the result. Is true if the second element is less than the
  first.
  """
  @spec op_lessthan(t()) :: t()
  def op_lessthan(%__MODULE__{stack: stack} = vm)
    when length(stack) < 2,
    do: err(vm, "OP_LESSTHAN invalid stack length")

  def op_lessthan(%__MODULE__{stack: [a, b | stack]} = vm) do
    res = if ScriptNum.decode(a) > ScriptNum.decode(b), do: 1, else: 0
    put_in(vm.stack, [ScriptNum.encode(res) | stack])
  end

  @doc """
  Compares numeric value of the top two stack elements, and both are replaced on
  the stack with the result. Is true if the second element is greater than the
  first.
  """
  @spec op_greaterthan(t()) :: t()
  def op_greaterthan(%__MODULE__{stack: stack} = vm)
    when length(stack) < 2,
    do: err(vm, "OP_GREATERTHAN invalid stack length")

  def op_greaterthan(%__MODULE__{stack: [a, b | stack]} = vm) do
    res = if ScriptNum.decode(a) < ScriptNum.decode(b), do: 1, else: 0
    put_in(vm.stack, [ScriptNum.encode(res) | stack])
  end

  @doc """
  Compares numeric value of the top two stack elements, and both are replaced on
  the stack with the result. Is true if the second element is less than or equal
  to the first.
  """
  @spec op_lessthanorequal(t()) :: t()
  def op_lessthanorequal(%__MODULE__{stack: stack} = vm)
    when length(stack) < 2,
    do: err(vm, "OP_LESSTHANOREQUAL invalid stack length")

  def op_lessthanorequal(%__MODULE__{stack: [a, b | stack]} = vm) do
    res = if ScriptNum.decode(a) >= ScriptNum.decode(b), do: 1, else: 0
    put_in(vm.stack, [ScriptNum.encode(res) | stack])
  end

  @doc """
  Compares numeric value of the top two stack elements, and both are replaced on
  the stack with the result. Is true if the second element is greater than or
  equal to the first.
  """
  @spec op_greaterthanorequal(t()) :: t()
  def op_greaterthanorequal(%__MODULE__{stack: stack} = vm)
    when length(stack) < 2,
    do: err(vm, "OP_GREATERTHANOREQUAL invalid stack length")

  def op_greaterthanorequal(%__MODULE__{stack: [a, b | stack]} = vm) do
    res = if ScriptNum.decode(a) <= ScriptNum.decode(b), do: 1, else: 0
    put_in(vm.stack, [ScriptNum.encode(res) | stack])
  end

  @doc """
  Compares numeric value of the top two stack elements, and both are replaced
  with the smaller value.
  """
  @spec op_min(t()) :: t()
  def op_min(%__MODULE__{stack: stack} = vm)
    when length(stack) < 2,
    do: err(vm, "OP_MIN invalid stack length")

  def op_min(%__MODULE__{stack: [a, b | stack]} = vm) do
    val = Enum.min([ScriptNum.decode(a), ScriptNum.decode(b)])
    put_in(vm.stack, [ScriptNum.encode(val) | stack])
  end

  @doc """
  Compares numeric value of the top two stack elements, and both are replaced
  with the greater value.
  """
  @spec op_max(t()) :: t()
  def op_max(%__MODULE__{stack: stack} = vm)
    when length(stack) < 2,
    do: err(vm, "OP_MAX invalid stack length")

  def op_max(%__MODULE__{stack: [a, b | stack]} = vm) do
    val = Enum.max([ScriptNum.decode(a), ScriptNum.decode(b)])
    put_in(vm.stack, [ScriptNum.encode(val) | stack])
  end

  @doc """
  The top (max) and second (min) numeric values on the stack define a range and
  the third element is checked to see if it is within the range. All three
  elements are replaced on the stack with the boolean result.
  """
  @spec op_within(t()) :: t()
  def op_within(%__MODULE__{stack: stack} = vm)
    when length(stack) < 3,
    do: err(vm, "OP_WITHIN invalid stack length")

  def op_within(%__MODULE__{stack: [max, min, sub | stack]} = vm) do
    val = ScriptNum.decode(sub)
    res = if ScriptNum.decode(min) <= val and val <= ScriptNum.decode(max), do: 1, else: 0
    put_in(vm.stack, [ScriptNum.encode(res) | stack])
  end

  @doc """
  The top element on the stack is hashed using `RIPEMD160`.
  """
  @spec op_ripemd160(t()) :: t()
  def op_ripemd160(%__MODULE__{stack: []} = vm), do: err(vm, "OP_RIPEMD160 stack empty")
  def op_ripemd160(%__MODULE__{stack: [top | stack]} = vm) do
    hash = :crypto.hash(:ripemd160, top)
    put_in(vm.stack, [hash | stack])
  end

  @doc """
  The top element on the stack is hashed using `SHA1`.
  """
  @spec op_sha1(t()) :: t()
  def op_sha1(%__MODULE__{stack: []} = vm), do: err(vm, "OP_SHA1 stack empty")
  def op_sha1(%__MODULE__{stack: [top | stack]} = vm) do
    hash = :crypto.hash(:sha, top)
    put_in(vm.stack, [hash | stack])
  end

  @doc """
  The top element on the stack is hashed using `SHA256`.
  """
  @spec op_sha256(t()) :: t()
  def op_sha256(%__MODULE__{stack: []} = vm), do: err(vm, "OP_SHA256 stack empty")
  def op_sha256(%__MODULE__{stack: [top | stack]} = vm) do
    hash = :crypto.hash(:sha256, top)
    put_in(vm.stack, [hash | stack])
  end

  @doc """
  The top element on the stack is hashed using `SHA256` then `RIPEMD160`.
  """
  @spec op_hash160(t()) :: t()
  def op_hash160(%__MODULE__{stack: []} = vm), do: err(vm, "OP_HASH160 stack empty")
  def op_hash160(%__MODULE__{stack: [top | stack]} = vm) do
    hash = :crypto.hash(:ripemd160, :crypto.hash(:sha256, top))
    put_in(vm.stack, [hash | stack])
  end

  @doc """
  The top element on the stack is hashed using `SHA256` then `SHA256` again.
  """
  @spec op_hash256(t()) :: t()
  def op_hash256(%__MODULE__{stack: []} = vm), do: err(vm, "OP_HASH256 stack empty")
  def op_hash256(%__MODULE__{stack: [top | stack]} = vm) do
    hash = :crypto.hash(:sha256, :crypto.hash(:sha256, top))
    put_in(vm.stack, [hash | stack])
  end

  @doc """
  Verifies the signature in the second top stack element against the current
  transaction sighash using the pubkey on top of the stack. Replaces them with
  the boolean result.
  """
  @spec op_checksig(t()) :: t()
  def op_checksig(%__MODULE__{stack: stack} = vm)
    when length(stack) < 2,
    do: err(vm, "OP_CHECKSIG invalid stack length")

  def op_checksig(%__MODULE__{opts: %{simulate: true}, stack: [_pk, _sig | stack]} = vm),
    do: put_in(vm.stack, [<<1>> | stack])

  def op_checksig(%__MODULE__{
    ctx: {%Tx{} = tx, vin, %TxOut{} = txout},
    stack: [pubkey, signature | stack]
  } = vm)
    when is_integer(vin)
  do
    if Sig.verify(signature, tx, vin, txout, PubKey.from_binary!(pubkey)),
      do: put_in(vm.stack, [<<1>> | stack]),
      else: put_in(vm.stack, [<<>> | stack])
  end

  def op_checksig(%__MODULE__{} = vm),
    do: err(vm, "OP_CHECKSIG invalid TX context")

  @doc """
  Runs `op_checksig/1` and `op_verify/1`.
  """
  @spec op_checksigverify(t()) :: t()
  def op_checksigverify(%__MODULE__{} = vm),
    do: vm |> op_checksig() |> op_verify()

  @doc """
  The top stack element is the number of public keys. The next n elements are
  the public keys. The next element is the number of signatures and the next n
  elements are the signatures.

  Each signature is itereated over and each public key is checked if it verifies
  the signature against the current transactions sighash. Once a public key is
  checked it is not checked again, so signatures must be pushed onto the stack
  in the same order as the corresponding public keys.
  """
  @spec op_checkmultisig(t()) :: t()
  def op_checkmultisig(%__MODULE__{stack: []} = vm),
    do: err(vm, "OP_CHECKMULTISIG stack empty")

  def op_checkmultisig(%__MODULE__{opts: %{simulate: true}, stack: [pk_length | stack]} = vm) do
    with {_pubkeys, [sig_length | stack]} <- Enum.split(stack, ScriptNum.decode(pk_length)),
         {_sigs, [_junk | stack]} <- Enum.split(stack, ScriptNum.decode(sig_length))
    do
      put_in(vm.stack, [<<1>> | stack])
    else
      {_ignore, stack} -> put_in(vm.stack, [<<>> | stack])
    end
  end

  def op_checkmultisig(%__MODULE__{
    ctx: {%Tx{} = tx, vin, %TxOut{} = txout},
    stack: [pk_length | stack]
  } = vm)
    when is_integer(vin)
  do
    with {pubkeys, [sig_length | stack]} <- Enum.split(stack, ScriptNum.decode(pk_length)),
         {sigs, [_junk | stack]} <- Enum.split(stack, ScriptNum.decode(sig_length))
    do
      sigs = Enum.reverse(sigs)
      pubkeys = Enum.reverse(pubkeys)

      # Iterate over sigs and build list of valid sigs and used keys
      {valid, _} = Enum.reduce(sigs, {[], []}, fn signature, {valid, usedkeys} ->
        # Iterate keys minus used keys until signature verifies
        Enum.reduce_while(pubkeys -- usedkeys, {valid, usedkeys}, fn pubkey, {valid, usedkeys} ->
          if Sig.verify(signature, tx, vin, txout, PubKey.from_binary!(pubkey)),
            do: {:halt, {[signature | valid], [pubkey | usedkeys]}},
            else: {:cont, {valid, [pubkey | usedkeys]}}
        end)
      end)

      case Enum.all?(sigs, & &1 in valid) do
        true -> put_in(vm.stack, [<<1>> | stack])
        _ -> put_in(vm.stack, [<<>> | stack])
      end
    else
      {_ignore, stack} -> put_in(vm.stack, [<<>> | stack])
    end
  end

  def op_checkmultisig(%__MODULE__{} = vm),
    do: err(vm, "OP_CHECKMULTISIG invalid TX context")

  @doc """
  Runs `op_checkmultisig/1` and `op_verify/1`.
  """
  @spec op_checkmultisigverify(t()) :: t()
  def op_checkmultisigverify(%__MODULE__{} = vm),
    do: vm |> op_checkmultisig() |> op_verify()

  @doc """
  Unused. Makes transaction invalid.
  """
  @spec op_reserved(t()) :: t()
  def op_reserved(%__MODULE__{} = vm), do: err(vm, "OP_RESERVED called")

  @doc """
  Determines if the Script VM is truthy or falsey.
  """
  @spec valid?(t()) :: boolean
  def valid?(%__MODULE__{if_stack: if_stack}) when length(if_stack) > 0, do: false
  def valid?(%__MODULE__{stack: [top | _]}), do: true?(top)

  # Adds the given error message to the VM
  defp err(vm, message), do: put_in(vm.error, message)

  # Evaluates whether the binary value is truthy
  defp true?(<<>>), do: false
  defp true?(<<0>>), do: false
  defp true?(<<128>>), do: false
  defp true?(_), do: true

end
