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


defmodule ListPermissionsCommand do

  def list_permissions([_|_] = args, _) when length(args) > 0 do
    HelpCommand.help
    {:bad_argument, args}
  end

  def list_permissions([], %{node: node_name, timeout: timeout, param: vhost}) do
    node_name
    |> Helpers.parse_node
    |> :rabbit_misc.rpc_call(
      :rabbit_auth_backend_internal,
      :list_vhost_permissions,
      [vhost],
      timeout
    )
  end

  def list_permissions([], %{node: _node_name, timeout: _timeout} = opts) do
    list_permissions([], Map.merge(opts, %{param: "/"}))
  end

  def usage, do: "list_permissions [-p <vhost>]"
end