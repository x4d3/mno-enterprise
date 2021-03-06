require 'rails_helper'

module MnoEnterprise
  describe Jpi::V1::Admin::SubscriptionEventsController, type: :controller do
    include MnoEnterprise::TestingSupport::SharedExamples::JpiV1Admin

    render_views
    routes { MnoEnterprise::Engine.routes }
    before { request.env["HTTP_ACCEPT"] = 'application/json' }

    before(:each) do
      Settings.merge!(dashboard: { marketplace: {provisioning: true } })
      Rails.application.reload_routes!
    end

    #===============================================
    # Assignments
    #===============================================
    let(:user) { build(:user, :admin) }
    let!(:current_user_stub) { stub_user(user) }

    let(:organization) { build(:organization) }
    let(:subscription) { build(:subscription) }
    let(:subscription_event) { build(:subscription_event, subscription: subscription) }

    #===============================================
    # Specs
    #===============================================
    before { sign_in user }

    describe 'GET #index' do
      subject { get :index, organization_id: organization.id, subscription_id: subscription.id }

      let(:data) { JSON.parse(response.body) }
      let(:includes) { [:'subscription'] }
      let(:expected_params) { { filter: { 'subscription.id': subscription.id }, _metadata: { act_as_manager: user.id, organization_id: organization.id } } }

      before { stub_api_v2(:get, "/subscription_events", [subscription_event], includes, expected_params) }

      it_behaves_like 'a jpi v1 admin action'

      it 'returns the subscription events' do
        subject
        expect(data['subscription_events'].first['id']).to eq(subscription_event.id)
      end
    end

    describe 'GET #show' do
      subject { get :show, id: subscription_event.id, organization_id: organization.id, subscription_id: subscription.id }

      let(:data) { JSON.parse(response.body) }
      let(:includes) { [:'subscription'] }
      let(:expected_params) do
        {
          filter: { id: subscription_event.id, 'subscription.id': subscription.id },
          _metadata: { act_as_manager: user.id, organization_id: organization.id },
          page: { number: 1, size: 1 } }
      end

      before { allow(subscription_event).to receive(:license_assignments).and_return([]) }
      before { allow(subscription_event).to receive(:organization).and_return(organization) }
      before { stub_api_v2(:get, "/subscription_events", subscription_event, includes, expected_params) }

      it_behaves_like 'a jpi v1 admin action'

      it 'returns the subscription event' do
        subject
        expect(data['subscription_event']['id']).to eq(subscription_event.id)
      end
    end
  end
end
