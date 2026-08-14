package com.dsproject.account.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.dsproject.account.model.Role;

public interface RoleRepository extends JpaRepository<Role, Long>{
}
