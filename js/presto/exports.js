var AWS = require("aws-sdk")

const https = require('https')
const http = require('http')
const axios = require('axios')
var isthariServer = "https://saas.isthari.com";

function containsKey(object, key) {
  return !!Object.keys(object).find(k => k.toLowerCase() === key.toLowerCase());
}



exports.handler = async (event) => {
    console.log(event)
    var path = event.path
    var method = event.httpMethod
    var headers = event.headers
    var body = event.body
    var queryStringParameters = event.queryStringParameters
    
    var host = headers.host;
    var hostSplit = host.split(".")
    var shortId = hostSplit[0].replace("presto-master-", "")
    
    delete headers["x-forwarded-for"]
    
    var origin = "https://saas.isthari.com";
    if (headers.origin=="http://localhost:5001"){
        origin = "http://localhost:5001"
    } else {
        origin = "https://saas.isthari.com"
    }
    
    if (method == "OPTIONS") {
      return {
          statusCode: 204,
          headers: {
              "Access-Control-Allow-Origin" : origin,
              "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
              // authorization,x-presto-catalog,x-presto-schema,x-presto-user
              "Access-Control-Allow-Headers": "*"
          },
          body: "OK"
      }  
    } else {
        if (path.startsWith("/ui/dist")) {
          path = path.replace("/ui/dist","");
	  redirectUrl = "https://saas-content.isthari.com/content/presto/350"+path;
	  console.log("redirect url: "+redirectUrl);
	  return {
              statusCode: 301,
	      headers: {
	          "Location": redirectUrl
	      },
	      body: "OK"
	   }
        }

    var securityCheck = checkSecurity(headers);
    if (securityCheck != null){
        return securityCheck;
    }
        
        return getHostname(headers, shortId)
            .then(function(hostname){
                return v1call(path, method, headers, origin, queryStringParameters, body, hostname, host, 0)
            })
    }
}

function checkSecurity(headers) {
    if (headers.authorization == null) {
        console.log("no authorization header")
        return {
            statusCode: 401,
                headers: {
                    "WWW-Authenticate": "Basic realm=\"User Visible Realm\""
                }
        }
    }    
}

let getHostname = (originalHeaders, shortId) => {
    return new Promise((resolve, reject) =>
    {
        var headers = {
            "Authorization" : originalHeaders.authorization
        }
        axios({
            method: "GET",
            url: isthariServer + "/api/deployer-manager/deployer/getHostnameByShortId/"+shortId+"/master?deploy=true",
            headers: headers,
            timeout: 10000
        }).then(function(response){
            console.log("Retrieved hostname "+response.data)
            console.log(response.data)
            resolve(response.data.privateIp)
        }).catch(function(error){
            console.log("failure in authentication 2");
            reject(error)
        })
    })
}


let v1call = (path, method, headers, origin, queryStringParameters, body, hostname, originalHost, tries) => {
    return new Promise((resolve, reject) => {
        var finalUrl = "http://"+hostname+":8080"+path
        
        console.log("---")
        var temp = ""
        Object.keys(queryStringParameters).forEach(function (key){
            console.log(key)
            if (temp.length > 0){
               temp += "&"
            }
            temp += key+"="+queryStringParameters[key]
        })
        console.log(temp)
	console.log("***")
        finalUrl = finalUrl + "?" + temp
        console.log("final url "+finalUrl)
        
        console.log("pre modify request headers");
        console.log(headers);
        
        delete headers.authorization
        delete headers.Authorization
        delete headers.host
        headers.host = hostname+":8080"
        
        request = {
            method: method,
            url: finalUrl,
            headers: headers,
            data: body,
            timeout: 10000
        };
        
        if (path.startsWith("/ui") && !path.startsWith("/ui/api")) {
            request.responseType = 'blob'
        }
        
        axios(request)
        .then(function(response){
            var headersOut = response.headers;
            headersOut["Access-Control-Allow-Origin"] = origin
            
            var body;
            if (path.startsWith("/ui") && !path.startsWith("/ui/api")) {            	           
            	body = response.data;
            } else {
            	if (response.data.nextUri) {
            		console.log("original next uri: "+response.data.nextUri);
            		console.log("original host: "+originalHost);
            		response.data.nextUri = response.data.nextUri.replace("http://"+hostname+":8080", "https://"+originalHost);
            		console.log("changed next uri "+response.data.nextUri);
            	}
            
            	body = JSON.stringify(response.data)
            }
            var output = {
                statusCode: response.status,
                headers: headersOut,
                body: body             
            }
            console.log(output)
            resolve(output)
        })
        .catch(function(error){
            console.log("error call to presto backend")
            console.log(error);
            setTimeout(function() {
                    if(tries<300) {
                        resolve(v1call(path, method, headers, origin, queryStringParameters, body, hostname, originalHost, 0))
                    } else {
                        reject(error)
                    }
                }, 1000);
        })
    })
}

