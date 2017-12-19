require IEx

defmodule Advent2017.Day18 do
  @doc ~S"""
  snd X sends the value of X to the other program. These values wait in a queue
  until that program is ready to receive them. Each program has its own message
  queue, so a program can never receive a message it sent.

  """
  def snd(state, x) do
    send(state[:target], {:snd, e(state, x)})
    state
    |> Map.update!(:snd, fn history -> [e(state, x)|history] end)
    |> next
  end

  @doc ~S"""
  set X Y sets register X to the value of Y.

      iex> Advent2017.Day18.set(%{pointer: 0, f: 0}, "f", "3")
      %{f: 3, pointer: 1}

      iex> Advent2017.Day18.set(%{pointer: 0, f: 3}, "x", "f")
      %{f: 3, x: 3, pointer: 1}
  """
  def set(state, x, y) do
    Map.put(state, a(x), e(state, y))
    |> next
  end

  @doc ~S"""
  add X Y increases register X by the value of Y.

      iex> Advent2017.Day18.add(%{pointer: 0, f: 3}, "f", "f")
      %{f: 6, pointer: 1}
  """
  def add(state, x, y) do
    Map.put(state, a(x), e(state, x) + e(state, y))
    |> next
  end

  @doc ~S"""
  mul X Y sets register X to the result of multiplying the value contained in
  register X by the value of Y.

      iex> Advent2017.Day18.mul(%{pointer: 0, f: 3}, "f", "f")
      %{f: 9, pointer: 1}
  """
  def mul(state, x, y) do
    Map.put(state, a(x), e(state, x) * e(state, y))
    |> next
  end

  @doc ~S"""
  mod X Y sets register X to the remainder of dividing the value contained in
  register X by the value of Y (that is, it sets X to the result of X modulo
  Y).

      iex> Advent2017.Day18.mod(%{pointer: 0, f: 3}, "f", "2")
      %{f: 1, pointer: 1}
  """
  def mod(state, x, y) do
    Map.put(state, a(x), rem(e(state, x), e(state,y)))
    |> next
  end

  @doc ~S"""
  rcv X receives the next value and stores it in register X. If no values are
  in the queue, the program waits for a value to be sent to it. Programs do not
  continue to the next instruction until they have received a value. Values are
  received in the order they are sent.

  """
  def rcv(state, x) do
    receive do
      {:snd, int} when is_integer(int) ->
        set(state, x, int)

        cond do
          state[:limit] == length(state[:rcv]) ->
            state
            |> Map.update!(:rcv, fn history -> [e(state, x)|history] end)
            |> stop
          true ->
            state
            |> Map.update!(:rcv, fn history -> [e(state, x)|history] end)
            |> next
        end
    after
      5000 -> stop(state)
    end
  end

  @doc ~S"""
  jgz X Y jumps with an offset of the value of Y, but only if the value of X
  is greater than zero. (An offset of 2 skips the next instruction, an offset
  of -1 jumps to the previous instruction, and so on.)

      iex> Advent2017.Day18.jgz(%{pointer: 0, f: 3}, "3", "2")
      %{pointer: 2, f: 3}
      iex> Advent2017.Day18.jgz(%{pointer: 0, f: 3}, "-3", "2")
      %{pointer: 1, f: 3}
  """
  def jgz(state, x, y) do
    case e(state, x) > 0 do
      true  -> Map.update!(state, :pointer, &(&1 + e(state, y)))
      false -> next(state)
    end
  end

  def a(str), do: String.to_atom(str)
  def next(state), do: Map.update!(state, :pointer, &(&1+1))
  def stop(state), do: Map.put(state, :halt, true)

  @doc ~S"""
  e evaluates a variable by the stack. If there's a register, it returns that.
  """
  def e(state, var) do
    cond do
      is_integer(var) ->
        var
      Enum.member?(Map.keys(state), a(var)) ->
        state[a(var)]
      Regex.match?(~r/[a-z]/, var) ->
        0
      true ->
        String.to_integer(var)
    end
  end

  def setup_state(state \\ %{}) do
    state
    |> Map.put_new(:pointer, 0)
    |> Map.put_new(:rcv, [])
    |> Map.put_new(:snd, [])
    |> Map.put_new(:target, self())
  end

  def run(state, instructions) do
    state = setup_state(state)

    case state[:halt] do
      true -> state
      _ ->
        instruction   = Enum.at(instructions, state[:pointer])
        [method|args] = String.split(instruction, " ", trim: true)

        run(apply(Advent2017.Day18, a(method), [state | args]), instructions)
    end
  end

  def p1 do
    {:ok, file} = File.read(__DIR__ <> "/input.txt")

    run(%{limit: 1}, String.split(file, "\n", trim: true))
    |> Map.get(:rcv)
    |> List.first
  end

  def p2 do
    # I guess I'm going to have to spin up some actors and use `send/3` and
    # `receive/1`... let's do some real concurrency!
    {:ok, file} = File.read(__DIR__ <> "/input.txt")

    instructions =
      file
      |> String.split("\n", trim: true)

    {:ok, p0} = Agent.start_link(fn -> setup_state(%{p: 0}) end)
    {:ok, p1} = Agent.start_link(fn -> setup_state(%{p: 1}) end)

    Agent.update(p0, fn state -> %{state | target: p1} end)
    Agent.update(p1, fn state -> %{state | target: p0} end)

    Agent.cast(p0, __MODULE__, :run, [instructions])
    Agent.cast(p1, __MODULE__, :run, [instructions])
  end
end
