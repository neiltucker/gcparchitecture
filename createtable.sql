create database if not exists db1;
use db1;

drop table if exists employees;

create table employees (
  companyid VARCHAR(255), 
  lastname VARCHAR(255), 
  firstname VARCHAR(255), 
  hiredate DATE, 
  salary INT, 
  fullname VARCHAR(255)
);

