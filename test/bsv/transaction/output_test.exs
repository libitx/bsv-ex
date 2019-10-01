defmodule BSV.Transaction.OutputTest do
  use ExUnit.Case
  doctest BSV.Transaction.Output

  setup_all do
    %{
      hex: "efbee82f000000001976a914c4263eb96d88849f498d139424b59a0cba1005e888ac",
      output: %BSV.Transaction.Output{
        satoshis: 803782383,
        script: %BSV.Transaction.Script{
          chunks: [
            :OP_DUP,
            :OP_HASH160,
            <<196, 38, 62, 185, 109, 136, 132, 159, 73, 141, 19, 148, 36, 181, 154,
              12, 186, 16, 5, 232>>,
            :OP_EQUALVERIFY,
            :OP_CHECKSIG
          ]
        }
      }
    }
  end


  describe "BSV.Transaction.Output.parse/2" do
    test "must parse single output", ctx do
      {output, ""} = ctx.hex
      |> BSV.Transaction.Output.parse(encoding: :hex)
      assert output.satoshis == 803782383
      assert length(output.script.chunks) == 5
    end
  end


  describe "BSV.Transaction.Output.serialize/2" do
    test "must serialize output to binary", ctx do
      output = BSV.Transaction.Output.serialize(ctx.output, encoding: :hex)
      assert output == ctx.hex
    end
  end

end