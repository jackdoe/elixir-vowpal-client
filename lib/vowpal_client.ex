defmodule VowpalClient do
  def start_link(name, address, port, timeout) do
    GenServer.start_link(__MODULE__, {address, port, timeout}, name: name)
  end

  @type feature() :: {integer(), float()} | {String.t(), float()} | String.t() | integer()
  @type namespace() :: {Strinb.t(), list(feature())}

  def toLine(namespaces) do
    line =
      namespaces
      |> Enum.map(fn {name, features} ->
        f =
          features
          |> Enum.map(fn e ->
            case e do
              {name, value} ->
                "#{name}:#{value}"

              name ->
                "#{name}:1"
            end
          end)
          |> Enum.join(" ")

        "|{name} #{f}"
      end)
      |> Enum.join(" ")

    line
  end

  @spec train(GenServer.server(), integer(), list(namespace())) :: float()
  def train(server_name, label, namespaces) do
    line = toLine(namespaces)
    v = GenServer.call(server_name, {:send, "#{label} #{line}\n"})
    {f, _} = Float.parse(v)
    f
  end

  @spec predict(GenServer.server(), list(namespace())) :: float()
  def predict(server_name, namespaces) do
    line = toLine(namespaces)
    v = GenServer.call(server_name, {:send, "#{line}\n"})
    {f, _} = Float.parse(v)
    f
  end

  @spec send(GenServer.server(), String.t()) :: String.t()
  def send(server_name, line) do
    GenServer.call(server_name, {:send, line})
  end

  @spec save(GenServer.server(), String.t()) :: binary()
  def save(server_name, path) do
    GenServer.call(server_name, {:save, path})
  end

  def init({address, port, timeout}) do
    {:ok, socket} =
      :gen_tcp.connect(
        address,
        port,
        [:binary, packet: :line, active: false, reuseaddr: true],
        timeout
      )

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

  def handle_call({:save, path}, from, socket) do
    # let it die
    :ok = :gen_tcp.send(socket, "save_#{path}\n")

    # vw will save the model async
    Task.start_link(fn ->
      waitToExist(path, 1000)
      GenServer.reply(from, File.read!(path))
    end)

    {:noreply, socket}
  end
end
