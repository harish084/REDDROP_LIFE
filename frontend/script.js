const BASE_URL = 'http://localhost:5000';
let hospitalVerified = false;
let hospitalDetails = null;

function showModal() {
    const modal = new bootstrap.Modal(document.getElementById('modal-hospital-details'));
    modal.show();
}

document.getElementById('hospital-details-form').addEventListener('submit', async function(e) {
    e.preventDefault();

    const hospitalName = document.getElementById('hospital-name').value.trim();
    const hospitalLocation = document.getElementById('hospital-location').value.trim();
    const hospitalContact = document.getElementById('hospital-contact').value.trim();
    
    try {
        const response = await fetch(`${BASE_URL}/verify-hospital`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                name: hospitalName,
                location: hospitalLocation,
                contact: hospitalContact
            })
        });

        if (response.ok) {
            hospitalDetails = {
                name: hospitalName,
                location: hospitalLocation,
                contact: hospitalContact
            };
            hospitalVerified = true;

            const modal = bootstrap.Modal.getInstance(document.getElementById('modal-hospital-details'));
            modal.hide();

            appendToChatLog('Chatbot', 'Hospital details verified successfully!');
            
            // Attempt to resend the last search query
            if (window.lastSearchQuery) {
                sendMessage(window.lastSearchQuery);
                window.lastSearchQuery = null;
            }
        } else {
            appendToChatLog('Chatbot', 'Hospital verification failed. Please try again.');
        }
    } catch (error) {
        console.error('Hospital Verification Error:', error);
        appendToChatLog('Chatbot', 'Network error during hospital verification.');
    }
});

function appendToChatLog(sender, message) {
    const chatLog = document.getElementById('chat-log');
    chatLog.innerHTML += `
        <div class="message ${sender.toLowerCase()}">
            <strong>${sender}:</strong> ${message}
        </div>
    `;
    chatLog.scrollTop = chatLog.scrollHeight;
}

async function sendMessage(forcedQuery) {
    const input = document.getElementById('user-input');
    const query = forcedQuery || input.value.trim();
    
    if (!query) return;
    
    appendToChatLog('You', query);
    
    if (!forcedQuery) {
        input.value = '';
    }

    try {
        const response = await fetch(`${BASE_URL}/chatbot`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ query, hospitalDetails }),
        });
        const responseData = await response.json();

        // Check if it's a hospital details request
        if (responseData.bypassVerification) {
            appendToChatLog('Chatbot', responseData.reply);
            return;
        }

        // Check if hospital verification is required
        if (responseData.requireHospitalVerification) {
            // Store the query for retry after verification
            window.lastSearchQuery = query;
            
            appendToChatLog('Chatbot', responseData.reply);
            showModal();
            return;
        }

        // Normal chatbot response
        appendToChatLog('Chatbot', responseData.reply);
    } catch (error) {
        console.error('Chatbot Error:', error);
        appendToChatLog('Chatbot', 'Sorry, I am unable to process your request.');
    }
}

async function registerDonor(event) {
    event.preventDefault();
    const name = document.getElementById('name');
    const contact = document.getElementById('contact');
    const bloodGroup = document.getElementById('blood-group');
    const location = document.getElementById('location');
    const donorData = {
        name: name.value.trim(),
        contact: contact.value.trim(),
        bloodGroup: bloodGroup.value,
        location: location.value.trim()
    };
    try {
        const response = await fetch(`${BASE_URL}/register`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(donorData),
        });
        if (response.ok) {
            alert('Registration Successful!');
            name.value = '';
            contact.value = '';
            bloodGroup.selectedIndex = 0;
            location.value = '';
        } else {
            alert('Registration Failed');
        }
    } catch (error) {
        console.error('Registration Error:', error);
        alert('Network Error. Please try again.');
    }
}

document.getElementById('registration-form').addEventListener('submit', registerDonor);

document.getElementById('user-input').addEventListener('keypress', (event) => {
    if (event.key === 'Enter') sendMessage();
});