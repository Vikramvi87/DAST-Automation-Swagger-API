# DAST Scan (AppScan on Cloud) Automation in Swagger API (OAS 2 and 3)

Using this script you can create a Automation where there is a API Swagger (Open API Spec 2 and 3) and there is the Swagger properties file. We get Swagger properties file and convert it using openapi2postmanv2 (https://github.com/postmanlabs/openapi-to-postman) to a Collection File and run the api calls (endpoint) with Newman (https://github.com/postmanlabs/newman).

We can do that inside a Container image or through a Bash Script.

Steps after instantiate the container image:
1 - Download json swagger
2 - Convert json swagger to postman collection
3 - Start the proxy server
4 - Run newmann against collection
5 - Stop proxy
6 - Get manual explorer file from proxy server
7 - Upload to asoc manual explorer file and scan template (scantdomfilteringfalse.scant)
8 - Start scan
9 - Wait scan finish
10 - Get report
