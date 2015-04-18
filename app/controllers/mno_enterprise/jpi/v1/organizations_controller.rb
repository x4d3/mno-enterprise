module MnoEnterprise
  class Jpi::V1::OrganizationsController < Jpi::V1::BaseResourceController
    respond_to :json

    # GET /mnoe/jpi/v1/organizations
    def index
      @organizations ||= current_user.organizations
    end
    
    # GET /mnoe/jpi/v1/organizations/1
    def show
      organization # load organization
    end

    # PUT /mnoe/jpi/v1/organizations/:id
    def update
      # Filter
      whitelist = [:name,:soa_enabled]
      attributes = (params[:organization] || {}).select { |k,v| whitelist.include?(k.to_sym) }
      
      # Update and Authorize
      organization.assign_attributes(attributes)
      authorize! :update, organization

      # Save
      if organization.save
        render 'show_reduced'
      else
        render json: organization.errors, status: :bad_request
      end
    end

    # PUT /mnoe/jpi/v1/organizations/:id/charge
    # def charge
    #   authorize! :manage_billing, organization
    #   payment = organization.charge
    #   s = ''
    #   if payment
    #     if payment.success?
    #       s = 'success'
    #     else
    #       s = 'fail'
    #     end
    #   else
    #     s = 'error'
    #   end
    #
    #   render json: { status: s, data: payment }
    # end

    # PUT /mnoe/jpi/v1/organizations/:id/update_billing
    # def update_billing
    #   whitelist = ['title','first_name','last_name','number','month','year','country','verification_value','billing_address','billing_city','billing_postcode', 'billing_country']
    #   attributes = params[:credit_card].select { |k,v| whitelist.include?(k.to_s) }
    #
    #   # Authorize and upsert
    #   authorize! :update, organization
    #   if (@credit_card = organization.credit_card)
    #     @credit_card.smart_update_attributes(attributes)
    #   else
    #     @credit_card = organization.create_credit_card(attributes)
    #   end
    #
    #   if @credit_card.errors.empty?
    #     render partial: 'credit_card'
    #   else
    #     render json: @credit_card.errors, status: :bad_request
    #   end
    # end

    # PUT /mnoe/jpi/v1/organizations/:id/invite_members
    def invite_members
      # Filter
      whitelist = ['email','role','team_id']
      attributes = []
      params[:invites].each do |invite|
        attributes << invite.select { |k,v| whitelist.include?(k.to_s) }
      end

      # Authorize and create
      authorize! :invite_member, organization
      attributes.each do |invite|
        @org_invite = organization.org_invites.create(
          user_email: invite['email'], 
          user_role: invite['role'],
          team_id: invite['team_id'],
          referrer_id: current_user.id
        )
        
        SystemNotificationMailer.organization_invite(@org_invite).deliver_now
      end

      render 'members'
    end

    # PUT /mnoe/jpi/v1/organizations/:id/update_member
    def update_member
      attributes = params[:member]
      @orga_relation = organization.orga_relations.joins(:user).where("users.email = ?",attributes[:email]).first
      @orga_relation ||= organization.org_invites.active.where("user_email = ?",attributes[:email]).first

      # Authorize and update
      if @orga_relation.is_a?(OrgaRelation)
        @orga_relation = OrgaRelation.find(@orga_relation.id)
        @orga_relation.assign_attributes(role: attributes[:role])
      elsif @orga_relation.is_a?(OrgaInvite)
        @orga_relation.assign_attributes(user_role: attributes[:role])
      end
      authorize! :update, @orga_relation
      @orga_relation.save

      render partial: 'members'
    end

    # PUT /mnoe/jpi/v1/organizations/:id/remove_member
    def remove_member
      attributes = params[:member]
      @member = User.find_by_email(attributes[:email])
      @member ||= organization.org_invites.active.find_by_user_email(attributes[:email])

      if @member.is_a?(User)
        authorize! :destroy, @member.orga_relations_all.where(organization_id: organization).first
        organization.remove_user(@member)
      elsif @member.is_a?(OrgaInvite)
        authorize! :destroy, @member
        @member.update_attribute(:status,'cancelled')
      end

      render partial: 'members'
    end
    
    protected
      def organization
        @organization ||= current_user.organizations.to_a.find { |o| o.id.to_s == params[:id].to_s }
      end
      
  end
end