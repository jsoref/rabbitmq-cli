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

defmodule RabbitMQ.CLI.Ctl.Commands.ChangePasswordCommand do
  alias RabbitMQ.CLI.Core.Helpers

  @behaviour RabbitMQ.CLI.CommandBehaviour
  use RabbitMQ.CLI.DefaultOutput
  def merge_defaults(args, opts), do: {args, opts}

  def validate(args, _) when length(args) < 2, do: {:validation_failure, :not_enough_args}
  def validate([_ | _] = args, _) when length(args) > 2, do: {:validation_failure, :too_many_args}
  def validate(_, _), do: :ok

  use RabbitMQ.CLI.Core.RequiresRabbitAppRunning

  def run([_user, _] = args, %{node: node_name}) do
    :rabbit_misc.rpc_call(
      node_name,
      :rabbit_auth_backend_internal,
      :change_password,
      args ++ [Helpers.cli_acting_user()]
    )
  end

  def usage, do: "change_password <username> <password>"

  def help_section(), do: :user_management

  def description(), do: "Changes the user password"

  def banner([user | _], _), do: "Changing password for user \"#{user}\" ..."
end
