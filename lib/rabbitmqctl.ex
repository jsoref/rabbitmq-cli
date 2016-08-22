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
## Copyright (c) 2007-2016 Pivotal Software, Inc.  All rights reserved.


defmodule RabbitMQCtl do
  alias RabbitMQ.CLI.Distribution,  as: Distribution

  alias RabbitMQ.CLI.Ctl.Commands.HelpCommand, as: HelpCommand
  alias RabbitMQ.CLI.Output, as: Output

  import RabbitMQ.CLI.Ctl.Helpers
  import  RabbitMQ.CLI.Ctl.Parser
  import RabbitMQ.CLI.ExitCodes


  def main(["--auto-complete", "./rabbitmqctl " <> str]) do
    auto_complete(str)
  end
  def main(["--auto-complete", "rabbitmqctl " <> str]) do
    auto_complete(str)
  end
  def main(unparsed_command) do
    {parsed_cmd, options, invalid} = parse(unparsed_command)
    case try_run_command(parsed_cmd, options, invalid) do
      {:validation_failure, _} = invalid ->
        error = validation_error(invalid, unparsed_command)
        {:error, exit_code_for(invalid), error}
      cmd_result -> cmd_result
    end
    |> Output.format_output(options)
    |> Output.print_output(options)
    |> exit_program
  end

  def try_run_command(parsed_cmd, options, invalid) do
    case {is_command?(parsed_cmd), invalid} do
      ## No such command
      {false, _}  ->
        usage_string = HelpCommand.all_usage()
        {:error, exit_usage, usage_string};
      ## Invalid options
      {_, [_|_]}  ->
        {:validation_failure, {:bad_option, invalid}};
      ## Command valid
      {true, []}  ->
        effective_options = options |> merge_all_defaults |> normalize_node
        Distribution.start(effective_options)

        run_command(effective_options, parsed_cmd)
    end
  end

  def auto_complete(str) do
    AutoComplete.complete(str)
    |> Stream.map(&IO.puts/1) |> Stream.run
    exit_program(exit_ok)
  end

  def merge_all_defaults(%{} = options) do
    options
    |> merge_defaults_node
    |> merge_defaults_timeout
    |> merge_defaults_longnames
  end

  defp merge_defaults_node(%{} = opts), do: Map.merge(%{node: get_rabbit_hostname}, opts)

  defp merge_defaults_timeout(%{} = opts), do: Map.merge(%{timeout: :infinity}, opts)

  defp merge_defaults_longnames(%{} = opts), do: Map.merge(%{longnames: false}, opts)

  defp normalize_node(%{node: node} = opts) do
    Map.merge(opts, %{node: parse_node(node)})
  end

  defp maybe_connect_to_rabbitmq("help", _), do: nil
  defp maybe_connect_to_rabbitmq(_, node) do
    connect_to_rabbitmq(node)
  end

  defp run_command(_, []), do: {:error, exit_ok, HelpCommand.all_usage()}
  defp run_command(options, [command_name | arguments]) do
    with_command(command_name,
        fn(command) ->
            case invalid_flags(command, options) do
              [] ->
                {arguments, options} = command.merge_defaults(arguments, options)
                case command.validate(arguments, options) do
                  :ok ->
                    print_banner(command, arguments, options)
                    maybe_connect_to_rabbitmq(command_name, options[:node])

                    command.run(arguments, options)
                    |> command.output(options)
                  err -> err
                end
              result  -> {:validation_failure, {:bad_option, result}}
            end
        end)
  end

  defp with_command(command_name, fun) do
    command = commands[command_name]
    fun.(command)
  end

  defp print_banner(command, args, opts) do
    case command.banner(args, opts) do
     nil -> nil
     banner -> IO.inspect banner
    end
  end

  defp validation_error({:validation_failure, err_detail}, unparsed_command) do
    {[command_name | _], _, _} = parse(unparsed_command)
    err = format_validation_error(err_detail, command_name) # TODO format the error better
    base_error = "Error: #{err}\nGiven:\n\t#{unparsed_command |> Enum.join(" ")}"

    usage = case is_command?(command_name) do
      true  ->
        command = commands[command_name]
        HelpCommand.base_usage(HelpCommand.program_name(), command)
      false ->
        HelpCommand.all_usage()
    end

    base_error <> "\n" <> usage 
  end

  defp format_validation_error(:not_enough_args, _), do: "not enough arguments."
  defp format_validation_error({:not_enough_args, detail}, _), do: "not enough arguments. #{detail}"
  defp format_validation_error(:too_many_args, _), do: "too many arguments."
  defp format_validation_error({:too_many_args, detail}, _), do: "too many arguments. #{detail}"
  defp format_validation_error(:bad_argument, _), do: "Bad argument."
  defp format_validation_error({:bad_argument, detail}, _), do: "Bad argument. #{detail}"
  defp format_validation_error({:bad_option, opts}, command_name) do
    header = case is_command?(command_name) do
      true  -> "Invalid options for this command:";
      false -> "Invalid options:"
    end
    Enum.join([header | for {key, val} <- opts do "#{key} : #{val}" end], "\n")
  end
  defp format_validation_error(err, _), do: inspect err

  defp invalid_flags(command, opts) do
    Map.take(opts, Map.keys(opts) -- (command.flags ++ global_flags))
    |> Map.to_list
  end

  defp exit_program(code) do
    :net_kernel.stop
    exit({:shutdown, code})
  end
end
