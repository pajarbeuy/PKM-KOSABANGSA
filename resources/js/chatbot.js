document.addEventListener('DOMContentLoaded', function () {
    const input = document.getElementById('chatbot-input');
    const sendBtn = document.getElementById('chatbot-send-btn');
    const messagesContainer = document.getElementById('chatbot-messages');
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');

    let hasMessages = false;

    function scrollToBottom() {
        messagesContainer.scrollTop = messagesContainer.scrollHeight;
    }

    function clearEmpty() {
        if (!hasMessages) {
            messagesContainer.innerHTML = '';
            hasMessages = true;
        }
    }

    function addMessage(text, isUser = false) {
        clearEmpty();
        const group = document.createElement('div');
        group.className = 'chatbot-message-group';

        const msg = document.createElement('div');
        msg.className = `chatbot-message ${isUser ? 'user-message' : 'bot-message'}`;

        if (!isUser) {
            const avatar = document.createElement('div');
            avatar.className = 'message-avatar';
            const img = document.createElement('img');
            img.src = '/images/kai-logo.svg';
            img.alt = 'KAI';
            img.style.width = '32px';
            img.style.height = '32px';
            img.style.borderRadius = '50%';
            avatar.appendChild(img);
            msg.appendChild(avatar);
        }

        const content = document.createElement('div');
        content.className = 'message-content';
        content.textContent = text;
        msg.appendChild(content);

        group.appendChild(msg);
        messagesContainer.appendChild(group);
        scrollToBottom();
    }

    function showTyping() {
        clearEmpty();
        const typing = document.createElement('div');
        typing.className = 'typing-indicator';
        typing.id = 'typing-indicator';
        typing.innerHTML = `
            <div class="message-avatar"><img src="/images/kai-logo.svg" alt="KAI" style="width: 32px; height: 32px; border-radius: 50%;"></div>
            <div class="typing-dots">
                <span></span><span></span><span></span>
            </div>
        `;
        messagesContainer.appendChild(typing);
        scrollToBottom();
    }

    function hideTyping() {
        const typing = document.getElementById('typing-indicator');
        if (typing) typing.remove();
    }

    async function sendMessage() {
        const text = input.value.trim();
        if (!text) return;

        addMessage(text, true);
        input.value = '';
        sendBtn.disabled = true;
        showTyping();

        try {
            const response = await fetch('/api/chat', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    'X-CSRF-TOKEN': csrfToken || '',
                },
                body: JSON.stringify({ message: text }),
            });

            const data = await response.json();
            hideTyping();
            addMessage(data.reply || 'Maaf, terjadi kesalahan.');
        } catch (e) {
            hideTyping();
            addMessage('Gagal terhubung ke server.');
        }

        sendBtn.disabled = false;
        input.focus();
    }

    sendBtn.addEventListener('click', sendMessage);
    input.addEventListener('keydown', function (e) {
        if (e.key === 'Enter') sendMessage();
    });
});