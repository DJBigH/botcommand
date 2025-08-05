(function () {
  const script = document.currentScript;
  const botIdentifier = script.getAttribute("data-bot");

  const formContainer = document.createElement("div");
  formContainer.style.position = "fixed";
  formContainer.style.bottom = "20px";
  formContainer.style.right = "20px";
  formContainer.style.width = "350px";
  formContainer.style.padding = "20px";
  formContainer.style.background = "#fff";
  formContainer.style.boxShadow = "0 0 10px rgba(0,0,0,0.2)";
  formContainer.style.zIndex = "9999";
  formContainer.style.borderRadius = "8px";
  formContainer.innerHTML = `
    <h4 style="margin-top: 0;">Liên hệ để chat</h4>
    <input id="userName" placeholder="Tên của bạn" style="width: 100%; margin-bottom: 10px; padding: 8px;" />
    <input id="userPhone" placeholder="Số điện thoại" style="width: 100%; margin-bottom: 10px; padding: 8px;" />
    <button id="startChat" style="width: 100%; padding: 10px; background-color: #007bff; color: white; border: none; border-radius: 4px;">Bắt đầu</button>
  `;
  document.body.appendChild(formContainer);

  document.getElementById("startChat").addEventListener("click", function () {
    const name = document.getElementById("userName").value.trim();
    const phone = document.getElementById("userPhone").value.trim();

    if (!name || !phone) {
      alert("Vui lòng nhập đầy đủ tên và số điện thoại.");
      return;
    }

    // Ẩn form
    formContainer.style.display = "none";

    // Hiển thị iframe chat
    const iframe = document.createElement("iframe");
    iframe.src = `http://localhost:3000/embed_chat?bot_identifier=${botIdentifier}&name=${encodeURIComponent(name)}&phone=${encodeURIComponent(phone)}`;
    iframe.style.position = "fixed";
    iframe.style.bottom = "20px";
    iframe.style.right = "20px";
    iframe.style.width = "350px";
    iframe.style.height = "500px";
    iframe.style.border = "none";
    iframe.style.zIndex = "9999";
    document.body.appendChild(iframe);
  });
})();
