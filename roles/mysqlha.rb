name "mysqlha"
description "MySQL with HA"
run_list (
    [
        "recipe[mysql::ha]",
    ]
)
default_attributes ({
        "php_memory_limit" => "512M",
        "dev_user" => "vagrant"
})