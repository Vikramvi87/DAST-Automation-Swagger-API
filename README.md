# DAST Scan (AppScan on Cloud) Automation in Swagger API (OAS 2 and 3)
<br>
Using this script you can create a Automation where there is a API Swagger (Open API Spec 2 and 3) and there is the Swagger properties file. We get Swagger properties file and convert it using openapi2postmanv2 (https://github.com/postmanlabs/openapi-to-postman) to a Collection File and run the api calls (endpoint) with Newman (https://github.com/postmanlabs/newman).<br>
<br>
We can do that inside a Container image or through a Bash Script.
<br>
Steps after instantiate the container image:<br>
1 - Download json swagger<br>
2 - Convert json swagger to postman collection<br>
3 - Start the proxy server<br>
4 - Run newmann against collection<br>
5 - Stop proxy<br>
6 - Get manual explorer file from proxy server<br>
7 - Upload to asoc manual explorer file and scan template (scantdomfilteringfalse.scant)<br>
8 - Start scan<br>
9 - Wait scan finish<br>
10 - Get report<br>
