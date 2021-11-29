defmodule BSV.Contract.OpCodeHelpers do
  @moduledoc """
  Helper module for using Op Codes in `BSV.Contract` modules.

  All known Op Codes are available as a function which simply pushes the Op Code
  word onto the Contract Script. Refer to `BSV.VM` for descriptions of each
  Op Code.

  In addition, `op_if/2` and `op_if/3` provide a more syntactically pleasing way
  of handling the flow controw operations by passing `handle_if` and `handle_else`
  callback functions.

      op_if(contract, &op_1add/1, &op_1sub/1)

      # Equivalent to...

      contract
      |> op_if()
      |> op_1add()
      |> op_else()
      |> op_1sub()
      |> op_endif()

  *The same applies to `op_notif/2` and `op_notif/3`*.
  """
  alias BSV.{Contract, OpCode}

  # Iterrates over all opcodes
  # Defines a function to push the specified opcode onto the contract script
  Enum.each(OpCode.all(), fn {op, _} ->
    key = op
    |> Atom.to_string()
    |> String.downcase()
    |> String.to_atom()

    @doc "Pushes the `#{op}` word onto the script."
    @spec unquote(key)(Contract.t()) :: Contract.t()
    def unquote(key)(%Contract{} = contract) do
      Contract.script_push(contract, unquote(op))
    end
  end)

  @doc """
  Wraps the given `handle_if` function with `OP_IF` and `OP_ENDIF` script words.
  """
  @spec op_if(Contract.t(), (Contract.t() -> Contract.t())) :: Contract.t()
  def op_if(%Contract{} = contract, handle_if) when is_function(handle_if) do
    contract
    |> op_if()
    |> handle_if.()
    |> op_endif()
  end

  @doc """
  Wraps the given `handle_if` and `handle_else` functions with `OP_IF`,
  `OP_ELSE` and `OP_ENDIF` script words.
  """
  @spec op_if(
    Contract.t(),
    (Contract.t() -> Contract.t()),
    (Contract.t() -> Contract.t())
  ) :: Contract.t()
  def op_if(%Contract{} = contract, handle_if, handle_else)
    when is_function(handle_if) and is_function(handle_else)
  do
    contract
    |> op_if()
    |> handle_if.()
    |> op_else()
    |> handle_else.()
    |> op_endif()
  end

  @doc """
  Wraps the given `handle_if` function with `OP_NOTIF` and `OP_ENDIF` script
  words.
  """
  @spec op_notif(Contract.t(), (Contract.t() -> Contract.t())) :: Contract.t()
  def op_notif(%Contract{} = contract, handle_if) when is_function(handle_if) do
    contract
    |> op_notif()
    |> handle_if.()
    |> op_endif()
  end

  @doc """
  Wraps the given `handle_if` and `handle_else` functions with `OP_NOTIF`,
  `OP_ELSE` and `OP_ENDIF` script words.
  """
  @spec op_notif(
    Contract.t(),
    (Contract.t() -> Contract.t()),
    (Contract.t() -> Contract.t())
  ) :: Contract.t()
  def op_notif(%Contract{} = contract, handle_if, handle_else)
    when is_function(handle_if) and is_function(handle_else)
  do
    contract
    |> op_notif()
    |> handle_if.()
    |> op_else()
    |> handle_else.()
    |> op_endif()
  end

end
