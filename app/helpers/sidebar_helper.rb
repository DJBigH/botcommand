module SidebarHelper
  def sidebar_link_to(name, path, icon: nil, **options)
    active = current_page?(path) ? "active" : ""
    icon_tag = icon.present? ? content_tag(:i, "", class: "nav-icon fas fa-#{icon}") : ""

    link = link_to(path, class: "nav-link #{active}", data: { turbo: false }) do
      concat(icon_tag)
      concat(content_tag(:p, name))
    end

    content_tag(:li, link, class: "nav-item")
  end
end

# Helper hỗ chỗ tạo active khi được click vào hẹ hẹ
