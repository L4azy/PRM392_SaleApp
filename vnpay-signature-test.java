import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.util.*;

public class VNPaySignatureTest {
    
    public static void main(String[] args) {
        // VNPay credentials
        String hashSecret = "OF6M0J6RIX8RN9ANH5Z0PKLY3YK6TKGT";
        
        // Sample parameters from your log
        Map<String, String> params = new TreeMap<>();
        params.put("vnp_Amount", "10000");
        params.put("vnp_Command", "pay");
        params.put("vnp_CreateDate", "20251107020708");
        params.put("vnp_CurrCode", "VND");
        params.put("vnp_ExpireDate", "20251107023708");
        params.put("vnp_IpAddr", "172.18.0.3");
        params.put("vnp_Locale", "vn");
        params.put("vnp_OrderInfo", "Skibidi");
        params.put("vnp_OrderType", "order-type");
        params.put("vnp_ReturnUrl", "http://localhost:3000/payment-result?");
        params.put("vnp_TmnCode", "L6HT7TRL");
        params.put("vnp_TxnRef", "66487383");
        params.put("vnp_Version", "2.1.0");
        
        // Build hash data
        StringBuilder hashData = new StringBuilder();
        boolean isFirst = true;
        
        for (Map.Entry<String, String> entry : params.entrySet()) {
            if (!isFirst) {
                hashData.append("&");
            }
            hashData.append(entry.getKey());
            hashData.append("=");
            hashData.append(entry.getValue());
            isFirst = false;
        }
        
        System.out.println("=== HASH DATA ===");
        System.out.println(hashData.toString());
        System.out.println();
        
        String signature = hmacSHA512(hashSecret, hashData.toString());
        System.out.println("=== GENERATED SIGNATURE ===");
        System.out.println(signature);
        System.out.println();
        
        // Expected from your log
        String expected = "f7aaef9b872180671dac9399663a99d81121c4224c40e83e6a7fd2434f7816a00da7bbe266331be442e99c20a742eb930035630248f8efe7131d7809b2a752ff";
        System.out.println("=== EXPECTED SIGNATURE ===");
        System.out.println(expected);
        System.out.println();
        
        System.out.println("=== MATCH ===");
        System.out.println(signature.equals(expected));
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
}
