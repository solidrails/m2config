# Description

Thrift interface for Mongrel2 configuration database.

# Example

Server:
    $ m2configsrv /srv/m2/config.sqlite

Client:
    $ irb
    >> require 'm2config'
    >> m2 = M2::remote_call
    >> m2.find_or_add_host M2::Host.new(:matching => 'fittl.com')

# License

m2config is licensed under the MIT license, see LICENSE file.