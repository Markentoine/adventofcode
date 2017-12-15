require IEx

defmodule Advent2017.Day14 do
  alias Advent2017.Day10, as: Knot

  @spec hex_to_bin(String) :: String
  def hex_to_bin(str) do
    str
    |> String.to_integer(16)
    |> Integer.to_string(2)
  end

  @spec defrag(String) :: List
  def defrag(input) do
    Enum.map(0..127, fn row ->
      Knot.dense_hash("#{input}-#{row}")
      |> hex_to_bin
      |> String.split("", [trim: true])
      |> Enum.map(&String.to_integer &1)
    end)
  end

  @doc """
  Transforms a "grid" of nested lists into a "grid" of nested maps.

  You can then use `get_in/2` and 'update_in/3` to access the grid in the form:
  `get_in(grid, [x, y])`

  The reasoning for this is it will hopefully make bound detection easier.
  """
  def list_grid_to_map_grid(grid) do
    Enum.into(Enum.with_index(grid), %{}, fn ({v, k}) ->
      {k, Enum.into(Enum.with_index(v), %{}, fn({a, b}) ->
        {b, a}
      end)}
    end)
  end

  @doc """
      iex> Advent2017.Day14.adjacent([2, 2])
      [[3, 2], [1, 2], [2, 3], [2, 1]]
  """
  def adjacent([x, y]) do
    [[x+1, y], [x-1, y], [x, y+1], [x, y-1]]
  end

  @spec contiguous(Map, List, MapSet) :: MapSet
  def contiguous(grid, coords, group \\ MapSet.new) do
    case get_in(grid, coords) do
      nil -> group
        0 -> group
        1 ->
          neighbors = Enum.reject(adjacent(coords), &MapSet.member?(group, &1))
          unless Enum.empty? neighbors do
            Enum.map(neighbors, fn adj ->
              contiguous(grid, adj, MapSet.put(group, coords))
            end)
            |> Enum.reduce(&MapSet.union &1, &2)
          else
            group
          end
    end
  end

  @doc """
  Expects a list of lists.
  """
  def find_groups(grid, visited \\ MapSet.new) do
    map = list_grid_to_map_grid(grid)
  end

  def p1 do
    defrag("ljoxqyyw")
    |> List.flatten
    |> Enum.sum
  end
  def p2 do
    defrag("ljoxqyyw")
    |> find_groups
  end
end
