define :sk_ssh_known_hosts_entry do
  host       = params[:host] || params[:name]
  rsa        = params[:rsa]
  dsa        = params[:dsa]
  ecdsa      = params[:ecdsa]
  ecdsa_type = params[:ecdsa_type]

  # key  = params[:key]
  # port = params[:port]

  # key ||= `ssh-keyscan -H -p #{port} #{host} 2>&1`
  #
  # Chef::Application.fatal! "Could not resolve #{host}" if key =~ /getaddrinfo/

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

  t.variables[:entries].push(
                               host: host,
                               type: "ssh-rsa",
                               key:  rsa,
  ) if rsa

  t.variables[:entries].push(
                               host: host,
                               type: "ssh-dss",
                               key:  dsa,
  ) if dsa

  t.variables[:entries].push(
                               host: host,
                               type: ecdsa_type,
                               key:  ecdsa,
  ) if ecdsa && ecdsa_type
end
