package com.project.spring.service.master;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.function.Function;

@Service
public class JWTService {

    // Secure Base64-encoded 256-bit secret key
    private final String secretKey = "qZqPYt9/4p4j2bsk7Lc2XqBZv7T9vMxI3Fo7KZs8mvQ=";

    // 🔐 Generate JWT token with claims: username (subject), role, id
    public String generateToken(String userName, String role, String dbName) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("role", role);
        claims.put("dbName", dbName);

        return Jwts.builder()
                .claims(claims)
                .subject(userName)
                .issuedAt(new Date(System.currentTimeMillis()))
                .expiration(new Date(System.currentTimeMillis() + 1000L * 60 * 60 * 24 * 30)) // 10 hours
                .signWith(getSigningKey())
                .compact();
    }

    // ✅ Extract username (subject) from JWT
    public String extractUserName(String token) {
        return extractClaim(token, Claims::getSubject);
    }

    // ✅ Extract role from JWT
    public String extractUserRole(String token) {
        return extractClaim(token, claims -> claims.get("role", String.class));
    }

    // ✅ Extract user ID (primary key) from JWT
    public String extractdbName(String token) {
        return extractClaim(token, claims -> claims.get("dbName", String.class));
    }

    // ✅ Check if token is valid and not expired
    public boolean validateToken(String token, UserDetails userDetails) {
        final String username = extractUserName(token);
        return username.equals(userDetails.getUsername()) && !isTokenExpired(token);
    }
    // ✅ Validate token without needing UserDetails
    public boolean isTokenValid(String token) {
        try {
            return !isTokenExpired(token);
        } catch (Exception e) {
            return false;
        }
    }

    // ===== INTERNAL HELPERS =====

    private boolean isTokenExpired(String token) {
        return extractExpiration(token).before(new Date());
    }

    private Date extractExpiration(String token) {
        return extractClaim(token, Claims::getExpiration);
    }

    private <T> T extractClaim(String token, Function<Claims, T> claimResolver) {
        final Claims claims = extractAllClaims(token);
        return claimResolver.apply(claims);
    }

    private Claims extractAllClaims(String token) {
        return Jwts.parser()
                .verifyWith(getSigningKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    private SecretKey getSigningKey() {
        byte[] keyBytes = Decoders.BASE64.decode(secretKey);
        return Keys.hmacShaKeyFor(keyBytes);
    }
}
