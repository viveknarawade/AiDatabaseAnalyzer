package org.TaskManager.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.TaskManager.entity.UserEntity;
import org.TaskManager.repository.AuthRepo;
import org.TaskManager.service.impl.JwtService;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.web.servlet.HandlerExceptionResolver;

import java.io.IOException;

@Component
@RequiredArgsConstructor
@Slf4j
public class JwtFilter extends OncePerRequestFilter {


    private final AuthRepo authRepo;
    private final JwtService jwtService;
    private final HandlerExceptionResolver handlerExceptionResolver;


    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain) throws ServletException, IOException {
       try {
           log.info("Incoming request: {}", request.getRequestURI());

           final String requestTokenHeader = request.getHeader("Authorization");

           if (requestTokenHeader == null || !requestTokenHeader.startsWith("Bearer ")) {
               filterChain.doFilter(request, response);
               return;
           }

           String token = requestTokenHeader.substring(7);
           String email = jwtService.getEmailFromToken(token);

           if (email != null && SecurityContextHolder.getContext().getAuthentication() == null) {

               UserEntity user = authRepo.findByEmail(email)
                       .orElseThrow(() -> new UsernameNotFoundException("User not found"));

               UsernamePasswordAuthenticationToken authToken = new UsernamePasswordAuthenticationToken(
                       user,
                       null,
                       java.util.Collections.emptyList()
               );


               authToken.setDetails(new org.springframework.security.web.authentication.WebAuthenticationDetailsSource().buildDetails(request));


               SecurityContextHolder.getContext().setAuthentication(authToken);
           }

           filterChain.doFilter(request, response);
       }catch (Exception ex){
           handlerExceptionResolver.resolveException(request,response,null,ex);
       }
    }
}
