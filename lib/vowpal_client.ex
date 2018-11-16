defmodule VowpalClient do
  @moduledoc """
  Provides a TCP client for Vowpal Wabbit, and exports functions `train/3`, `predict/2`, and `save/2`

  `spawn_vowpal/2` is just for debugging purposes, ideally you will have vowpal running somewhere else ('vw --foreground --port 12312 --num_children 1 ...')

  ## Examples

      iex> VowpalClient.spawn_vowpal(12123)
      #PID<0.140.0>

      iex> VowpalClient.start_link(:vw, {127,0,0,1}, 12123, 1000)
      {:ok, #PID<0.143.0>}

      iex> VowpalClient.train(:vw, -1, [{"features",["a","b","c"]}])
      -0.856059

      iex> VowpalClient.predict(:vw,  [{"features",["a","b","c"]}])
      -0.998616

      iex> VowpalClient.predict(:vw,  [{"features",["a","b","d"]}])
      -0.748962

  """

  use GenServer

  @spec spawn_vowpal(integer(), list(String.t())) :: pid()
  def spawn_vowpal(port, arguments \\ []) do
    spawn_link(fn ->
      System.cmd(
        System.find_executable("vw"),
        ["--port", "#{port}", "--foreground", "--num_children", "1"] ++ arguments,
        into: IO.stream(:stdio, :line)
      )
    end)
  end

  @doc """
  Connects to Vowpal Wabbit server on specific port

  ## Parameters
    - server_name: genserver server name, e.g. :vw
    - address: inet address e.g.: {127,0,0,1}
    - port: the port to connect to
    - timeout: connect timeout ngiven to `:gen_tcp.connect/4`

  ## Examples

      iex> VowpalClient.start_link(:vw, {127,0,0,1}, 12123, 1000)
      {:ok, #PID<0.143.0>}

  this sends to vw: "-1 |features a b c\\n"
  """

  @spec start_link(GenServer.name(), :gen_tcp.address(), integer(), integer()) ::
          GenServer.on_start()
  def start_link(name, address, port, timeout) do
    GenServer.start_link(__MODULE__, {address, port, timeout}, name: name)
  end

  @type feature() :: {integer(), float()} | {String.t(), float()} | String.t() | integer()
  @type namespace() :: {Strinb.t(), list(feature())}

  defp toLine(namespaces) do
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

        "|#{name} #{f}"
      end)
      |> Enum.join(" ")

    line
  end

  @doc """
  Sends a train line to Vowpal Wabbit
  vowpal accepts format as: "label |namespace feature feature feature |namespace featuree:value ...

  label is integer, features can be either integer or string or touple of {string/int, float value}

  ## Parameters
    - server_name: genserver server name (same you gave to `start_link/3`)
    - label: the training label (for example -1 for click, 1 for convert)
    - namespaces: training features of that example, list of `namespace/0` type

  ## Examples

      iex> VowpalClient.start_link(:vw, {127,0,0,1}, 12123, 1000)
      {:ok, #PID<0.143.0>}

      iex> VowpalClient.predict(:vw,  [{"features",["a","b","c"]}])
      -0.998616

  this sends to vw: "|features a b c\\n"
  """

  @spec train(GenServer.server(), integer(), list(namespace())) :: float()
  def train(server_name, label, namespaces) do
    line = toLine(namespaces)
    v = GenServer.call(server_name, {:send, "#{label} #{line}\n"})
    {f, _} = Float.parse(v)
    f
  end

  @doc """
  Sends a predict line to Vowpal Wabbit, almost the same as `train/3` but without the label
  vowpal accepts format as: "|namespace feature feature feature |namespace featuree:value ...


  ## Parameters
    - server_name: genserver server name (same you gave to `start_link/3`)
    - namespaces: training features of that example

  ## Examples

      iex> VowpalClient.start_link(:vw, {127,0,0,1}, 12123, 1000)
      {:ok, #PID<0.143.0>}

      iex> VowpalClient.train(:vw, -1, [{"features",["a","b","c"]}])
      -0.856059

  this sends to vw: "-1 |features a b c\\n"
  """

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

  @doc """
  Asks Vowpal Wabbit to save the regressor (model) by sending a line save_path_to_model, e.g. save_/tmp/example

  ## Parameters
    - server_name: genserver server name (same you gave to `start_link/3`)
    - path: path to where the model will be saved

  The models is saved async from vw, so the function polls waiting for the filename to appear
  then it reads it and returns the binary so you can save it

  if you want to start vowpal loading initial regressor pass --initial_regressor /path/to/file

  ## Examples

     iex> VowpalClient.save(:vw, "/tmp/abc.txt")
     6, 0, 0, 0, 56, 46, 54, 46, 49, 0, 1, 0, 0, 0, 0, 109, 0, 0, 128, 191, 0, 0,
     0, 0, 18, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 31, 0, 0, 0, 32, 45,
     45, 104, 97, 115, ...

  this sends to vw: "save_/tmp/abc.txt\\n"
  """

  @spec save(GenServer.server(), String.t()) :: binary()
  def save(server_name, path) do
    GenServer.call(server_name, {:save, path})
  end

  @impl true
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

  @impl true
  def handle_call({type, line}, from, socket) do
    case type do
      :send ->
        if !String.ends_with?(line, "\n") do
          raise ArgumentError, message: "line must end with \\n"
        end

        # let it die
        :ok = :gen_tcp.send(socket, line)
        {:ok, data} = :gen_tcp.recv(socket, 0)
        {:reply, data, socket}

      :save ->
        :ok = :gen_tcp.send(socket, "save_#{line}\n")

        # vw will save the model async
        Task.start_link(fn ->
          waitToExist(line, 1000)
          GenServer.reply(from, File.read!(line))
        end)

        {:noreply, socket}

      _ ->
        raise ArgumentError, message: "not sure what to do"
    end
  end

  defp waitToExist(path, interval) do
    if File.exists?(path) do
      true
    else
      :timer.sleep(interval)
      waitToExist(path, interval)
    end
  end
end
