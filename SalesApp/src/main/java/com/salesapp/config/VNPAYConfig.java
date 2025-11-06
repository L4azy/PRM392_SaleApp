package com.salesapp.config;

import jakarta.servlet.http.HttpServletRequest;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.util.*;

public class VNPAYConfig {
    public static String vnp_PayUrl = "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html";
    public static String vnp_Returnurl = "/vnpay-payment-return";
    // VNPay Official Demo Credentials - these are guaranteed to work in sandbox
    // Replace with your actual credentials after registering at https://sandbox.vnpayment.vn/
    public static String vnp_TmnCode = System.getenv("VNPAY_TMN_CODE") != null 
        ? System.getenv("VNPAY_TMN_CODE") 
        : "DEMOV210";  // VNPay official demo TMN Code
    public static String vnp_HashSecret = System.getenv("VNPAY_HASH_SECRET") != null 
        ? System.getenv("VNPAY_HASH_SECRET") 
        : "LMYUMHROMPVFXBBTWAGSCAKLKFWSUPLT";  // VNPay official demo Hash Secret
    public static String vnp_apiUrl = "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html";

    public static String hashAllFields(Map fields) {
        List fieldNames = new ArrayList(fields.keySet());
        Collections.sort(fieldNames);
        StringBuilder sb = new StringBuilder();
        
        boolean isFirst = true;
        for (Object fieldNameObj : fieldNames) {
            String fieldName = (String) fieldNameObj;
            String fieldValue = (String) fields.get(fieldName);
            if ((fieldValue != null) && (fieldValue.length() > 0)) {
                if (!isFirst) {
                    sb.append("&");
                }
                sb.append(fieldName);
                sb.append("=");
                sb.append(fieldValue);
                isFirst = false;
            }
        }
        return hmacSHA512(vnp_HashSecret, sb.toString());
    }

    public static String hmacSHA512(final String key, final String data) {
        try {
            if (key == null || data == null) {
                throw new NullPointerException();
            }
            final Mac hmac512 = Mac.getInstance("HmacSHA512");
            byte[] hmacKeyBytes = key.getBytes();
            final SecretKeySpec secretKey = new SecretKeySpec(hmacKeyBytes, "HmacSHA512");
            hmac512.init(secretKey);
            byte[] dataBytes = data.getBytes(StandardCharsets.UTF_8);
            byte[] result = hmac512.doFinal(dataBytes);
            StringBuilder sb = new StringBuilder(2 * result.length);
            for (byte b : result) {
                sb.append(String.format("%02x", b & 0xff));
            }
            return sb.toString();
        } catch (Exception ex) {
            return "";
        }
    }

    public static String getIpAddress(HttpServletRequest request) {
        String ipAddress;
        try {
            ipAddress = request.getHeader("X-FORWARDED-FOR");
            if (ipAddress == null) {
                ipAddress = request.getLocalAddr();
            }
        } catch (Exception e) {
            ipAddress = "Invalid IP:" + e.getMessage();
        }
        return ipAddress;
    }

    public static String getRandomNumber(int len) {
        Random rnd = new Random();
        String chars = "0123456789";
        StringBuilder sb = new StringBuilder(len);
        for (int i = 0; i < len; i++) {
            sb.append(chars.charAt(rnd.nextInt(chars.length())));
        }
        return sb.toString();
    }
}
