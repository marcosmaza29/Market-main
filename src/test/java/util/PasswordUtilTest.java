package util;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class PasswordUtilTest {
    @Test
    void hashVerificaContrasenaCorrecta() {
        String hash = PasswordUtil.hashPassword("ClaveDePrueba123!");
        assertNotEquals("ClaveDePrueba123!", hash);
        assertTrue(PasswordUtil.checkPassword("ClaveDePrueba123!", hash));
        assertFalse(PasswordUtil.checkPassword("incorrecta", hash));
    }
}
