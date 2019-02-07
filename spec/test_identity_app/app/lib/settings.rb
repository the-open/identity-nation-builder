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
      "site_slug" => ENV['NATION_BUILDER_SITE_SLUG'],
      "site" => ENV['NATION_BUILDER_SITE'],
      "token" => ENV['NATION_BUILDER_TOKEN'],
      "debug" => ENV['NATION_BUILDER_DEBUG'],
      "author_id" => ENV['NATION_BUILDER_AUTHOR_ID'],
      "push_batch_amount" => nil,
      "pull_batch_amount" => nil,
    }
  end

  def self.options
  end
end
