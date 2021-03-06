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

hosts = [
  {
    hostname:     node['hostname'],
    fqdn:         node['fqdn'],
    machinename:  node['machinename'],
    ipaddress:    node['ipaddress'],
    # ohai uses node['keys'] which conficts with node#keys, but that is an ohai issue and will not be fixed
    # so foodcritic needs to ignore these.
    rsa:          node['keys'] && node['keys']['ssh'] && node['keys']['ssh']['host_rsa_public'],   # ~FC039
    dsa:          node['keys'] && node['keys']['ssh'] && node['keys']['ssh']['host_dsa_public'],   # ~FC039
    ecdsa:        node['keys'] && node['keys']['ssh'] && node['keys']['ssh']['host_ecdsa_public'], # ~FC039
    ecdsa_type:   node['keys'] && node['keys']['ssh'] && node['keys']['ssh']['host_ecdsa_type'],   # ~FC039
  },
]

res = Chef::Search::Query.new.search(
  :node,
  "keys_ssh:* NOT name:#{node.name}",
  filter_result: {
    'hostname'    => [ 'hostname' ],
    'fqdn'        => [ 'fqdn' ],
    'ipaddress'   => [ 'ipaddress' ],
    'machinename' => [ 'machinename' ],
    'rsa'         => %w(keys ssh host_rsa_public),
    'dsa'         => %w(keys ssh host_dsa_public),
    'ecdsa'       => %w(keys ssh host_ecdsa_public),
    'ecdsa_type'  => %w(keys ssh host_ecdsa_type),
  },
)

hosts += res[0].map { |host| Hash[host.map { |k, v| [k.to_sym, v] }] } # symbolize_keys

# Add the data from the data_bag to the list of nodes.
# We need to rescue in case the data_bag doesn't exist.
begin
  hosts += data_bag('ssh_known_hosts').map do |item|
    entry = data_bag_item('ssh_known_hosts', item)
    {
      fqdn:        entry['fqdn'],
      ipaddress:   entry['ipaddress'],
      hostname:    entry['hostname'],
      machinename: entry['machinename'],
      rsa:         entry['rsa'],
      dsa:         entry['dsa'],
      ecsda:       entry['ecsda'],
      ecdsa_type:  entry['ecdsa_type'],
    }
  end
rescue Net::HTTPServerException # seriously?  this is a terrible error
  Chef::Log.debug "Could not load data bag 'ssh_known_hosts'"
end

# Loop over the hosts and add 'em
hosts.each do |host|
  entry_name = [ host[:fqdn], host[:machinename], host[:hostname], host[:ipaddress] ].compact.join(",")
  sk_ssh_known_hosts_entry entry_name do
    rsa host[:rsa]
    dsa host[:dsa]
    ecdsa host[:ecdsa]
    ecdsa_type host[:ecdsa_type]
  end
end
