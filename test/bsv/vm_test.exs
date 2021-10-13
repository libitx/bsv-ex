defmodule BSV.VMTest do
  use ExUnit.Case, async: true
  alias BSV.VM
  alias BSV.ScriptNum
  doctest VM

  setup do
    %{vm: %VM{}}
  end

  describe "1. Constants" do
    test "pushes data to stack", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_0, "test123", :OP_TRUE, :OP_1NEGATE, :OP_10])
      assert vm.stack == [<<10>>, <<129>>, <<1>>, "test123", <<>>]
    end
  end

  describe "2. Flow control" do
    test "evals truthy side of OP_IF block", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_IF, "foo", :OP_ELSE, "bar", :OP_ENDIF])
      assert vm.stack == ["foo"]
    end

    test "evals falsey side of OP_IF block", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_0, :OP_IF, "foo", :OP_ELSE, "bar", :OP_ENDIF])
      assert vm.stack == ["bar"]
    end

    test "evals truthy side of OP_NOTIF block", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_NOTIF, "foo", :OP_ELSE, "bar", :OP_ENDIF])
      assert vm.stack == ["bar"]
    end

    test "evals falsey side of OP_NOTIF block", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_0, :OP_NOTIF, "foo", :OP_ELSE, "bar", :OP_ENDIF])
      assert vm.stack == ["foo"]
    end

    test "handles nested OP_IF blocks", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_IF, "foo", :OP_IF, "qux", :OP_ENDIF, :OP_ELSE, "bar", :OP_ENDIF])
      assert vm.stack == ["qux"]
    end

    test "OP_VERIFY asserts truthyness", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_VERIFY, :OP_2])
      assert vm.stack == [<<2>>]
    end

    test "OP_VERIFY terminates when false", %{vm: vm} do
      {:error, vm} = VM.eval(vm, [:OP_0, :OP_VERIFY, :OP_2])
      assert vm.stack == [<<>>]
      assert vm.error == "OP_VERIFY failed"
    end

    test "OP_RETURN ends eval and returns additional chunks", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_RETURN, "foo", "bar"])
      assert vm.stack == [<<1>>]
      assert vm.op_return == ["foo", "bar"]
    end
  end

  describe "3. Stack" do
    test "OP_TOALTSTACK moves top of stack to alt stack", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_2, :OP_TOALTSTACK])
      assert vm.stack == [<<1>>]
      assert vm.alt_stack == [<<2>>]
    end

    test "OP_FROMALTSTACK moves top of alt stack to stack", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_2, :OP_TOALTSTACK, :OP_FROMALTSTACK])
      assert vm.stack == [<<2>>, <<1>>]
      assert vm.alt_stack == []
    end

    test "OP_2DROP removes top two items from stack", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_2, :OP_3, :OP_2DROP])
      assert vm.stack == [<<1>>]
    end

    test "OP_2DUP duplicates top two items on stack", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_2, :OP_2DUP])
      assert vm.stack == [<<2>>, <<1>>, <<2>>, <<1>>]
    end

    test "OP_3DUP duplicates top three items on stack", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_2, :OP_3, :OP_3DUP])
      assert vm.stack == [<<3>>, <<2>>, <<1>>, <<3>>, <<2>>, <<1>>]
    end

    test "OP_2OVER copies two items two spaces back on the stack", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_2, :OP_9, :OP_9, :OP_2OVER])
      assert vm.stack == [<<2>>, <<1>>, <<9>>, <<9>>, <<2>>, <<1>>]
    end

    test "OP_2ROT moves the 5th and 6th items to top of stack", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_2, :OP_3, :OP_4, :OP_5, :OP_6, :OP_2ROT])
      assert vm.stack == [<<2>>, <<1>>, <<6>>, <<5>>, <<4>>, <<3>>]
    end

    test "OP_2SWAP swaps the top two pairs of items", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_2, :OP_3, :OP_4, :OP_2SWAP])
      assert vm.stack == [<<2>>, <<1>>, <<4>>, <<3>>]
    end

    test "OP_IFDUP duplicates the top item if it is truthy", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_2, :OP_IFDUP])
      assert vm.stack == [<<2>>, <<2>>, <<1>>]
    end

    test "OP_IFDUP wont duplicate the top item if it is not truthy", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_0, :OP_IFDUP])
      assert vm.stack == [<<>>, <<1>>]
    end

    test "OP_DEPTH puts the stack length on top of the stack", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_2, :OP_3, :OP_4, :OP_DEPTH])
      assert vm.stack == [<<4>>, <<4>>, <<3>>, <<2>>, <<1>>]
    end

    test "OP_DROP removes the top stack item", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_2, :OP_3, :OP_DROP])
      assert vm.stack == [<<2>>, <<1>>]
    end

    test "OP_DUP duplicates the top stack item", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_2, :OP_DUP])
      assert vm.stack == [<<2>>, <<2>>, <<1>>]
    end

    test "OP_NIP removes the 2nd stack item", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_2, :OP_NIP])
      assert vm.stack == [<<2>>]
    end

    test "OP_OVER copies the 2nd stack item to the top", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_2, :OP_OVER])
      assert vm.stack == [<<1>>, <<2>>, <<1>>]
    end

    test "OP_PICK copies the nth stack item to the top", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_2, :OP_3, :OP_4, :OP_5, :OP_4, :OP_PICK])
      assert vm.stack == [<<1>>, <<5>>, <<4>>, <<3>>, <<2>>, <<1>>]
    end

    test "OP_ROLL moves the nth stack item to the top", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_2, :OP_3, :OP_4, :OP_5, :OP_4, :OP_ROLL])
      assert vm.stack == [<<1>>, <<5>>, <<4>>, <<3>>, <<2>>]
    end

    test "OP_ROT rotates the top 3 items", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_2, :OP_3, :OP_4, :OP_5, :OP_ROT])
      assert vm.stack == [<<3>>, <<5>>, <<4>>, <<2>>, <<1>>]
    end

    test "OP_SWAP swaps the top two items on the stack", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_2, :OP_3, :OP_SWAP])
      assert vm.stack == [<<2>>, <<3>>, <<1>>]
    end

    test "OP_TUCK copies the top stack item and inserts 2 behind", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_2, :OP_3, :OP_TUCK])
      assert vm.stack == [<<3>>, <<2>>, <<3>>, <<1>>]
    end
  end

  describe "4. Data Manipulation" do
    test "OP_CAT concatenates the top two items on the stack", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_2, :OP_3, :OP_CAT])
      assert vm.stack == [<<2, 3>>, <<1>>]
    end

    test "OP_SPLIT splits the second item on the stack by the index of the top", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, ["foobarqux", :OP_6, :OP_SPLIT])
      assert vm.stack == ["qux", "foobar"]
    end

    test "OP_NUM2BIN converts numeric value into bytes", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [67305985, :OP_10, :OP_NUM2BIN])
      assert vm.stack == [<<1, 2, 3, 4, 0, 0, 0, 0, 0, 0>>]
    end

    test "OP_NUM2BIN converts neg numeric value into bytes", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [-67305985, :OP_10, :OP_NUM2BIN])
      assert vm.stack == [<<1, 2, 3, 4, 0, 0, 0, 0, 0, 128>>]
    end

    test "OP_BIN2NUM converts bytes into numeric value", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [<<1, 2, 3, 4, 0, 0, 0, 0, 0, 0>>, :OP_BIN2NUM])
      assert vm.stack == [<<1, 2, 3, 4>>]
    end

    test "OP_BIN2NUM converts bytes into negative numeric value", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [<<1, 2, 3, 4, 0, 0, 0, 0, 0, 128>>, :OP_BIN2NUM])
      assert vm.stack == [<<1, 2, 3, 132>>]
    end

    test "OP_SIZE pushes the length of the top element of the stack", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, ["foobarqux", :OP_SIZE])
      assert vm.stack == [<<9>>, "foobarqux"]
    end
  end

  describe "5. Bitwise logic" do
    test "OP_INVERT flips the bits of top stack item", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [<<1, 2, 3>>, :OP_INVERT])
      assert vm.stack == [<<254, 253, 252>>]
    end

    test "OP_AND calculates the bitwise AND of top two stack items", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [<<1, 1>>, <<2, 2>>, :OP_AND])
      assert vm.stack == [<<0, 0>>]
    end

    test "OP_OR calculates the bitwise OR of top two stack items", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [<<1, 1>>, <<2, 2>>, :OP_OR])
      assert vm.stack == [<<3, 3>>]
    end

    test "OP_XOR calculates the bitwise XOR of top two stack items", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [<<1, 1>>, <<2, 2>>, :OP_XOR])
      assert vm.stack == [<<3, 3>>]
    end

    test "OP_EQUAL compared equality of top two stack items", %{vm: vm} do
      assert {:ok, %VM{stack: [<<>>]}} = VM.eval(vm, [<<1, 1>>, <<2, 2>>, :OP_EQUAL])
      assert {:ok, %VM{stack: [<<1>>]}} = VM.eval(vm, [<<1, 1>>, <<1, 1>>, :OP_EQUAL])
    end

    test "OP_EQUALVERIFY as OP_EQUAL but halts if not truthy stack", %{vm: vm} do
      assert {:error, %VM{stack: [<<>>]}} = VM.eval(vm, [<<1, 1>>, <<2, 2>>, :OP_EQUALVERIFY])
      assert {:ok, %VM{stack: []}} = VM.eval(vm, [<<1, 1>>, <<1, 1>>, :OP_EQUALVERIFY])
    end
  end

  describe "6. Arithmetic" do
    test "OP_1ADD adds 1 on the top value on the stack", %{vm: vm} do
      assert {:ok, %VM{stack: [val]}} = VM.eval(vm, [12345, :OP_1ADD])
      assert ScriptNum.decode(val) == 12346
    end

    test "OP_1SUB subs 1 from the top value on the stack", %{vm: vm} do
      assert {:ok, %VM{stack: [val]}} = VM.eval(vm, [12345, :OP_1SUB])
      assert ScriptNum.decode(val) == 12344
    end

    test "OP_NEGATE negates the top value on the stack", %{vm: vm} do
      assert {:ok, %VM{stack: [val]}} = VM.eval(vm, [12345, :OP_NEGATE])
      assert ScriptNum.decode(val) == -12345
    end

    test "OP_ABS makes the top value on the stack positive", %{vm: vm} do
      assert {:ok, %VM{stack: [val]}} = VM.eval(vm, [-12345, :OP_ABS])
      assert ScriptNum.decode(val) == 12345
    end

    test "OP_NOT returns true if the top stack item is not true", %{vm: vm} do
      assert {:ok, %VM{stack: [<<1>>]}} = VM.eval(vm, [0, :OP_NOT])
      assert {:ok, %VM{stack: [<<>>]}} = VM.eval(vm, [1, :OP_NOT])
      assert {:ok, %VM{stack: [<<>>]}} = VM.eval(vm, [12345, :OP_NOT])
    end

    test "OP_0NOTEQUAL returns true if the top stack item is not false", %{vm: vm} do
      assert {:ok, %VM{stack: [<<>>]}} = VM.eval(vm, [0, :OP_0NOTEQUAL])
      assert {:ok, %VM{stack: [<<1>>]}} = VM.eval(vm, [1, :OP_0NOTEQUAL])
      assert {:ok, %VM{stack: [<<1>>]}} = VM.eval(vm, [12345, :OP_0NOTEQUAL])
    end

    test "OP_ADD adds the top two stack items", %{vm: vm} do
      assert {:ok, %VM{stack: [val]}} = VM.eval(vm, [-10000, 12345, :OP_ADD])
      assert ScriptNum.decode(val) == 2345
    end

    test "OP_SUB subtracts 2nd from top from top", %{vm: vm} do
      assert {:ok, %VM{stack: [val]}} = VM.eval(vm, [500, 100, :OP_SUB])
      assert ScriptNum.decode(val) == 400
    end

    test "OP_MUL multiplies the top two stack items", %{vm: vm} do
      assert {:ok, %VM{stack: [val]}} = VM.eval(vm, [5, 100, :OP_MUL])
      assert ScriptNum.decode(val) == 500
    end

    test "OP_DIV divides 2nd from top from top", %{vm: vm} do
      assert {:ok, %VM{stack: [val]}} = VM.eval(vm, [100, 5, :OP_DIV])
      assert ScriptNum.decode(val) == 20
    end

    test "OP_MOD divides 2nd from top from top and returns the remainder", %{vm: vm} do
      assert {:ok, %VM{stack: [val]}} = VM.eval(vm, [13, 3, :OP_MOD])
      assert ScriptNum.decode(val) == 1
    end

    test "OP_LSHIFT bitshifts the 2nd stack items to the left by the top stack item number", %{vm: vm} do
      assert {:ok, %VM{stack: [<<0, 1, 0>>]}} = VM.eval(vm, [<<0, 0, 128>>, :OP_1, :OP_LSHIFT])
      assert {:ok, %VM{stack: [<<255, 255, 252>>]}} = VM.eval(vm, [<<255, 255, 255>>, :OP_2, :OP_LSHIFT])
      assert {:ok, %VM{stack: [<<255, 240, 0>>]}} = VM.eval(vm, [<<255, 255, 255>>, :OP_12, :OP_LSHIFT])
      assert {:ok, %VM{stack: [<<81, 137, 201, 107, 249, 217, 31, 72>>]}} = VM.eval(vm, [<<84, 98, 114, 90, 254, 118, 71, 210>>, :OP_2, :OP_LSHIFT])
    end

    test "OP_RSHIFT bitshifts the 2nd stack items to the right by the top stack item number", %{vm: vm} do
      assert {:ok, %VM{stack: [<<0, 128, 0>>]}} = VM.eval(vm, [<<1, 0, 0>>, :OP_1, :OP_RSHIFT])
      assert {:ok, %VM{stack: [<<63, 255, 255>>]}} = VM.eval(vm, [<<255, 255, 255>>, :OP_2, :OP_RSHIFT])
      assert {:ok, %VM{stack: [<<0, 15, 255>>]}} = VM.eval(vm, [<<255, 255, 255>>, :OP_12, :OP_RSHIFT])
      assert {:ok, %VM{stack: [<<21, 24, 156, 150, 191, 157, 145, 244>>]}} = VM.eval(vm, [<<84, 98, 114, 90, 254, 118, 71, 210>>, :OP_2, :OP_RSHIFT])
    end

    test "OP_BOOLAND checks boolean positivity of both of top two stack items", %{vm: vm} do
      assert {:ok, %VM{stack: [<<1>>]}} = VM.eval(vm, [:OP_1, :OP_1, :OP_BOOLAND])
      assert {:ok, %VM{stack: [<<>>]}} = VM.eval(vm, [:OP_0, :OP_1, :OP_BOOLAND])
      assert {:ok, %VM{stack: [<<>>]}} = VM.eval(vm, [:OP_0, :OP_0, :OP_BOOLAND])
    end

    test "OP_BOOLOR checks boolean positivity of either of top two stack items", %{vm: vm} do
      assert {:ok, %VM{stack: [<<1>>]}} = VM.eval(vm, [:OP_1, :OP_1, :OP_BOOLOR])
      assert {:ok, %VM{stack: [<<1>>]}} = VM.eval(vm, [:OP_0, :OP_1, :OP_BOOLOR])
      assert {:ok, %VM{stack: [<<>>]}} = VM.eval(vm, [:OP_0, :OP_0, :OP_BOOLOR])
    end

    test "OP_NUMEQUAL compares numerical equality of top two stack items", %{vm: vm} do
      assert {:ok, %VM{stack: [<<1>>]}} = VM.eval(vm, [:OP_1, :OP_1, :OP_NUMEQUAL])
      assert {:ok, %VM{stack: [<<>>]}} = VM.eval(vm, [:OP_0, :OP_1, :OP_NUMEQUAL])
    end

    test "OP_NUMEQUALVERIFY as OP_NUMEQUAL but halts if not truthy stack", %{vm: vm} do
      assert {:ok, %VM{stack: [<<10>>]}} = VM.eval(vm, [:OP_1, :OP_1, :OP_NUMEQUALVERIFY, :OP_10])
      assert {:error, %VM{stack: [<<>>]}} = VM.eval(vm, [:OP_0, :OP_1, :OP_NUMEQUALVERIFY, :OP_10])
    end

    test "OP_NUMNOTEQUAL check top two stack items are not numerically equal", %{vm: vm} do
      assert {:ok, %VM{stack: [<<>>]}} = VM.eval(vm, [:OP_1, :OP_1, :OP_NUMNOTEQUAL])
      assert {:ok, %VM{stack: [<<1>>]}} = VM.eval(vm, [:OP_0, :OP_1, :OP_NUMNOTEQUAL])
    end

    test "OP_LESSTHAN checks if the second stack item is less than the top", %{vm: vm} do
      assert {:ok, %VM{stack: [<<>>]}} = VM.eval(vm, [:OP_2, :OP_2, :OP_LESSTHAN])
      assert {:ok, %VM{stack: [<<1>>]}} = VM.eval(vm, [:OP_1, :OP_2, :OP_LESSTHAN])
      assert {:ok, %VM{stack: [<<>>]}} = VM.eval(vm, [:OP_2, :OP_1, :OP_LESSTHAN])
    end

    test "OP_GREATERTHAN checks if the second stack item is grater than the top", %{vm: vm} do
      assert {:ok, %VM{stack: [<<>>]}} = VM.eval(vm, [:OP_2, :OP_2, :OP_GREATERTHAN])
      assert {:ok, %VM{stack: [<<>>]}} = VM.eval(vm, [:OP_1, :OP_2, :OP_GREATERTHAN])
      assert {:ok, %VM{stack: [<<1>>]}} = VM.eval(vm, [:OP_2, :OP_1, :OP_GREATERTHAN])
    end

    test "OP_LESSTHANOREQUAL checks if the second stack item is less than or equal to the top", %{vm: vm} do
      assert {:ok, %VM{stack: [<<1>>]}} = VM.eval(vm, [:OP_2, :OP_2, :OP_LESSTHANOREQUAL])
      assert {:ok, %VM{stack: [<<1>>]}} = VM.eval(vm, [:OP_1, :OP_2, :OP_LESSTHANOREQUAL])
      assert {:ok, %VM{stack: [<<>>]}} = VM.eval(vm, [:OP_2, :OP_1, :OP_LESSTHANOREQUAL])
    end

    test "OP_GREATERTHANOREQUAL checks if the second stack item is greater than or equal to the top", %{vm: vm} do
      assert {:ok, %VM{stack: [<<1>>]}} = VM.eval(vm, [:OP_2, :OP_2, :OP_GREATERTHANOREQUAL])
      assert {:ok, %VM{stack: [<<>>]}} = VM.eval(vm, [:OP_1, :OP_2, :OP_GREATERTHANOREQUAL])
      assert {:ok, %VM{stack: [<<1>>]}} = VM.eval(vm, [:OP_2, :OP_1, :OP_GREATERTHANOREQUAL])
    end

    test "OP_MIN selects the min value from the top two stack items", %{vm: vm} do
      assert {:ok, %VM{stack: [<<1>>]}} = VM.eval(vm, [:OP_1, :OP_2, :OP_MIN])
    end

    test "OP_MAX selects the max value from the top two stack items", %{vm: vm} do
      assert {:ok, %VM{stack: [<<2>>]}} = VM.eval(vm, [:OP_1, :OP_2, :OP_MAX])
    end

    test "OP_WITHIN checks if the 3rd stack item is within the range defined by 2nd and top", %{vm: vm} do
      assert {:ok, %VM{stack: [<<1>>]}} = VM.eval(vm, [:OP_1, :OP_1, :OP_5, :OP_WITHIN])
      assert {:ok, %VM{stack: [<<1>>]}} = VM.eval(vm, [:OP_3, :OP_1, :OP_5, :OP_WITHIN])
      assert {:ok, %VM{stack: [<<1>>]}} = VM.eval(vm, [:OP_5, :OP_1, :OP_5, :OP_WITHIN])
      assert {:ok, %VM{stack: [<<>>]}} = VM.eval(vm, [:OP_6, :OP_1, :OP_5, :OP_WITHIN])
    end
  end

  describe "7a. Crypto operations" do
    test "OP_RIPEMD160 hashes the top stack item", %{vm: vm} do
      assert {:ok, %VM{stack: [top]}} = VM.eval(vm, ["foo", :OP_RIPEMD160])
      assert top == <<66, 207, 162, 17, 1, 142, 164, 146, 253, 238, 69, 172, 99, 123, 121, 114, 160, 173, 104, 115>>
    end

    test "OP_SHA1 hashes the top stack item", %{vm: vm} do
      assert {:ok, %VM{stack: [top]}} = VM.eval(vm, ["foo", :OP_SHA1])
      assert top == <<11, 238, 199, 181, 234, 63, 15, 219, 201, 93, 13, 212, 127, 60, 91, 194, 117, 218, 138, 51>>
    end

    test "OP_SHA256 hashes the top stack item", %{vm: vm} do
      assert {:ok, %VM{stack: [top]}} = VM.eval(vm, ["foo", :OP_SHA256])
      assert top == <<44, 38, 180, 107, 104, 255, 198, 143, 249, 155, 69, 60, 29, 48, 65, 52, 19, 66, 45, 112, 100, 131, 191, 160, 249, 138, 94, 136, 98, 102, 231, 174>>
    end

    test "OP_HASH160 hashes the top stack item", %{vm: vm} do
      assert {:ok, %VM{stack: [top]}} = VM.eval(vm, ["foo", :OP_HASH160])
      assert top == <<225, 207, 124, 129, 3, 71, 107, 109, 127, 233, 228, 151, 154, 161, 14, 124, 83, 31, 207, 66>>
    end

    test "OP_HASH256 hashes the top stack item", %{vm: vm} do
      assert {:ok, %VM{stack: [top]}} = VM.eval(vm, ["foo", :OP_HASH256])
      assert top == <<199, 173, 232, 143, 199, 162, 20, 152, 166, 165, 229, 195, 133, 225, 246, 139, 237, 130, 43, 114, 170, 99, 196, 169, 164, 138, 2, 194, 70, 110, 226, 158>>
    end
  end


  alias BSV.{Address, KeyPair, OutPoint, PrivKey, PubKey, Sig, Tx, TxBuilder, UTXO}
  alias BSV.Contract.P2PKH

  @test_privkey PrivKey.from_wif!("KyGHAK8MNohVPdeGPYXveiAbTfLARVrQuJVtd3qMqN41UEnTWDkF")
  @test_keypair KeyPair.from_privkey(@test_privkey)
  @test_address Address.from_pubkey(@test_keypair.pubkey)

  describe "OP_CHECKSIG" do
    setup %{vm: vm} do
      prev_tx = TxBuilder.to_tx(%TxBuilder{
        outputs: [P2PKH.lock(50000, %{address: @test_address})]
      })

      utxo = %UTXO{
        outpoint: %OutPoint{hash: Tx.get_hash(prev_tx), index: 0},
        txout: List.first(prev_tx.outputs)
      }

      tx = TxBuilder.to_tx(%TxBuilder{
        inputs: [P2PKH.unlock(utxo, %{keypair: @test_keypair})]
      })

      %{
        sig: Sig.sign(tx, 0, utxo.txout, @test_keypair.privkey),
        vm: Map.merge(vm, %{ctx: {tx, 0, utxo.txout}})
      }
    end

    test "OP_CHECKSIG verifies the signature using the public key", %{sig: sig, vm: vm} do
      assert {:ok, %VM{stack: [<<1>>]}} = VM.eval(vm, [sig, PubKey.to_binary(@test_keypair.pubkey), :OP_CHECKSIG])
    end

    test "OP_CHECKSIG returns false if signature invalid", %{sig: sig, vm: vm} do
      keypair = KeyPair.new()
      assert {:ok, %VM{stack: [<<>>]}} = VM.eval(vm, [sig, PubKey.to_binary(keypair.pubkey), :OP_CHECKSIG])
    end

    test "OP_CHECKSIGVERIFY as OP_CHECKSIG but halts if not truthy stack", %{sig: sig, vm: vm} do
      assert {:ok, %VM{stack: []}} = VM.eval(vm, [sig, PubKey.to_binary(@test_keypair.pubkey), :OP_CHECKSIGVERIFY])
      keypair = KeyPair.new()
      assert {:error, %VM{stack: [<<>>]}} = VM.eval(vm, [sig, PubKey.to_binary(keypair.pubkey), :OP_CHECKSIGVERIFY])
    end
  end

  describe "OP_CHECKMULTISIG" do
    setup %{vm: vm} do
      keys = Enum.map(1..3, fn _i -> KeyPair.new() end)

      prev_tx = TxBuilder.to_tx(%TxBuilder{
        outputs: [P2PKH.lock(50000, %{address: @test_address})]
      })

      utxo = %UTXO{
        outpoint: %OutPoint{hash: Tx.get_hash(prev_tx), index: 0},
        txout: List.first(prev_tx.outputs)
      }

      tx = TxBuilder.to_tx(%TxBuilder{
        inputs: [P2PKH.unlock(utxo, %{keypair: @test_keypair})]
      })

      sigs = Enum.map(keys, fn k -> Sig.sign(tx, 0, utxo.txout, k.privkey) end)

      %{
        keys: Enum.map(keys, & PubKey.to_binary(&1.pubkey)),
        sigs: sigs,
        vm: Map.merge(vm, %{ctx: {tx, 0, utxo.txout}})
      }
    end

    test "OP_CHECKMULTISIG verifies all of the signatures using all the public keys", %{keys: keys, sigs: sigs, vm: vm} do
      script = [:OP_0 | sigs] ++ [:OP_3 | keys] ++ [:OP_3, :OP_CHECKMULTISIG]
      assert {:ok, %VM{stack: [<<1>>]}} = VM.eval(vm, script)
    end

    test "OP_CHECKMULTISIG verifies all of the signatures using 2/3 the public keys", %{keys: keys, sigs: sigs, vm: vm} do
      [_skip | sigs] = sigs
      script = [:OP_0 | sigs] ++ [:OP_2 | keys] ++ [:OP_3, :OP_CHECKMULTISIG]
      assert {:ok, %VM{stack: [<<1>>]}} = VM.eval(vm, script)
    end

    test "OP_CHECKMULTISIG returns false if sigs in wrong order", %{keys: keys, sigs: sigs, vm: vm} do
      [_skip | sigs] = sigs
      script = [:OP_0 | Enum.reverse(sigs)] ++ [:OP_2 | keys] ++ [:OP_3, :OP_CHECKMULTISIG]
      assert {:ok, %VM{stack: [<<>>]}} = VM.eval(vm, script)
    end

    test "OP_CHECKMULTISIG returns false if junk value doesn't exist", %{keys: keys, sigs: sigs, vm: vm} do
      script = sigs ++ [:OP_3 | keys] ++ [:OP_3, :OP_CHECKMULTISIG]
      assert {:ok, %VM{stack: [<<>>]}} = VM.eval(vm, script)
    end

    test "OP_CHECKMULTISIGVERIFY as OP_CHECKMULTISIG but halts if not truthy stack", %{keys: keys, sigs: sigs, vm: vm} do
      script = [:OP_0 | sigs] ++ [:OP_3 | keys] ++ [:OP_3, :OP_CHECKMULTISIGVERIFY]
      assert {:ok, %VM{stack: []}} = VM.eval(vm, script)
      script = [:OP_0 | Enum.reverse(sigs)] ++ [:OP_3 | keys] ++ [:OP_3, :OP_CHECKMULTISIGVERIFY]
      assert {:error, %VM{stack: [<<>>]}} = VM.eval(vm, script)
    end
  end

end
