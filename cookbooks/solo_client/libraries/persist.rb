#
#   Copyright 2013 Geodelic
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License. 
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
#
require 'rubygems'

begin
    require 'fog'
    FOGFOUND = true unless defined? FOGFOUND
rescue LoadError => e
    Chef::Log.warn("Fog library not found. This is fine in development environments, but it is required in production.")
    FOGFOUND = false unless defined? FOGFOUND
end

class RequirementError < RuntimeError
end


module Fog
  module AWS
    class SimpleDB
      class Real

        def _get_attributes(domain_name, item_name, attributes = {}, consistent_read = false)
          Chef::Log.debug "override being used! and consistent_read is #{consistent_read}."
          request({
            'Action'          => 'GetAttributes',
            'DomainName'      => domain_name,
            'ItemName'        => item_name,
            'ConsistentRead'  => consistent_read,
            :idempotent       => true,
            :parser           => Fog::Parsers::AWS::SimpleDB::GetAttributes.new(@nil_string)
          }.merge!(encode_attribute_names(attributes)))
        end

        def _select(select_expression, next_token = nil, consistent_read = false)
          Chef::Log.debug "override being used! and consistent_read is #{consistent_read}."
          request(
            'Action'            => 'Select',
            'NextToken'         => next_token,
            'SelectExpression'  => select_expression,
            'ConsistentRead'    => consistent_read,
            :idempotent         => true,
            :parser             => Fog::Parsers::AWS::SimpleDB::Select.new(@nil_string)
          )
        end

        def encode_attributes(attributes, replace_attributes = [], expected_attributes = {})
          encoded_attributes = {}
          if attributes

            expected_attributes.keys.each_with_index do |exkey, index|
              for value in Array(expected_attributes[exkey])
                encoded_attributes["Expected.#{index}.Name"] = exkey.to_s
                if ( value == false ) || ( value == true )
                    exptype = "Exists"
                else
                    exptype = "Value"
                    value = value.to_s unless value.nil?
                end
                encoded_attributes["Expected.#{index}.#{exptype}"] = value unless value.nil?
              end
            end

            index = 0
            for key in attributes.keys
                values = attributes[key]
                if not values.is_a? Array
                    values = [values]
                end
              for value in values
                encoded_attributes["Attribute.#{index}.Name"] = key.to_s
                if replace_attributes.include?(key)
                  encoded_attributes["Attribute.#{index}.Replace"] = 'true'
                end
                encoded_attributes["Attribute.#{index}.Value"] = value.to_s unless value.nil?
                index += 1
              end
            end
          end
          Chef::Log.debug "override encode_attributes being used! encoded_attributes: >#{encoded_attributes.inspect}<"
          encoded_attributes
        end

        def encode_attribute_names(attributes)
          Chef::Log.debug "override encode_attribute_names being used!"
          AWS.indexed_param('AttributeName', attributes.map {|attribute| attribute.to_s})
        end
      end
    end
  end
end


class ValueError < RuntimeError
end

class PersistError < RuntimeError
end


class PersistWrapper
    @@pbackend = nil
    @@deployment = nil

    def initialize(pbackend, deployment)
        if not FOGFOUND
            raise RequirementError, "Aborting: The fog library is missing!"
        end
        @@pbackend = pbackend
        @@deployment = deployment
    end

    def self.deployment
        @@deployment
    end

    def method_missing(method, *args, &block)
        @@pbackend.send(method, *args, &block)
    end

    def self.method_missing(method, *args, &block)
        @@pbackend.send(method, *args, &block)
    end
end

class FogSimpleDBWrapper
    def initialize(collection, node_name, ec2_region)
        if not FOGFOUND
            raise RequirementError, "Aborting: The fog library is missing!"
        end
        @@collection = collection
        @@node_name = node_name
        sdb_host = case ec2_region
          when 'ap-northeast-1'
            'sdb.ap-northeast-1.amazonaws.com'
          when 'ap-southeast-1'
            'sdb.ap-southeast-1.amazonaws.com'
          when 'eu-west-1'
            'sdb.eu-west-1.amazonaws.com'
          when 'us-east-1'
            'sdb.us-east-1.amazonaws.com'
          when 'us-west-1'
            'sdb.us-west-1.amazonaws.com'
          end
        fog = Fog::AWS::SimpleDB.new( get_creds() )
        @@sdb = FogRetryProxy.new(fog)
    end

    def put(attributes, options = {})
        _put(@@node_name, attributes, options)
    end
    def _put(item, attributes, options = {})
        if ( not attributes.is_a? Hash ) || ( attributes.length == 0 )
            raise ValueError, "Cannot store this: #{attributes.inspect}"
        end
        to_delete = {}
        to_store = {}
        attributes.each_pair do |key, val|
            if val.nil?
                to_delete[key] = val
            elsif val.is_a? Numeric
                Chef::Log.debug("#{key}'s value is Numeric: #{val}")
                to_store[key] = val
            elsif val.is_a? String
                to_store[key] = val
            elsif val.instance_of? PersistList
                to_store[key] = val
            else
                raise TypeError, "Cannot persist values that are not strings or numbers.\nWas given value >#{val.inspect}< of type #{val.class} for key #{key}"
            end
        end
        if to_delete.length > 0
            delete(to_delete)
        end
        if to_store.length > 0
            #TODO: add in retry logic
            response = @@sdb.put_attributes(@@collection, item, to_store, options)
            if response.status != 200
                raise PersistError, "Something went wrong during the db insert! Got response code #{response.status}. Response body: #{response.body}"
            end
        end
    end

    def get(attributes = [])
        _get(@@node_name, attributes)
    end
    def _get(item, attributes = [])
        #TODO: add in retry logic
        response = @@sdb._get_attributes(@@collection, item, attributes, true)
        if response.status != 200
            raise PersistError, "Something went wrong while querying simpledb! Got response code #{response.status}. Response body: #{response.body}"
        end
        return value_flatten(response.body['Attributes'])
    end

    def delete(attributes = {})
        _delete(@@node_name, attributes)
    end
    def _delete(item, attributes = {})
        #TODO: add in retry logic
        Chef::Log.debug("In FogSimpleDBWrapper, told to delete >#{attributes.inspect}<.")
        response = @@sdb.delete_attributes(@@collection, item, attributes)
        if response.status != 200
            raise PersistError, "Something went wrong while deleting attributes from simpledb! Got response code #{response.status}. Response body: #{response.body}"
        end
    end

    def value_flatten(hsh)
        return Mash[hsh.map {|k,v| [k, (( v[0] unless v.length > 1 ) || PersistList.new(v, k) )]}]
    end

    def search(comparison_expression, attributes = nil, next_token = nil)
        if not @@sdb
            raise PersistError, "SDBWrapper was never initialized! The class must be initialized at least once before this method can be used!"
        end
        if not attributes
            attributes = "*"
        elsif attributes.is_a? Array
            attributes = attributes.join(',')
        end
        q = "select #{attributes} from #{@@collection}"
        if comparison_expression and comparison_expression != ''
            q << " where #{comparison_expression}"
        end
        Chef::Log.debug("Querying simpledb with >#{q}<")
        #TODO: add in retry logic
        response = @@sdb._select(q, next_token, true)
        if response.status != 200
            raise PersistError, "Something went wrong while querying simpledb! Got response code #{response.status}. Response body: #{response.body}"
        end
        Chef::Log.debug("Query found #{response.body['Items'].length} results")
        if attributes.strip == "count(*)"
            return response.body['Items']['Domain']['Count'][0].to_i
        end
        return response.body['Items'].values.map { |result| value_flatten(result) }
    end
end

class BasicObject
  instance_methods.each do |m|
    undef_method(m) if m.to_s !~ /(?:^__|^nil\?$|^send$|^object_id$|^instance_eval$|^instance_of\?$)/
  end
end

class PersistList < BasicObject
    @@_modifies = [:<<, :[]=, :clear, :collect!, :map!, :compact!, :concat, :delete, :delete_at, :delete_if, :fill, :flatten!, :insert, :pop, :push, :reject!, :replace, :shift, :slice!, :uniq!, :unshift]
    def initialize(wrap, key)
        @_wrapped = wrap
        @_key = key
    end
    def method_missing(method, *args, &block)
        if @@_modifies.include? method.to_sym
            Chef::Log.debug("A method that could potentially modify the wrapped list is being called.")
            h = @_wrapped.hash
            modify_watch = true
        else
            modify_watch = false
        end
        r = @_wrapped.send(method, *args, &block)
        if modify_watch && h != @_wrapped.hash
            Chef::Log.debug("Wrapped list has changed - trying to persist.")
            PersistWrapper.put({@_key => self}, {:replace => [@_key]})
        end
        return r
    end
end

class FogRetryProxy < BasicObject
    MAX_HTTP_RETRY = 20
    def initialize(wrap)
        @_wrapped = wrap
    end
    def method_missing(method, *args, &block)
        attempts = 1
        loop do
            begin
                return @_wrapped.send(method, *args, &block)
                #r = @_wrapped.send(method, *args, &block)
                #break
            rescue Excon::Errors::InternalServerError => e
            rescue Excon::Errors::ServiceUnavailable => e
            end
            Chef::Log.warn("Error info:\ntype: #{e.class}\nerror msg: #{e}\ntraceback:\n#{e.backtrace.join("\n")}")
            if attempts >= MAX_HTTP_RETRY
                raise PersistError, "failed to perform aws operation after #{MAX_HTTP_RETRY} attempts! bailing out!"
            end
            Chef::Log.warn("Got an error while connecting to aws. Going to wait and try again.")
            sleep (1.0+0.2*attempts.to_f)
            attempts += 1
        end
        #return r
    end
end

class PersistentMash < Mash
    alias _update update
    alias _merge! merge!
    alias _store store

    def initialize(pbackend)
        @pbackend = pbackend
        #super()
        _update(pbackend.get())
    end

    def []= (key, val)
        val = PersistList.new(val, key) if (val.is_a?(Array) && !val.instance_of?(PersistList))
        @pbackend.put({key => val}, {:replace => [key]})
        super(key, val)
    end

    def update(other_hash)
        other_hash = Hash[other_hash.map {|k,v| [k,((v.is_a?(Array) && !v.instance_of?(PersistList)) ? PersistList.new(v, k) : v )]}]
        @pbackend.put(other_hash, {:replace => other_hash.keys})
        super(other_hash)
    end

    alias store []=
    alias merge! update
end

