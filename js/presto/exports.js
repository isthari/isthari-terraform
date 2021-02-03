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
    
    var origin = checkOrigin(headers);
    
    var optionsCheck = checkOptions(method, origin);
    if (optionsCheck != null){
        return optionsCheck;
    }
    
    var staticContentCheck = checkStaticContent(path)
    if (staticContentCheck != null){
        return staticContentCheck
    }
    
    var pathCheck = checkPath(path);
    if (pathCheck != null){
        return pathCheck;
    }
        
    var securityCheck = checkSecurity(headers);
    if (securityCheck != null){
        return securityCheck;
    }
        
    return getHostname(headers, shortId, path)
    	.then(function(hostname){
    	    return checkRunning(hostname);
    	})
        .then(function(hostname){
            return v1call(path, method, headers, origin, queryStringParameters, body, hostname, host, 0)
        })
}

function checkOrigin(headers) {
    var origin = "https://saas.isthari.com";
    if (headers.origin!=null && headers.origin.startsWith("http://localhost")) {
        origin = headers.origin;
    } else {
        origin = "https://saas.isthari.com"
    }
    return origin;
}

function checkOptions(method, origin) {
    if (method == "OPTIONS") {
        return {
            statusCode: 204,
            headers: {
                "Access-Control-Allow-Origin" : origin,
                "Access-Control-Allow-Methods": "POST, GET, OPTIONS",  
                "Access-Control-Allow-Headers": "*"
            },
            body: "OK"
        }  
    }
}

function checkStaticContent(path) {
    // TODO get version from server
    if (path.startsWith("/ui/dist")) {
        path = path.replace("/ui/dist","");
	redirectUrl = "https://saas-content.isthari.com/content/presto/350"+path;
	console.log("static content redirect url: "+redirectUrl);
	return {
            statusCode: 301,
	    headers: {
	        "Location": redirectUrl
	    },
	    body: "OK"
        }
    }
}

function checkPath(path) {
    if (path.length==0 
      || path=='/'
      || path=='/ui') {
        return {
            statusCode: 301,
	    headers: {
	        "Location": "/ui/"
	    },
	    body: "OK"
        }
    }
}

function checkSecurity(headers) {
    	var cookies = getCookiesFromHeader(headers);
    	var accessToken = cookies["access_token"];
    	if (accessToken != null) {
    	    console.log("authorize with access_token cookie");
    	    headers.authorization = "Bearer "+accessToken;
    	}

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

function getCookiesFromHeader(headers) {

    if (headers === null || headers === undefined || headers.cookie === undefined) {
        return {};
    }

    // Split a cookie string in an array
    var list = {}
    var rc = headers.cookie;
   
    rc && rc.split(';').forEach(function( cookie ) {
        var parts = cookie.split('=');
        var key = parts.shift().trim()
        var value = decodeURI(parts.join('='));   
        if (key != '') {
            list[key] = value
        }
    });

    return list;
};

let getHostname = (originalHeaders, shortId, path) => {
    return new Promise((resolve, reject) =>
    {
        var headers = {
            "Authorization" : originalHeaders.authorization
        }
        
        var deploy = (path.startsWith("/ui") || path.startsWith("/favicon"))?false: true;
        console.log(path + " force deploy "+deploy);
        
        axios({
            method: "GET",
            url: isthariServer + "/api/deployer-manager/deployer/getHostnameByShortId/"+shortId+"/master?deploy="+deploy,
            headers: headers,
            timeout: 10000
        }).then(function(response){
            console.log("Retrieved hostname "+response.data.privateIp)
            resolve(response.data.privateIp)
        }).catch(function(error){
            console.log("failure in authentication");
            reject(error)
        })
    })
}

let checkRunning = (hostname) => {
    return new Promise((resolve, reject) =>
    {
        axios({
            method: "GET",
            url: "http://"+hostname+":8080/ui/api/query",
            timeout: 10000
        }).then(function(response){
            console.log("Status running");
            resolve(hostname)
        }).catch(function(error){
            console.log("Starting");
            setTimeout(function(){
                resolve(checkRunning(hostname));
            }, 1000);
        })
    })
}

let v1call = (path, method, headers, origin, queryStringParameters, body, hostname, originalHost, tries) => {
    return new Promise((resolve, reject) => {
    
        var finalUrl = "http://"+hostname+":8080"+path        
        var temp = ""
        Object.keys(queryStringParameters).forEach(function (key){
            console.log(key)
            if (temp.length > 0){
               temp += "&"
            }
            temp += key+"="+queryStringParameters[key]
        })
        finalUrl = finalUrl + "?" + temp
        console.log("final url "+finalUrl)
        
        //console.log("pre modify request headers");
        //console.log(headers);
        
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
            		response.data.infoUri = response.data.infoUri.replace("http://"+hostname+":8080", "https://"+originalHost);
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
            
            var response = error.response            	
            if (response!=null && response.status >= 400) {
                console.log("error fail fast "+ response.status);
            	 var output = {
                    statusCode: response.status,
                    headers: response.headers,
                    body: response.data             
                }
                console.log(output)
                resolve(output)
            } else {                       
                setTimeout(function() {        	            	
                    if(tries<300) {
                        resolve(v1call(path, method, headers, origin, queryStringParameters, body, hostname, originalHost, 0))
                    } else {
                        reject(error)
                    }
                }, 1000);
            }
        })
    })
}

