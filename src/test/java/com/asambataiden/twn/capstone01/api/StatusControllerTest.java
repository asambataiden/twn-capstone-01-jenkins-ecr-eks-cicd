package com.asambataiden.twn.capstone01.api;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class StatusControllerTest {
    private final StatusController controller = new StatusController();

    @Test
    void returnsServiceStatus() {
        assertThat(controller.status())
            .containsEntry("service", "twn-capstone-01")
            .containsEntry("status", "ok");
    }
}
