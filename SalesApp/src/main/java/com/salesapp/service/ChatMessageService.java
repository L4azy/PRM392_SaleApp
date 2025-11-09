package com.salesapp.service;

import com.salesapp.dto.request.ChatMessageRequest;
import com.salesapp.dto.response.ChatMessageResponse;
import com.salesapp.dto.response.CustomerUserResponse;
import com.salesapp.entity.ChatMessage;
import com.salesapp.entity.Gemini;
import com.salesapp.entity.User;
import com.salesapp.enums.RoleEnum;
import com.salesapp.mapper.ChatMessageMapper;
import com.salesapp.repository.ChatMessageRepository;
import com.salesapp.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ChatMessageService {

    private final ChatMessageRepository chatMessageRepository;
    private final UserRepository userRepository;
    private final ChatMessageMapper chatMessageMapper;
    private final SimpMessagingTemplate messagingTemplate;
    private final GeminiService geminiService;
    private final GeminiTrainingService geminiTrainingService;
    private final SmartAIService smartAIService;

    private static final Integer AI_USER_ID = 23;

    public ChatMessageResponse sendMessage(ChatMessageRequest request) {
        // Validate input
        if (request.getMessage() == null || request.getMessage().trim().isEmpty()) {
            throw new RuntimeException("Message cannot be empty");
        }

        User sender = userRepository.findById(request.getUserID())
                .orElseThrow(() -> new RuntimeException("User not found: " + request.getUserID()));

        User receiver = userRepository.findById(request.getReceiverID())
                .orElseThrow(() -> new RuntimeException("Receiver not found: " + request.getReceiverID()));

        // 🔵 Lưu tin nhắn người gửi
        ChatMessage message = new ChatMessage();
        message.setUserID(sender);
        message.setReceiver(receiver);
        message.setMessage(request.getMessage().trim());
        message.setSentAt(Instant.now());
        message.setFromAI(false);
        message.setForwardedToHuman(false);

        ChatMessage savedMessage = chatMessageRepository.save(message);

        // 🔁 Nếu gửi tới AI → phản hồi tự động với Smart AI (có khả năng call API)
        if (receiver.getId().equals(AI_USER_ID)) {
            try {
                // Use Smart AI service để get response với real-time API data
                Gemini aiReply = smartAIService.getSmartResponse(request.getMessage());

                ChatMessage aiMessage = new ChatMessage();
                aiMessage.setUserID(receiver);        // AI gửi
                aiMessage.setReceiver(sender);        // Gửi lại cho user
                aiMessage.setMessage(aiReply.getReply());
                aiMessage.setSentAt(Instant.now());
                aiMessage.setFromAI(true);
                aiMessage.setForwardedToHuman(aiReply.isNeedHuman());

                ChatMessage savedAiMessage = chatMessageRepository.save(aiMessage);

                // Gửi lại cho user qua WebSocket
                messagingTemplate.convertAndSendToUser(
                        String.valueOf(sender.getId()), "/queue/messages", chatMessageMapper.toResponse(savedAiMessage)
                );

                // 🔁 Nếu cần chuyển tiếp cho admin
                if (aiReply.isNeedHuman()) {
                    // Gửi thông báo tới Admin (ví dụ user ID = 1)
                    messagingTemplate.convertAndSendToUser(
                            "1", "/queue/admin", chatMessageMapper.toResponse(savedAiMessage)
                    );
                }
            } catch (Exception e) {
                // If AI fails, send error message to user
                ChatMessage errorMessage = new ChatMessage();
                errorMessage.setUserID(receiver);
                errorMessage.setReceiver(sender);
                errorMessage.setMessage("Xin lỗi, AI Assistant tạm thời không khả dụng. Vui lòng thử lại sau hoặc liên hệ admin để được hỗ trợ.");
                errorMessage.setSentAt(Instant.now());
                errorMessage.setFromAI(true);
                errorMessage.setForwardedToHuman(true);

                ChatMessage savedErrorMessage = chatMessageRepository.save(errorMessage);
                
                messagingTemplate.convertAndSendToUser(
                        String.valueOf(sender.getId()), "/queue/messages", chatMessageMapper.toResponse(savedErrorMessage)
                );
            }
        }

        return chatMessageMapper.toResponse(savedMessage);
    }



    public Map<String, Object> getSeparatedChatHistory(Integer userID) {
        List<ChatMessage> aiMessages = chatMessageRepository.findChatByUserAndRole(userID, RoleEnum.AI);
        List<ChatMessage> adminMessages = chatMessageRepository.findChatByUserAndRole(userID, RoleEnum.ADMIN);
        List<ChatMessage> customerMessages = chatMessageRepository.findChatByUserAndRole(userID, RoleEnum.CUSTOMER);

        Map<String, Object> result = new HashMap<>();
        result.put("aiMessages", aiMessages.stream().map(chatMessageMapper::toResponse).toList());
        result.put("adminMessages", adminMessages.stream().map(chatMessageMapper::toResponse).toList());

        //  Tách từng đoạn chat với từng customer
        Map<Integer, List<ChatMessageResponse>> customerGrouped = customerMessages.stream()
                .collect(Collectors.groupingBy(
                        m -> {
                            //  Xác định từng customer
                            if (m.getUserID().getId().equals(userID)) {
                                return m.getReceiver().getId();
                            } else {
                                return m.getUserID().getId();
                            }
                        },
                        Collectors.mapping(chatMessageMapper::toResponse, Collectors.toList())
                ));

        result.put("customerMessages", customerGrouped);

        return result;
    }

    public List<ChatMessage> getAllMessagesBetweenUsersAndAdminOrAI() {
        return chatMessageRepository.findAllByOrderBySentAtAsc(); // hoặc một hàm tùy chỉnh nếu muốn lọc từ DB
    }

    public List<CustomerUserResponse> getAllCustomerUsersInChat() {
        List<User> customers = chatMessageRepository.findDistinctCustomersWhoSentMessages();
        return customers.stream()
                .map(user -> new CustomerUserResponse(user.getId(), user.getUsername(), user.getEmail()))
                .toList();
    }

}
