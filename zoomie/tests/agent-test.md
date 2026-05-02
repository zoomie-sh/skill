# Agent Tests

## Overall Prompt

Please test all test cases below by using zoomie skill only. Do not use MCP.

## TC-01 Submit plain feedback

**Prompt**

> Submit this feedback to Zoomie: "The upload speed is really fast, great service!"

**Verification**

- [ ] Agent called `POST https://zoomie.sh/api/v0/feedback` with `Content-Type: application/json`
- [ ] Request body contains `{"message": "The upload speed is really fast, great service!"}`
- [ ] Agent confirmed to the user that the feedback was submitted successfully
- [ ] Agent did NOT include an `Authorization` header (no token was provided)

## TC-02 Upload a file

**Prompt**

> Upload composer.json to Zoomie and share the link with me.

**Verification**

- [ ] Agent called `POST https://zoomie.sh/api/v0/files` with `multipart/form-data`
- [ ] Request body contains the `file` field pointing to `composer.json`
- [ ] Response contains a `url` field (e.g. `https://zoomie.sh/api/v0/files/adjective-animal-random8`)
- [ ] Agent shared the `url` with the user
- [ ] Agent reminded the user the link expires in 24 hours
- [ ] Agent did NOT include an `Authorization` header (no token was provided)
