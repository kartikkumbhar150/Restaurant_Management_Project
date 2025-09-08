package com.project.spring.service.master;

import com.twilio.rest.api.v2010.account.Message;
import com.twilio.type.PhoneNumber;
import com.project.spring.config.TwilioConfig;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;
import java.util.Random;

@Service
public class OtpService {

    private final Map<String, String> otpStorage = new HashMap<>();
    private final TwilioConfig twilioConfig;

    public OtpService(TwilioConfig twilioConfig) {
        this.twilioConfig = twilioConfig;
    }

    public String sendOtp(String phone) {
        // Convert phone to string
        String phoneStr = String.valueOf(phone).trim().replaceAll("\\s+", "");

        if (!phoneStr.startsWith("+")) {
            phoneStr = "+91" + phoneStr; // Default to +91 for India; adjust as needed
        }

        // Validate phone number format
        if (!phoneStr.matches("^\\+\\d{10,15}$")) {
            throw new IllegalArgumentException("Invalid phone number format. Must be like +91932213XXXX");
        }

        // Generate OTP
        String otp = String.format("%06d", new Random().nextInt(999999));
        otpStorage.put(phoneStr, otp);

        System.out.println("[DEBUG] OTP for " + phoneStr + " is " + otp);

        try {
            Message.creator(
                new PhoneNumber(phoneStr),
                new PhoneNumber(twilioConfig.getTwilioPhoneNumber()),
                "Your OTP is: " + otp
            ).create();
        } catch (Exception e) {
            System.err.println("Error sending OTP to " + phoneStr + ": " + e.getMessage());
            throw new RuntimeException("Failed to send OTP: " + e.getMessage());
        }

        return otp;
    }

    public boolean verifyOtp(String phone, int otp) {
        String phoneStr = String.valueOf(phone).trim().replaceAll("\\s+", "");

        if (!phoneStr.startsWith("+")) {
            phoneStr = "+91" + phoneStr;
        }

        String storedOtp = otpStorage.get(phoneStr);
        return storedOtp != null && storedOtp.equals(String.format("%06d", otp));
    }
}
