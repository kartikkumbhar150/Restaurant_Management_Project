package com.project.spring.config;

import com.project.spring.model.master.StaffUser;
import com.project.spring.repo.master.StaffUserRepository;
import com.project.spring.service.master.JWTService;
import com.project.spring.service.master.MyStaffUserDetailsService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
public class JwtFilter extends OncePerRequestFilter {

    @Autowired
    private JWTService jwtService;

    @Autowired
    private MyStaffUserDetailsService userDetailsService;

    @Autowired
    private StaffUserRepository staffUserRepository; // ✅ Needed to fetch DB user and token

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain)
            throws ServletException, IOException {

        String authHeader = request.getHeader("Authorization");
        String token = null;
        String username = null;
        String dbName = null;

        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            token = authHeader.substring(7);
            try {
                username = jwtService.extractUserName(token);
                dbName = jwtService.extractdbName(token);

                System.out.println("Token: " + token);
                System.out.println("Username extracted: " + username);
                System.out.println("Tenant DB extracted from token: " + dbName);

                // ✅ Set tenant context before DB/auth
                if (dbName != null) {
                    TenantContext.setCurrentTenant(dbName);
                } else {
                    TenantContext.setCurrentTenant("master");
                }
            } catch (Exception e) {
                System.out.println("Invalid token: " + e.getMessage());
            }
        } else {
            System.out.println("Authorization header missing or invalid: " + authHeader);
        }

        try {
            if (username != null && SecurityContextHolder.getContext().getAuthentication() == null) {
                StaffUser dbUser = staffUserRepository.findByUserName(username).orElse(null);

                if (dbUser != null && jwtService.isTokenValidForUser(token, dbUser)) {
                    // ✅ Use DB user for validation (ensures only latest token works)
                    UserDetails userDetails = userDetailsService.loadUserByUsername(username);

                    UsernamePasswordAuthenticationToken authToken =
                            new UsernamePasswordAuthenticationToken(
                                    userDetails, null, userDetails.getAuthorities());

                    authToken.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                    SecurityContextHolder.getContext().setAuthentication(authToken);
                } else {
                    System.out.println("Token invalid or not matching DB stored token");
                }
            }

            filterChain.doFilter(request, response);

        } finally {
            // ✅ Always clear tenant after request
            TenantContext.clear();
        }
    }
}
