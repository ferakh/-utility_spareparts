# SAP Integration Suite Flow

This project uses SAP Integration Suite as the integration layer in front of the CAP `IntegrationService`.

The recommended pattern is:

- Use CAP `IntegrationLogs` for business/integration events that support teams need to see against a spare request.
- Use CPI Message Monitoring, exception subprocesses, and email alerts for technical failures.
- Do not try to write every technical exception back to CAP, because CAP may be the failing dependency.

## Endpoints

Deployed CAP service base:

```text
https://f0f58fb4trial-dev-utility-spareparts-srv.cfapps.ap21.hana.ondemand.com
```

Precheck a spare request:

```text
GET /odata/v4/field-maintenance/SpareRequests(${property.request_ID})
```

Update request status:

```text
POST /odata/v4/integration/updateRequestStatus
```

Record controlled integration events:

```text
POST /odata/v4/integration/recordIntegrationLog
```

Attach a photo to a spare request:

```text
POST /odata/v4/field-maintenance/addRequestPhoto
```

## Main Flow

```text
Sender
-> Groovy: ValidateAndPrepare
-> Request Reply: GET SpareRequests(${property.request_ID})
-> Groovy: ConvertPrecheckResult
-> Router
   -> 200: RestoreOriginalPayload -> POST updateRequestStatus
   -> 404: PrepareNotFoundResponse -> optional POST recordIntegrationLog -> End
   -> Default: PreparePrecheckFailureResponse -> optional POST recordIntegrationLog -> End
Exception Subprocess
-> PrepareExceptionEmail
-> Mail Receiver
-> End
```

Use `recordIntegrationLog` only for controlled business/integration outcomes, such as:

```text
CAP_PRECHECK
SPARE_REQUEST_NOT_FOUND
CAP_PRECHECK_FAILED
STATUS_UPDATE
SUPPLIER_ACKNOWLEDGEMENT
MANUAL_REVIEW_REQUIRED
```

Use email/monitoring for technical exceptions, such as:

```text
OAuth token failure
CAP service unavailable
Timeout
Groovy script exception
SMTP failure
Unexpected HTTP 500
```

## Photo Upload

The first supported upload path is JSON with base64 content. This works well from CPI, Postman, and simple mobile clients.

```http
POST /odata/v4/field-maintenance/addRequestPhoto
Content-Type: application/json
Accept: application/json
```

```json
{
  "request_ID": "7e371e0d-6651-4bfc-8e88-bf829266ca97",
  "fileName": "damaged-pump.jpg",
  "mimeType": "image/jpeg",
  "contentBase64": "/9j/4AAQSkZJRgABAQ...",
  "description": "Photo from field technician"
}
```

The action accepts either raw base64 content or a data URL:

```text
data:image/jpeg;base64,/9j/4AAQSkZJRgABAQ...
```

Validation rules:

```text
request_ID is required
fileName is required
mimeType must start with image/
contentBase64 is required
photo size must be 5 MB or smaller
```

Successful uploads create a `RequestPhotos` record and write a `PHOTO_ATTACHED` entry to `IntegrationLogs`.
New uploads also fill `contentUrl`, which the Fiori Photos table displays as an `Open Image` link.

After upload, the binary image can be downloaded with:

```text
GET /odata/v4/field-maintenance/RequestPhotos(<photo_ID>)/content
```

Example:

```text
GET /odata/v4/field-maintenance/RequestPhotos(11111111-1111-1111-1111-111111111111)/content
```

Photos uploaded before binary content support was added may only have `contentBase64`; re-upload those photos to make the `/content` URL return image bytes.

## ValidateAndPrepare

```groovy
import groovy.json.JsonSlurper

def processData(def message) {
    def body = message.getBody(String)
    def json = new JsonSlurper().parseText(body)

    if (!json.request_ID) {
        throw new IllegalArgumentException("request_ID is required before calling CAP")
    }

    if (!json.status) {
        throw new IllegalArgumentException("status is required before calling CAP")
    }

    def uuidPattern = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/
    if (!(json.request_ID ==~ uuidPattern)) {
        throw new IllegalArgumentException("request_ID must be a valid UUID")
    }

    message.setProperty("originalUpdatePayload", body)
    message.setProperty("request_ID", json.request_ID.toString())

    return message
}
```

## ConvertPrecheckResult

Use this after the `GET SpareRequests(${property.request_ID})` step.

```groovy
import groovy.json.JsonSlurper

def processData(def message) {
    def responseCode = message.getHeader("CamelHttpResponseCode", String)
    def body = message.getBody(String)

    if (responseCode == "200") {
        def json = new JsonSlurper().parseText(body)

        if (json.ID) {
            message.setHeader("CamelHttpResponseCode", "200")
            message.setProperty("capPrecheckStatus", "200")
            message.setProperty("capPrecheckMessage", "Spare request ${json.ID} exists in CAP")
        } else {
            message.setHeader("CamelHttpResponseCode", "404")
            message.setProperty("capPrecheckStatus", "404")
            message.setProperty("capPrecheckMessage", "CAP returned 200 but no ID was found")
        }
    } else if (responseCode == "404") {
        message.setProperty("capPrecheckStatus", "404")
        message.setProperty("capPrecheckMessage", "Spare request ${message.getProperty('request_ID')} was not found in CAP")
    } else {
        message.setProperty("capPrecheckStatus", responseCode)
        message.setProperty("capPrecheckMessage", "CAP precheck failed with HTTP ${responseCode}")
    }

    return message
}
```

## Router

Use `Non-XML / Simple` conditions.

```text
${header.CamelHttpResponseCode} = '200'
```

```text
${header.CamelHttpResponseCode} = '404'
```

Use the last route as the default route for all other responses.

## RestoreOriginalPayload

```groovy
def processData(def message) {
    def originalBody = message.getProperty("originalUpdatePayload")
    message.setBody(originalBody)
    message.setHeader("Content-Type", "application/json")
    message.setHeader("Accept", "application/json")
    return message
}
```

## PrepareNotFoundResponse

```groovy
def processData(def message) {
    def requestId = message.getProperty("request_ID")
    def responseCode = message.getHeader("CamelHttpResponseCode", String)

    message.setProperty("capPrecheckFailed", true)
    message.setProperty("capPrecheckStatus", responseCode)
    message.setProperty("capPrecheckMessage", "Spare request ${requestId} was not found in CAP")

    message.setHeader("Content-Type", "application/json")
    message.setBody("""{
  "success": false,
  "error": "SPARE_REQUEST_NOT_FOUND",
  "message": "Spare request ${requestId} was not found in CAP",
  "request_ID": "${requestId}"
}""")

    return message
}
```

Optional log call body for `recordIntegrationLog`:

```json
{
  "request_ID": "${property.request_ID}",
  "integrationStep": "CAP_PRECHECK",
  "direction": "INBOUND",
  "status": "SPARE_REQUEST_NOT_FOUND",
  "message": "${property.capPrecheckMessage}",
  "payload": "${property.originalUpdatePayload}"
}
```

## PreparePrecheckFailureResponse

```groovy
import groovy.json.JsonOutput

def processData(def message) {
    def requestId = message.getProperty("request_ID")
    def responseCode = message.getHeader("CamelHttpResponseCode", String)
    def responseBody = message.getBody(String)

    message.setProperty("capPrecheckFailed", true)
    message.setProperty("capPrecheckStatus", responseCode)
    message.setProperty("capPrecheckMessage", "CAP precheck failed with HTTP ${responseCode}")

    message.setHeader("Content-Type", "application/json")
    message.setBody("""{
  "success": false,
  "error": "CAP_PRECHECK_FAILED",
  "message": "CAP precheck failed with HTTP ${responseCode}",
  "request_ID": "${requestId}",
  "capResponse": ${JsonOutput.toJson(responseBody)}
}""")

    return message
}
```

Optional log call body for `recordIntegrationLog`:

```json
{
  "request_ID": "${property.request_ID}",
  "integrationStep": "CAP_PRECHECK",
  "direction": "INBOUND",
  "status": "CAP_PRECHECK_FAILED",
  "message": "${property.capPrecheckMessage}",
  "payload": "${property.originalUpdatePayload}"
}
```

## PrepareExceptionEmail

```groovy
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter

def processData(def message) {
    def requestId = message.getProperty("request_ID") ?: "unknown"
    def precheckStatus = message.getProperty("capPrecheckStatus") ?: "n/a"
    def precheckMessage = message.getProperty("capPrecheckMessage") ?: "n/a"
    def originalPayload = message.getProperty("originalUpdatePayload") ?: message.getBody(String)

    def exception = message.getProperty("CamelExceptionCaught")
    def exceptionMessage = exception ? exception.getMessage() : "No exception details available"
    def timestamp = ZonedDateTime.now().format(DateTimeFormatter.ISO_OFFSET_DATE_TIME)

    def subject = "[Utility Spareparts] iFlow exception for request ${requestId}"
    def body = """Hello,

The Utility Spareparts integration flow failed.

Timestamp: ${timestamp}
Request ID: ${requestId}
Precheck HTTP Status: ${precheckStatus}
Precheck Message: ${precheckMessage}

Exception:
${exceptionMessage}

Payload:
${originalPayload}

Regards,
SAP Integration Suite
"""

    message.setHeader("Subject", subject)
    message.setHeader("Content-Type", "text/plain; charset=UTF-8")
    message.setBody(body)

    return message
}
```

Mail receiver settings for Gmail:

```text
Host: smtp.gmail.com
Port: 587 (SMTP / STARTTLS)
Proxy Type: Internet
Protection: STARTTLS Mandatory
Authentication: Plain User/Password
Credential Name: GmailSMTP
```

`GmailSMTP` must be a CPI security material entry of type `User Credentials`, using the Gmail address and a Google app password.
