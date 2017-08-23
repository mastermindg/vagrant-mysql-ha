name "mysqldefault"
description "Default MySQL Role - No HA"
run_list (
    [
        "recipe[mysql::default]",
    ]
)
default_attributes ({
        "php_memory_limit" => "512M",
        "dev_user" => "vagrant"
})