defmodule Advent2017.Day7 do
  defmodule Disc do
    defstruct name: "",
              weight: 0,
              missing_children: MapSet.new,
              children: MapSet.new

    defp w(weight) do
      weight
      |> String.replace(~r/\(|\)/, "")
      |> String.to_integer
    end

    defp c(children) do
      children
      |> String.split(", ", [trim: true])
      |> MapSet.new
    end

    def new([name_and_weight]) do
      [name, weight] = String.split(name_and_weight, " ")
      %Disc{name: name, weight: w(weight)}
    end

    def new([name_and_weight, children]) do
      [name, weight] = String.split(name_and_weight, " ")
      %Disc{name: name, weight: w(weight), missing_children: c(children)}
    end

    def add_child(parent, child) do
      parent
    end
  end

  def build_tower([child | remaining_nodes]) do
    # I have a list of nodes that haven't been placed yet.
    # child
    #   if List.empty(remaining_nodes)
    #   check to see if it belongs in remaining_nodes
    parent =
      Enum.find(remaining_nodes, &(MapSet.member?(&1.missing_children, child)))

    cond do
      Enum.empty? remaining_nodes -> # win condition
        MapSet.new([child])
      parent ->
        parent = Disc.add_child(parent, child)
    end
  end

  def load_file_into_nodes(file_name) do
    {:ok, file} = File.read("lib/day7/#{file_name}")

    file
    |> String.split("\n", [trim: true])
    |> Enum.map(&(String.split(&1, " -> ", [trim: true])))
    |> Enum.map(&(Disc.new &1))
  end

  def p1 do
    load_file_into_nodes("test.txt")
    |> build_tower
    |> List.first
    |> Map.fetch(:name)
  end

  def p2, do: nil
end
