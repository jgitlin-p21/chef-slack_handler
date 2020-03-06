
# Description

A cookbook for configures a Chef handler that sends reports and exceptions to Slack.  There are two options for use:

1. Providing a team name and api_key (Uses the [slackr gem](https://rubygems.org/gems/slackr))
2. Providing a hash containing incoming webhook url(s)

NOTE: If both methods are configured, webhooks will take precedence.

* v1.0.0 of this cookbook requires chef-client 14+, users of older chef clients should pin to previous version ~>0.9.2

This cookbook was originally a fork of [dcm-ops/chef-slack_handler](https://github.com/dcm-ops/chef-slack_handler) by [Dan Ryan](dan.ryan@enstratius.com). We have taken over maintenance of this cookbook and released it to Supermarket.

# Requirements

* An existing Slack incoming webhook(s)

# Usage 1

1. Create a new Slack webhook ([https://slack.com/services/new/incoming-webhook](https://slack.com/services/new/incoming-webhook))
2. Set the `team` and `api_key` attributes above on the node/environment/etc.
3. Include this `slack_handler` recipe.

## Usage 1 Attributes

* `node['chef_client']['handler']['slack']['team']` - Your Slack team name (<team-name>.slack.com)
* `node['chef_client']['handler']['slack']['api_key']` - The API key of your Slack incoming webhook
* `node['chef_client']['handler']['slack']['channel']` - The #channel to send the results, should include the hash

### Optional attributes

* `node['chef_client']['handler']['slack']['username']` - The username of the Slack message, defaults to the node name
* `node['chef_client']['handler']['slack']['icon_url']` - The Slack message icon, defaults to nil
* `node['chef_client']['handler']['slack']['icon_emoji']` - The Slack message icon defined by available `:emoji:`, defaults to nil
* `node['chef_client']['handler']['slack']['timeout']` - Timeout in seconds for the Slack API call, defaults to 15
* `node['chef_client']['handler']['slack']['fail_only']` - Only report when runs fail as opposed to every single occurrence, defaults to false
* `node['chef_client']['handler']['slack']['send_start_message']` - Send a message when the run starts, defaults to false
* `node['chef_client']['handler']['slack']['message_detail_level']` - The level of detail in the message. Valid options are `basic`, `elapsed` and `resources`, defaults to `basic`
* `node['chef_client']['handler']['slack']['cookbook_detail_level']` - The level of detail about the cookbook used in the message. Valid options are `off` and `all`, defaults to `off`
* `node['chef_client']['handler']['slack']['send_environment']` - Send the `node.chef_environment`, defaults to false
* `node['chef_client']['handler']['slack']['send_organization']` - Send the `organization from /etc/chef/client.rb`, defaults to false

NOTE: If both `icon_url` and `icon_emoji` are set, `icon_url` will take precedence.

# Usage 2

1. Create a new Slack webhook ([https://slack.com/services/new/incoming-webhook](https://slack.com/services/new/incoming-webhook))
2. Set the attributes as specified below
3. Include this `slack_handler` recipe.

## Usage 2 Attributes

Push as many webhooks as you wish onto the node config:

```
# Add `webhook1` URL
node['chef_client']['handler']['slack']['webhooks']['name'].push('webhook1')
node['chef_client']['handler']['slack']['webhooks']['webhook1']['url'] = 'https://hooks.slack.com/1/2/3'

# Add `webhook2` URL
node['chef_client']['handler']['slack']['webhooks']['name'].push('webhook2')
node['chef_client']['handler']['slack']['webhooks']['webhook2']['url'] = 'https://hooks.slack.com/1/2/4'
```

### Optional attributes

Global to all webhooks:

```
# Timeout in seconds for the Slack API call, defaults to 15
node['chef_client']['handler']['slack']['timeout'] = 30

## Customizations for Slack WebHook config
## See https://api.slack.com/incoming-webhooks#customizations_for_custom_integrations
# The username of the Slack message, defaults to Slack WebHook config (i.e. nil)
node['chef_client']['handler']['slack']['username'] = 'Chef Bot'
# Icon URL, defaults to Slack WebHook config (i.e. nil)
node['chef_client']['handler']['slack']['icon_url'] = 'https://avatars1.githubusercontent.com/u/29740'
# Emoji for the Slack call, defaults to Slack WebHook config (i.e. nil)
node['chef_client']['handler']['slack']['icon_emoji'] = ':fork_and_knife:'

# Only report when runs fail as opposed to every single occurrence, defaults to false
node['chef_client']['handler']['slack']['fail_only'] = true
# Send a message when the run starts, defaults to false
node['chef_client']['handler']['slack']['send_start_message'] = true
# The level of detail in the message. Valid options are 'basic', 'elapsed' and 'resources', defaults to 'basic'
node['chef_client']['handler']['slack']['message_detail_level'] = 'resources'
# The level of detail about the cookbook used in the message. Valid options are 'off' and 'all', defaults to 'off'
node['chef_client']['handler']['slack']['cookbook_detail_level'] = 'all'
# Send the node.chef_environment, defaults to false
node['chef_client']['handler']['slack']['send_environment'] = true
# Send the organization from /etc/chef/client.rb, defaults to false
node['chef_client']['handler']['slack']['send_organization'] = true
```

NOTE: If both `icon_url` and `icon_emoji` are set, `icon_url` will take precedence.

Each webhook may also override the `fail_only`, `message_detail_level` and `cookbook_detail_level` global optional attributes:

```
# Optional attributes for `webhook1`
node['chef_client']['handler']['slack']['webhooks']['webhook1']['fail_only'] = true
node['chef_client']['handler']['slack']['webhooks']['webhook1']['send_start_message'] = true
node['chef_client']['handler']['slack']['webhooks']['webhook1']['message_detail_level'] = 'elapsed'
node['chef_client']['handler']['slack']['webhooks']['webhook1']['cookbook_detail_level'] = 'all'
node['chef_client']['handler']['slack']['webhooks']['webhook1']['send_environment'] = true
node['chef_client']['handler']['slack']['webhooks']['webhook1']['send_organization'] = true
```

# Pinnacle 21 Fork

Extending beyond the original, `chef-slack_handler` can also publish custom messages from your recipe's resources to chef.
 Simply extend any resource and define a `message` method on the resource instance, and if the resource runs the message
 will be posted to Slack. Usage example:

```
template '/etc/cron.d/some_job' do
  source 'something.erb'
  @message = " - *enabled* some cron job on `#{node.name}`"
  singleton_class.class_eval { attr_reader 'message' }
end

# Check if updates are needed and update Node attributes
ruby_block 'report on something' do
  block do
    @data = gather_some_data_or_whatever
    def self.message
      @data
    end
  end
end

```

The Slack message would then comtain 

> " - *enabled* some cron job on `#{node.name}`"

As well as whatever string `gather_some_data_or_whatever` method returned. (Implementation of that method left up to the reader)

# Credits

Borrowed everything from the `logstash_handler` cookbook [here](https://github.com/lusis/logstash_handler), who in turn borrowed quite a bit from the `graphite_handler` cookbook [here](https://github.com/realityforge-cookbooks/graphite_handler).

Forked from Rackspace Hosting's version to add some new features 

# License

`slack_handler` is provided under the Apache License 2.0. See `LICENSE` for details.
