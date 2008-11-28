require 'ostruct'

class Conf < OpenStruct
end

class SetupController < ApplicationController
  skip_before_filter :check_for_setup # because we're already here
  before_filter :check_for_config_files, :except => [:finished, :error]

  def index
    @conf = Conf.new(YAML::load_file("#{RAILS_ROOT}/config/config.yml.example"))
  end

  def set_config
    @conf = params[:conf].to_hash
    @conf.each do |k,v| 
      @conf[k] = true if v == "true"; 
      @conf[k] = false if v == "false";
    end
    @conf['domain_with_port'] = @conf['domain']
    @conf['domain'] = @conf['domain'].split(":").first
    @original_conf = YAML::load_file("#{RAILS_ROOT}/config/config.yml.example")
    @conf.reverse_merge!(@original_conf)
    File.open("#{RAILS_ROOT}/config/config.yml", "w") do |f|
      f.write(YAML::dump(@conf))
    end
    
    if config_exists?
      redirect_to :controller => 'setup', :action => 'database'
    else
      flash[:notice] = "There was a problem writing the config file.  Maybe you don't have permission? "
      redirect_to :action => 'index'
    end
  end

  def database
    # Add some extra paths to search through
    %w{/usr/local/bin /opt/local/bin /opt/local/lib/mysql5/bin}.each do |path|
      ENV['PATH'] += ":#{path}" if File.exist?(path)
    end
    @has_sqlite = !(`which sqlite`.blank?) || !(`which sqlite3`.blank?) rescue false
    @has_mysql = (!`which mysql_config`.blank?) || (!`which mysql_config5`.blank?) rescue false
  end

  def set_database
    @db = { RAILS_ENV => params[:db].to_hash }

    File.open("#{RAILS_ROOT}/config/database.yml", "w") do |f|
      f.write(YAML::dump(@db))
    end
    
    if !db_config_exists?
      flash[:notice] = "There was a problem writing the config file.  Maybe you don't have permission? "
      redirect_to root_url
      return
    end

    # `cd #{RAILS_ROOT} && export RAILS_ENV=#{RAILS_ENV} && rake db:create`
    # `cd #{RAILS_ROOT} && export RAILS_ENV=#{RAILS_ENV} && rake db:migrate`
    create_database(params[:db].to_hash) rescue nil
    migrate_database(params[:db].to_hash)
    dump_schema

    redirect_to :action => 'finished'
  end

  def finished
  end

  def error
  end
 
  protected
    def check_for_config_files
      if config_exists? && db_config_exists?
        flash[:notice] = "Everything seems to be set up.  All of the needed config files have been created in <i>config/</i>."
        redirect_to :action => 'error'
        return true
      end
      if config_exists?
        redirect_to(:action => 'database') if %w(index set_config).include? params[:action]
        return true
      end
      if db_config_exists?
        redirect_to(:action => 'index') if %w(database set_database).include? params[:action]
        return true
      end
    end
  
    def config_exists?
      File.exist?("#{RAILS_ROOT}/config/config.yml")
    end

    def db_config_exists?
      File.exist?("#{RAILS_ROOT}/config/database.yml")
    end

    def dump_schema
      require 'active_record/schema_dumper'
      File.open("#{RAILS_ROOT}/db/schema.rb", "w") do |file|
        ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
      end
    end

    def migrate_database(config)
      ActiveRecord::Base.logger = Logger.new("/dev/null")
      ActiveRecord::Base.configurations[RAILS_ENV] = config
      ActiveRecord::Migrator.migrate("#{RAILS_ROOT}/db/migrate/", nil)
    end 

    def create_database(config)
      require 'sqlite3'
      require 'active_record' # weird, yes
      begin
        if config['adapter'] =~ /sqlite/
          if File.exist?(config['database'])
            raise StandardError, "database already exists"
          else
            begin
              # Create the SQLite database
              ActiveRecord::Base.establish_connection(config)
              ActiveRecord::Base.connection
            rescue
              $stderr.puts $!, *($!.backtrace)
              raise StandardError, "Could not create the database.  Maybe you don't have permission? "
            end
          end
          return # Skip the else clause of begin/rescue    
        else
          ActiveRecord::Base.establish_connection(config)
          ActiveRecord::Base.connection
        end
      rescue
        case config['adapter']
        when 'mysql'
          @charset   = ENV['CHARSET']   || 'utf8'
          @collation = ENV['COLLATION'] || 'utf8_general_ci'
          begin
            ActiveRecord::Base.establish_connection(config.merge('database' => nil))
            ActiveRecord::Base.connection.create_database(config['database'], :charset => (config['charset'] || @charset), :collation => (config['collation'] || @collation))
            ActiveRecord::Base.establish_connection(config)
          rescue
            $stderr.puts "Couldn't create database for #{config.inspect}, charset: #{config['charset'] || @charset}, collation: #{config['collation'] || @collation} (if you set the charset manually, make sure you have a matching collation)"
          end
        when 'postgresql'
          @encoding = config[:encoding] || ENV['CHARSET'] || 'utf8'
          begin
            ActiveRecord::Base.establish_connection(config.merge('database' => 'postgres', 'schema_search_path' => 'public'))
            ActiveRecord::Base.connection.create_database(config['database'], config.merge('encoding' => @encoding))
            ActiveRecord::Base.establish_connection(config)
          rescue
            $stderr.puts $!, *($!.backtrace)
            $stderr.puts "Couldn't create database for #{config.inspect}"
          end
        end
      else
        $stderr.puts "#{config['database']} already exists"
      end
    end
end
