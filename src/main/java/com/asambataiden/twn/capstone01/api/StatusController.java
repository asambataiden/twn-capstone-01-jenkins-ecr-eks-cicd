package com.asambataiden.twn.capstone01.api;

import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class StatusController {
    @GetMapping("/api/status")
    public Map<String, String> status() {
        return Map.of("service", "twn-capstone-01", "status", "ok");
    }
}
