Rspec.describe 'ZooStatsApiGraphql', type: :request do
  describe '/' do
    before do
      allow(ActiveRecord::Base).to receive(:connected?).and_return(true)
    end

    it 'should return a health check response' do
      get '/'
      expected_response = {
        'status' => 'ok',
        'version' => VERSION,
        'database_status' => 'connected',
        'commit_id' => ENV['REVISION']
      }
      expect(response.body).to eq(expected_response.to_json)
    end
  end

  context 'when supplying tokens' do
    let(:headers) do
      {'HTTP_AUTHORIZATION' => 'Bearer FakeToken'}
    end
    let(:credential) { instance_double(Credential) }

    before do
      allow(Credential).to receive(:new).and_return(credential)
      allow(ZooStatsSchema).to receive(:execute) { |query, params| params }
    end

    describe 'graphql' do
      let(:params) do
        {
          query: 'Graphql query',
          operation_name: nil
        }
      end

      context 'with no token' do
        it 'should set context :user_id and :admin to nil without auth headers' do
          post '/graphql', params: params
          context_param = JSON.parse(response.body)["context"]
          expect(context_param["current_user"]).to be_nil
          expect(context_param["admin"]).to be_nil
        end
      end

      context 'with correct token' do
        let(:current_user) { 123 }
        let(:admin_status) { false }
        before do
          expect(credential).to receive(:ok?).and_return(true)
          expect(credential).to receive(:current_user_id).and_return(current_user)
          expect(credential).to receive(:current_admin_status).and_return(admin_status)
        end
        it 'should set correct context from auth header' do
          post '/graphql', params: params, headers: headers
          context_param = JSON.parse(response.body)["context"]
          expect(context_param["current_user"]).to eq(current_user)
          expect(context_param["admin"]).to eq(admin_status)
        end
      end
    end
  end

  context 'with HTTP basic authentication' do
    let(:username) { "user" }
    let(:password) { "secret" }
    let(:headers) do
      {'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(username, password)}
    end

    before do
      allow(ZooStatsSchema).to receive(:execute) { |query, params| params }
    end

    describe 'graphql' do
      let(:params) do
        {
          query: 'Graphql query',
          operation_name: nil
        }
      end

      context 'with no token' do
        it 'should set context :user_id and :admin to nil without auth headers' do
          post '/graphql', params: params
          context_param = JSON.parse(response.body)["context"]
          expect(context_param["basic_user"]).to be_nil
          expect(context_param["basic_password"]).to be_nil
        end
      end

      context 'with correct token' do
        it 'should set correct context from auth header' do
          post '/graphql', params: params, headers: headers
          context_param = JSON.parse(response.body)["context"]
          expect(context_param["basic_user"]).to eq(username)
          expect(context_param["basic_password"]).to eq(password)
        end
      end
    end
  end
end
