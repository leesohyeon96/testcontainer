package com.shl.testcontainer.dao;

import com.shl.testcontainer.entity.User;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

import java.util.List;

@Mapper
public interface UserDao {
    @Select("SELECT * FROM user")
    List<User> findAll();
}
