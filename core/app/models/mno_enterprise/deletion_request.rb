module MnoEnterprise
  class DeletionRequest < BaseResource
    property :created_at, type: :time
    property :updated_at, type: :time

    custom_endpoint :freeze, on: :member, request_method: :patch

    #============================================
    # CONSTANTS
    #============================================
    EXPIRATION_TIME = 60 #minutes

    #============================================
    # Instance methods
    #============================================
    # We want to use the token instead of the id
    def to_param
      self.token
    end

    def active?
      self.status != 'cancelled' && self.created_at >=  EXPIRATION_TIME.minutes.ago
    end

    def freeze_account!
      result = self.freeze
      process_custom_result(result)
    end

  end
end

