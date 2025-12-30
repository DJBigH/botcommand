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
    iframe.style.width = "500px";
    iframe.style.height = "700px";
    iframe.style.zIndex = "1";
    iframe.style.border = "none";
    // URL mặc định
    iframe.src = `http://localhost:3000/embed_chat?bot_identifier=${encodeURIComponent(
      botIdentifier
    )}`;

    document.body.appendChild(iframe);

    iframe.onload = () => {
      iframe.contentWindow.postMessage({ botIdentifier: botIdentifier }, "*");
    };

    // 👉 Nút bật/tắt widget chat
    const btnChat = document.getElementById("btn-chat");
    if (btnChat) {
      btnChat.addEventListener("click", () => {
        const opened = iframe.classList.toggle("open");

        if (opened) {
          // 🔵 Hiện chat + cho click
          iframe.style.pointerEvents = "auto";
          iframe.style.opacity = "1";
        } else {
          // 🔴 Tắt chat + không cho click → không chặn UI
          iframe.style.pointerEvents = "none";
          iframe.style.opacity = "0";
        }
      });
    }

    // Form submit → load lại iframe
    const chatForm = document.getElementById("chat-form");
    if (chatForm) {
      chatForm.addEventListener("submit", (e) => {
        e.preventDefault();

        const name = document.getElementById("name")?.value || "";
        const phone = document.getElementById("phone")?.value || "";

        iframe.src = `http://localhost:3000/embed_chat?bot_identifier=${encodeURIComponent(
          botIdentifier
        )}&name=${encodeURIComponent(name)}&phone=${encodeURIComponent(phone)}`;
      });
    }
  });
})();
