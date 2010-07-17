require 'yaml'


module PomPomPom
  class Config
    REPOSITORIES = %w(http://repo1.maven.org/maven2)
    TARGET_DIR = 'lib'
    CACHE_DIR = File.expand_path('~/.pompompom')
    CONFIG_FILE = File.expand_path('~/.pompompomrc')
    
    attr_reader :repositories, :target_dir, :cache_dir, :config_file
    
    def initialize(options={})
      @repositories = options[:repositories] || REPOSITORIES
      @target_dir   = options[:target_dir]   || TARGET_DIR
      @cache_dir    = options[:cache_dir]    || CACHE_DIR
      @config_file  = options[:config_file]  || CONFIG_FILE
    end
    
    def load!
      return unless file_exists?
      options = symbolize_keys(YAML.load(File.read(@config_file)))
      @repositories = options[:repositories] || @repositories
      @target_dir   = options[:target_dir]   || @target_dir
      @cache_dir    = options[:cache_dir]    || @cache_dir
      @config_file  = options[:config_file]  || @config_file
    end
    
    def file_exists?
      File.exists?(@config_file)
    end
    
    def create_file!
      return if file_exists?
      File.open(@config_file, 'w') do |f| 
        f.write(YAML.dump('repositories' => @repositories))
      end
    end
    
    def symbolize_keys(h)
      h.keys.inject({}) do |acc, k|
        acc[k.to_sym] = if Hash === h[k] then symbolize_keys(h[k]) else h[k] end
        acc
      end
    end
  end
end