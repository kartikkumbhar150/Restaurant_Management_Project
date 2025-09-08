package com.project.spring.service.master;

import com.project.spring.model.master.StaffUser;
import com.project.spring.model.master.StaffUserPrincipal;
import com.project.spring.repo.master.StaffUserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

@Service
public class MyStaffUserDetailsService implements UserDetailsService{
    
    @Autowired
    private StaffUserRepository userRepo;
    
    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        StaffUser user = userRepo.findByUserName(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + username));

        return new StaffUserPrincipal(user); //  Returning correct principal class
    }
}
