# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Xóa dữ liệu cũ nếu cần
Category.destroy_all
Product.destroy_all

# Tạo 10 danh mục
categories = [
  "Điện thoại", "Laptop", "Thời trang", "Gia dụng", "Mỹ phẩm",
  "Đồ chơi", "Thực phẩm", "Thể thao", "Sách", "Xe cộ"
]

categories.each do |name|
  Category.create!(name: name)
end

# Tạo 10 sản phẩm mẫu
products = [
  { name: "iPhone 15 Pro Max", price: 34990000 },
  { name: "MacBook Air M2", price: 28990000 },
  { name: "Áo thun nam basic", price: 199000 },
  { name: "Nồi chiên không dầu", price: 1490000 },
  { name: "Son môi Dior", price: 890000 },
  { name: "Bộ Lego City", price: 950000 },
  { name: "Hạt điều rang muối", price: 159000 },
  { name: "Vợt cầu lông Yonex", price: 750000 },
  { name: "Sách lập trình Ruby", price: 320000 },
  { name: "Xe đạp thể thao", price: 4200000 }
]

products.each do |product|
  Product.create!(
    name: product[:name],
    price: product[:price],
    category: Category.order("RANDOM()").first # Gán ngẫu nhiên danh mục
  )
end

