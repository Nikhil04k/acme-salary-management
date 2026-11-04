require "rails_helper"

RSpec.describe "API V1 Sessions", type: :request do
  let(:user) do
    create(
      :user,
      email: "hr@example.com",
      password: "Password@123",
      role: "hr_manager"
    )
  end

  describe "POST /api/v1/login" do
    it "returns a JWT for valid credentials" do
      post "/api/v1/login",
           params: {
             user: {
               email: user.email,
               password: "Password@123"
             }
           },
           as: :json

      expect(response).to have_http_status(:ok)

      expect(response.parsed_body).to include(
        "success" => true,
        "message" => "Login successful"
      )

      expect(response.headers["Authorization"]).to start_with("Bearer ")
    end

    it "rejects invalid credentials" do
      post "/api/v1/login",
           params: {
             user: {
               email: user.email,
               password: "WrongPassword"
             }
           },
           as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "protected endpoints" do
    it "rejects requests without a JWT" do
      get "/api/v1/employees", as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "allows requests with a valid JWT" do
      post "/api/v1/login",
          params: {
            user: {
              email: user.email,
              password: "Password@123"
            }
          },
          as: :json

      token = response.headers["Authorization"]

      get "/api/v1/employees",
          headers: { "Authorization" => token },
          as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["success"]).to be true
    end
  end

  describe "DELETE /api/v1/logout" do
    it "revokes the JWT and prevents further access" do
      post "/api/v1/login",
          params: {
            user: {
              email: user.email,
              password: "Password@123"
            }
          },
          as: :json

      token = response.headers["Authorization"]

      expect(token).to be_present

      delete "/api/v1/logout",
            headers: { "Authorization" => token },
            as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["success"]).to be true

      get "/api/v1/employees",
          headers: { "Authorization" => token },
          as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
