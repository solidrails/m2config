require 'sqlite3'

module M2
  module Config
    class Handler
      def initialize(db_path)
        @db = SQLite3::Database.new(db_path)
        @db.results_as_hash = true
      end
      
      def find_or_add_host(host)
        @db_host_find ||= @db.prepare("SELECT id FROM host WHERE id = ? OR matching = ?")
        rows = @db_host_find.execute!(host.id, host.matching)
        return rows[0][0].to_i if rows[0] && rows[0][0]
        
        host.server_id = 1 unless host.server_id
        host.maintenance = false unless host.maintenance
        host.name = host.matching unless host.name
        host.validate
        
        @db_host_insert ||= @db.prepare("INSERT INTO host (server_id, maintenance, name, matching) VALUES (?, ?, ?, ?)")
        @db_host_insert.execute(host.server_id, host.maintenance ? 1 : 0, host.name, host.matching)
        @db.last_insert_row_id
      end
      
      def remove_host(host_id)
        @db_host_delete ||= @db.prepare("DELETE FROM host WHERE id = ?")
        @db_host_delete.execute(host_id)
      end
      
      def find_routes_for_host(host_id)
        @db_host_routes ||= @db.prepare("SELECT * FROM route WHERE host_id = ?")
        rows = @db_host_routes.execute(host_id)
        routes = []
        rows.each do |row|
          route = M2::Route.new :id => row.delete('id'), :path => row.delete('path'), :reversed => row.delete('reversed') == 1,
                                :host_id => row.delete('host_id'), :target_id => row.delete('target_id'),
                                :target_type => constantize("M2::TargetType::" + row.delete('target_type').upcase)
          row.reject! {|k,v| k.class == Fixnum || v.nil? }
          route.additional_fields = row unless row.empty?
          routes << route
        end
        return routes
      end
      
      def find_or_add_route(route)
        @db_route_find ||= @db.prepare("SELECT id FROM route WHERE id = ? OR (host_id = ? AND path = ?)")
        rows = @db_route_find.execute!(route.id, route.host_id, route.path)
        return rows[0][0].to_i if rows[0] && rows[0][0]
        
        route.reversed = false unless route.reversed
        route.validate
        
        fields = {:path => route.path, :reversed => (route.reversed ? 1 : 0), :host_id => route.host_id, :target_id => route.target_id,
                  :target_type => M2::TargetType::VALUE_MAP[route.target_type].downcase}
        fields = route.additional_fields.merge(fields) if route.additional_fields
        @db.execute('INSERT INTO route (%s) VALUES (%s)' % [fields.keys.join(', '), (['?'] * fields.values.size).join(', ')], fields.values)
        @db.last_insert_row_id
      end
      
      def remove_route(route_id)
        @db_route_delete ||= @db.prepare("DELETE FROM route WHERE id = ?")
        @db_route_delete.execute(route_id)
      end
      
    protected
      # Mostly copied from Rails ActiveSupport 3.0.3, commit 05da7528474f0ff42ddb
      # https://github.com/rails/rails/blob/3-0-stable/activesupport/lib/active_support/inflector/methods.rb
      def constantize(camel_cased_word) #:nodoc:
        names = camel_cased_word.split('::')
        names.shift if names.empty? || names.first.empty?
        
        constant = Object
        names.each do |name|
          if Module.method(:const_get).arity == 1 # Ruby 1.8
            constant = constant.const_defined?(name) ? constant.const_get(name) : constant.const_missing(name)
          else # Ruby 1.9
            constant = constant.const_defined?(name, false) ? constant.const_get(name) : constant.const_missing(name)
          end
        end
        constant
      end
    end
  end
end
