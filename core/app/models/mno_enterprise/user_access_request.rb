module MnoEnterprise
  class UserAccessRequest < BaseResource
    # Expiration timeout for pending and active requests
    EXPIRATION_TIMEOUT = 24.hours

    property :created_at, type: :time
    property :updated_at, type: :time
    property :approved_at, type: :time
    property :expiration_date, type: :time
    property :denied_at, type: :time
    property :revoked_at, type: :time
    property :requester_id, type: :string
    property :user_id, type: :string
    property :status

    custom_endpoint :approve, on: :member, request_method: :patch
    custom_endpoint :deny, on: :member, request_method: :patch
    custom_endpoint :revoke, on: :member, request_method: :patch

    def self.active_requested(user_id)
      includes(:requester).where(user_id: user_id, status: 'requested', 'created_at.gt': EXPIRATION_TIMEOUT.ago)
    end

    def self.last_access_request(user_id)
      includes(:requester).where('requester_id.none' => true, user_id: user_id, status: 'approved').order(created_at: :desc).first
    end

    def self.notify_pending_requests(user, access_duration)
      user = user.load_required(:user_access_requests, :'user_access_requests.requester')
      user.user_access_requests.each do |request|
        # Notify the admin that the access is now granted for the user and delete the request
        if request.status == 'requested'
          if request.requester
            MnoEnterprise::SystemNotificationMailer.access_approved_all(user.id, request.requester.id, access_duration).deliver_later
          end
          request.destroy
        end
      end
    end

    def to_audit_event
      { id: id, user_id: user_id, requester_id: requester_id , status: status}
    end

    def current_status
      if (status == 'approved' && expiration_date && Time.now > expiration_date ) || (status == 'requested' && created_at < EXPIRATION_TIMEOUT.ago)
        'expired'
      else
        status
      end
    end

    def approve!
      input = { data: { attributes: { expiration_date: EXPIRATION_TIMEOUT.from_now} } }
      result = approve(input)
      process_custom_result(result)
    end

    def revoke!
      process_custom_result(revoke)
    end

    def deny!
      process_custom_result(deny)
    end
  end
end
