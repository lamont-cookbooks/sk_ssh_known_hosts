define :sk_ssh_known_hosts_entry do
  host = params[:host] || params[:name]
  key  = params[:key]
  port = params[:port]

  key ||= `ssh-keyscan -H -p #{port} #{host} 2>&1`

  Chef::Application.fatal! "Could not resolve #{host}" if key =~ /getaddrinfo/

  t = begin
        resources(template: "ssh_known_hosts_template_file")
      rescue Chef::Exceptions::ResourceNotFound
        template "ssh_known_hosts_template_file" do
          path node['sk_ssh_known_hosts']['file']
          source "ssh_known_hosts.erb"
          cookbook "sk_ssh_known_hosts"
          variables(
            entries: [],
          )
        end
      end

  t.variables[:entries].push(key)
end
