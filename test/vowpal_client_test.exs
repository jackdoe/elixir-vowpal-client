defmodule VowpalClientTest do
  use ExUnit.Case

  test "greets the world" do
    model_name = "/tmp/test_model_vowpal_client"
    File.rm("#{model_name}")
    System.cmd("killall", ["-9", "vw"])

    pid = VowpalClient.spawn_vowpal(12312)

    :timer.sleep(:timer.seconds(1))

    try do
      VowpalClient.start_link(VowpalClientTest, {127, 0, 0, 1}, 123_12, 1000)
      assert "0\n" == VowpalClient.send(VowpalClientTest, "|a 12 3\n")
      assert 0 != byte_size(VowpalClient.save(VowpalClientTest, model_name))
      assert "0\n" == VowpalClient.send(VowpalClientTest, "|a 12 3\n")
      assert "0\n" == VowpalClient.send(VowpalClientTest, "1 |a 12 3\n")
      assert "0.579291\n" == VowpalClient.send(VowpalClientTest, "|a 12 3\n")
      assert 0.579291 == VowpalClient.predict(VowpalClientTest, [{"a", [{"12", 1}, {"3", 1}]}])
      assert 0.579291 == VowpalClient.train(VowpalClientTest, -1, [{"a", [{"12", 1}, {"3", 1}]}])
      assert -0.006252 == VowpalClient.predict(VowpalClientTest, [{"a", [{"12", 1}, {"3", 1}]}])
      assert -0.006252 == VowpalClient.predict(VowpalClientTest, [{"a", [{"12", 1}, "3"]}])
      assert -0.006252 == VowpalClient.predict(VowpalClientTest, [{"a", [12, 3]}])
    rescue
      e ->
        System.cmd("killall", ["-9", "vw"])
        raise e
    end

    System.cmd("killall", ["-9", "vw"])
    Process.delete(pid)
  end
end
