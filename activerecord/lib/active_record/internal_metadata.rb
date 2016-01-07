require 'active_record/scoping/default'
require 'active_record/scoping/named'

module ActiveRecord
  # This class is used to create a table that keeps track of values and keys such
  # as which environment migrations were run in.
  class InternalMetadata < ActiveRecord::Base
    class << self
      def primary_key
        "key"
      end

      def table_name
        "#{table_name_prefix}#{ActiveRecord::Base.internal_metadata_table_name}#{table_name_suffix}"
      end

      def index_name
        "#{table_name_prefix}unique_#{ActiveRecord::Base.internal_metadata_table_name}#{table_name_suffix}"
      end

      def store(hash)
        hash.each do |key, value|
          first_or_initialize(key: key).update_attributes!(value: value)
        end
      end

      def value_for(key)
        where(key: key).pluck(:value).first
      end

      def table_exists?
        ActiveSupport::Deprecation.silence { connection.table_exists?(table_name) }
      end

      # Creates a internal metadata table with columns +key+ and +value+
      def create_table
        unless table_exists?
          connection.create_table(table_name, primary_key: :key, id: false ) do |t|
            t.column :key,   :string
            t.column :value, :string
            t.timestamps
          end

          connection.add_index table_name, :key, unique: true, name: index_name
        end
      end
    end
  end
end
