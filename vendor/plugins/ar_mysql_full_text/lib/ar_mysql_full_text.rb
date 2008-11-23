# ArMysqlFullText
module ActiveRecord
  class SchemaDumper #:nodoc:
      # modifies index support for MySQL full text indexes
      def indexes(table, stream)
        indexes = @connection.indexes(table)
        indexes.each do |index|
          if index.name=~/FullText_/ and @connection.is_a?(ActiveRecord::ConnectionAdapters::MysqlAdapter)
            stream.puts <<RUBY
  execute "ALTER TABLE #{index.table} ENGINE = MyISAM"
  execute "CREATE FULLTEXT INDEX #{index.name} ON #{index.table} (#{index.columns.join(',')})"
RUBY
          else
            stream.print "  add_index #{index.table.inspect}, #{index.columns.inspect}, :name => #{index.name.inspect}"
            stream.print ", :unique => true" if index.unique
            stream.puts
          end
        end
        stream.puts unless indexes.empty?
      end
  end
end
