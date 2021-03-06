module MnoEnterprise::Concerns::Controllers::Jpi::V1::Admin::BaseResourceController
  extend ActiveSupport::Concern

  #==================================================================
  # Included methods
  #==================================================================
  # 'included do' causes the included code to be evaluated in the
  # context where it is included rather than being executed in the module's context
  included do
    ADMIN_CACHE_DURATION = 12.hours
    before_filter :check_authorization
  end

  protected

  def timestamp
    @timestamp ||= (params[:timestamp] || 0).to_i
  end

  # Check current user is logged in
  # Check organization is valid if specified
  def check_authorization
    if current_user && current_user.admin_role.present?
      return true
    end
    render nothing: true, status: :unauthorized
    false
  end

  def render_not_found(resource = controller_name.singularize, id = params[:id])
    render json: { errors: {message: "#{resource.titleize} not found (id=#{id})", code: 404, params: params} }, status: :not_found
  end

  def render_bad_request(attempted_action, issue)
    render json: { errors: {message: "Error while trying to #{attempted_action}: #{issue}", code: 400, params: params} }, status: :bad_request
  end

  def render_forbidden_request(attempted_action)
    render json: { errors: {message: "Error while trying to #{attempted_action}: you do not have permission", code: 403} }, status: :forbidden
  end
end
