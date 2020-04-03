class SlackHandlerUtil
  def initialize(default_config, run_status)
    @default_config = default_config
    @run_status = run_status
  end

  def start_message(context = {})
    "Chef run started on #{node_details(context)}" \
    "#{run_status_cookbook_detail(context)}"
  end

  def end_message(context = {})
    "Chef run #{run_status_human_readable} on #{node_details(context)}" \
    "#{run_status_cookbook_detail(context)}#{run_status_message_detail(context)}"
  end

  def fail_only(context = {})
    return context['fail_only'] unless context['fail_only'].nil?
    @default_config[:fail_only]
  end

  def only_if_messages(context = {})
    return context['only_if_messages'] unless context['only_if_messages'].nil?
    @default_config[:only_if_messages]
  end

  def no_messages?
    resources_with_messages.count == 0
  end

  def send_on_start(context = {})
    return context['send_start_message'] unless context['send_start_message'].nil?
    @default_config[:send_start_message]
  end

  private

  def node
    @run_status.node
  end

  def run_status_human_readable
    @run_status.success? ? 'succeeded' : 'failed'
  end

  def node_details(context = {})
    "#{organization_details(context)}#{environment_details(context)}node #{node.name}"
  end

  def environment_details(context = {})
    return "env #{node.chef_environment}, " if context['send_environment'] || @default_config[:send_environment]
  end

  def organization_details(context = {})
    organization = File.file?('/etc/chef/client.rb') ? File.open('/etc/chef/client.rb').read.match(%r{(?<=\/organizations\/)(\w+-?\w+)}) : "Organization not found in client.rb"
    return "org #{organization}, " if context['send_organization'] || @default_config[:send_organization]
  end

  def run_status_cookbook_detail(context = {})
    case context['cookbook_detail_level'] || @default_config[:cookbook_detail_level]
    when "all"
      cookbooks = if Chef.respond_to?(:run_context)
                    Chef.run_context.cookbook_collection
                  else
                    run_context.cookbook_collection
                  end
      " using cookbooks #{cookbooks.values.map { |x| x.name.to_s + ' ' + x.version }}"
    end
  end

  def resources_with_messages
    @run_status.updated_resources.filter {|r| r.respond_to?(:message) && r.message }
  end

  def resource_messages
    resources_with_messages.map &:message
  end

  def run_status_message_detail(context = {})
    messages = ["\n"]
    updated_resources = @run_status.updated_resources
    begin
      messages += resource_messages
    rescue => err
      puts "Exception in slack_handler: #{err} #{err.full_message}"
    end
    elapsed_time = @run_status.elapsed_time.round
    messages <<
      case context['message_detail_level'] || @default_config[:message_detail_level]
      when "elapsed"
        "#{updated_resources.count} resources updated in #{elapsed_time} seconds." unless updated_resources.nil?
      when "resources"
        "#{updated_resources.count} resources updated in #{elapsed_time} seconds:\n#{updated_resources.join(', ')}" unless updated_resources.nil?
      end
    messages.join "\n"
  end
end
