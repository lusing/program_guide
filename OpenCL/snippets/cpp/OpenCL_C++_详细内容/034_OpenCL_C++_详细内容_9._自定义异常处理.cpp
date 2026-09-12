class OpenCLError : public std::runtime_error {
public:
    OpenCLError(cl_int error, const std::string& msg)
        : std::runtime_error(msg + " (Error code: " + std::to_string(error) + ")"),
          errorCode(error) {}

    cl_int getErrorCode() const { return errorCode; }

private:
    cl_int errorCode;
};

// 使用宏简化错误处理
#define CL_CHECK(err) \
    do { \
        cl_int err_code = (err); \
        if (err_code != CL_SUCCESS) { \
            throw OpenCLError(err_code, "OpenCL error at " + std::string(__FILE__) + ":" + std::to_string(__LINE__)); \
        } \
    } while(0)
