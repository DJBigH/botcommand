(function () {
  const scripts = document.querySelectorAll('script[src*="chat_widget.js"]');
  const currentScript = scripts[scripts.length - 1];
  const botIdentifier = currentScript?.getAttribute("data-bot");

  if (!botIdentifier) {
    console.error("Thiếu data-bot!");
    return;
  }

  window.addEventListener("DOMContentLoaded", () => {
    const iframe = document.createElement("iframe");
    iframe.style.position = "fixed";
    iframe.style.bottom = "20px";
    iframe.style.right = "20px";
    iframe.style.width = "1000px";
    iframe.style.height = "1000px";
    iframe.style.zIndex = "9999";
    iframe.style.border = "none";
    iframe.style.borderRadius = "15px";

    // Truyền botIdentifier vào URL
    iframe.src = `http://localhost:3000/embed_chat?bot_identifier=${encodeURIComponent(
      botIdentifier
    )}`;

    document.body.appendChild(iframe);

    // Nếu muốn truyền thêm dữ liệu sau khi iframe load, dùng postMessage
    iframe.onload = () => {
      iframe.contentWindow.postMessage({ botIdentifier: botIdentifier }, "*");
    };

    // Xử lý form chat widget (ví dụ khi submit form)
    const chatForm = document.getElementById("chat-form");
    if (chatForm) {
      chatForm.addEventListener("submit", (e) => {
        e.preventDefault();
        const name = document.getElementById("name")?.value || "";
        const phone = document.getElementById("phone")?.value || "";

        // Cập nhật src iframe khi có thông tin
        iframe.src = `http://localhost:3000/embed_chat?bot_identifier=${encodeURIComponent(
          botIdentifier
        )}&name=${encodeURIComponent(name)}&phone=${encodeURIComponent(phone)}`;
      });
    }
  });
})();
