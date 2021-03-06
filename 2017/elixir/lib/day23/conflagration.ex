defmodule Advent2017.Day23 do
  @moduledoc """
  Part 1:
  You decide to head directly to the CPU and fix the printer from there. As you
  get close, you find an experimental coprocessor doing so much work that the
  local programs are afraid it will halt and catch fire. This would cause
  serious issues for the rest of the computer, so you head in and see what you
  can do.

  The code it's running seems to be a variant of the kind you saw recently on
  that tablet. The general functionality seems very similar, but some of the
  instructions are different:

  set X Y sets register X to the value of Y.  sub X Y decreases register X by
  the value of Y.  mul X Y sets register X to the result of multiplying the
  value contained in register X by the value of Y.  jnz X Y jumps with an
  offset of the value of Y, but only if the value of X is not zero.  (An offset
  of 2 skips the next instruction, an offset of -1 jumps to the previous
  instruction, and so on.) Only the instructions listed above are used. The
  eight registers here, named a through h, all start at 0.

  The coprocessor is currently set to some kind of debug mode, which allows for
  testing, but prevents it from doing any meaningful work.

  Part 2:

  There are four ways to handle this that I can see: Write a machine fast
  enough to complete in time, write code in elixir that optimizes the loops in
  the assembly, optimize the assembly input, or hand trace and understand the
  assembly. 1 seems impossible, 2 seems really complex, 5 is a solved problem
  so I believe I'm going to try and optimize the assembly.

  I'm going to build a quick heatmap of what instructions get called so that I
  can identify which is the tightest inner loop, then try to unwrap it a little
  bit while not changing the answer to p1. Theoretically I may be able to lower
  the complexity sufficiently that p2 just completes in time.
  """
  defmodule Machine do
    @moduledoc "Represents the state of my machine"
    defstruct pointer: 0,
              reg: %{},
              instructions: [],
              heatmap: %{}

    def put(machine, x, y) do
      Map.update!(machine, :reg, fn reg -> Map.put(reg, String.to_atom(x), y) end)
    end

    defimpl Inspect do
      def inspect(machine, _) do
        """
        #{Kernel.inspect machine.reg}
        #{Kernel.inspect machine.heatmap}

        #{Enum.at(machine.instructions, machine.pointer)}
        """
      end
    end
  end

  def next(machine), do: Map.update!(machine, :pointer, &(&1 + 1))
  def stop(machine) do
    Map.put(machine, :pointer, 99_999_999_999)
  end

  @doc ~S"""
  set X Y sets register X to the value of Y.
  """
  def set(machine, x, y) do
    machine
    |> Machine.put(x, e(machine, y))
    |> next
  end

  @doc ~S"""
  mul X Y sets register X to the result of multiplying the value contained in
  register X by the value of Y.
  """
  def mul(machine, x, y) do
    machine
    |> Machine.put(x, e(machine, x) * e(machine, y))
    |> next
  end

  @doc ~S"""
  sub X Y decreases register X by the value of Y.
  """
  def sub(machine, x, y) do
    machine
    |> Machine.put(x, e(machine, x) - e(machine, y))
    |> next
  end

  @doc ~S"""
  jnz X Y jumps with an offset of the value of Y, but only if the value of X is
  not zero. (An offset of 2 skips the next instruction, an offset of -1 jumps
  to the previous instruction, and so on.)
  """
  def jnz(machine, x, y) do
    case e(machine, x) != 0 do
      true  -> Map.update!(machine, :pointer, &(&1 + e(machine, y)))
      false -> next(machine)
    end
  end

  @doc ~S"""
  e evaluates a variable by the stack. If there's a register, it returns that.
  """
  def e(machine, var) do
    cond do
      is_integer(var) ->
        var
      Enum.member?(Map.keys(machine.reg), String.to_atom(var)) ->
        machine.reg[String.to_atom(var)]
      Regex.match?(~r/[a-z]/, var) ->
        0
      true ->
        String.to_integer(var)
    end
  end

  def run(machine) do
    instruction = Enum.at(machine.instructions, machine.pointer)
    if is_nil(instruction) do
      machine
    else
      [method|args] = String.split(instruction, " ", trim: true)

      run(apply(Advent2017.Day23, String.to_atom(method), [instrument(machine) | args]))
    end
  end

  def instrument(machine) do
    Map.update!(machine, :heatmap, fn heatmap ->
      Map.update(heatmap, machine.pointer, 1, & &1 + 1)
    end)
  end

  def is_prime?(num, primes) do
    Enum.member?(primes, num)
  end

  def is_prime?(num) do
    hd(sieve(num)) == num
  end

  def sieve(num) when is_integer(num) do
    2..num
    |> Enum.to_list
    |> sieve([])
  end

  def sieve([], primes), do: primes
  def sieve([number|numbers], primes) do
    numbers
    |> Enum.reject(& rem(&1, number) == 0)
    |> sieve([number|primes])
  end

  def p1 do
    {:ok, file} = File.read(__DIR__ <> "/input.txt")

    %Machine{instructions: String.split(file, "\n", trim: true)}
    |> run
    |> Map.get(:heatmap)
    |> Map.get(12)
  end

  @doc """
  b = 93             # set b 93
  c = b              # set c b
  if a != 0 do       # jnz a 2 ; jnz 1 5 (a != 0)
    b = b * 100      # mul b 100
    b = b + 100_000  # sub b -100000
    c = b            # set c b
    c = c + 17_000   # sub c -17000
  end

  A:                 # (jnz 1 -23 :32)
    f = 1            # set f 1
    d = 2            # set d 2
    B:
      e = 2          # set e 2
      C:             # (jnz g -8 :20)
        g = d        # set g d           |
        g = g * e    # mul g e           |
        g = g - b    # sub g b           |-> if d * e - b == 0 then f = 0
        if g == 0 do # jnz g 2 (g == 0)  |
          f = 0      # set f 0           |
        end
        e = e + 1    # sub e -1 (e + 1)
        g = e        # set g e
        g = g - b    # sub g b
      jnz g C        # jnz g -8
      d = d + 1      # sub d -1 (d + 1)
      g = d          # set g d
      g = g - b      # sub g b
    jnz g B          # jnz g -13
    if f != 0 do     # jnz f 2 (f == 0)
      h = h + 1      # sub h -1
    end
    g = b            # set g b
    g = g - c        # sub g c
    if g != 0 do     # jnz g 2 jnz 1 3 (g != 0)
      b = b + 17     # sub b -17
    else
      exit
    end
  jnz 1 A
  """
  def p2 do
    b  = 109_300 # (lower bound?)
    c  = 126_300 # (higher bound?)
    primes = sieve(c)

    Enum.reduce(Enum.take_every(b..c, 17), 0, fn num, non_primes ->
      if is_prime?(num, primes) do
        non_primes
      else
        non_primes + 1
      end
    end)
  end
end
