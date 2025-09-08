package com.project.spring.config;

import com.project.spring.service.master.JWTService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
public class TenantFilter extends OncePerRequestFilter {

    @Autowired
    private JWTService jwtService;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain)
            throws ServletException, IOException {

        final String authHeader = request.getHeader("Authorization");

        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7); // Remove "Bearer " prefix

            try {
                if (jwtService.isTokenValid(token)) {
                    //Directly extract dbName (tenant ID) from the token
                    String dbName = jwtService.extractdbName(token);

                    if (dbName != null && !dbName.isBlank()) {
                        TenantContext.setCurrentTenant(dbName);
                        System.out.println("Tenant set from token: " + dbName);
                    } else {
                        response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Tenant info missing in token");
                        return;
                    }
                } else {
                    response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Invalid JWT token");
                    return;
                }
            } catch (Exception e) {
                response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Token parsing failed: " + e.getMessage());
                return;
            }
        }

        try {
            filterChain.doFilter(request, response);
        } finally {
            TenantContext.clear(); 
        }
    }
}
