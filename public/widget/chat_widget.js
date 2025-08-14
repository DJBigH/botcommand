(function () {
  const scripts = document.querySelectorAll('script[src*="chat_widget.js"]');
  const currentScript = scripts[scripts.length - 1];
  const botIdentifier = currentScript?.getAttribute("data-bot");

  if (!botIdentifier) {
    console.error("Thiếu data-bot!");
    return;
  }
  // $(".chatAi-block.show").addEventListener("DOMContentLoaded", () => {
  //   iframe.style.width = "500px";
  //   iframe.style.height = "800px";
  // })
  window.addEventListener("DOMContentLoaded", () => {
    const iframe = document.createElement("iframe");
    iframe.style.position = "fixed";
    iframe.style.bottom = "20px";
    iframe.style.right = "20px";
    iframe.style.width = "500px";
    iframe.style.height = "700px";
    iframe.style.zIndex = "-1";
    iframe.style.border = "none";

    // $('#btn-chat').click(function (event) {
    //   iframe.classList.add("add");
    //   console.log("da add")
    //   iframe.style.width = "100px";
    //   iframe.style.height = "700px";
    // })

    // var btnChat = document.getElementById('btn-chat');
    // btnChat.addEventListener('click', function () {
    //   // var iframe = document.querySelector('iframe');
    //   iframe.classList.add('add');
    //   console.log("da add");
    //   iframe.style.width = '100px';
    //   iframe.style.height = '700px';
    // });


    // else 
    // {
    //   // Phần tử không có lớp .show
    //   console.log('Phần tử không có lớp .show');
    // }
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
