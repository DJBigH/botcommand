class Api::ProductsController < ApplicationController
  def index
    render json: Product.includes(:category).all.as_json(include: :category)
  end

  def show
    render json: Product.find(params[:id])
  end

  def create
    product = Product.new(product_params)
    if product.save
      render json: product
    else
      render json: { errors: product.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    product = Product.find(params[:id])
    if product.update(product_params)
      render json: product
    else
      render json: { errors: product.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    Product.find(params[:id]).destroy
    head :no_content
  end

  def hot
    products = Product.where(is_hot: 1).limit(5)
    render json: products
  end

  def by_category
    if params[:category_id]
      products = Product.where(category_id: params[:category_id])
      render json: products
    else
      render json: { error: "Thiếu category_id" }, status: :bad_request
    end
  end

  def search
  keyword = params[:keyword]
  products = Product.where("name LIKE ?", "%#{keyword}%")
  render json: products
  end

  def by_price_range
  min = params[:min].to_f
  max = params[:max].to_f
  products = Product.where(price: min..max)
  render json: products
  end

  private

  def product_params
    params.require(:product).permit(:name, :price, :description, :is_hot, :category_id)
  end
end
