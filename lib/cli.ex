defmodule Cli do
  @usage """
  TODO add usage
  """

  @output_tmpl """
  # {release}

  {changes}
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
          group_by: :string,
          output: :string
        ]
      )

    IO.inspect(parsed)
    parsed
  end

  defp generate_changelog(args) do
    cond do
      is_nil(args[:release]) ->
        IO.puts("missing release option")

      is_nil(args[:url]) ->
        generate_changelog([{:url, git_repo()} | args])

      is_nil(args[:labels]) ->
        print_with_no_grouping(Changeloggen.get_prs(args[:url], args[:release]), args[:release])
        # TODO handle when grouped by labels
    end
  end

  defp git_repo() do
    "github.com/jaegertracing/jaeger"
  end

  defp print_with_no_grouping({:ok, []}, release),
    do: IO.puts("No changes found with release label: #{release}")

  defp print_with_no_grouping({:error, reason}, _), do: IO.puts("Error: #{reason}")

  defp print_with_no_grouping({:ok, prs}, release) do
    prs_string = Enum.reduce(prs, "", fn pr, acc -> acc <> "* #{pr}\n" end)

    String.replace(@output_tmpl, "{release}", release)
    |> String.replace("{changes}", prs_string)
    |> IO.puts()
  end
end
