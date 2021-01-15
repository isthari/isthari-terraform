var AWS = require("aws-sdk")

const https = require('https')
const http = require('http')
const axios = require('axios')
var isthariServer = "https://saas.isthari.com";

function containsKey(object, key) {
  return !!Object.keys(object).find(k => k.toLowerCase() === key.toLowerCase());
}

function createAuthenticateResponse() {
    return {
        statusCode: 401,
        headers: {
            "WWW-AUTHENTICATE" : "Basic realm='presto server'"
        }
    }
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
        if (headers.Authorization == null && headers.authorization == null) {
            console.log("no authorization header")
            return {
                statusCode: 401,
                headers: {
                    "WWW-Authenticate": "Basic realm=\"User Visible Realm\""
                }
            }
        }
        
        var authorization = null
        if (headers.Authorization != null){
            authorization = headers.Authorization
        } else {
            authorization = headers.authorization
        }
        return checkOrDeploy(authorization, shortId)
            .then(function(){
                return getHostname(authorization, shortId)
            })
            .then(function(hostname){
                return v1call(path, method, headers, origin, queryStringParameters, body, hostname, 0)
            })
    }
}

let checkOrDeploy = (authorization, shortId) => {
    var headers = {
        "Authorization" : authorization
    }
    return new Promise((resolve, reject) => {
        // TODO coger el cluster id del hostname
        axios({
            method: "GET",
            url: isthariServer + "/api/deployer-manager/deployer/checkOrDeployByShortId/"+shortId,
            headers: headers,
            timeout: 10000
        }).then(function(response){
            resolve(response)
        }).catch(function(error){
            console.log("failure in authentication 1");
            console.log ("Server "+isthariServer)
            reject(error)
        })
    })
}

let getHostname = (authorization, shortId) => {
    return new Promise((resolve, reject) =>
    {
        var headers = {
            "Authorization" : authorization
        }
        axios({
            method: "GET",
            url: isthariServer + "/api/deployer-manager/deployer/getHostnameByShortId/"+shortId+"/master",
            headers: headers,
            timeout: 10000
        }).then(function(response){
            console.log("Retrieved hostname "+response.data)
            console.log(response.data)
            resolve(response.data)
        }).catch(function(error){
            console.log("failure in authentication 2");
            reject(error)
        })
    })
}


let v1call = (path, method, headers, origin, queryStringParameters, body, hostname, tries) => {
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
        
        axios({
            method: method,
            url: finalUrl,
            headers: headers,
            data: body,
            timeout: 10000
        })
        .then(function(response){
            var headersOut = response.headers;
            headersOut["Access-Control-Allow-Origin"] = origin
            
            var body;
            if (path.startsWith("/ui")) {
            	body = response.data;
            } else {
            	if (response.data.nextUri) {
            		response.data.nextUri = response.data.nextUri.replace("http://"+hostname+":8080", "https://presto-master-cj7lmfbcet.sncc0rnbbo.cloud.isthari.com");
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
                        resolve(v1call(path, method, headers, origin, queryStringParameters, body, hostname, 0))
                    } else {
                        reject(error)
                    }
                }, 100);
        })
    })
}

