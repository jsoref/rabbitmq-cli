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
## Copyright (c) 2007-2019 Pivotal Software, Inc.  All rights reserved.

defmodule RabbitMQ.CLI.Diagnostics.Commands.CheckPortListenerCommand do
  @moduledoc """
  Exits with a non-zero code if there is no active listener
  for the given port on the target node.

  This command is meant to be used in health checks.
  """

  import RabbitMQ.CLI.Diagnostics.Helpers, only: [listeners_on: 2,
                                                  listener_maps: 1]


  @behaviour RabbitMQ.CLI.CommandBehaviour

  use RabbitMQ.CLI.Core.AcceptsDefaultSwitchesAndTimeout
  use RabbitMQ.CLI.Core.MergesNoDefaults
  use RabbitMQ.CLI.Core.AcceptsOnePositiveIntegerArgument
  use RabbitMQ.CLI.Core.RequiresRabbitAppRunning

  def run([port], %{node: node_name, timeout: timeout}) do
    case :rabbit_misc.rpc_call(node_name,
      :rabbit_networking, :active_listeners, [], timeout) do
      {:error, _}    = err -> err;
      {:error, _, _} = err -> err;
      xs when is_list(xs)  ->
        locals = listeners_on(xs, node_name) |> listener_maps
        found  = Enum.any?(locals, fn %{port: p} ->
                  to_string(port) == to_string(p)
                 end)
        case found do
          true  -> {true,  port}
          false -> {false, port, locals}
        end;
      other                -> other
    end
  end

  def output({true, port}, %{node: node_name, formatter: "json"}) do
    {:ok, %{"result"   => "ok",
            "node"     => node_name,
            "port"     => port}}
  end
  def output({true, port}, %{node: node_name}) do
    {:ok, "A listener for port #{port} is running on node #{node_name}."}
  end
  def output({false, port, listeners}, %{formatter: "json"}) do
    ports = Enum.map(listeners, fn %{port: p} -> p end)
    {:error, %{"result"    => "error",
               "missing"   => port,
               "ports"     => ports,
               "listeners" => listeners}}
  end
  def output({false, port, listeners}, %{node: node_name}) do
    ports = Enum.map(listeners, fn %{port: p} -> p end)
            |> Enum.sort |> Enum.join(", ")
    {:error, "No listener for port #{port} is active on node #{node_name}. "
             <> "Found listeners that use the following ports: #{ports}"}
  end

  def usage, do: "check_port_listener <port>"

  def banner([port], %{node: node_name}) do
    "Asking node #{node_name} if there's an active listener on port #{port} ..."
  end
end