defmodule Advent2017.Day5 do
  def trampoline(list, index, jumps, inc) do
    cond do
      index < 0 ->
        jumps
      index >= tuple_size(list) ->
        jumps
      true ->
        value  = elem(list, index)
        offset = index + value

        list
        |> put_elem(index, inc.(value))
        |> trampoline(offset, jumps+1, inc)
    end
  end

  def run(inc) do
    {:ok, file} = File.read("./lib/day5/input.txt")

    file
    |> String.split("\n", [trim: true])
    |> Enum.map(&(String.to_integer(&1)))
    |> List.to_tuple
    |> trampoline(0, 0, inc)
  end

  def p1 do
    run(&(&1 + 1))
  end

  def p2 do
    run(&(if &1 >= 3, do: &1 - 1, else: &1 + 1))
  end
end