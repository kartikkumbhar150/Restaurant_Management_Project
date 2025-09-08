package com.project.spring.service.master;

import com.project.spring.config.TwilioConfig;
import com.project.spring.exception.ResourceNotFoundException;
import com.project.spring.model.master.StaffUser;
import com.project.spring.repo.master.StaffUserRepository;
import com.twilio.rest.api.v2010.account.Message;
import com.twilio.type.PhoneNumber;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;
import java.util.Random;

@Service
public class ForgotPasswordService {

    private final Map<String, String> otpStorage = new HashMap<>();
    private final TwilioConfig twilioConfig;
    private final StaffUserRepository staffUserRepository;
    private final PasswordEncoder passwordEncoder;

    public ForgotPasswordService(TwilioConfig twilioConfig,
                                 StaffUserRepository staffUserRepository,
                                 PasswordEncoder passwordEncoder) {
        this.twilioConfig = twilioConfig;
        this.staffUserRepository = staffUserRepository;
        this.passwordEncoder = passwordEncoder;
    }

    public String sendOtp(String phoneNo) {
        String lookupNumber = cleanPhone(phoneNo);

        // Check if user exists in DB
        boolean userExists = staffUserRepository.findByUserName(lookupNumber).isPresent();
        if (!userExists) {
            throw new ResourceNotFoundException("Account doesn't exist!");
        }

        // Generate OTP
        String otp = String.format("%06d", new Random().nextInt(1_000_000));
        otpStorage.put(lookupNumber, otp);

        System.out.println("[DEBUG] OTP for " + lookupNumber + " is " + otp);

        // Send OTP via Twilio
        try {
            Message.creator(
                    new PhoneNumber("+91" + lookupNumber),
                    new PhoneNumber(twilioConfig.getTwilioPhoneNumber()),
                    "Your OTP is: " + otp
            ).create();
        } catch (Exception e) {
            throw new RuntimeException("Failed to send OTP: " + e.getMessage(), e);
        }

        return otp; // Debug only — remove in production
    }

    public boolean verifyOtp(String phoneNo, int otp) {
        String lookupNumber = cleanPhone(phoneNo);
        String storedOtp = otpStorage.get(lookupNumber);
        return storedOtp != null && storedOtp.equals(String.format("%06d", otp));
    }

    public boolean updatePassword(String phoneNo, String newPassword) {
        String lookupNumber = cleanPhone(phoneNo);

        StaffUser user = staffUserRepository.findByUserName(lookupNumber)
                .orElseThrow(() -> new ResourceNotFoundException("Account doesn't exist!"));

        user.setPassword(passwordEncoder.encode(newPassword));
        staffUserRepository.save(user);

        return true;
    }

    private String cleanPhone(String phoneNo) {
        String lookupNumber = phoneNo.trim().replaceAll("\\s+", "");
        if (!lookupNumber.matches("\\d{10,15}")) {
            throw new IllegalArgumentException("Invalid phone number format.");
        }
        return lookupNumber;
    }
}
