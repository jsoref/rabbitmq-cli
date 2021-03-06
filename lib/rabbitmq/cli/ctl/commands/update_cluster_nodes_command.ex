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
## The Initial Developer of the Original Code is Pivotal Software, Inc.
## Copyright (c) 2016-2017 Pivotal Software, Inc.  All rights reserved.

defmodule RabbitMQ.CLI.Ctl.Commands.UpdateClusterNodesCommand do
  alias RabbitMQ.CLI.Core.{Config, Helpers}

  @behaviour RabbitMQ.CLI.CommandBehaviour

  use RabbitMQ.CLI.Core.MergesNoDefaults
  use RabbitMQ.CLI.Core.AcceptsOnePositionalArgument
  use RabbitMQ.CLI.Core.RequiresRabbitAppStopped

  def run([seed_node], options=%{node: node_name}) do
    long_or_short_names = Config.get_option(:longnames, options)
    seed_node_normalised = Helpers.normalise_node(seed_node, long_or_short_names)
    :rabbit_misc.rpc_call(
      node_name,
      :rabbit_mnesia,
      :update_cluster_nodes,
      [seed_node_normalised]
    )
  end

  def usage() do
    "update_cluster_nodes <existing_cluster_member_node_to_seed_from>"
  end

  def help_section(), do: :cluster_management

  def description(), do: "Instructs an already clustered node to contact <clusternode> to cluster when waking up"

  def banner([seed_node], %{node: node_name}) do
    "Will seed #{node_name} from #{seed_node} on next start"
  end

  def output({:error, :mnesia_unexpectedly_running}, %{node: node_name}) do
    {:error, RabbitMQ.CLI.Core.ExitCodes.exit_software(),
     RabbitMQ.CLI.DefaultOutput.mnesia_running_error(node_name)}
  end

  def output({:error, :cannot_cluster_node_with_itself}, %{node: node_name}) do
    {:error, RabbitMQ.CLI.Core.ExitCodes.exit_software(),
     "Error: cannot cluster node with itself: #{node_name}"}
  end

  use RabbitMQ.CLI.DefaultOutput
end
