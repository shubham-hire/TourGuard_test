const twilio = require('twilio');

const accountSid = process.env.TWILIO_ACCOUNT_SID || 'AC710fcc4cf5008cfc16b19caccc43a4a5';
const authToken = process.env.TWILIO_AUTH_TOKEN || '205fae8af397adde5491aee74e2c4412';
const twilioPhoneNumber = process.env.TWILIO_PHONE_NUMBER || ''; // Your Twilio phone number

const client = twilio(accountSid, authToken);

/**
 * Format phone number to include country code
 * @param {string} phone - Phone number
 * @returns {string} Formatted phone number with country code
 */
function formatPhoneNumber(phone) {
  // Remove any spaces, dashes, or parentheses
  let cleaned = phone.replace(/[\s\-\(\)]/g, '');
  
  // If already has country code, return as is
  if (cleaned.startsWith('+')) {
    return cleaned;
  }
  
  // If starts with 0, remove it
  if (cleaned.startsWith('0')) {
    cleaned = cleaned.substring(1);
  }
  
  // Add +91 for India if no country code
  if (!cleaned.startsWith('+')) {
    cleaned = `+91${cleaned}`;
  }
  
  return cleaned;
}

/**
 * Send SMS to a single phone number
 * @param {string} to - Recipient phone number
 * @param {string} message - Message to send
 * @returns {Promise<Object>} Twilio message result
 */
async function sendSMS(to, message) {
  try {
    const formattedPhone = formatPhoneNumber(to);
    
    // If no Twilio phone number is configured, throw error
    if (!twilioPhoneNumber) {
      throw new Error('Twilio phone number not configured. Please set TWILIO_PHONE_NUMBER environment variable.');
    }
    
    const result = await client.messages.create({
      body: message,
      from: twilioPhoneNumber,
      to: formattedPhone,
    });
    
    console.log(`SMS sent to ${formattedPhone}: ${result.sid}`);
    return { success: true, sid: result.sid, to: formattedPhone };
  } catch (error) {
    console.error(`Error sending SMS to ${to}:`, error.message);
    return { success: false, error: error.message, to };
  }
}

/**
 * Send SMS to multiple emergency contacts
 * @param {Array<Object>} contacts - Array of contact objects with 'phone' and optionally 'name'
 * @param {string} message - Message to send
 * @returns {Promise<Array>} Array of results for each SMS
 */
async function sendSMSToContacts(contacts, message) {
  const results = [];
  
  for (const contact of contacts) {
    const phone = contact.phone || contact.phoneNumber;
    if (!phone) {
      results.push({ success: false, error: 'No phone number provided', contact });
      continue;
    }
    
    const result = await sendSMS(phone, message);
    results.push({ ...result, contactName: contact.name || 'Unknown' });
    
    // Small delay between messages to avoid rate limiting
    await new Promise(resolve => setTimeout(resolve, 500));
  }
  
  return results;
}

module.exports = {
  sendSMS,
  sendSMSToContacts,
  formatPhoneNumber,
};

