defmodule Cli do
  @usage """
  Usage:

  changelogen [--release=v0.1.0] [--labels=Bug,Feature]
  """

  def main(args) do
    parse_args(args)
    |> generate_changelog()
  end

  defp parse_args(args) when is_list(args) do
    {parsed, _, _} =
      OptionParser.parse(args,
        switches: [
          release: :string,
          url: :string,
          labels: :string,
          output: :string,
          help: :boolean
        ]
      )

    parsed
  end

  defp generate_changelog(args) do
    cond do
      args[:help] ->
        IO.puts @usage

      is_nil(args[:release]) ->
        generate_changelog([{:release, "Release version placeholder"} | args])

      is_nil(args[:url]) ->
        case Git.parse_origin_url() do
          {:ok, url} ->
            generate_changelog([{:url, url} | args])

          {:error, reason} ->
            IO.puts("Error: could not resolve a repository URL: #{reason}")
        end

      is_nil(args[:labels]) ->
        case Api.get_prs_after_last_release(args[:url]) do
          {:ok, []} ->
            IO.puts("No matching PRs found matching release: #{args[:release]}")
          {:ok, prs} ->
            IO.puts(Formatter.no_grouping(prs, args[:release]))
          {:error, reason} ->
            IO.puts("Error: #{reason}")
        end

      is_bitstring(args[:labels]) ->
        labels =
          String.trim(args[:labels])
          |> String.split(",")
          |> Enum.map(&String.trim/1)

        case Api.get_prs_after_last_release(args[:url]) do
          {:ok, []} ->
            IO.puts("No matching PRs found matching release: #{args[:release]}")
          {:ok, prs} ->
            groups = Api.group_by_labels(prs, labels)
            IO.puts(Formatter.grouped(groups, args[:release]))
          {:error, reason} ->
            IO.puts("Error: #{reason}")
        end

      true ->
        IO.puts("Unknown error. Check usage and try again.")
    end
  end

end
