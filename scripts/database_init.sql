drop database if exists 'batch_load' with (force);
create database batch_load;

create schema if not exists control;
create schema if not exists bronze;
create schema if not exists silver;
create schema if not exists gold;
