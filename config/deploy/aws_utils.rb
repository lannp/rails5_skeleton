require "yaml"
require "aws-sdk"

def get_ec2_targets
  init_data
  targets = {}
  @instance_name_tags.each do |role_name, tag_name|
    targets[role_name] = @ec2.describe_instances(filters:[{ name: "tag:Name", values: [tag_name] }]).reservations
      .map(&:instances).flatten.compact.map(&:private_ip_address)
  end
  targets
end

def update_ec2_tags ref_type, ref_name, last_commit
  init_data
  @ec2.describe_instances(filters:[{ name: "tag:Name", values: @instance_name_tags.values }]).reservations
    .map(&:instances).flatten.compact.each do |instance|
      @ec2.create_tags({
        resources: [instance.instance_id],
        tags: [
          {key: "#{ref_type}", value: ref_name},
          {key: "LastCommit", value: last_commit},
        ]
      })
      puts <<-EOM
An EC2 instance #{instance.private_ip_address} has been tagged as follows:
- #{ref_type}: #{ref_name}
- LastCommit: #{last_commit}
EOM
    end
end

private
def init_data
  deploying_roles = ENV["DEPLOYING_ROLES"].split(",")
  @instance_name_tags ||= YAML
    .load_file(ENV["SETTING_FILE"] || "config/deploy/settings.yml")["instance_name_tags"][ENV["RAILS_ENV"]]
    .select { |role_name, _| deploying_roles.include? role_name }
  @ec2 ||= Aws::EC2::Client.new(region: ENV["AWS_REGION"])
end
