package com.salesapp;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import java.util.TimeZone;

@SpringBootApplication
public class SalesAppApplication {

    public static void main(String[] args) {
        // Set default timezone to Vietnam for VNPay compatibility
        TimeZone.setDefault(TimeZone.getTimeZone("Asia/Ho_Chi_Minh"));
        System.out.println("Application timezone set to: " + TimeZone.getDefault().getID());
        
        SpringApplication.run(SalesAppApplication.class, args);
    }

}
