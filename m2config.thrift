namespace * M2

enum TargetType {
  DIRECTORY = 1,
  PROXY = 2,
  HANDLER = 3,
}

struct Host {
  1: optional i32 id,
  2: optional i32 server_id, # defaults to 1
  3: optional bool maintenance, # defaults to false
  4: optional string name, # defaults to matching field value
  5: required string matching,
}

struct Route {
  1: optional i32 id,
  2: required string path,
  3: optional bool reversed, # defaults to false
  4: required i32 host_id,
  5: required i32 target_id,
  6: required TargetType target_type,
  7: optional map<string, string> additional_fields, # Mongrel2 config db extensions
}

service Config {
  /**
    Returns the ID of an existing host, or adds it if it doesn't exist yet.
    
    @returns Internal ID of the host.
  */
  i32 find_or_add_host(1: required Host host);
  
  /**
    Removes the specified host, does nothing if host doesn't exist.
  */
  void remove_host(1: required i32 host_id);
  
  /**
    Returns the ID of an existing route, or adds it if it doesn't exist yet.
    
    @returns Internal ID of the route.
  */
  i32 find_or_add_route(1: required Route route);
  
  /**
    Removes the specified route, does nothing if route doesn't exist.
  */
  void remove_route(1: required i32 route_id);
}