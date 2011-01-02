require 'sqlite3'

module M2
  module Config
    class Handler
      def initialize(db_path)
        @db = SQLite3::Database.new(db_path)
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
    end
  end
end
