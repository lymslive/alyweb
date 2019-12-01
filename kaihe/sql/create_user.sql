create user kaihe identified by '0xKaiHe';
grant all on db_kaihe.* to kaihe;
grant all on db_kaihe_test.* to kaihe;

create user kaihe@localhost identified by '0xKaiHe';
grant all on db_keihe_test.* to kaihe@localhost;

flush privileges;

