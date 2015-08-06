#!/usr/bin/env ruby
##
#$LOAD_PATH.unshift(File.dirname(__FILE__)) unless $LOAD_PATH.include?(File.dirname(__FILE__)) 
require 'rubydns'
require_relative 'myresolver'

INTERFACES = [
    [:udp, "0.0.0.0", 5300],
    [:tcp, "0.0.0.0", 5300]
]
Name = Resolv::DNS::Name
IN = Resolv::DNS::Resource::IN

# Use upstream DNS for name resolution.
#mainland = RubyDNS::Resolver.new([ [:udp, "192.168.2.1", 53]])
#oversea = RubyDNS::Resolver.new([ [:tcp, "8.8.8.8", 53]])
#myresolver = MyResolver.new([[:udp, "192.168.2.1", 53],[:tcp, "106.185.41.36", 53]])
#myresolver = MyResolver.new([[:udp, "192.168.2.1", 53]])
#oversea_resolver = MyResolver.new([:q:[:tcp, "8.8.8.8", 53],[:tcp, "151.236.20.236", 53],[:tcp, "106.185.41.36", 53]])
oversea_resolver = MyResolver.new([[:tcp, "127.0.0.1", 5533]])

# Start the RubyDNS server
RubyDNS::run_server(:listen => INTERFACES) do
    match(/test\.mydomain\.org/, IN::A) do |transaction|
        transaction.respond!("10.0.0.80")
    end

    # Default DNS handler
    otherwise do |transaction|
        transaction.passthrough!(oversea_resolver)
        #res2 = transaction.passthrough!(oversea)

        # puts res1.class
        # puts res2

        # res1 

    end
end
