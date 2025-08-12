Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'http://127.0.0.1:5500'  # Hoặc '*', nếu bạn muốn cho phép tất cả (không khuyến khích trong production)

    resource '*',
      headers: :any,
      methods: [:get, :post, :options, :head],
      credentials: false
  end
end
