package com.shl.testcontainer;

import com.shl.testcontainer.dao.UserDao;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

@SpringBootTest
@Testcontainers
class TestcontainerServiceConnectionTests {

    @Container
    // PostgreSQLContainer 타입을 인식해 url/username/password를 Spring DataSource에 자동 주입 (Spring Boot 3.1+)
    @ServiceConnection
    // 자동으로 test/test/test (database/username/password) 로 생성함
    // 커스텀 할 순 있지만, 굳이 testcontainer 로 띄워졌다가 사라지는 걸 할 필요는 없음
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15")
            .withInitScript("init.sql");

    @Autowired
    private UserDao userMapper;

    @Test
    void testMapper() {
        var users = userMapper.findAll();
        System.out.println(users);
    }
}
