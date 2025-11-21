const twilio = require('twilio');



const accountSid = 'AC710fcc4cf5008cfc16b19caccc43a4a5';
const authToken = process.env.TWILIO_AUTH_TOKEN || '205fae8af397adde5491aee74e2c4412'; // REPLACE THIS WITH YOUR REAL TOKEN
const serviceSid = 'VA9f244d049bb16cb29ed6d9f3419ce7cb';

const client = twilio(accountSid, authToken);

exports.sendOtp = async (req, res) => {
  try {
    const { phone } = req.body;
    if (!phone) {
      return res.status(400).json({ error: 'Phone number is required' });
    }

    // Ensure phone number has country code (assuming +91 for India if missing)
    const formattedPhone = phone.startsWith('+') ? phone : `+91${phone}`;

    const verification = await client.verify.v2.services(serviceSid)
      .verifications
      .create({ to: formattedPhone, channel: 'sms' });

    console.log(`OTP sent to ${formattedPhone}: ${verification.sid}`);
    res.status(200).json({ success: true, message: 'OTP sent successfully', sid: verification.sid });
  } catch (error) {
    console.error('Error sending OTP:', error);
    res.status(500).json({ error: error.message });
  }
};

exports.verifyOtp = async (req, res) => {
  try {
    const { phone, otp } = req.body;
    if (!phone || !otp) {
      return res.status(400).json({ error: 'Phone and OTP are required' });
    }

    const formattedPhone = phone.startsWith('+') ? phone : `+91${phone}`;

    const verificationCheck = await client.verify.v2.services(serviceSid)
      .verificationChecks
      .create({ to: formattedPhone, code: otp });

    if (verificationCheck.status === 'approved') {
      res.status(200).json({ success: true, message: 'OTP verified successfully' });
    } else {
      res.status(400).json({ success: false, message: 'Invalid OTP' });
    }
  } catch (error) {
    console.error('Error verifying OTP:', error);
    res.status(500).json({ error: error.message });
  }
};
