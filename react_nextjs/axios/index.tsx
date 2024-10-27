import axios, { AxiosInstance, AxiosResponse, InternalAxiosRequestConfig } from "axios";

const request: AxiosInstance = axios.create({
  baseURL: process.env.REACT_APP_API_BASE_URL || "http://localhost:8001",
  timeout: 10000
});

// 请求拦截器
request.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    const token = localStorage.getItem("token");
    if (token) {
        if (!config.headers) {
            config.headers = new axios.AxiosHeaders();
        }
        config.headers["Authorization"] = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    // 对请求错误做些什么
    return Promise.reject(error);
  }
);

// 响应拦截器
request.interceptors.response.use(
  (response: AxiosResponse) => {
    return response.data;
  },
  (error) => {
    if (error.response) {
      switch (error.response.status) {
        case 401:
          break;
        case 403:
          break;
        case 404:
          break;
        // deal with other status codes
      }
    }
    return Promise.reject(error);
  }
);

export default request;
