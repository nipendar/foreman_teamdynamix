desc <<-DESC.strip_heredoc.squish
  Scans existing hosts and creates or updates the asset in TeamDynamix.
    * If found, update the fields in the TeamDynamix asset.
    * If not found, create a TeamDynamix asset with desired fields.
    * If host does not have a teamdynamix_asset_id or it is deleted via backend, it creates a new asset.

  It could be run for all the hosts as:
    * rake hosts:sync_with_teamdynamix

  Or for specific hosts as (No space b/w hostnames):
    * rake hosts:sync_with_teamdynamix[hostname1,hostname2,..,hostnameX]
DESC
namespace :hosts do
  task :sync_with_teamdynamix => :environment do |_task|
    @td_api = TeamdynamixApi.instance
    @errors = []
    @hosts_synced = []

    sync_existing_assets_to_hosts

    create_assets_for_unmapped_hosts

    print_summary
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def sync_existing_assets_to_hosts
    # sending empty search param to get all the assets in TD at once
    # Note: due to a limitation(possibly a bug) in TD search asset api
    #       each and every search payload returns all the assets.
    @teamdynamix_assets = @td_api.search_asset({})

    @teamdynamix_assets.each do |asset|
      asset_id = asset['ID']
      # WHEN Asset is already mapped to a host
      # THEN update the asset in TD as per current configuration
      host = Host.find_by(teamdynamix_asset_id: asset_id)
      if host.present?
        @hosts_synced << host.id
        @td_api.update_asset(host)
        next
      end
      hosts = Host.where('name IN (?)', [asset['Name'], asset['SerialNumber']])
      # WHEN Asset does not have a matching host, THEN Do nothing
      next if hosts.blank?
      # WHEN Asset has more than one  matching host, THEN report error
      if hosts.count > 1
        @errors << "#{hosts.count} matching hosts found for asset with ID #{asset['ID']}"
        next
      end
      # WHEN Asset has a uniquely matching host which is not yet synced
      # THEN update the host with the asset ID
      # AND update the asset in TD as per current configuration
      host = hosts.first
      @hosts_synced << host.id
      host.teamdynamix_asset_id = asset_id
      @errors << "failed to update host ##{host.id} for asset ID ##{asset_id}" unless host.save
      @td_api.update_asset(host)
    end
  rescue StandardError => e
    @errors << "component: syncing_assets_to_hosts, asset_id: #{asset['ID']},
                asset_name: #{asset['Name']}, Error: #{e.message}"
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  # sync hosts that do not have assets created in Teamdynamix
  def create_assets_for_unmapped_hosts
    @hosts = Host.all
    unmapped_hosts = @hosts.reject { |host| @hosts_synced.include?(host.id) }
    unmapped_hosts.each do |host|
      @td_api.create_aset(host)
    end
  rescue StandardError => e
    @errors << "component: creating_new_assets, host: #{host.id}, hostname: #{host.name}, Error: #{e.message}"
  end

  def print_summary
    puts "\n Summary:"
    puts "\t Total Assets in TD: #{@teamdynamix_assets.count}"
    puts "\t Total Hosts: #{@hosts.count} \n\t Hosts Synced: #{@hosts_synced.uniq.count}"
    return if @errors.blank?
    puts "\n\n Errors: #{@errors.count}"
    @errors.each do |error|
      puts "\t#{error}"
    end
  end
end
