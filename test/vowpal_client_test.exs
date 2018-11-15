defmodule VowpalClientTest do
  use ExUnit.Case
  doctest VowpalClient

  test "greets the world" do
    cwd = "/tmp"
    model_name = "test_model_vowpal_client"
    File.rm("#{cwd}/#{model_name}")
    System.cmd("killall", ["-9", "vw"])

    pid =
      spawn(fn ->
        System.cmd(
          "/usr/local/bin/vw",
          ["--port", "12312", "--foreground", "--num_children", "1"],
          cd: cwd,
          into: IO.stream(:stdio, :line)
        )
      end)

    :timer.sleep(:timer.seconds(1))

    try do
      VowpalClient.start_link(VowpalClientTest, {127, 0, 0, 1}, 123_12, 1000)
      assert "0\n" == VowpalClient.send(VowpalClientTest, "|a 12 3\n")
      assert 0 != byte_size(VowpalClient.save(VowpalClientTest, {cwd, model_name}))
      assert "0\n" == VowpalClient.send(VowpalClientTest, "|a 12 3\n")
      assert "0\n" == VowpalClient.send(VowpalClientTest, "1 |a 12 3\n")
      assert "0.579291\n" == VowpalClient.send(VowpalClientTest, "|a 12 3\n")
    rescue
      e ->
        System.cmd("killall", ["-9", "vw"])
        raise e
    end

    Process.delete(pid)
  end
end
