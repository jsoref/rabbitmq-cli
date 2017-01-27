## The contents of this file are subject to the Mozilla Public License
## Version 1.1 (the "License"); you may not use this file except in
## compliance with the License. You may obtain a copy of the License
## at http://www.mozilla.org/MPL/
##
## Software distributed under the License is distributed on an "AS IS"
## basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
## the License for the specific language governing rights and
## limitations under the License.
##
## The Original Code is RabbitMQ.
##
## The Initial Developer of the Original Code is GoPivotal, Inc.
## Copyright (c) 2007-2017 Pivotal Software, Inc.  All rights reserved.


defmodule HelpCommandTest do
  use ExUnit.Case, async: false

  alias RabbitMQ.CLI.Core.CommandModules, as: CommandModules
  alias RabbitMQ.CLI.Core.ExitCodes,   as: ExitCodes

  @command RabbitMQ.CLI.Ctl.Commands.HelpCommand

  setup_all do
    :ok
  end

  test "basic usage info is printed" do
    assert @command.run([], %{}) =~ ~r/Default node is \"rabbit@server\"/
  end

  test "command usage info is printed if command is specified" do
    CommandModules.module_map
    |>  Map.keys
    |>  Enum.each(
          fn(command) ->
            assert @command.run([command], %{}) =~ ~r/#{command}/
          end)
  end

  test "Command info is printed" do
    assert @command.run([], %{}) =~ ~r/Commands:\n/

    # Checks to verify that each module's command appears in the list.
    CommandModules.module_map
    |>  Map.keys
    |>  Enum.each(
          fn(command) ->
            assert @command.run([], %{}) =~ ~r/\n    #{command}.*\n/
          end)
  end

  test "Commands are sorted alphabetically" do
    [cmd1, cmd2, cmd3] = CommandModules.module_map
    |> Map.keys
    |> Enum.sort
    |> Enum.take(3)

    output = @command.run([], %{})

    {start1, _} = :binary.match(output, cmd1)
    {start2, _} = :binary.match(output, cmd2)
    {start3, _} = :binary.match(output, cmd3)

    assert start1 < start2
    assert start2 < start3
  end

  test "Info items are defined for existing commands" do
    assert @command.run([], %{}) =~ ~r/vhostinfoitem/
    assert @command.run([], %{}) =~ ~r/queueinfoitem/
    assert @command.run([], %{}) =~ ~r/exchangeinfoitem/
    assert @command.run([], %{}) =~ ~r/bindinginfoitem/
    assert @command.run([], %{}) =~ ~r/connectioninfoitem/
    assert @command.run([], %{}) =~ ~r/channelinfoitem/
  end

  test "Info items are printed for selected command" do
    assert @command.run(["list_vhosts"], %{}) =~ ~r/vhostinfoitem/
    assert @command.run(["list_queues"], %{}) =~ ~r/queueinfoitem/
    assert @command.run(["list_exchanges"], %{}) =~ ~r/exchangeinfoitem/
    assert @command.run(["list_bindings"], %{}) =~ ~r/bindinginfoitem/
    assert @command.run(["list_connections"], %{}) =~ ~r/connectioninfoitem/
    assert @command.run(["list_channels"], %{}) =~ ~r/channelinfoitem/
  end

  test "Help command returns exit code OK" do
    assert @command.output("Help string", %{}) ==
      {:error, ExitCodes.exit_ok, "Help string"}
  end

  test "No arguments also produce help command" do
    assert @command.run([], %{}) =~ ~r/Usage:/
  end

  test "Extra arguments also produce help command" do
    assert @command.run(["extra1", "extra2"], %{}) =~ ~r/Usage:/
  end
end
