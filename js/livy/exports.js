var AWS = require("aws-sdk")

const https = require('https')
const http = require('http')
const axios = require('axios')
var isthariServer = "https://saas.isthari.com";

var mainHost = "saas.isthari.com"

exports.handler = async (event) => {
    console.log(event)
    
    var path = event.path
    var method = event.httpMethod
    var headers = event.headers
    var body = event.body
    var queryStringParameters = event.queryStringParameters
    
    var host = headers.host;
    var hostSplit = host.split(".")
    var shortId = hostSplit[0].replace("livy-master-", "")
    console.log("shortId: "+shortId)
    
    delete headers["x-forwarded-for"]
    
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
            return v1call(path, method, headers, "origin_null", queryStringParameters, body, hostname, host, 0)
        })        
}

// old and further beyond
function checkStaticContent(path) {
    // TODO get version from server
/*    if (path.startsWith("/ui/dist")) {
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
    }*/
}

function checkPath(path) {
    if (path.length==0 
      || path=='/') {
        return {
            statusCode: 301,
	    headers: {
	        "Location": "/ui"
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
                    "WWW-Authenticate": "Basic realm=\"Isthari\""
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
        
        // TODO check force deploy
        var deploy = (path.startsWith("/ui") || path.startsWith("/favicon"))?false: true;
        console.log(path + " force deploy "+deploy);
        
        axios({
            method: "GET",
            url: isthariServer + "/api/deployer-manager/deployer/getHostnameByShortId/"+shortId+"/livy?deploy="+deploy,
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
	resolve(hostname)
/*        axios({
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
        })*/
    })
}

let v1call = (path, method, headers, origin, queryStringParameters, body, hostname, originalHost, tries) => {
	return new Promise((resolve, reject) => {
        var finalUrl = "http://"+hostname+":8998"+path
        console.log("final url "+finalUrl)
        axios({
                method: method,
                url: finalUrl,
                headers: headers,
                data: body,
                timeout: 1000
            })
            .then(function(response) {
                var body;
                
                if (path.startsWith("/ui") || path.startsWith("/static")){
                    body = response.data
                } else {
	            body = JSON.stringify(response.data)
                }
                
                var output = {
                    statusCode: response.status,
                    headers: response.headers,
                    body: body
                }
                console.log(output)
                resolve(output)
            })
            .catch(function(error){
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
                    console.log(error)
                    console.log("retry "+tries)
                    setTimeout(function() {
                        if(tries<300) {
                            resolve(v1call(path, method, headers, origin, queryStringParameters, body, hostname, originalHost, tries+1))
                        } else {
                            reject(error)
                        }
                    }, 1000);
                }
            })
    })
}


