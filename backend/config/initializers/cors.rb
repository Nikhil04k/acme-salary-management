Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(
      "https://acme-salary-management-6ds.pages.dev",
      "http://localhost:5174",
      "http://127.0.0.1:5174"
    )

    resource "*",
      headers: %w[Authorization Content-Type Accept],
      methods: %i[get post put patch delete options head],
      expose: ["Authorization"],
      max_age: 600
  end
end
