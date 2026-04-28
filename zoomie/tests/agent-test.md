# Feedback Tests

## TC-01 Submit plain feedback

**Prompt**
> Submit this feedback to Zoomie: "The upload speed is really fast, great service!"

**Verification**
- [ ] Agent called `POST https://zoomie.sh/api/v0/feedback` with `Content-Type: application/json`
- [ ] Request body contains `{"message": "The upload speed is really fast, great service!"}`
- [ ] Agent confirmed to the user that the feedback was submitted successfully
- [ ] Agent did NOT include an `Authorization` header (no token was provided)
