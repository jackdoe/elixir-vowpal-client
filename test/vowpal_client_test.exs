defmodule VowpalClientTest do
  use ExUnit.Case
  doctest VowpalClient

  test "greets the world" do
    model_name = "/tmp/test_model_vowpal_client"
    File.rm("#{model_name}")
    System.cmd("killall", ["-9", "vw"])

    pid =
      spawn(fn ->
        System.cmd(
          "/usr/local/bin/vw",
          ["--port", "12312", "--foreground", "--num_children", "1"],
          into: IO.stream(:stdio, :line)
        )
      end)

    :timer.sleep(:timer.seconds(1))

    try do
      VowpalClient.start_link(VowpalClientTest, {127, 0, 0, 1}, 123_12, 1000)
      assert "0\n" == VowpalClient.send(VowpalClientTest, "|a 12 3\n")
      assert 0 != byte_size(VowpalClient.save(VowpalClientTest, model_name))
      assert "0\n" == VowpalClient.send(VowpalClientTest, "|a 12 3\n")
      assert "0\n" == VowpalClient.send(VowpalClientTest, "1 |a 12 3\n")
      assert "0.579291\n" == VowpalClient.send(VowpalClientTest, "|a 12 3\n")
      assert 0.193097 == VowpalClient.predict(VowpalClientTest, [{"a", [{"12", 1}, {"3", 1}]}])
      assert 0.193097 == VowpalClient.train(VowpalClientTest, -1, [{"a", [{"12", 1}, {"3", 1}]}])
      assert -0.389133 == VowpalClient.predict(VowpalClientTest, [{"a", [{"12", 1}, {"3", 1}]}])
      assert -0.389133 == VowpalClient.predict(VowpalClientTest, [{"a", [{"12", 1}, "3"]}])
      assert -0.389133 == VowpalClient.predict(VowpalClientTest, [{"a", [12, 3]}])
    rescue
      e ->
        System.cmd("killall", ["-9", "vw"])
        raise e
    end

    System.cmd("killall", ["-9", "vw"])
    Process.delete(pid)
  end
end
