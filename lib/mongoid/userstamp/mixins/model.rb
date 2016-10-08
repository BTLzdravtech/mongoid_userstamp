# -*- encoding : utf-8 -*-

module Mongoid
module Userstamp

  module Model

    extend ActiveSupport::Concern

    included do

      belongs_to_record mongoid_userstamp_config.created_name, class_name: mongoid_userstamp_config.user_model
      belongs_to_record mongoid_userstamp_config.updated_name, class_name: mongoid_userstamp_config.user_model

      before_create :set_created_by
      before_save :set_updated_by

      protected

      def set_created_by
        current_user = Mongoid::Userstamp.current_user(self.class.mongoid_userstamp_config.user_model)
        return if current_user.blank? || self.send(self.class.mongoid_userstamp_config.created_name)
        self.send("#{self.class.mongoid_userstamp_config.created_name}=", current_user)
      end

      def set_updated_by
        current_user = Mongoid::Userstamp.current_user(self.class.mongoid_userstamp_config.user_model)
        return if current_user.blank? || self.send("#{self.class.mongoid_userstamp_config.updated_name}_id_changed?")
        self.send("#{self.class.mongoid_userstamp_config.updated_name}=", current_user)
      end
    end

    module ClassMethods

      def belongs_to_record(association_name, options={})
        association_class = options[:class_name] || association_name.to_s.singularize.classify
        class_eval %<
        field :#{association_name}_id, type: Integer
        index(#{association_name}_id: 1)

        def #{association_name}
          @#{association_name} ||= #{association_class}.where(id: #{association_name}_id).first if #{association_name}_id
        end

        def #{association_name}=(object)
          @#{association_name} = object
          self.#{association_name}_id = object.try :id
        end
      >
      end

      def current_user
        Mongoid::Userstamp.current_user(mongoid_userstamp_config.user_model)
      end
    end
  end
end
end
