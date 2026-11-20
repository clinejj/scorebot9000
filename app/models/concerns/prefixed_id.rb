# Prefixed public IDs in TypeID format ("usr_01h455vb4pex5vsknk084sn02q").
#
#   class User < ApplicationRecord
#     has_prefixed_id :usr
#   end
#
#   user.public_id        # => "usr_01h455vb4pex5vsknk084sn02q"
#   user.to_param         # => same, so URL helpers use it
#   User.find("usr_...")  # works, as do relation finds and where(id: "usr_...")
#
# The id attribute's type accepts either the raw UUID or the TypeID with the
# right prefix; a TypeID with the wrong prefix casts to nil (so finds raise
# RecordNotFound instead of matching another model's row).
module PrefixedId
  mattr_accessor :registry, default: {}

  # Look up any record by its prefixed ID, e.g. from an admin search box.
  def self.locate(public_id)
    prefix, uuid = TypeId.decode(public_id)
    model_name = registry[prefix] or return nil
    model_name.constantize.find_by(id: uuid)
  rescue TypeId::InvalidError
    nil
  end

  class Type < ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Uuid
    attr_reader :prefix

    def initialize(prefix)
      @prefix = prefix
      super()
    end

    private
      def cast_value(value)
        string = value.to_s
        return super unless string.include?("_")

        decoded_prefix, uuid = TypeId.decode(string)
        uuid if decoded_prefix == prefix
      rescue TypeId::InvalidError
        nil
      end
  end

  extend ActiveSupport::Concern

  included do
    class_attribute :id_prefix, instance_writer: false, default: nil
  end

  class_methods do
    def has_prefixed_id(prefix)
      prefix = prefix.to_s
      TypeId.validate_prefix!(prefix)
      if (existing = PrefixedId.registry[prefix]) && existing != name
        raise ArgumentError, "prefix #{prefix} already used by #{existing}"
      end

      PrefixedId.registry[prefix] = name
      self.id_prefix = prefix
      attribute :id, PrefixedId::Type.new(prefix)
    end

    def public_id_for(uuid)
      uuid && id_prefix && TypeId.encode(id_prefix, uuid)
    end

    def find_by_public_id(public_id)
      find_by(id: public_id) if id_prefix && TypeId.valid?(public_id, prefix: id_prefix)
    end

    def find_by_public_id!(public_id)
      find_by_public_id(public_id) || raise(ActiveRecord::RecordNotFound.new("Couldn't find #{name} #{public_id}", name))
    end
  end

  def public_id
    self.class.public_id_for(id)
  end

  def to_param
    id_prefix ? (public_id if persisted?) : super
  end
end
