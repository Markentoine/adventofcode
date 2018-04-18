defmodule Advent2016.Day8 do
  @moduledoc """
  http://adventofcode.com/2016/day/8
  """

  def rect(screen, x, y) do
    for x <- 0..x-1 do
      for y <- 0..y-1 do
        {x, y}
      end
    end
    |> List.flatten
  end

  def rotate(screen, :row, y, offset) do
    {row, remainder} =
      screen
      |> Enum.split_with(fn({_, target}) -> target == y end)

    row
    |> Enum.map(fn({x, y}) -> {rem(x + offset, 50), y} end)
    |> Kernel.++(remainder)
  end

  def rotate(screen, :column, x, offset) do
    {column, remainder} =
      screen
      |> Enum.split_with(fn({target, _}) -> target == x end)

    column
    |> Enum.map(fn({x, y}) -> {x, rem(y + offset, 6)} end)
    |> Kernel.++(remainder)
  end

  def print(screen) do
    {max_x, _} = Enum.max_by(screen, fn({x, _}) -> x end)
    {_, max_y} = Enum.max_by(screen, fn({_, y}) -> y end)

    for y <- 0..max_y do
      for x <- 0..max_x do
        case Enum.member?(screen, {x, y}) do
           true -> "#"
          false -> "."
        end
      end
      |> Enum.join
      |> Kernel.<>("\n")
    end
    |> Enum.join
    |> IO.puts
  end

  def p1, do: nil
  def p2, do: nil
end
