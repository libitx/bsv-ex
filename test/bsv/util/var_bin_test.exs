defmodule BSV.Util.VarBinTest do
  use ExUnit.Case
  doctest BSV.Util.VarBin

  setup_all do
    %{
      hex_ins: "027bb22176433bb45bacede86a43764f98c7023f1a79b00138e3d3ea610716a8f1010000006b483045022100c7036739f47361398bd115dbe9302fdc456d75f83fb38e531f4a445c8385138a022006f68ca095a35886f3eb217f416650490a3f0a279f8dc564d0222c884002f85841210232b357c5309644cf4aa72b9b2d8bfe58bdf2515d40119318d5cb51ef378cae7effffffff197725400c9846a19a03cfd151bd089b9ec3e90ecbfa72b9c5448d52b2baae43020000006b483045022100b23044350aaaafb08480fee7addadde918c2b5515b66a3c445be05ca809ce290022044c89daa88303522cb72830ab71d1411da65f0a58dca43fcd998f80df3794cc441210282d7e568e56f59e01a4edae297ac26caabc4684971ac6c7558c91c0fa84002f7ffffffff",
      hex_outs: "03efbee82f000000001976a914c4263eb96d88849f498d139424b59a0cba1005e888ac010c1dfa000000001976a9146cbff9881ac47da8cb699e4543c28f9b3d6941da88ac404b4c00000000001976a914f7899faf1696892e6cb029b00c713f044761f03588ac",
    }
  end


  describe "Parsing and serializing BSV.Transaction.Input" do
    test "must parse multiple inputs", ctx do
      {inputs, ""} = ctx.hex_ins
      |> BSV.Util.decode(:hex)
      |> BSV.Util.VarBin.parse_items(&BSV.Transaction.Input.parse/1)
      assert length(inputs) == 2
    end

    test "must serialize multiple inputs" do
      data = [
        %BSV.Transaction.Input{
          txid: "0000000000000000000000000000000000000000000000000000000000000000",
          index: 1,
          script: %BSV.Transaction.Script{chunks: [:OP_FALSE]},
          sequence: 0
        },
        %BSV.Transaction.Input{
          txid: "1111111111111111111111111111111111111111111111111111111111111111",
          index: 2,
          script: %BSV.Transaction.Script{chunks: [:OP_FALSE]},
          sequence: 100
        }
      ] |> BSV.Util.VarBin.serialize_items(&BSV.Transaction.Input.serialize/1)
      <<n::integer, _::binary>> = data
      assert n == 2
      assert is_binary(data)
    end

    test "must parse and serialize back to original form", ctx do
      data = ctx.hex_ins
      |> BSV.Util.decode(:hex)
      |> BSV.Util.VarBin.parse_items(&BSV.Transaction.Input.parse/1)
      |> elem(0)
      |> BSV.Util.VarBin.serialize_items(&BSV.Transaction.Input.serialize/1)
      |> BSV.Util.encode(:hex)
      assert data == ctx.hex_ins
    end
  end


  describe "Parsing and serializing BSV.Transaction.Output" do
    test "must parse multiple outputs", ctx do
      {outputs, ""} = ctx.hex_outs
      |> BSV.Util.decode(:hex)
      |> BSV.Util.VarBin.parse_items(&BSV.Transaction.Output.parse/1)
      assert length(outputs) == 3
    end

    test "must serialize multiple outputs" do
      data = [
        %BSV.Transaction.Output{
          script: %BSV.Transaction.Script{chunks: [:OP_FALSE]}
        },
        %BSV.Transaction.Output{
          script: %BSV.Transaction.Script{chunks: [:OP_FALSE]}
        },
        %BSV.Transaction.Output{
          script: %BSV.Transaction.Script{chunks: [:OP_FALSE]}
        }
      ] |> BSV.Util.VarBin.serialize_items(&BSV.Transaction.Output.serialize/1)
      <<n::integer, _::binary>> = data
      assert n == 3
      assert is_binary(data)
    end

    test "must parse and serialize back to original form", ctx do
      data = ctx.hex_outs
      |> BSV.Util.decode(:hex)
      |> BSV.Util.VarBin.parse_items(&BSV.Transaction.Output.parse/1)
      |> elem(0)
      |> BSV.Util.VarBin.serialize_items(&BSV.Transaction.Output.serialize/1)
      |> BSV.Util.encode(:hex)
      assert data == ctx.hex_outs
    end
  end

end
