defmodule VowpalClient do
  def start_link(name, address, port, timeout) do
    {:ok, socket} =
      :gen_tcp.connect(
        address,
        port,
        [:binary, packet: :line, active: false, reuseaddr: true],
        timeout
      )

    GenServer.start_link(__MODULE__, socket, name: name)
  end

  @spec send(GenServer.server(), String.t()) :: String.t()
  def send(server_name, line) do
    GenServer.call(server_name, {:send, line})
  end

  @spec save(GenServer.server(), {String.t(), String.t()}) :: binary()
  def save(server_name, {cwd, model_name}) do
    GenServer.call(server_name, {:save, {cwd, model_name}})
  end

  def init(socket) do
    {:ok, socket}
  end

  def handle_call({:send, line}, _from, socket) do
    if !String.ends_with?(line, "\n") do
      raise ArgumentError, message: "line must end with \\n"
    end

    # let it die
    :ok = :gen_tcp.send(socket, line)
    {:ok, data} = :gen_tcp.recv(socket, 0)
    {:reply, data, socket}
  end

  defp waitToExist(path, interval) do
    if File.exists?(path) do
      true
    else
      :timer.sleep(interval)
      waitToExist(path, interval)
    end
  end

  def handle_call({:save, {cwd, model_name}}, from, socket) do
    # let it die
    :ok = :gen_tcp.send(socket, "save_#{model_name}\n")

    # vw will save the model async
    Task.start_link(fn ->
      path = "#{cwd}/#{model_name}"
      waitToExist(path, 1000)
      GenServer.reply(from, File.read!(path))
    end)

    {:noreply, socket}
  end
end
