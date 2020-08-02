defmodule Cli do
  @usage """
  TODO add usage
  """

  @output_tmpl """
  # {release}

  {changes}
  """

  @grouped_changes_tmpl """
  ## {label}

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
        case git_repo() do
          {:ok, url} ->
            generate_changelog([{:url, git_repo()} | args])

          {:error, reason} ->
            IO.puts("Error: could not resolve a repository URL: #{reason}")
        end

      is_nil(args[:labels]) ->
        print_with_no_grouping(Changeloggen.get_prs(args[:url], args[:release]), args[:release])

      is_bitstring(args[:labels]) ->
        labels =
          String.trim(args[:labels])
          |> String.split(",")
          |> Enum.map(&String.trim/1)

        print_after_grouping(
          Changeloggen.get_prs(args[:url], args[:release]),
          args[:release],
          labels
        )

      true ->
        IO.puts("Unknown error. Check usage and try again.")
    end
  end

  defp git_repo() do
    Git.parse_origin_url()
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

  defp print_after_grouping({:error, reason}, _, _), do: IO.puts("Error: #{reason}")

  defp print_after_grouping({:ok, prs}, release, labels)
       when is_bitstring(release) and is_list(labels) do
    groups =
      Changeloggen.group_by_labels(prs, labels)
      |> Map.to_list()
      |> Enum.map(&group_tmpl/1)
      |> Enum.filter(fn tmpl -> tmpl !== "" end)

    case groups do
      [] ->
        IO.puts("No PRs found matching supplied labels")

      _ ->
        changes = Enum.reduce(groups, "", fn group, acc -> acc <> group end)

        String.replace(@output_tmpl, "{release}", release)
        |> String.replace("{changes}", changes)
        |> IO.puts()
    end
  end

  defp group_tmpl({_, []}), do: ""

  defp group_tmpl({label, prs}) do
    prs_string = Enum.reduce(prs, "", fn pr, acc -> acc <> "* #{pr}\n" end)

    String.replace(@grouped_changes_tmpl, "{label}", label)
    |> String.replace("{changes}", prs_string)
  end
end
