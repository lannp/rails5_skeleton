if ENV["LOCAL_DEPLOY"]
  server "localhost", user: "deploy", roles: %w(app db)
else
  instances = fetch(:instances)

  instances.each_with_index do |(role_name, hosts), i|
    roles = [role_name]
    roles << "db" if i == 0
    hosts.each do |host|
      server host, user: "deploy", roles: roles
    end
  end
end
