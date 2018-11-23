# This patch allows accessing the settings hash with dot notation
class Hash
  def method_missing(method, *opts)
    m = method.to_s
    return self[m] if key?(m)
    super
  end
end

class Settings
  def self.nation_builder
    return {
      "database_url" => ENV['NATION_BUILDER_DATABASE_URL'],
      "read_only_database_url" => ENV['NATION_BUILDER_DATABASE_URL'],
      "api" => {
        "url" => ENV['NATION_BUILDER_API_URL'],
        "secret" => ENV['NATION_BUILDER_API_SECRET']
      },
      "sync_batch_size" => 1000,
      "opt_out_subscription_id" => 4
    }
  end

  def self.kooragang
    return {
      "opt_out_subscription_id" => 3
    }
  end

  def self.options
    return {
      "use_redshift" => true,
      "default_phone_country_code" => '61'
    }
  end

  def self.databases
    return {
      "zip_schema" => false,
      "zip_primary_key" => false
    }
  end

  def self.geography
    return {
      "postcode_dash" => false
    }
  end
end
