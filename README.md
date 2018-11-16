# VowpalClient

Provides a TCP client for [Vowpal Wabbit](https://github.com/VowpalWabbit/vowpal_wabbit), and exports functions `VowpalClient.train/3`, `VowpalClient.predict/2`, and `VowpalClient.save/2`

`VowpalClient.spawn_vowpal/2` is just for debugging purposes, ideally you will have vowpal running somewhere else (`vw --foreground --port 12312 --num_children 1 ...`)

Vowpal Wabbit is amazing and fast linear model tool, (and by fast I mean *fast*)
make sure you check out: [Vowpal Examples](https://github.com/VowpalWabbit/vowpal_wabbit/wiki/Examples)

This is *incomplete* client, that at the moment works with my very-basic use case, but as I am using it, it will get more complete.

[issues](https://github.com/jackdoe/elixir-vowpal-client/issues) [fork](https://github.com/jackdoe/elixir-vowpal-client) [license - MIT](https://en.wikipedia.org/wiki/MIT_License)

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



## Installation

The package can be installed
by adding `vowpal_client` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:vowpal_client, "~> 0.1.0"}
  ]
end
```

## Documentation

Documentation: [https://hexdocs.pm/vowpal_client](https://hexdocs.pm/vowpal_client)


## License

MIT

