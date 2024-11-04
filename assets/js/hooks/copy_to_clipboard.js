const CopyToClipboard = {
  mounted() {
    this.el.addEventListener("click", () => {
      const targetId = this.el.dataset.target;
      const codeElement = document.getElementById(targetId);

      if (codeElement) {
        navigator.clipboard.writeText(codeElement.textContent.trim())
          .then(() => {
            // Show success state
            const copyIcon = this.el.querySelector('.copy-icon');
            const checkIcon = this.el.querySelector('.check-icon');
            const copyText = this.el.querySelector('.copy-text');
            const successText = this.el.querySelector('.success-text');

            // Hide copy elements, show success elements
            copyIcon.classList.add('hidden');
            checkIcon.classList.remove('hidden');
            if (copyText && successText) {
              copyText.classList.add('hidden');
              successText.classList.remove('hidden');
            }

            // Reset after 2 seconds
            setTimeout(() => {
              copyIcon.classList.remove('hidden');
              checkIcon.classList.add('hidden');
              if (copyText && successText) {
                copyText.classList.remove('hidden');
                successText.classList.add('hidden');
              }
            }, 2000);
          })
          .catch(err => {
            console.error("Failed to copy text: ", err);
          });
      }
    });
  }
};

export default CopyToClipboard;
