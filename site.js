"use strict";

const repository_input = document.getElementById("repo_url");
const copy_button = document.getElementById("copy_url");
const copy_status = document.getElementById("copy_status");

copy_button.addEventListener("click", async () => {
  let timeout_id;
  copy_button.disabled = true;
  copy_status.textContent = "コピーしています…";
  try {
    if (!navigator.clipboard) throw new Error("Clipboard API is unavailable");
    await Promise.race([
      navigator.clipboard.writeText(repository_input.value),
      new Promise((_, reject) => { timeout_id = setTimeout(() => reject(new Error("Clipboard timeout")), 2500); })
    ]);
    copy_status.textContent = "URLをコピーしました。VCC / ALCOMに貼り付けてください。";
  } catch {
    repository_input.focus();
    repository_input.select();
    copy_status.textContent = "URLを選択しました。右クリックまたはキーボード操作でコピーしてください。";
  } finally {
    clearTimeout(timeout_id);
    copy_button.disabled = false;
  }
});

// Keep the visible version labels in sync with the repository listing.
fetch("index.json")
  .then(response => {
    if (!response.ok) throw new Error("Listing is unavailable");
    return response.json();
  })
  .then(listing => {
    document.querySelectorAll("[data-version]").forEach(label => {
      const versions = Object.keys(listing.packages[label.dataset.version]?.versions || {})
        .filter(version => /^\d+\.\d+\.\d+$/.test(version))
        .sort((left, right) => {
          const a = left.split(".").map(Number);
          const b = right.split(".").map(Number);
          return b[0] - a[0] || b[1] - a[1] || b[2] - a[2];
        });
      if (versions.length) label.textContent = "v" + versions[0];
    });
  })
  .catch(() => { /* Static content and the manual URL remain available. */ });
