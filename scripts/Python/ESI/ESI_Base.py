import hashlib
import json
import time
import requests
import email

class Base:

    defaultSuccessCodes = [200, 204]

    def hashRequest(self, url, method, payload, accessToken):
    
        hashingDict = {
            "URL": url, 
            "Method": method, 
            "Payload": payload, 
            "Authentication": accessToken
        }
        
        hashingData = str.encode(
            json.dumps(hashingDict, separators=(",", ":"))
        )
        
        return hashlib.sha256(hashingData).hexdigest()
        
    def cleanupCache(self):
    
        databaseCursor = self.databaseConnection.cursor(buffered=True)
    
        cleanupStatement = "DELETE FROM esicache WHERE expiration <= %s"
        currentTime = int(time.time())
        
        databaseCursor.execute(cleanupStatement, (currentTime,))
        
        self.databaseConnection.commit()
        databaseCursor.close()
        
    def checkCache(self, endpoint, hash):
    
        databaseCursor = self.databaseConnection.cursor(buffered=True)
    
        checkStatement = "SELECT response FROM esicache WHERE endpoint=%s AND hash=%s AND expiration > %s"
        currentTime = int(time.time())
        
        databaseCursor.execute(checkStatement, (endpoint, hash, currentTime))
        
        result = False
        
        for (response, ) in databaseCursor:
        
            result = json.loads(response)
        
        databaseCursor.close()
        
        return result
        
    def populateCache(self, endpoint, hash, response, expires):
    
        databaseCursor = self.databaseConnection.cursor(buffered=True)
    
        insertStatement = "INSERT INTO esicache (endpoint, hash, expiration, response) VALUES (%s, %s, %s, %s)"
        
        databaseCursor.execute(insertStatement, (endpoint, hash, expires, response))
        
        self.databaseConnection.commit()
        databaseCursor.close()
        
 def makeRequest(
    self, 
    endpoint, 
    url, 
    method = "GET", 
    payload = None, 
    accessToken = None, 
    expectResponse = True, 
    successCodes = [], 
    cacheTime = 0, 
    retries = 0
):
    responseData = {"Success": False, "Data": None}

    self.cleanupCache()

    # 计算用于缓存的哈希（保持和原来哈希逻辑一致）
    request_hash = self.hashRequest(url, method, payload, accessToken)

    cacheCheck = self.checkCache(endpoint, request_hash)
    if cacheCheck != False:
        responseData["Success"] = True
        responseData["Data"] = cacheCheck
        return responseData

    # 准备请求参数：使用 requests 的 json= 参数更清晰（requests 会序列化）
    for retryCounter in range(retries + 1):
        try:
            requestMethod = getattr(requests, method.lower())
            headers = {"accept": "application/json"}

            if accessToken is not None:
                headers["Authorization"] = "Bearer " + accessToken

            # 使用 json 参数，如果 payload 为 None 则不传
            if payload is not None:
                request = requestMethod(url=url, json=payload, headers=headers, timeout=30)
            else:
                request = requestMethod(url=url, headers=headers, timeout=30)

        except Exception as e:
            # 网络/连接异常：记录并在允许的重试内继续
            last_exception = e
            continue

        # 成功 HTTP 响应处理
        if request.status_code in (self.defaultSuccessCodes + successCodes):
            responseData["Success"] = True

            # 如果不期望返回体（e.g. expectResponse=False），直接成功返回
            if not expectResponse:
                # 将响应体（可能为空）写入缓存以避免重复请求
                try:
                    raw_text = request.text if hasattr(request, "text") else ""
                    self.populateCache(endpoint, request_hash, raw_text, int(time.time()) + cacheTime)
                except Exception:
                    pass
                return responseData

            # 处理有可能为空的响应体（比如 204）
            raw_text = request.text if hasattr(request, "text") else ""
            if not raw_text:
                # 没有响应体，返回 Success=True, Data=None
                responseData["Data"] = None
            else:
                try:
                    responseData["Data"] = json.loads(raw_text)
                except Exception:
                    # 无法解析为 JSON（可能是 HTML 错误页），把原始文本放入 Data 或把调用视为失败
                    responseData["Data"] = raw_text

            # 缓存：把原始文本写入数据库（字符串），checkCache 会 json.loads 取出
            try:
                # 计算过期时间，优先使用响应头的 Expires
                if "Expires" in request.headers:
                    expiryDatetime = email.utils.parsedate_to_datetime(request.headers["Expires"])
                    expiry = int(expiryDatetime.timestamp())
                else:
                    expiry = int(time.time()) + cacheTime

                self.populateCache(endpoint, request_hash, raw_text, expiry)
            except Exception:
                pass

            return responseData

        else:
            # 非成功 HTTP code，继续重试或退出循环
            last_status = request.status_code
            last_response_text = getattr(request, "text", "")
            # 继续重试（如果 retryCount 还没耗尽）
            continue

    # 如果循环结束仍没成功，把最后的错误信息放回（或抛出）
    responseData["Success"] = False
    responseData["Data"] = {
        "error": "Request failed",
        "last_exception": str(last_exception) if 'last_exception' in locals() else None,
        "last_status": locals().get("last_status", None),
        "last_response": locals().get("last_response_text", None)
    }
    return responseData
