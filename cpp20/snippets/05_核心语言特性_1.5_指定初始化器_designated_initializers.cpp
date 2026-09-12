struct Point {
    int x, y, z;
};

Point p {.y = 10, .x = 5}; // x=5, y=10, z=0

struct Config {
    std::string host;
    int port;
    bool secure;
};

Config cfg {
    .host = "localhost",
    .port = 8080,
    .secure = true
};
