require 'aws-sdk-cloudwatchlogs'

client = Aws::CloudWatchLogs::Client.new

pager_token = nil
fetched_count = 0
log_groups_never_expired = []

loop do
  resp = client.describe_log_groups(
    limit: 50,
    next_token: pager_token
  )

  log_groups = resp.log_groups
  fetched_count += log_groups.size
  p "pager_token: #{pager_token}"
  p "fetched_count: #{fetched_count}"

  a = log_groups.filter { |log_group| log_group.retention_in_days == nil }
                .map do |log_group|
    {
      name: log_group.log_group_name,
      stored_volume_in_gigabytes: log_group.stored_bytes / 1000000000,
      retention: log_group.retention_in_days
    }
  end

  if a.size.positive?
    p resp
    p a
    log_groups_never_expired += a
  end

  pager_token = resp.next_token
  sleep 0.2

  break if pager_token.nil?
end

p "log_groups_never_expired.size: #{log_groups_never_expired.size}"
p log_groups_never_expired.sort_by { |element| element[:stored_volume_in_gigabytes] }.reverse

log_groups_never_expired.each do|log_group|
  put_resp = client.put_retention_policy(log_group_name: log_group[:name], retention_in_days: 1827) # 5 years
  p put_resp.successful?
  sleep 0.1
end
