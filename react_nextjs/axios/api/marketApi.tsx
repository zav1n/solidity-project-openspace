import request from "../index";
export const getSignature = (data: unknown) => request({
  url: "/sign",
  method: "post",
  data
})
export const addWhiteList = (data: unknown) =>
  request({
    url: "/addWhitelist",
    method: "post",
    data
  });