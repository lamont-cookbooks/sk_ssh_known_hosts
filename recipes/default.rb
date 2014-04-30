#
# Cookbook Name:: ssh_known_hosts
# Recipe:: default
#
# Author:: Scott M. Likens (<scott@likens.us>)
# Author:: Joshua Timberman (<joshua@opscode.com>)
# Author:: Seth Vargo (<sethvargo@gmail.com>)
#
# Copyright 2009, Adapp, Inc.
# Copyright 2011-2013, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Gather a list of all nodes, warning if using Chef Solo

hosts = [ {
  hostname:   node['hostname'],
  fqdn:       node['fqdn'],
  ipaddress:  node['ipaddress'],
  rsa:        node['keys'] && node['keys']['ssh'] && node['keys']['ssh']['host_rsa_public'],
  dsa:        node['keys'] && node['keys']['ssh'] && node['keys']['ssh']['host_dsa_public'],
  ecdsa:      node['keys'] && node['keys']['ssh'] && node['keys']['ssh']['host_ecdsa_public'],
  ecdsa_type: node['keys'] && node['keys']['ssh'] && node['keys']['ssh']['host_ecdsa_type'],
} ]

if Chef::Config[:solo]
  Chef::Log.warn 'ssh_known_hosts requires Chef search - Chef Solo does not support search!'
else
  hosts += partial_search(
    :node,
    "keys_ssh:* NOT name:#{node.name}",
    keys: {
      hostname:    [ 'hostname' ],
      fqdn:        [ 'fqdn' ],
      ipaddress:   [ 'ipaddress' ],
      rsa:         %w(keys ssh host_rsa_public),
      dsa:         %w(keys ssh host_dsa_public),
      ecdsa:       %w(keys ssh host_ecdsa_public),
      ecdsa_type:  %w(keys ssh host_ecdsa_type),
    },
  )
end

# Add the data from the data_bag to the list of nodes.
# We need to rescue in case the data_bag doesn't exist.
begin
  hosts += data_bag('ssh_known_hosts').map do |item|
    entry = data_bag_item('ssh_known_hosts', item)
    {
      fqdn:        entry['fqdn'],
      ipaddress:   entry['ipaddress'],
      hostname:    entry['hostname'],
      rsa:         entry['rsa'],
      dsa:         entry['dsa'],
      ecsda:       entry['ecsda'],
      ecdsa_type:  entry['ecdsa_type'],
    }
  end
rescue
  Chef::Log.info "Could not load data bag 'ssh_known_hosts'"
end

# Loop over the hosts and add 'em
hosts.each do |host|
  entry_name = [ host[:fqdn], host[:ipaddress], host[:hostname] ].compact.join(",")
  sk_ssh_known_hosts_entry entry_name do
    rsa host[:rsa]
    dsa host[:dsa]
    ecdsa host[:ecdsa]
    ecdsa_type host[:ecdsa_type]
  end
end
